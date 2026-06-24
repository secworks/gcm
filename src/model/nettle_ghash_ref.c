/*
 * nettle_ghash_ref.c
 *
 * Small standalone GHASH reference extracted from GNU Nettle's gcm.c logic,
 * specifically the GCM_TABLE_BITS == 0 path:
 *   - gcm_gf_add
 *   - gcm_gf_shift
 *   - gcm_gf_mul
 *   - gcm_hash
 *
 * Original Nettle gcm.c copyright notice:
 *   Copyright (C) 2011, 2013 Niels Möller
 *   Copyright (C) 2011 Katholieke Universiteit Leuven
 *   Contributed by Nikos Mavrogiannopoulos
 *
 * GNU Nettle is free software: you can redistribute it and/or modify it under
 * the terms of either:
 *   - the GNU Lesser General Public License as published by the Free Software
 *     Foundation; either version 3 of the License, or (at your option) any
 *     later version, or
 *   - the GNU General Public License as published by the Free Software
 *     Foundation; either version 2 of the License, or (at your option) any
 *     later version,
 * or both in parallel.
 *
 * This file keeps the algorithmic structure of the original bitwise Nettle
 * implementation but uses byte arrays directly to avoid depending on Nettle's
 * internal union nettle_block16, config macros, endian macros, memxor, etc.
 */

#include "nettle_ghash_ref.h"

#include <string.h>

#define GHASH_POLYNOMIAL 0xe1u

typedef struct {
  uint8_t b[16];
} block16;

static void gcm_gf_add(block16 *r, const block16 *x, const block16 *y)
{
  for (size_t i = 0; i < 16; i++) {
    r->b[i] = (uint8_t)(x->b[i] ^ y->b[i]);
  }
}

/*
 * Multiplication by 010...0, i.e. a right shift in the big-endian GHASH
 * representation. If the shifted-out bit is one, add the reduction polynomial.
 * r == x is allowed.
 */
static void gcm_gf_shift(block16 *r, const block16 *x)
{
  uint8_t carry = 0;
  uint8_t shifted_out = (uint8_t)(x->b[15] & 1u);
  uint8_t tmp[16];

  for (size_t i = 0; i < 16; i++) {
    uint8_t next_carry = (uint8_t)(x->b[i] & 1u);
    tmp[i] = (uint8_t)((x->b[i] >> 1) | (carry << 7));
    carry = next_carry;
  }

  if (shifted_out) {
    tmp[0] ^= GHASH_POLYNOMIAL;
  }

  memcpy(r->b, tmp, sizeof(tmp));
}

/*
 * Sets x <- x * y mod r, using the plain bitwise algorithm from the GCM
 * specification. This is the Nettle GCM_TABLE_BITS == 0 multiplication path.
 */
static void gcm_gf_mul(block16 *x, const block16 *y)
{
  block16 V;
  block16 Z;

  memcpy(V.b, x->b, sizeof(V.b));
  memset(Z.b, 0, sizeof(Z.b));

  for (size_t i = 0; i < 16; i++) {
    uint8_t b = y->b[i];

    for (unsigned j = 0; j < 8; j++, b <<= 1) {
      if (b & 0x80u) {
        gcm_gf_add(&Z, &Z, &V);
      }
      gcm_gf_shift(&V, &V);
    }
  }

  memcpy(x->b, Z.b, sizeof(Z.b));
}

static void gcm_hash(const block16 *h, block16 *x, size_t length, const uint8_t *data)
{
  while (length >= 16) {
    for (size_t i = 0; i < 16; i++) {
      x->b[i] ^= data[i];
    }

    gcm_gf_mul(x, h);

    data += 16;
    length -= 16;
  }

  if (length > 0) {
    for (size_t i = 0; i < length; i++) {
      x->b[i] ^= data[i];
    }

    gcm_gf_mul(x, h);
  }
}

void nettle_ghash_ref(const uint8_t h[16],
                      const uint8_t *data,
                      size_t len,
                      uint8_t y[16])
{
  block16 hh;
  block16 yy;

  memcpy(hh.b, h, sizeof(hh.b));
  memset(yy.b, 0, sizeof(yy.b));

  if (len != 0) {
    gcm_hash(&hh, &yy, len, data);
  }

  memcpy(y, yy.b, sizeof(yy.b));
}

void nettle_ghash_ref_blocks(const uint8_t h[16],
                             const uint8_t *blocks,
                             size_t num_blocks,
                             uint8_t y[16])
{
  nettle_ghash_ref(h, blocks, num_blocks * 16, y);
}
