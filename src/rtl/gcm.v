//======================================================================
//
// gcm.v
// -----
// Top level wrapper for the AES-GCM block cipher mode core.
//
//
// Author: Joachim Strombergson
// Copyright (c) 2016, Secworks Sweden AB
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

module gcm(
           // Clock and reset.
           input wire           clk,
           input wire           reset_n,

           input wire           cs,
           input wire           we,
           input wire  [7 : 0]  address,
           input wire  [31 : 0] write_data,
           output wire [31 : 0] read_data
          );

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam ADDR_NAME0          = 8'h00;
  localparam ADDR_NAME1          = 8'h01;
  localparam ADDR_VERSION        = 8'h02;

  localparam ADDR_CTRL           = 8'h08;
  localparam CTRL_INIT_BIT       = 0;
  localparam CTRL_NEXT_BIT       = 1;
  localparam CTRL_DONE_BIT       = 2;

  localparam ADDR_STATUS         = 8'h09;
  localparam STATUS_READY_BIT    = 0;
  localparam STATUS_VALID_BIT    = 1;
  localparam STATUS_CORRECT_ICV  = 2;

  localparam ADDR_CONFIG         = 8'h0a;
  localparam CONFIG_ENCDEC_BIT   = 0;
  localparam CONFIG_KEYLEN_BIT   = 1;
  localparam CONFIG_TAGLEN_START = 4;
  localparam CONFIG_TAGLEN_END   = 5;

  localparam ADDR_KEY0           = 8'h10;
  localparam ADDR_KEY7           = 8'h17;
  localparam KEY_WORDS           = 8;

  localparam ADDR_BLOCK0         = 8'h20;
  localparam ADDR_BLOCK3         = 8'h23;
  localparam BLOCK_WORDS         = 4;

  localparam ADDR_NONCE0         = 8'h30;
  localparam ADDR_NONCE3         = 8'h33;
  localparam NONCE_WORDS         = 4;

  localparam ADDR_TAG0           = 8'h40;
  localparam ADDR_TAG3           = 8'h43;
  localparam TAG_WORDS           = 4;

  localparam WSIZE               = 32;

  localparam CORE_NAME0          = 32'h67636d2d; // "gcm-"
  localparam CORE_NAME1          = 32'h61657320; // "aes "
  localparam CORE_VERSION        = 32'h302e3032; // "0.02"


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg          init_reg;
  reg          init_new;

  reg          next_reg;
  reg          next_new;

  reg          done_reg;
  reg          done_new;

  reg          encdec_reg;
  reg          encdec_new;
  reg          encdec_we;

  reg          valid_reg;
  reg          ready_reg;
  reg          tag_correct_reg;

  reg [31 : 0] block_reg [0 : 3];
  reg          block_we;
  reg [1 : 0]  block_address;

  reg          keylen_reg;
  reg          keylen_new;
  reg          keylen_we;

  reg [31 : 0] key_reg [0 : 7];
  reg          key_we;
  reg [2 : 0]  key_address;

  reg [1 : 0]  taglen_reg;
  reg [1 : 0]  taglen_new;
  reg          taglen_we;

  reg [31 : 0] nonce_reg [0 : 3];
  reg          nonce_we;
  reg [1 : 0]  nonce_address;

  reg [31 : 0] tag_reg [0 : 3];
  reg          tag_we;
  reg [1 : 0]  tag_address;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [31 : 0]   tmp_read_data;

  reg            core_encdec;
  wire           core_ready;
  wire           core_valid;
  wire           core_tag_correct;

  wire [127 : 0] core_block_in;
  wire [127 : 0] core_block_out;

  wire [127 : 0] core_tag_in;
  wire [127 : 0] core_tag_out;

  wire [255 : 0] core_key;
  wire [127 : 0] core_nonce;
  wire           core_keylen;
  wire [127 : 0] core_result;

  reg            config_we;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign read_data = tmp_read_data;

  assign core_block_in = {block_reg[0], block_reg[1], block_reg[2], block_reg[3]};
  assign core_key    = {key_reg[0], key_reg[1], key_reg[2], key_reg[3],
                        key_reg[4], key_reg[5], key_reg[6], key_reg[7]};


  //----------------------------------------------------------------
  // GCM core instantiation.
  //----------------------------------------------------------------
  gcm_core core(
                .clk(clk),
                .reset_n(reset_n),

                .init(init_reg),
                .next(next_reg),
                .done(done_reg),

                .enc_dec(encdec_reg),
                .keylen(keylen_reg),
                .taglen(taglen_reg),

                .ready(core_ready),
                .valid(core_valid),
                .tag_correct(core_tag_correct),

                .key(core_key),
                .nonce(core_nonce),
                .block_in(core_block_in),
                .block_out(core_block_out),
                .tag_in(core_tag_in),
                .tag_out(core_tag_out)
               );


  //----------------------------------------------------------------
  // reg_update
  //
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with synchronous
  // active low reset.
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin : reg_update
      integer i;

      if (!reset_n)
        begin
          for (i = 0 ; i < 4 ; i = i + 1)
            begin
              block_reg[i] <= 32'h0;
              nonce_reg[i] <= 32'h0;
              tag_reg[i]   <= 32'h0;
            end

          for (i = 0 ; i < 8 ; i = i + 1)
            key_reg[i] <= 32'h0;

          init_reg   <= 0;
          next_reg   <= 0;
          done_reg   <= 0;
          encdec_reg <= 0;
          keylen_reg <= 0;
          taglen_reg <= 2'h0;
          valid_reg  <= 0;
          ready_reg  <= 0;
        end
      else
        begin
          ready_reg <= core_ready;
          valid_reg <= core_valid;
          init_reg  <= init_new;
          next_reg  <= next_new;
          done_reg  <= done_new;

          if (config_we)
            begin
              encdec_reg <= write_data[CONFIG_ENCDEC_BIT];
              keylen_reg <= write_data[CONFIG_KEYLEN_BIT];
              taglen_reg <= write_data[CONFIG_TAGLEN_END : CONFIG_TAGLEN_START];
            end

          if (keylen_we)
            keylen_reg <= keylen_new;

          if (taglen_we)
            taglen_reg <= taglen_new;

          if (encdec_we)
            encdec_reg <= encdec_new;

          if (block_we)
            block_reg[block_address] <= write_data;

          if (key_we)
            key_reg[key_address] <= write_data;

          if (nonce_we)
            key_reg[nonce_address] <= write_data;

          if (tag_we)
            key_reg[tag_address] <= write_data;
        end
    end // reg_update


  //----------------------------------------------------------------
  // api
  //
  // The interface command decoding logic.
  //----------------------------------------------------------------
  always @*
    begin : api
      init_new       = 0;
      next_new       = 0;
      done_new       = 0;
      config_we      = 0;
      key_we         = 0;
      block_we       = 0;
      nonce_we       = 0;
      tag_we         = 0;
      keylen_new     = 0;
      keylen_we      = 0;
      taglen_new     = 0;
      taglen_we      = 0;
      encdec_new     = 0;
      encdec_we      = 0;
      tmp_read_data  = 32'h0;

      key_address    = address[2 : 0];
      block_address  = address[1 : 0];
      nonce_address  = address[1 : 0];
      tag_address    = address[1 : 0];

      if (cs)
        begin
          if (we)
            begin
              if (address == ADDR_CTRL)
                  begin
                    init_new = write_data[CTRL_INIT_BIT];
                    next_new = write_data[CTRL_NEXT_BIT];
                    done_new = write_data[CTRL_DONE_BIT];
                  end

              if (address == ADDR_CONFIG)
                config_we = 1;

              if ((address >= ADDR_KEY0) && (address <= ADDR_KEY7))
                key_we = 1;

              if ((address >= ADDR_BLOCK0) && (address <= ADDR_BLOCK3))
                block_we = 1;

              if ((address >= ADDR_NONCE0) && (address <= ADDR_NONCE3))
                nonce_we = 1;

              if ((address >= ADDR_TAG0) && (address <= ADDR_TAG3))
                tag_we = 1;
            end // if (we)

          else
            begin
              if (address == ADDR_NAME0)
                tmp_read_data = CORE_NAME0;

              if (address == ADDR_NAME1)
                tmp_read_data = CORE_NAME1;

              if (address == ADDR_VERSION)
                tmp_read_data = CORE_VERSION;

              if (address == ADDR_CTRL)
                tmp_read_data = {30'h0, next_reg, init_reg};

              if (address == ADDR_STATUS)
                tmp_read_data = {30'h0, valid_reg, ready_reg};

              if (address == ADDR_CONFIG)
                tmp_read_data = {30'h0, valid_reg, ready_reg};

              if ((address >= ADDR_KEY0) && (address <= ADDR_KEY7))
                tmp_read_data = key_reg[key_address];

              if ((address >= ADDR_BLOCK0) && (address <= ADDR_BLOCK3))
                tmp_read_data = block_reg[block_address];

              if ((address >= ADDR_NONCE0) && (address <= ADDR_NONCE3))
                tmp_read_data = block_reg[nonce_address];

              if ((address >= ADDR_TAG0) && (address <= ADDR_TAG3))
                tmp_read_data = block_reg[tag_address];
            end
        end
    end // addr_decoder
endmodule // aes

//======================================================================
// EOF aes.v
//======================================================================
