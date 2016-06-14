//======================================================================
//
// gcm_gmult.v
// -----------
// Galois Multiplies for the GCM core.
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

module gcm_gmult(
                 input wire            clk,
                 input wire            reset_n,

                 input wire            next,
                 output wire           ready,

                 input wire [127 : 0]  a,
                 input wire [127 : 0]  b,
                 output wire [127 : 0] res
                );

  //----------------------------------------------------------------
  // Defines.
  //----------------------------------------------------------------
  localparam CTRL_IDLE = 2'h0;
  localparam CTRL_INIT = 2'h1;
  localparam CTRL_CTR  = 2'h2;
  localparam CTRL_DONE = 2'h3;


  //----------------------------------------------------------------
  // Gaolis multiplication functions.
  //----------------------------------------------------------------
  function [7 : 0] gm2(input [7 : 0] op);
    begin
      gm2 = {op[6 : 0], 1'b0} ^ (8'h1b & {8{op[7]}});
    end
  endfunction // gm2

  function [7 : 0] gm3(input [7 : 0] op);
    begin
      gm3 = gm2(op) ^ op;
    end
  endfunction // gm3

  function [7 : 0] gm4(input [7 : 0] op);
    begin
      gm4 = gm2(gm2(op));
    end
  endfunction // gm4

  function [7 : 0] gm7(input [7 : 0] op);
    begin
      gm7 = gm3(op) ^ gm3(op) ^ gm2(op);
    end
  endfunction // gm09

  function [7 : 0] gm8(input [7 : 0] op);
    begin
      gm8 = gm2(gm4(op));
    end
  endfunction // gm8

  function [7 : 0] gm128(input [7 : 0] op);
    begin
      gm128 = gm2(gm8(gm8(op)));
    end
  endfunction // gm8

  //----------------------------------------------------------------
  // Registers.
  //----------------------------------------------------------------
  reg           ready_reg;
  reg           ready_new;

  reg [127 : 0] res_reg;
  reg [127 : 0] res_new;
  reg           res_we;

  reg [1 : 0]   gmult_ctrl_reg;
  reg [1 : 0]   gmult_ctrl_new;
  reg           gmult_ctrl_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------

  //----------------------------------------------------------------
  // Concurrent assignments.
  //----------------------------------------------------------------
  assign ready = ready_reg;
  assign res   = res_reg;


  //----------------------------------------------------------------
  // reg_update
  //
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with synchronous
  // active low reset.
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin : reg_update
      if (!reset_n)
        begin
          ready_reg <= 0;
          res_reg   <= 128'h0;
        end
      else
        begin
          ready_reg <= ready_new;

          if (res_we)
            res_reg <= res_new;

          if (gmult_ctrl_we)
            gmult_ctrl_reg <= gmult_ctrl_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // gmult_dp
  //----------------------------------------------------------------
  always @*
    begin : gmult_dp
      res_we = 0;
      res_new = 128'h0;

    end // gmult_dp


  //----------------------------------------------------------------
  // gmult_ctrl
  //----------------------------------------------------------------
  always @*
    begin : gmult_ctrl
      ready_new     = 0;
      gmult_ctrl_new = CTRL_IDLE;
      gmult_ctrl_we  = 0;

      case (gmult_ctrl_reg)
        CTRL_IDLE:
          begin
            ready_new = 1;
            if (next)
              begin
                gmult_ctrl_new = CTRL_INIT;
                gmult_ctrl_we  = 1;
              end
          end

        CTRL_INIT:
          begin
            gmult_ctrl_new = CTRL_IDLE;
            gmult_ctrl_we  = 1;
          end

        CTRL_CTR:
          begin
          end

        CTRL_DONE:
          begin
          end

        default:
          begin
          end
      endcase // case (gmult_ctrl_reg)
    end // gmult_ctrl

endmodule // gcm_gmult

//======================================================================
// EOF gcm_gmult.v
//======================================================================
