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
                input wire            keylen,
                input wire [1 : 0]    taglen,

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
  localparam CTRL_IDLE = 3'h0;
  localparam CTRL_INIT = 3'h1;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [127 : 0] ctr_reg;
  reg [127 : 0] ctr_new;
  reg           ctr_we;

  reg [2 : 0]   gcm_ctrl_reg;
  reg [2 : 0]   gcm_ctrl_new;
  reg           gcm_ctrl_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg            aes_init;
  reg            aes_next;
  wire           aes_encdec;
  wire           aes_ready;
  wire           aes_valid;

  reg            ctr_init;
  reg            ctr_next;

  reg            gmult_next;
  wire           gmult_ready;
  reg [127 : 0]  gmult_a;
  reg [127 : 0]  gmult_b;
  wire [127 : 0] gmult_result;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  // We will only use the AES core for encryption. We hardwire
  // the operation. This will allow the synthesis tool to remove
  // the decryption datapath.
  assign aes_encdec = 1;


  //----------------------------------------------------------------
  // Core instantiations.
  //----------------------------------------------------------------
  aes_core aes(
               .clk(clk),
               .reset_n(reset_n),

               .encdec(aes_encdec),
               .init(aes_init),
               .next(aes_next),
               .ready(aes_ready),

               .key(key),
               .keylen(keylen),

               .block(block_in),
               .result(block_out),
               .result_valid(aes_valid)
              );


  gcm_gmult gmult(
                  .clk(clk),
                  .reset_n(reset_n),

                  .next(gmult_next),
                  .ready(gmult_ready),

                  .a(gmult_a),
                  .b(gmult_b),
                  .res(gmult_result)
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
          ctr_reg      <= 64'h0;
          gcm_ctrl_reg <= CTRL_IDLE;
        end
      else
        begin
          if (ctr_we)
            ctr_reg <= ctr_new;

          if (gcm_ctrl_we)
            gcm_ctrl_reg <= gcm_ctrl_new;

        end
    end // reg_update


  //----------------------------------------------------------------
  // ctr_logic
  //----------------------------------------------------------------
  always @*
    begin : ctr_logic
      ctr_new = 128'h0;
      ctr_we  = 0;

      if (ctr_init)
        begin
          ctr_new = nonce;
          ctr_we  = 1;
        end

      if (ctr_next)
        begin
          ctr_new = {ctr_reg[127 : 64], ctr_reg[63 : 0] + 1'b1};
          ctr_we  = 1;
        end
    end // ctr_logic


  //----------------------------------------------------------------
  // gcm_core_ctrl_fsm
  //----------------------------------------------------------------
  always @*
    begin : gcm_core_ctrl_fsm
      aes_init     = 0;
      aes_next     = 0;
      ctr_init     = 0;
      ctr_next     = 0;
      gcm_ctrl_new = CTRL_IDLE;
      gcm_ctrl_we  = 0;

      case (gcm_ctrl_reg)
        CTRL_IDLE:
          begin
            if (init)
              begin
                gcm_ctrl_new = CTRL_INIT;
                gcm_ctrl_we  = 1;
              end
          end

        CTRL_INIT:
          begin
            gcm_ctrl_new = CTRL_IDLE;
            gcm_ctrl_we  = 1;
          end

        default:
          begin
          end
      endcase // case (gcm_ctrl_reg)
    end // gcm_core_ctrl_fsm

endmodule // gcm_core

//======================================================================
// EOF gcm_core.v
//======================================================================
