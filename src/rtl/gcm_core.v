//======================================================================
//
// gcm_core.v
// ----------
// Galois Counter Mode core for AES.
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

module gcm_core(
                input wire            clk,
                input wire            reset_n,

                input wire            init,
                input wire            next,
                input wire            done,

                input wire            enc_dec,
                input wire            key_size,
                input wire [1 : 0]    tag_size,

                output wire           ready,
                output wire           valid,
                output wire           tag_correct,

                input wire [255 : 0]  key,
                input wire [127 : 0]  nonce,
                input wire [127 : 0]  block_in,
                output wire [127 : 0] block_out,
                input wire [127 : 0]  tag_in,
                output wire [127 : 0] tag_out
               );

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam GCM_CTRL_IDLE = 3'h0;
  localparam GCM_CTRL_INIT = 3'h1;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [2 : 0] gcm_ctrl_reg;
  reg [2 : 0] gcm_ctrl_new;
  reg         gcm_ctrl_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [31 : 0]   tmp_read_data;
  reg            tmp_error;

  wire           aes_encdec;
  wire           aes_ready;
  wire [127 : 0] aes_block;
  wire [255 : 0] aes_key;
  wire           aes_keylen;
  wire [127 : 0] aes_result;
  wire           aes_valid;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign aes_encdec = 1;


  //----------------------------------------------------------------
  // AES core instantiation.
  //----------------------------------------------------------------
  aes_core core(
                .clk(clk),
                .reset_n(reset_n),

                .encdec(aes_encdec),
                .init(aes_init),
                .next(aes_next),
                .ready(aes_ready),

                .key(aes_key),
                .keylen(aes_keylen),

                .block(aes_block),
                .result(aes_result),
                .result_valid(aes_valid)
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
          gcm_ctrl_reg <= GCM_CTRL_IDLE;
        end
      else
        begin
          if (gcm_ctrl_we)
            gcm_ctrl_reg <= gcm_ctrl_new;

        end
    end // reg_update


  //----------------------------------------------------------------
  // gcm_core_ctrl_fsm
  //----------------------------------------------------------------
  always @*
    begin : gcm_core_ctrl_fsm

    end // gcm_core_ctrl_fsm

endmodule // gcm_core

//======================================================================
// EOF gcm_core.v
//======================================================================
