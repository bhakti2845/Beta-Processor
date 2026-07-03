`timescale 1ns / 1ps

module tb_Control_unit;

    reg z;
    reg [5:0] op;

    wire [3:0] alufn;
    wire [1:0] wdsel;
    wire [1:0] pcsel;
    wire ra2sel;
    wire asel;
    wire bsel;
    wire moe;
    wire mwr;
    wire werf;

    Control_unit dut (
        .z(z),
        .op(op),
        .alufn(alufn),
        .wdsel(wdsel),
        .pcsel(pcsel),
        .ra2sel(ra2sel),
        .asel(asel),
        .bsel(bsel),
        .moe(moe),
        .mwr(mwr),
        .werf(werf)
    );

    task check;
        input [5:0] op_in;
        input z_in;
        input [3:0] exp_alufn;
        input [1:0] exp_wdsel;
        input [1:0] exp_pcsel;
        input exp_ra2sel;
        input exp_asel;
        input exp_bsel;
        input exp_moe;
        input exp_mwr;
        input exp_werf;
        input [160:0] name;
        begin
            op = op_in;
            z = z_in;
            #10;

            if (
                alufn  !== exp_alufn  ||
                wdsel  !== exp_wdsel  ||
                pcsel  !== exp_pcsel  ||
                ra2sel !== exp_ra2sel ||
                asel   !== exp_asel   ||
                bsel   !== exp_bsel   ||
                moe    !== exp_moe    ||
                mwr    !== exp_mwr    ||
                werf   !== exp_werf
            ) begin
                $display("FAIL %s", name);
                $display("op=%b z=%b", op, z);
                $display("expected alufn=%b wdsel=%b pcsel=%b ra2sel=%b asel=%b bsel=%b moe=%b mwr=%b werf=%b",
                         exp_alufn, exp_wdsel, exp_pcsel, exp_ra2sel, exp_asel, exp_bsel, exp_moe, exp_mwr, exp_werf);
                $display("got      alufn=%b wdsel=%b pcsel=%b ra2sel=%b asel=%b bsel=%b moe=%b mwr=%b werf=%b",
                         alufn, wdsel, pcsel, ra2sel, asel, bsel, moe, mwr, werf);
            end else begin
                $display("PASS %s", name);
            end
        end
    endtask

    initial begin
        $dumpfile("control_unit.vcd");
        $dumpvars(0, tb_Control_unit);

        check(6'b100000, 1'b0, 4'b0000, 2'b01, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, "ADD");
        check(6'b100001, 1'b0, 4'b0001, 2'b01, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, "SUB");
        check(6'b100100, 1'b0, 4'b0100, 2'b01, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, "CMPEQ");
        check(6'b100101, 1'b0, 4'b0101, 2'b01, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, "CMPLT");
        check(6'b100110, 1'b0, 4'b0110, 2'b01, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, "CMPLE");
        check(6'b101000, 1'b0, 4'b1000, 2'b01, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, "AND");
        check(6'b101001, 1'b0, 4'b1001, 2'b01, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, "OR");
        check(6'b101010, 1'b0, 4'b1010, 2'b01, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, "XOR");
        check(6'b101011, 1'b0, 4'b1011, 2'b01, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, "XNOR");
        check(6'b101100, 1'b0, 4'b1100, 2'b01, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, "SHL");
        check(6'b101101, 1'b0, 4'b1101, 2'b01, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, "SHR");
        check(6'b101111, 1'b0, 4'b1111, 2'b01, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, "SRA");

        check(6'b110000, 1'b0, 4'b0000, 2'b01, 2'b00, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, "ADDC");
        check(6'b110001, 1'b0, 4'b0001, 2'b01, 2'b00, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, "SUBC");
        check(6'b111000, 1'b0, 4'b1000, 2'b01, 2'b00, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, "ANDC");
        check(6'b111001, 1'b0, 4'b1001, 2'b01, 2'b00, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, "ORC");
        check(6'b111010, 1'b0, 4'b1010, 2'b01, 2'b00, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, "XORC");

        check(6'b011000, 1'b0, 4'b0000, 2'b10, 2'b00, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b1, "LD");
        check(6'b011001, 1'b0, 4'b0000, 2'b00, 2'b00, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, "ST");
        check(6'b011111, 1'b0, 4'b0000, 2'b10, 2'b00, 1'b0, 1'b1, 1'b1, 1'b1, 1'b0, 1'b1, "LDR");

        check(6'b011011, 1'b0, 4'b0000, 2'b00, 2'b10, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, "JMP");

        check(6'b011100, 1'b1, 4'b0000, 2'b00, 2'b01, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, "BEQ taken");
        check(6'b011100, 1'b0, 4'b0000, 2'b00, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "BEQ not taken");

        check(6'b011101, 1'b0, 4'b0000, 2'b00, 2'b01, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, "BNE taken");
        check(6'b011101, 1'b1, 4'b0000, 2'b00, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "BNE not taken");

        check(6'b000000, 1'b0, 4'b0000, 2'b00, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "illegal op group");
        check(6'b100010, 1'b0, 4'b0000, 2'b01, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "illegal alu op");
        check(6'b010000, 1'b0, 4'b0000, 2'b00, 2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, "illegal class 01 op");

        $display("Control unit test completed");
        $finish;
    end

endmodule