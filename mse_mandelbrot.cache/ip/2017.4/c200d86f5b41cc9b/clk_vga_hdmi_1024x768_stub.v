// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.4 (lin64) Build 2086221 Fri Dec 15 20:54:30 MST 2017
// Date        : Mon Feb 26 13:58:38 2018
// Host        : t450s-debian running 64-bit Debian GNU/Linux testing (buster)
// Command     : write_verilog -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ clk_vga_hdmi_1024x768_stub.v
// Design      : clk_vga_hdmi_1024x768
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a200tsbg484-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix(ClkVgaxC, ClkHdmixC, reset, PllLockedSO, 
  ClkSys100MhzxC)
/* synthesis syn_black_box black_box_pad_pin="ClkVgaxC,ClkHdmixC,reset,PllLockedSO,ClkSys100MhzxC" */;
  output ClkVgaxC;
  output ClkHdmixC;
  input reset;
  output PllLockedSO;
  input ClkSys100MhzxC;
endmodule
