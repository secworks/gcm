GCM
===

Galois Counter Mode block cipher mode for AES.


## Introduction ##

This implementation supports 128 and 256 bit keys and 64, 96
or 128 bit TAG/ICV.


## Implementation results ##

Nothing yet.


## Status ##

***(2016-06-12)***

Implementation started (again). The top level is getting close to done
with the functionality needed to use the core. The core itself contains
an AES instance and is getting the first parts of the datapath and
control path.

There is a testbench for the top level to at least allow us to build
from the top level. The build system also supports linting.



## References ##

Recommendation for Block Cipher Modes of Operation: Galois/Counter Mode
(GCM) and GMAC
http://csrc.nist.gov/publications/nistpubs/800-38D/SP-800-38D.pdf

The Galois/Counter Mode of Operation (GCM):
http://csrc.nist.gov/groups/ST/toolkit/BCM/documents/proposedmodes/gcm/gcm-revised-spec.pdf

MACsecGCM-AESTestVectors.
http://www.ieee802.org/1/files/public/docs2011/bn-randall-test-vectors-0511-v1.pdf
