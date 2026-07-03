`timescale 1ns / 1ps

module ALU(
    input [3:0] alufn,
    input [31:0] A,
    input [31:0] B,
    output reg [31:0] Y
);

    always @(*) begin
        case(alufn)
            4'b0000: Y = A + B;
            4'b0001: Y = A - B;
            4'b0100: Y = (A == B) ? 32'd1 : 32'd0;
            4'b0101: Y = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
            4'b0110: Y = ($signed(A) <= $signed(B)) ? 32'd1 : 32'd0;
            4'b1000: Y = A & B;
            4'b1001: Y = A | B;
            4'b1010: Y = A ^ B;
            4'b1011: Y = ~(A ^ B);
            4'b1100: Y = A << B[4:0];
            4'b1101: Y = A >> B[4:0];
            4'b1111: Y = $signed(A) >>> B[4:0];
            default: Y = A + B;
        endcase
    end

endmodule