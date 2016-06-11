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

AES_SRC=../../aes/src/rtl/*.v

CORE_SRC=../src/rtl/gcm_core.v

TOP_SRC=../src/rtl/gcm.v $(CORE_SRC)
TOP_TB_SRC=../src/tb/tb_gcm.v

CC=iverilog
LINT=verilator


all: top.sim


top.sim: $(TOP_TB_SRC) $(TOP_SRC)
	$(CC) -o top.sim $(TOP_TB_SRC) $(TOP_SRC)


sim-top: top.sim
	./top.sim


lint:
	verilator --lint-only  -Wall -Wno-fatal -Wno-DECLFILENAME $(TOP_SRC)


debug:
	@echo "No debug available."


clean:
	rm -f top.sim


help:
	@echo "Supported targets:"
	@echo "------------------"
	@echo "all:      Build all simulation targets."
	@echo "wb:       Build the Wishbone simulation target."
	@echo "top:      Build the top simulation target."
	@echo "core:     Build the core simulation target."
	@echo "sim-top:  Run top level simulation."
	@echo "sim-core: Run core level simulation."
	@echo "lint:     Run the linter on both the block based and the stream based top levels."
	@echo "debug:    Print the internal varibles."
	@echo "clean:    Delete all built files."

#===================================================================
# EOF Makefile
#===================================================================