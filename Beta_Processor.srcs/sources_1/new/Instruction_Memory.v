`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2026 22:34:24
// Design Name: 
// Module Name: Instruction_Memory
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


module Instruction_Memory(
    input  wire [31:0] Addr,
    output wire [31:0] Out
);

    reg [31:0] IM [0:31];

  // initial begin
      //  $readmemh("filename.hex", IM);
   // end

    assign Out = IM[Addr];

endmodule