#
# Makefile
# --------
# Makefile for building the Nettle ghash reference model.

CC ?= clang
CFLAGS ?= -std=c99 -Wall -Wextra -Wpedantic -O2
LDFLAGS ?=

.PHONY: all test clean

all: test_nettle_ghash_ref

test_nettle_ghash_ref: test_nettle_ghash_ref.o nettle_ghash_ref.o
	$(CC) $(LDFLAGS) -o $@ $^

%.o: %.c nettle_ghash_ref.h
	$(CC) $(CFLAGS) -c -o $@ $<

test: test_nettle_ghash_ref
	./test_nettle_ghash_ref

clean:
	rm -f test_nettle_ghash_ref *.o
