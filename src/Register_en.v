`timescale 1ns / 1ps

module Register_en(
    input clk,
    input reset,
    input en,
    input [31:0] D,
    output reg [31:0] Q
);

    always @(posedge clk or negedge reset) begin
        if (reset == 1'b0)
            Q <= 32'd0;
        else if (en == 1'b1)
            Q <= D;
    end

endmodule
