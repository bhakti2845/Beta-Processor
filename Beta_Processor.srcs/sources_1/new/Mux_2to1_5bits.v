`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.06.2026 11:16:31
// Design Name: 
// Module Name: Mux_2to1_5bits
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


module Mux_2to1_5bits(
input [4:0]In0, In1,
input sel,
output [4:0]Out
    );
    assign Out= (sel==1)?In1:In0;
    
endmodule
