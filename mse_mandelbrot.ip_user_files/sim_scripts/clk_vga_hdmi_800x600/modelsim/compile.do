vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xil_defaultlib
vlib modelsim_lib/msim/xpm

vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib
vmap xpm modelsim_lib/msim/xpm

vlog -work xil_defaultlib -64 -incr -sv "+incdir+../../../../mse_mandelbrot.srcs/sources_1/ip/clk_vga_hdmi_800x600" "+incdir+../../../../mse_mandelbrot.srcs/sources_1/ip/clk_vga_hdmi_800x600" \
"/opt/Xilinx/Vivado/2017.4/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -64 -93 \
"/opt/Xilinx/Vivado/2017.4/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work xil_defaultlib -64 -93 \
"../../../../mse_mandelbrot.srcs/sources_1/ip/clk_vga_hdmi_800x600/clk_vga_hdmi_800x600_sim_netlist.vhdl" \


vlog -work xil_defaultlib \
"glbl.v"

