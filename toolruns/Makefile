#===================================================================
#
# Makefile
# --------
# Makefile for building gcm core and top simulations.
#
#
# Author: Joachim Strombergson
# Copyright (c) 2016, Secworks Sweden AB
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or
# without modification, are permitted provided that the following
# conditions are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#===================================================================

AES_SRC = ../../aes/src/rtl/aes_core.v ../../aes/src/rtl/aes_decipher_block.v ../../aes/src/rtl/aes_encipher_block.v ../../aes/src/rtl/aes_inv_sbox.v ../../aes/src/rtl/aes_key_mem.v ../../aes/src/rtl/aes_sbox.v

GHASH_SRC = ../src/rtl/gcm_ghash.v
GHASH_TB_SRC = ../src/tb/tb_gcm_ghash.v

CORE_SRC = ../src/rtl/gcm_core.v $(AES_SRC) $(GHASH_SRC)
CORE_TB_SRC = ../src/tb/tb_gcm_core.v

TOP_SRC = ../src/rtl/gcm.v $(CORE_SRC)
TOP_TB_SRC = ../src/tb/tb_gcm.v

CC = iverilog
CC_FLAGS = -Wall

LINT = verilator
LINT_FLAGS = +1364-2001ext+ --lint-only -Wall -Wno-fatal -Wno-DECLFILENAME


all: top.sim core.sim ghash.sim


top.sim:	$(TOP_TB_SRC) $(TOP_SRC)
		$(CC) $(CC_FLAGS) -o top.sim $(TOP_TB_SRC) $(TOP_SRC)


core.sim:	$(CORE_TB_SRC) $(CORE_SRC)
		$(CC) $(CC_FLAGS) -o core.sim $(CORE_SRC) $(CORE_TB_SRC)

ghash.sim:	$(GHASH_TB_SRC) $(GHASH_SRC)
		$(CC) $(CC_FLAGS) -o core.sim $(GHASH_SRC) $(GHASH_TB_SRC)


sim-top: 	top.sim
		./top.sim


sim-core: 	core.sim
		./core.sim


sim-ghash: 	ghash.sim
		./ghash.sim


lint: $(TOP_SRC)
	$(LINT) $(LINT_FLAGS) $(TOP_SRC)


clean:
	rm -f *.sim


help:
	@echo "Supported targets:"
	@echo "------------------"
	@echo "all:       Build all simulation targets."
	@echo "top.sim:   Build the top simulation target."
	@echo "core.sim:  Build the core simulation target."
	@echo "ghash.sim: Build the core simulation target."
	@echo "sim-top:   Run top level simulation."
	@echo "sim-core:  Run core level simulation."
	@echo "sim-ghash: Run core level simulation."
	@echo "lint:      Run the linter on the source."
	@echo "clean:    Delete all built files."

#===================================================================
# EOF Makefile
#===================================================================
