`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2026 18:47:39
// Design Name: 
// Module Name: Register_file
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


module Register_file(
    input  wire        clk,
    input  wire [4:0]  RA1,
    input  wire [4:0]  RA2,
    input  wire [4:0]  WA,
    input  wire        WE,
    input  wire [31:0] WD,
    output wire [31:0] RD1,
    output wire [31:0] RD2
);

    reg [31:0] RF [0:31];

    assign RD1 = (RA1 == 5'd31) ? 32'b0 : RF[RA1];
    assign RD2 = (RA2 == 5'd31) ? 32'b0 : RF[RA2];

    always @(posedge clk) begin
        if (WE && (WA != 5'd31)) begin
            RF[WA] <= WD;
        end
    end

endmodule
