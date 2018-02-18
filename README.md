GCM
===
Galois Counter Mode block cipher mode for AES as specified in NIST SP
800-38D (GCM) [1] and compatible with RFC5288 - AES Galois Counter Mode
(GCM) Cipher Suites for TLS [2].


## Introduction ##

This implementation supports 128 and 256 bit keys and 64, 96
or 128 bit TAG/ICV.



## Status ##

Not completed. Does not yet work.
The GHASH module (gcm_mult.v) is far from being completed.

The top level is getting close to done with the functionality needed to
use the core. The core itself contains an AES instance and is getting
the first parts of the datapath and control path.

There is a testbench for the top level to at least allow us to build
from the top level. The build system also supports linting.

For more info, see the git log.


## Implementation results ##

Nothing yet.



## References ##

[1] Recommendation for Block Cipher Modes of Operation: Galois/Counter Mode
(GCM) and GMAC
http://csrc.nist.gov/publications/nistpubs/800-38D/SP-800-38D.pdf

[2] IETF. AES Galois Counter Mode (GCM) Cipher Suites for TLS. RFC5288.
https://tools.ietf.org/html/rfc5288

[3] The Galois/Counter Mode of Operation (GCM):
http://csrc.nist.gov/groups/ST/toolkit/BCM/documents/proposedmodes/gcm/gcm-revised-spec.pdf

[4] MACsecGCM-AESTestVectors.
http://www.ieee802.org/1/files/public/docs2011/bn-randall-test-vectors-0511-v1.pdf
