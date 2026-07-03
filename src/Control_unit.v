`timescale 1ns / 1ps


module Control_unit(
    input wire z,
    input wire [5:0] op,
    output reg [3:0] alufn,
    output reg [1:0] wdsel,
    output reg [1:0] pcsel,
    output reg ra2sel,
    output reg asel,
    output reg bsel,
    output reg moe,
    output reg mwr,
    output reg werf
);

    always @(*) begin
        pcsel  = 2'b00;
        ra2sel = 1'b0;
        asel   = 1'b0;
        bsel   = 1'b0;
        moe    = 1'b0;
        mwr    = 1'b0;
        wdsel  = 2'b00;
        werf   = 1'b0;
        alufn  = 4'b0000;

        case(op[5:4])

            2'b10: begin
                pcsel  = 2'b00;
                ra2sel = 1'b0;
                asel   = 1'b0;
                bsel   = 1'b0;
                moe    = 1'b0;
                mwr    = 1'b0;
                wdsel  = 2'b01;
                werf   = 1'b1;

                case(op[3:0])
                    4'b0000: alufn = 4'b0000;
                    4'b0001: alufn = 4'b0001;
                    4'b0100: alufn = 4'b0100;
                    4'b0101: alufn = 4'b0101;
                    4'b0110: alufn = 4'b0110;
                    4'b1000: alufn = 4'b1000;
                    4'b1001: alufn = 4'b1001;
                    4'b1010: alufn = 4'b1010;
                    4'b1011: alufn = 4'b1011;
                    4'b1100: alufn = 4'b1100;
                    4'b1101: alufn = 4'b1101;
                    4'b1111: alufn = 4'b1111;
                    default: begin
                        alufn = 4'b0000;
                        werf  = 1'b0;
                    end
                endcase
            end

            2'b11: begin
                pcsel  = 2'b00;
                ra2sel = 1'b0;
                asel   = 1'b0;
                bsel   = 1'b1;
                moe    = 1'b0;
                mwr    = 1'b0;
                wdsel  = 2'b01;
                werf   = 1'b1;

                case(op[3:0])
                    4'b0000: alufn = 4'b0000;
                    4'b0001: alufn = 4'b0001;
                    4'b0100: alufn = 4'b0100;
                    4'b0101: alufn = 4'b0101;
                    4'b0110: alufn = 4'b0110;
                    4'b1000: alufn = 4'b1000;
                    4'b1001: alufn = 4'b1001;
                    4'b1010: alufn = 4'b1010;
                    4'b1011: alufn = 4'b1011;
                    4'b1100: alufn = 4'b1100;
                    4'b1101: alufn = 4'b1101;
                    4'b1111: alufn = 4'b1111;
                    default: begin
                        alufn = 4'b0000;
                        werf  = 1'b0;
                    end
                endcase
            end

            2'b01: begin
                case(op[3:0])

                    4'b1000: begin
                        pcsel  = 2'b00;
                        ra2sel = 1'b0;
                        asel   = 1'b0;
                        bsel   = 1'b1;
                        moe    = 1'b1;
                        mwr    = 1'b0;
                        wdsel  = 2'b10;
                        werf   = 1'b1;
                        alufn  = 4'b0000;
                    end

                    4'b1001: begin
                        pcsel  = 2'b00;
                        ra2sel = 1'b1;
                        asel   = 1'b0;
                        bsel   = 1'b1;
                        moe    = 1'b0;
                        mwr    = 1'b1;
                        wdsel  = 2'b00;
                        werf   = 1'b0;
                        alufn  = 4'b0000;
                    end

                    4'b1111: begin
                        pcsel  = 2'b00;
                        ra2sel = 1'b0;
                        asel   = 1'b1;
                        bsel   = 1'b1;
                        moe    = 1'b1;
                        mwr    = 1'b0;
                        wdsel  = 2'b10;
                        werf   = 1'b1;
                        alufn  = 4'b0000;
                    end

                    4'b1011: begin
                        pcsel  = 2'b10;
                        ra2sel = 1'b0;
                        asel   = 1'b0;
                        bsel   = 1'b0;
                        moe    = 1'b0;
                        mwr    = 1'b0;
                        wdsel  = 2'b00;
                        werf   = 1'b1;
                        alufn  = 4'b0000;
                    end

                    4'b1100: begin
                        pcsel  = (z == 1'b1) ? 2'b01 : 2'b00;
                        ra2sel = 1'b0;
                        asel   = 1'b0;
                        bsel   = 1'b0;
                        moe    = 1'b0;
                        mwr    = 1'b0;
                        wdsel  = 2'b00;
                        werf   = (z == 1'b1) ? 1'b1 : 1'b0;
                        alufn  = 4'b0000;
                    end

                    4'b1101: begin
                        pcsel  = (z == 1'b0) ? 2'b01 : 2'b00;
                        ra2sel = 1'b0;
                        asel   = 1'b0;
                        bsel   = 1'b0;
                        moe    = 1'b0;
                        mwr    = 1'b0;
                        wdsel  = 2'b00;
                        werf   = (z == 1'b0) ? 1'b1 : 1'b0;
                        alufn  = 4'b0000;
                    end

                    default: begin
                        pcsel  = 2'b00;
                        ra2sel = 1'b0;
                        asel   = 1'b0;
                        bsel   = 1'b0;
                        moe    = 1'b0;
                        mwr    = 1'b0;
                        wdsel  = 2'b00;
                        werf   = 1'b0;
                        alufn  = 4'b0000;
                    end

                endcase
            end

            default: begin
                pcsel  = 2'b00;
                ra2sel = 1'b0;
                asel   = 1'b0;
                bsel   = 1'b0;
                moe    = 1'b0;
                mwr    = 1'b0;
                wdsel  = 2'b00;
                werf   = 1'b0;
                alufn  = 4'b0000;
            end

        endcase
    end

endmodule
