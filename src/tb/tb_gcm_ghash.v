//======================================================================
//
// tb_gcm.v
// --------
// Testbench for the GCM core top level wrapper.
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


//------------------------------------------------------------------
// Test module.
//------------------------------------------------------------------
module tb_gcm();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG = 0;

  parameter CLK_HALF_PERIOD = 2;
  parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;

  // The address map.
  parameter ADDR_NAME0       = 8'h00;
  parameter ADDR_NAME1       = 8'h01;
  parameter ADDR_VERSION     = 8'h02;

  parameter ADDR_CTRL        = 8'h08;
  parameter CTRL_INIT_VALUE  = 8'h01;
  parameter CTRL_NEXT_VALUE  = 8'h02;

  parameter ADDR_STATUS      = 8'h09;
  parameter STATUS_READY_BIT = 0;
  parameter STATUS_VALID_BIT = 1;


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0]  cycle_ctr;
  reg [31 : 0]  error_ctr;
  reg [31 : 0]  tc_ctr;

  reg           tb_clk;
  reg           tb_reset_n;
  reg           tb_cs;
  reg           tb_we;
  reg [7 : 0]   tb_address;
  reg [31 : 0]  tb_write_data;
  wire [31 : 0] tb_read_data;
  wire          tb_error;
  reg [31 : 0]  read_data;


  //----------------------------------------------------------------
  // Device Under Test.
  //----------------------------------------------------------------
  gcm dut(
          .clk(tb_clk),
          .reset_n(tb_reset_n),

          .cs(tb_cs),
          .we(tb_we),
          .address(tb_address),
          .write_data(tb_write_data),
          .read_data(tb_read_data)
         );


  //----------------------------------------------------------------
  // clk_gen
  //
  // Clock generator process.
  //----------------------------------------------------------------
  always
    begin : clk_gen
      #CLK_HALF_PERIOD tb_clk = !tb_clk;
    end // clk_gen


  //----------------------------------------------------------------
  // sys_monitor
  //
  // Generates a cycle counter and displays information about
  // the dut as needed.
  //----------------------------------------------------------------
  always
    begin : sys_monitor
      #(2 * CLK_HALF_PERIOD);
      cycle_ctr = cycle_ctr + 1;
    end


  //----------------------------------------------------------------
  // dump_dut_state()
  //
  // Dump the state of the dump when needed.
  //----------------------------------------------------------------
  task dump_dut_state;
    begin
      $display("State of DUT");
      $display("------------");
      $display("Inputs and outputs:");
      $display("cs = 0x%01x, we = 0x%01x",
               dut.cs, dut.we);
      $display("address = 0x%02x", dut.address);
      $display("write_data = 0x%08x, read_data = 0x%08x",
               dut.write_data, dut.read_data);
      $display("tmp_read_data = 0x%08x", dut.tmp_read_data);
      $display("");

      $display("Control and status:");
      $display("");
    end
  endtask // dump_dut_state


  //----------------------------------------------------------------
  // reset_dut()
  //
  // Toggles reset to force the DUT into a well defined state.
  //----------------------------------------------------------------
  task reset_dut;
    begin
      $display("*** Toggle reset.");
      tb_reset_n = 0;
      #(4 * CLK_HALF_PERIOD);
      tb_reset_n = 1;
    end
  endtask // reset_dut


  //----------------------------------------------------------------
  // init_sim()
  //
  // Initialize all counters and testbed functionality as well
  // as setting the DUT inputs to defined values.
  //----------------------------------------------------------------
  task init_sim;
    begin
      cycle_ctr = 32'h0;
      error_ctr = 32'h0;
      tc_ctr = 32'h0;

      tb_clk = 0;
      tb_reset_n = 0;
      tb_cs = 0;
      tb_we = 0;
      tb_address = 6'h0;
      tb_write_data = 32'h0;
    end
  endtask // init_dut


  //----------------------------------------------------------------
  // display_test_result()
  //
  // Display the accumulated test results.
  //----------------------------------------------------------------
  task display_test_result;
    begin
      if (error_ctr == 0)
        begin
          $display("*** All %02d test cases completed successfully.", tc_ctr);
        end
      else
        begin
          $display("*** %02d test cases completed.", tc_ctr);
          $display("*** %02d errors detected during testing.", error_ctr);
        end
    end
  endtask // display_test_result


  //----------------------------------------------------------------
  // wait_ready()
  //
  // Wait for the ready flag in the dut to be set.
  // (Actually we wait for either ready or valid to be set.)
  //
  // Note: It is the callers responsibility to call the function
  // when the dut is actively processing and will in fact at some
  // point set the flag.
  //----------------------------------------------------------------
  task wait_ready;
    begin
      read_data = 0;

      while (read_data == 0)
        begin
          read_word(ADDR_STATUS);
        end
    end
  endtask // wait_ready


  //----------------------------------------------------------------
  // write_word()
  //
  // Write the given word to the DUT using the DUT interface.
  //----------------------------------------------------------------
  task write_word(input [7 : 0]  address,
                  input [31 : 0] word);
    begin
      if (DEBUG)
        begin
          $display("*** Writing 0x%08x to 0x%02x.", word, address);
          $display("");
        end

      tb_address = address;
      tb_write_data = word;
      tb_cs = 1;
      tb_we = 1;
      #(CLK_PERIOD);
      tb_cs = 0;
      tb_we = 0;
    end
  endtask // write_word


  //----------------------------------------------------------------
  // read_word()
  //
  // Read a data word from the given address in the DUT.
  // the word read will be available in the global variable
  // read_data.
  //----------------------------------------------------------------
  task read_word(input [7 : 0]  address);
    begin
      tb_address = address;
      tb_cs = 1;
      tb_we = 0;
      #(CLK_PERIOD);
      read_data = tb_read_data;
      tb_cs = 0;

      if (DEBUG)
        begin
          $display("*** Reading 0x%08x from 0x%02x.", read_data, address);
          $display("");
        end
    end
  endtask // read_word


  //----------------------------------------------------------------
  // check_name_version()
  //
  // Read the name and version from the DUT.
  //----------------------------------------------------------------
  task check_name_version;
    reg [31 : 0] name0;
    reg [31 : 0] name1;
    reg [31 : 0] version;
    begin

      read_word(ADDR_NAME0);
      name0 = read_data;
      read_word(ADDR_NAME1);
      name1 = read_data;
      read_word(ADDR_VERSION);
      version = read_data;

      $display("DUT name: %c%c%c%c%c%c%c%c",
               name0[31 : 24], name0[23 : 16], name0[15 : 8], name0[7 : 0],
               name1[31 : 24], name1[23 : 16], name1[15 : 8], name1[7 : 0]);
      $display("DUT version: %c%c%c%c",
               version[31 : 24], version[23 : 16], version[15 : 8], version[7 : 0]);
    end
  endtask // check_name_version


  //----------------------------------------------------------------
  // gcm_tests()
  //----------------------------------------------------------------
  task gcm_tests;
    begin : gcm_tests

      $display("*** Testcases for gcm functionality started.");

      $display("*** Testcases for gcm functionality completed.");
    end
  endtask // gcm_tests


  //----------------------------------------------------------------
  // gcm_test
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : gcm_test
      $display("   -- Testbench for gcm started --");

      init_sim();
      reset_dut();

      check_name_version();
      gcm_tests();

      display_test_result();

      $display("   -- Testbench for gcm done. --");
      $finish;
    end // gcm_test
endmodule // tb_gcm

//======================================================================
// EOF tb_gcm.v
//======================================================================
