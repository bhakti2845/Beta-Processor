`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.06.2026 12:30:42
// Design Name: 
// Module Name: Register_4
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


module Register_4(
input clk, reset,
input [3:0]D,
output reg [3:0]Q
    );
    always@(posedge clk or negedge reset)begin
    if(reset==0) Q<=4'd0;
    else Q<=D;
    end
endmodule
