`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.06.2026 12:21:57
// Design Name: 
// Module Name: Register_1
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


module Register_1(
input clk, reset,
input D,
output reg Q
    );
    always@(posedge clk or negedge reset)begin
    if(reset==0) Q<=1'd0;
    else Q<=D;
    end
endmodule
