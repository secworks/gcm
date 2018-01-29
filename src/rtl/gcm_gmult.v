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
                 input wire [127 : 0]  opa,
                 output wire [127 : 0] res
                );


  //----------------------------------------------------------------
  // Gaolis multiplication functions.
  //----------------------------------------------------------------
  function [127 : 0] gm2(input [127 : 0] op);
    begin
      gm2 = {op[126 : 0], 1'b0} ^ (128'h1b & {128{op[127]}});
    end
  endfunction // gm2

  function [127 : 0] gm3(input [127 : 0] op);
    begin
      gm3 = gm2(op) ^ op;
    end
  endfunction // gm3

  function [127 : 0] gm4(input [127 : 0] op);
    begin
      gm4 = gm2(gm2(op));
    end
  endfunction // gm4

  function [127 : 0] gm7(input [127 : 0] op);
    begin
      gm7 = gm4(op) ^ gm3(op);
    end
  endfunction // gm7

  function [127 : 0] gm8(input [127 : 0] op);
    begin
      gm8 = gm2(gm4(op));
    end
  endfunction // gm8

  function [127 : 0] gm16(input [127 : 0] op);
    begin
      gm16 = gm4(gm4(op));
    end
  endfunction // gm16

  function [127 : 0] gm128(input [127 : 0] op);
    begin
      gm128 = gm8(gm16(op));
    end
  endfunction // gm128


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [127 : 0] op_reg;
  reg [127 : 0] res_new;
  reg [127 : 0] res_reg;

  reg [127 : 0] pipe1_reg;
  reg [127 : 0] pipe1_new;
  reg [127 : 0] pipe2_reg;
  reg [127 : 0] pipe2_new;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign res = res_reg;


  //----------------------------------------------------------------
  // reg_update
  //
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with synchronous
  // active low reset. All registers have write enable.
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin: reg_update
      if (!reset_n)
        begin
          op_reg    <= 128'h0;
          res_reg   <= 128'h0;
          pipe1_reg <= 128'h0;
          pipe2_reg <= 128'h0;
        end
      else
        begin
          op_reg    <= op;
          res_reg   <= res_new;
          pipe1_reg <= pipe1_new;
          pipe2_reg <= pipe2_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // gmult_logic
  //----------------------------------------------------------------
  always @*
    begin : gmult_logic
      pipe1_new = gm128(op_reg);
      pipe2_new = gm7(op_reg) + gm2(op_reg) + op_reg + 1'b1;
      res_new = pipe1_reg + pipe2_reg;
    end // gmult_logic

endmodule // gcm_gmult

//======================================================================
// EOF gcm_gmult.v
//======================================================================
