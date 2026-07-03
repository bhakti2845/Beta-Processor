`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.06.2026 14:37:10
// Design Name: 
// Module Name: Top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Top(
 input clk,
    input reset,
    output z,
    output [5:0] opcode,
    output [3:0] alufn_debug,
    output [1:0] wdsel_debug,
    output [1:0] pcsel_debug,
    output werf_debug,
    output bsel_debug,
    output asel_debug,
    output mwr_debug,
    output moe_debug,
    output ra2sel_debug
    );
    wire [5:0]Out;
    wire [3:0]alufn;
    wire [1:0]wdsel,pcsel;
    wire werf,bsel,asel,ra2sel,mwr,moe;
    Datapath_unit DU(clk,reset,alufn,wdsel,pcsel,werf,bsel,asel,mwr,moe,ra2sel,z,Out);
    Control_unit CU(z,Out,alufn,wdsel,pcsel,ra2sel,asel,bsel,moe, mwr, werf);
    assign opcode=Out;
    assign alufn_debug = alufn;
    assign wdsel_debug = wdsel;
    assign pcsel_debug = pcsel;
    assign werf_debug = werf;
    assign bsel_debug = bsel;
    assign asel_debug = asel;
    assign mwr_debug = mwr;
    assign moe_debug = moe;
    assign ra2sel_debug = ra2sel;
endmodule
