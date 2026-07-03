`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2026 19:42:10
// Design Name: 
// Module Name: PCSEL_mux
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


module PCSEL_mux(
    input  wire [31:0] In0,
    input  wire [31:0] In1,
    input  wire [31:0] In2,
    input  wire [31:0] In3,
    input  wire [1:0]  sel,
    output reg  [31:0] Out
);

    always @(*) begin
        case (sel)
            2'b00: Out = In0;
            2'b01: Out = In1;
            2'b10: Out = In2;
            2'b11: Out = In3;
            default: Out = 32'd0;
        endcase
    end

endmodule
