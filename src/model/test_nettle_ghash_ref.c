//======================================================================
//
// test_nettle_ref.c
// -----------------
// Application that use the Nettle ghash implementation to verify
// the NIST testvectors. And then generate new testvectors to drive
// verificstion of the ghash hw implementatiom.
//
//
// Author: Joachim Strombergson
// Copyright (c) 2026, Assured AB
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or
// without modification, are permitted provided that the following
// conditions are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================

#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "nettle_ghash_ref.h"

typedef struct {
  const char *name;
  const char *h_hex;
  const char *data_hex;
  const char *expected_y_hex;
} test_vector;

static int hexval(int c)
{
  if ('0' <= c && c <= '9') return c - '0';
  if ('a' <= c && c <= 'f') return c - 'a' + 10;
  if ('A' <= c && c <= 'F') return c - 'A' + 10;
  return -1;
}

static size_t compact_hex_len(const char *s)
{
  size_t n = 0;

  for (; *s; s++) {
    if (isxdigit((unsigned char)*s)) {
      n++;
    }
  }

  return n;
}

static int parse_hex(const char *hex, uint8_t **out, size_t *out_len)
{
  size_t digits = compact_hex_len(hex);
  uint8_t *buf;
  size_t pos = 0;
  int high = -1;

  if ((digits & 1u) != 0) {
    fprintf(stderr, "odd number of hex digits\n");
    return 0;
  }

  buf = calloc(digits / 2u ? digits / 2u : 1u, 1);
  if (!buf) {
    perror("calloc");
    return 0;
  }

  for (; *hex; hex++) {
    int v = hexval((unsigned char)*hex);

    if (v < 0) {
      if (isspace((unsigned char)*hex) || *hex == ':' || *hex == '_') {
        continue;
      }
      fprintf(stderr, "invalid hex character: '%c'\n", *hex);
      free(buf);
      return 0;
    }

    if (high < 0) {
      high = v;
    } else {
      buf[pos++] = (uint8_t)((high << 4) | v);
      high = -1;
    }
  }

  *out = buf;
  *out_len = pos;
  return 1;
}

static int parse_hex_fixed16(const char *hex, uint8_t out[16])
{
  uint8_t *buf = NULL;
  size_t len = 0;

  if (!parse_hex(hex, &buf, &len)) {
    return 0;
  }

  if (len != 16) {
    fprintf(stderr, "expected 16 bytes, got %zu\n", len);
    free(buf);
    return 0;
  }

  memcpy(out, buf, 16);
  free(buf);
  return 1;
}

static void print_hex(const uint8_t *x, size_t len)
{
  for (size_t i = 0; i < len; i++) {
    printf("%02x", x[i]);
  }
}

/*
 * These are GHASH values from the NIST SP 800-38D GCM examples, expressed as
 * raw GHASH input streams. For the full-GCM cases, data_hex is A || C || len(A)||len(C)
 * where the final length block uses 64-bit big-endian bit lengths.
 */
static const test_vector vectors[] = {
  {
    .name = "NIST SP800-38D, Test Case 2: GHASH(C || len), AES-128 zero key/plaintext",
    .h_hex = "66e94bd4ef8a2c3b884cfa59ca342b2e",
    .data_hex =
      "0388dace60b6a392f328c2b971b2fe78"
      "00000000000000000000000000000080",
    .expected_y_hex = "f38cbb1ad69223dcc3457ae5b6b0f885",
  },
  {
    .name = "NIST SP800-38D, same H: raw one-block GHASH(C) intermediate",
    .h_hex = "66e94bd4ef8a2c3b884cfa59ca342b2e",
    .data_hex = "0388dace60b6a392f328c2b971b2fe78",
    .expected_y_hex = "5e2ec746917062882c85b0685353deb7",
  },
  {
    .name = "NIST SP800-38D, Test Case 1 equivalent: empty GHASH input",
    .h_hex = "66e94bd4ef8a2c3b884cfa59ca342b2e",
    .data_hex = "",
    .expected_y_hex = "00000000000000000000000000000000",
  },
};

int main(void)
{
  unsigned failures = 0;
  const size_t n_vectors = sizeof(vectors) / sizeof(vectors[0]);

  for (size_t i = 0; i < n_vectors; i++) {
    uint8_t h[16];
    uint8_t expected[16];
    uint8_t y[16];
    uint8_t *data = NULL;
    size_t data_len = 0;
    int ok;

    printf("[%zu/%zu] %s\n", i + 1, n_vectors, vectors[i].name);

    ok = parse_hex_fixed16(vectors[i].h_hex, h) &&
         parse_hex(vectors[i].data_hex, &data, &data_len) &&
         parse_hex_fixed16(vectors[i].expected_y_hex, expected);

    if (!ok) {
      free(data);
      return 2;
    }

    nettle_ghash_ref(h, data, data_len, y);

    if (memcmp(y, expected, 16) != 0) {
      printf("  FAIL\n");
      printf("  got      "); print_hex(y, 16); printf("\n");
      printf("  expected "); print_hex(expected, 16); printf("\n");
      failures++;
    } else {
      printf("  PASS     "); print_hex(y, 16); printf("\n");
    }

    free(data);
  }

  if (failures) {
    printf("\n%u test(s) failed\n", failures);
    return 1;
  }

  printf("\nAll GHASH tests passed\n");
  return 0;
}
//======================================================================
// EOF test_nettle_ref.c
//======================================================================
