`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2026 19:17:37
// Design Name: 
// Module Name: Data_memory
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


module Data_memory(
    input  wire        clk,
    input  wire [31:0] WD,
    input  wire [31:0] Addr,
    input  wire        RW,
    input  wire        OE,
    output wire [31:0] RD
);

    reg [31:0] mem [0:1023];

    assign RD = (OE == 1'b1) ? mem[Addr] : 32'd0;

    always @(posedge clk) begin
        if (RW == 1'b1) begin
            mem[Addr] <= WD;
        end
    end

endmodule
