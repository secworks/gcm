# nettle_ghash_ref
## Introduction

This is a small, standalone SP 800-38D GHASH reference implementation
extracted from GNU Nettle's `gcm.c` with `GCM_TABLE_BITS == 0`. The
purpose is to geneerate testvectors to drive the HW implementation.

`nettle_ghash_ref()` computes raw GHASH state `Y` with implicit zero padding for
a final partial block, matching Nettle's internal `gcm_hash()` behavior.

Files:
- `nettle_ghash_ref.c` — extracted GHASH implementation.
- `nettle_ghash_ref.h` — public header.
- `test_nettle_ghash_ref.c` — Testvector generator.
- `Makefile` — build and run tests.
