# nettle_ghash_ref

This is a small, standalone reference implementation (model) of GHASH
as specified in [NIST SP 800-38D
(GCM)](https://csrc.nist.gov/pubs/sp/800/38/d/final). The reference
model is extracted from the gcm implementation in the [Nettle
cryptographic library](https://www.lysator.liu.se/~nisse/nettle/)

The purpose of the model is to drive the HW implementation by
generating testvectors that the testbench can read and execute.

## Details
The code is extracted from GNU Nettle's `gcm.c` with `GCM_TABLE_BITS == 0`.

`nettle_ghash_ref()` computes raw GHASH state `Y` with implicit zero padding for
a final partial block, matching Nettle's internal `gcm_hash()` behavior.


## License
The top level test driver 'test_nettle_ghash_ref.c' as well as the
header file is licensed under the rest of the GCM project. The
reference implementation exctracted from Nettle is licensed under the
same license as the Nettle library:

```
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
```

---
