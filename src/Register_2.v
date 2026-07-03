`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.06.2026 12:27:06
// Design Name: 
// Module Name: Register_2
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

module Register_2(
input clk, reset,
input [1:0]D,
output reg [1:0]Q
    );
    always@(posedge clk or negedge reset)begin
    if(reset==0) Q<=2'b00;
    else Q<=D;
    end
endmodule
