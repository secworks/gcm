/*
 * nettle_ghash_ref.h
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

#ifndef NETTLE_GHASH_REF_H
#define NETTLE_GHASH_REF_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define NETTLE_GHASH_REF_BLOCK_SIZE 16

/*
 * Compute raw GHASH state Y over data using hash subkey h.
 *
 * Semantics match Nettle's internal gcm_hash() for GCM_TABLE_BITS == 0:
 *   Y_0 = 0
 *   Y_i = (Y_{i-1} xor X_i) * H
 *
 * Full 16-byte blocks are consumed directly. If len is not a multiple of 16,
 * the final partial block is implicitly zero-padded on the right.
 *
 * h and y are 16 bytes. data may be NULL only when len == 0.
 */
void nettle_ghash_ref(const uint8_t h[16],
                      const uint8_t *data,
                      size_t len,
                      uint8_t y[16]);

/* Convenience wrapper for an integer number of 16-byte blocks. */
void nettle_ghash_ref_blocks(const uint8_t h[16],
                             const uint8_t *blocks,
                             size_t num_blocks,
                             uint8_t y[16]);

#ifdef __cplusplus
}
#endif

#endif /* NETTLE_GHASH_REF_H */
