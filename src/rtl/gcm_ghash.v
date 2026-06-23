//======================================================================
//
// gcm_ghash.v
// -----------
// GHASH module for the GCM core.
//
//
// Author: Joachim Strombergson
// Copyright (c) 2018, 2026 Assured AB
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

`default_nettype none

module gcm_ghash(
                 input  wire         clk,
                 input  wire         reset_n,

                 input  wire         init,
                 input  wire         next,

                 input  wire [127:0] h,
                 input  wire [127:0] block,

                 output wire         ready,
                 output wire [127:0] y
                );

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam CTRL_IDLE  = 1'h0;
  localparam CTRL_ROUND = 1'h1;

  localparam LOGIC_IDLE = 2'h0;
  localparam LOGIC_INIT = 2'h1;
  localparam LOGIC_NEXT = 2'h2;
  localparam LOGIC_GMUL = 2'h3;

  //----------------------------------------------------------------
  // Registers including update vectors and contol.
  //----------------------------------------------------------------
  reg [127:0] h_reg;
  reg [127:0] h_new;
  reg         h_we;

  reg [127:0] v_reg;
  reg [127:0] v_new;
  reg         v_we;

  reg [127:0] x_reg;
  reg [127:0] x_new;
  reg         x_we;

  reg [127:0] y_reg;
  reg [127:0] y_new;
  reg         y_we;

  reg [3:0]  round_ctr_reg;
  reg [3:0]  round_ctr_new;
  reg        round_ctr_rst;
  reg        round_ctr_inc;
  reg        round_ctr_we;

  reg        ready_reg;
  reg        ready_new;
  reg        ready_we;

  reg        gcm_ghash_ctrl_reg;
  reg        gcm_ghash_ctrl_new;
  reg        gcm_ghash_ctrl_we;

  //----------------------------------------------------------------
  // wires
  //----------------------------------------------------------------
  reg [1 : 0] logic_ctrl;

  //----------------------------------------------------------------
  // Funnctions.
  //----------------------------------------------------------------
  function automatic [127 : 0] gf_shift(input [127:0] v);
    begin
      if (v[0])
        gf_shift = (v >> 1) ^ 128'he1000000000000000000000000000000;
      else
        gf_shift = (v >> 1);
    end
  endfunction // gf_shift

  //----------------------------------------------------------------
  // Concurrent connectivity for ports.
  //----------------------------------------------------------------
  assign ready = ready_reg;
  assign y     = y_reg;

  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @(posedge clk) begin
    if (!reset_n) begin
      h_reg              <= 128'h0;
      y_reg              <= 128'h0;
      v_reg              <= 128'h0;
      x_reg              <= 128'h0;
      round_ctr_reg      <= 4'h0;
      gcm_ghash_ctrl_reg <= CTRL_IDLE;
      ready_reg          <= 1'h1;
    end

    else begin
      if (h_we) begin
        h_reg <= h_new;
      end

      if (v_we) begin
        v_reg <= v_new;
      end

      if (x_we) begin
        x_reg <= x_new;
      end

      if (y_we) begin
        y_reg <= y_new;
      end

      if (round_ctr_we) begin
        round_ctr_reg <= round_ctr_new;
      end

      if (ready_we) begin
        ready_reg <= ready_new;
      end

      if (gcm_ghash_ctrl_we) begin
        gcm_ghash_ctrl_reg <= gcm_ghash_ctrl_new;
      end
    end
  end

  //----------------------------------------------------------------
  // round_ctr
  //----------------------------------------------------------------
  always @*
    begin: round_ctr
      round_ctr_new = 4'h0;
      round_ctr_we  = 1'h0;

      if (round_ctr_rst) begin
        round_ctr_new = 4'h0;
        round_ctr_we  = 1'h1;
        end
      else if (round_ctr_inc) begin
        round_ctr_new = round_ctr_reg + 1'h1;
        round_ctr_we  = 1'h1;
      end
    end

  //----------------------------------------------------------------
  // ghash_logic
  //----------------------------------------------------------------
  always @*
    begin: round_logic
      integer     i;

      h_new = 128'h0;
      v_new = 128'h0;
      x_new = 128'h0;
      y_new = 128'h0;
      h_we  = 1'h0;
      v_we  = 1'h0;
      x_we  = 1'h0;
      y_we  = 1'h0;

      case (logic_ctrl)
        LOGIC_IDLE: begin
          // We do nothing
        end

        LOGIC_INIT: begin
          h_new = h;
          v_new = 128'h0;
          x_new = 128'h0;
          y_new = 128'h0;
          h_we  = 1'h1;
          v_we  = 1'h1;
          x_we  = 1'h1;
          y_we  = 1'h1;
        end

        LOGIC_NEXT: begin
          v_new = h_reg;
          v_we  = 1'h1;
          x_new = y_reg ^ block;
          x_we  = 1'h1;
          y_new = 128'h0;
          y_we  = 1'h1;
        end

        LOGIC_GMUL: begin
          v_new = v_reg;
          x_new = x_reg;
          y_new = y_reg;

          for (i = 0; i < 8; i = i + 1) begin
            if (x_new[127]) begin
              y_new = y_new ^ v_new;
            end
            v_new = gf_shift(v_new);
            x_new = {x_new[126:0], 1'b0};
          end
          v_we  = 1'h1;
          x_we  = 1'h1;
          y_we  = 1'h1;
        end

        default: begin end
      endcase // case (logic_ctrl)
    end

  //----------------------------------------------------------------
  // gcm_ghash_crtl
  //----------------------------------------------------------------
  always @*
    begin: gcm_ghash_ctrl
      ready_new          = 1'h0;
      ready_we           = 1'h0;
      round_ctr_rst      = 1'h0;
      round_ctr_inc      = 1'h0;
      logic_ctrl         = LOGIC_IDLE;
      gcm_ghash_ctrl_new = CTRL_IDLE;
      gcm_ghash_ctrl_we  = 1'h0;

      case(gcm_ghash_ctrl_reg)
        CTRL_IDLE: begin
          if (init) begin
            logic_ctrl = LOGIC_INIT;
          end

          if (next) begin
            ready_new     = 1'h0;
            ready_we      = 1'h1;
            round_ctr_rst = 1'h0;
            logic_ctrl    = LOGIC_NEXT;
            gcm_ghash_ctrl_new = CTRL_ROUND;
            gcm_ghash_ctrl_we  = 1'h1;
          end
        end

        CTRL_ROUND: begin
          logic_ctrl    = LOGIC_GMUL;
          round_ctr_inc = 1'h1;

          if (round_ctr_reg == 4'hf) begin
            ready_new          = 1'h1;
            ready_we           = 1'h1;
            gcm_ghash_ctrl_new = CTRL_IDLE;
            gcm_ghash_ctrl_we  = 1'h1;
          end
        end

        default: begin end
      endcase // case (gcm_ghash_ctrl_reg)
    end

endmodule // gcm_ghash

//======================================================================
// EOF gcm_ghash.v
//======================================================================
