module gcm_mult():

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

endmodule // gcm_mult
