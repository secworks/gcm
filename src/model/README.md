# nettle_ghash_ref

This is a small, standalone reference implementation (model) of GHASH
as specified in [NIST SP 800-38D
(GCM)](https://csrc.nist.gov/pubs/sp/800/38/d/final). The reference
model is extracted from the gcm implementation in the [Nettle
cryptographic library](https://www.lysator.liu.se/~nisse/nettle/)

The purpose of the model is to drive the HW implementation by
generating testvectors that the testbench can read and execute.

Details
The code is extracted from GNU Nettle's `gcm.c` with `GCM_TABLE_BITS == 0`.

`nettle_ghash_ref()` computes raw GHASH state `Y` with implicit zero padding for
a final partial block, matching Nettle's internal `gcm_hash()` behavior.
