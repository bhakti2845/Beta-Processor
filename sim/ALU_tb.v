`timescale 1ns / 1ps

module tb_ALU;

    reg [3:0] alufn;
    reg [31:0] A;
    reg [31:0] B;
    wire [31:0] Y;

    ALU dut (
        .alufn(alufn),
        .A(A),
        .B(B),
        .Y(Y)
    );

    task check;
        input [3:0] fn;
        input [31:0] a_in;
        input [31:0] b_in;
        input [31:0] expected;
        input [160:0] name;
        begin
            alufn = fn;
            A = a_in;
            B = b_in;
            #10;

            if (Y !== expected) begin
                $display("FAIL %s", name);
                $display("alufn=%b A=%h B=%h expected=%h got=%h", alufn, A, B, expected, Y);
            end else begin
                $display("PASS %s", name);
            end
        end
    endtask

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, tb_ALU);

        check(4'b0000, 32'd10, 32'd5, 32'd15, "ADD");
        check(4'b0001, 32'd10, 32'd5, 32'd5, "SUB");

        check(4'b0100, 32'd10, 32'd10, 32'd1, "CMPEQ true");
        check(4'b0100, 32'd10, 32'd5, 32'd0, "CMPEQ false");

        check(4'b0101, 32'd5, 32'd10, 32'd1, "CMPLT true");
        check(4'b0101, 32'd10, 32'd5, 32'd0, "CMPLT false");
        check(4'b0101, 32'hFFFF_FFFF, 32'd1, 32'd1, "CMPLT signed negative");

        check(4'b0110, 32'd5, 32'd5, 32'd1, "CMPLE equal");
        check(4'b0110, 32'd5, 32'd10, 32'd1, "CMPLE less");
        check(4'b0110, 32'd10, 32'd5, 32'd0, "CMPLE false");

        check(4'b1000, 32'hF0F0_F0F0, 32'h0F0F_0F0F, 32'h0000_0000, "AND");
        check(4'b1001, 32'hF0F0_F0F0, 32'h0F0F_0F0F, 32'hFFFF_FFFF, "OR");
        check(4'b1010, 32'hAAAA_AAAA, 32'h5555_5555, 32'hFFFF_FFFF, "XOR");
        check(4'b1011, 32'hAAAA_AAAA, 32'h5555_5555, 32'h0000_0000, "XNOR");

        check(4'b1100, 32'h0000_0001, 32'd4, 32'h0000_0010, "SHL");
        check(4'b1101, 32'h8000_0000, 32'd4, 32'h0800_0000, "SHR");
        check(4'b1111, 32'h8000_0000, 32'd4, 32'hF800_0000, "SRA");

        check(4'b1100, 32'h0000_0001, 32'd31, 32'h8000_0000, "SHL by 31");
        check(4'b1101, 32'h8000_0000, 32'd31, 32'h0000_0001, "SHR by 31");
        check(4'b1111, 32'h8000_0000, 32'd31, 32'hFFFF_FFFF, "SRA by 31");

        check(4'b0010, 32'd7, 32'd8, 32'd15, "default ADD");

        $display("ALU test completed");
        $finish;
    end

endmodule