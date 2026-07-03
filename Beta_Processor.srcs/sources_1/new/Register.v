`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.06.2026 20:06:51
// Design Name: 
// Module Name: Register
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


module Register(
input clk, reset,
input [31:0]D,
output reg [31:0]Q
    );
    always@(posedge clk or negedge reset)begin
    if(reset==0) Q<=32'd0;
    else Q<=D;
    end
endmodule
