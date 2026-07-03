`timescale 1ns / 1ps

module tb_Top_Control_Hazard;

    reg clk;
    reg reset;

    wire z;
    wire [5:0] opcode;
    wire [3:0] alufn_debug;
    wire [1:0] wdsel_debug;
    wire [1:0] pcsel_debug;
    wire werf_debug;
    wire bsel_debug;
    wire asel_debug;
    wire mwr_debug;
    wire moe_debug;
    wire ra2sel_debug;

    integer i;
    integer cycle;
    integer pass_count;
    integer fail_count;
    integer annul_count;

    Top dut (
        .clk(clk),
        .reset(reset),
        .z(z),
        .opcode(opcode),
        .alufn_debug(alufn_debug),
        .wdsel_debug(wdsel_debug),
        .pcsel_debug(pcsel_debug),
        .werf_debug(werf_debug),
        .bsel_debug(bsel_debug),
        .asel_debug(asel_debug),
        .mwr_debug(mwr_debug),
        .moe_debug(moe_debug),
        .ra2sel_debug(ra2sel_debug)
    );

    always #5 clk = ~clk;

    function [31:0] C;
        input [5:0] op;
        input [4:0] rc;
        input [4:0] ra;
        input [15:0] lit;
        begin
            C = {op, rc, ra, lit};
        end
    endfunction

    task clear_all;
        begin
            for (i = 0; i < 32; i = i + 1) begin
                dut.DU.IM.IM[i] = 32'h83FFF800;
            end

            for (i = 0; i < 32; i = i + 1) begin
                dut.DU.RF.RF[i] = 32'h00000000;
            end

            for (i = 0; i < 1024; i = i + 1) begin
                dut.DU.DM.mem[i] = 32'h00000000;
            end
        end
    endtask

    task apply_reset;
        begin
            reset = 1'b0;
            repeat(2) @(posedge clk);
            #1;
            reset = 1'b1;
        end
    endtask

    task print_cycle;
        input [255:0] test_name;
        begin
            $display("------------------------------------------------------------");
            $display("%s | CYCLE %0d", test_name, cycle);
            $display("reset=%b stall=%b annul=%b z=%b pcsel=%b", reset, dut.DU.stall, dut.DU.annul, z, pcsel_debug);
            $display("PC=%h fetched=%h opcode=%b", dut.DU.PC_out, dut.DU.IM_out, opcode);
            $display("IF_ID_IR=%h", dut.DU.IF_ID_IR_out);
            $display("ID_EX_IR=%h", dut.DU.ID_EX_IR_out);
            $display("EX_MEM_IR=%h", dut.DU.EX_MEM_IR_out);
            $display("MEM_WB_IR=%h", dut.DU.MEM_WB_IR_out);
            $display("RD1=%h RD1_bypass=%h", dut.DU.RD1, dut.DU.RD1_bypass);
            $display("WB WD=%h WA=%0d WERF=%b", dut.DU.WD, dut.DU.MEM_WB_IR_out[25:21], dut.DU.werf_wb);
        end
    endtask

    task run_cycles;
        input integer n;
        input [255:0] test_name;
        begin
            for (i = 0; i < n; i = i + 1) begin
                @(posedge clk);
                #1;
                cycle = cycle + 1;

                if (dut.DU.annul == 1'b1)
                    annul_count = annul_count + 1;

                print_cycle(test_name);
            end
        end
    endtask

    task check_reg;
        input [4:0] reg_no;
        input [31:0] expected;
        input [255:0] name;
        begin
            if (dut.DU.RF.RF[reg_no] === expected) begin
                $display("PASS %-40s R%0d=%h expected=%h", name, reg_no, dut.DU.RF.RF[reg_no], expected);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL %-40s R%0d=%h expected=%h", name, reg_no, dut.DU.RF.RF[reg_no], expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_annul_zero;
        input [255:0] name;
        begin
            if (annul_count == 0) begin
                $display("PASS %-40s annul_count=%0d expected=0", name, annul_count);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL %-40s annul_count=%0d expected=0", name, annul_count);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_annul_happened;
        input [255:0] name;
        begin
            if (annul_count > 0) begin
                $display("PASS %-40s annul_count=%0d expected>0", name, annul_count);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL %-40s annul_count=%0d expected>0", name, annul_count);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task test_BEQ_not_taken;
        begin
            reset = 1'b0;
            clear_all();
            cycle = 0;
            annul_count = 0;

            dut.DU.IM.IM[0]  = C(6'b011100, 5'd5, 5'd2, 16'd6);
            dut.DU.IM.IM[4]  = C(6'b110000, 5'd10, 5'd31, 16'd11);
            dut.DU.IM.IM[28] = C(6'b110000, 5'd11, 5'd31, 16'd22);

            dut.DU.RF.RF[2] = 32'd9;

            $display("");
            $display("TEST 1: BEQ NOT TAKEN");
            $display("IM[0]  BEQ  R2 == 0, target PC=28, R5=PC+4");
            $display("IM[4]  ADDC R10 = R31 + 11");
            $display("IM[28] ADDC R11 = R31 + 22");
            $display("Input R2=%h", dut.DU.RF.RF[2]);
            $display("Expected: no annul, R10=11, R5=4");

            apply_reset();
            run_cycles(9, "BEQ_NOT_TAKEN");

            check_reg(5'd5, 32'd4, "BEQ not taken link R5=PC+4");
            check_reg(5'd10, 32'd11, "BEQ not taken fall-through");
            check_annul_zero("BEQ not taken no annul");
        end
    endtask

    task test_BEQ_taken;
        begin
            reset = 1'b0;
            clear_all();
            cycle = 0;
            annul_count = 0;

            dut.DU.IM.IM[0]  = C(6'b011100, 5'd5, 5'd2, 16'd6);
            dut.DU.IM.IM[4]  = C(6'b110000, 5'd10, 5'd31, 16'd11);
            dut.DU.IM.IM[28] = C(6'b110000, 5'd11, 5'd31, 16'd22);

            dut.DU.RF.RF[2] = 32'd0;

            $display("");
            $display("TEST 2: BEQ TAKEN");
            $display("IM[0]  BEQ  R2 == 0, target PC=28, R5=PC+4");
            $display("IM[4]  ADDC R10 = R31 + 11");
            $display("IM[28] ADDC R11 = R31 + 22");
            $display("Input R2=%h", dut.DU.RF.RF[2]);
            $display("Expected: annul fall-through, R10=0, R11=22, R5=4");

            apply_reset();
            run_cycles(12, "BEQ_TAKEN");

            check_reg(5'd5, 32'd4, "BEQ taken link R5=PC+4");
            check_reg(5'd10, 32'd0, "BEQ taken fall-through annulled");
            check_reg(5'd11, 32'd22, "BEQ taken target executed");
            check_annul_happened("BEQ taken annul");
        end
    endtask

    task test_BNE_not_taken;
        begin
            reset = 1'b0;
            clear_all();
            cycle = 0;
            annul_count = 0;

            dut.DU.IM.IM[0]  = C(6'b011101, 5'd5, 5'd2, 16'd6);
            dut.DU.IM.IM[4]  = C(6'b110000, 5'd10, 5'd31, 16'd33);
            dut.DU.IM.IM[28] = C(6'b110000, 5'd11, 5'd31, 16'd44);

            dut.DU.RF.RF[2] = 32'd0;

            $display("");
            $display("TEST 3: BNE NOT TAKEN");
            $display("IM[0]  BNE  R2 != 0, target PC=28, R5=PC+4");
            $display("IM[4]  ADDC R10 = R31 + 33");
            $display("IM[28] ADDC R11 = R31 + 44");
            $display("Input R2=%h", dut.DU.RF.RF[2]);
            $display("Expected: no annul, R10=33, R5=4");

            apply_reset();
            run_cycles(9, "BNE_NOT_TAKEN");

            check_reg(5'd5, 32'd4, "BNE not taken link R5=PC+4");
            check_reg(5'd10, 32'd33, "BNE not taken fall-through");
            check_annul_zero("BNE not taken no annul");
        end
    endtask

    task test_BNE_taken;
        begin
            reset = 1'b0;
            clear_all();
            cycle = 0;
            annul_count = 0;

            dut.DU.IM.IM[0]  = C(6'b011101, 5'd5, 5'd2, 16'd6);
            dut.DU.IM.IM[4]  = C(6'b110000, 5'd10, 5'd31, 16'd33);
            dut.DU.IM.IM[28] = C(6'b110000, 5'd11, 5'd31, 16'd44);

            dut.DU.RF.RF[2] = 32'd9;

            $display("");
            $display("TEST 4: BNE TAKEN");
            $display("IM[0]  BNE  R2 != 0, target PC=28, R5=PC+4");
            $display("IM[4]  ADDC R10 = R31 + 33");
            $display("IM[28] ADDC R11 = R31 + 44");
            $display("Input R2=%h", dut.DU.RF.RF[2]);
            $display("Expected: annul fall-through, R10=0, R11=44, R5=4");

            apply_reset();
            run_cycles(12, "BNE_TAKEN");

            check_reg(5'd5, 32'd4, "BNE taken link R5=PC+4");
            check_reg(5'd10, 32'd0, "BNE taken fall-through annulled");
            check_reg(5'd11, 32'd44, "BNE taken target executed");
            check_annul_happened("BNE taken annul");
        end
    endtask

    task test_JMP;
        begin
            reset = 1'b0;
            clear_all();
            cycle = 0;
            annul_count = 0;

            dut.DU.IM.IM[0]  = C(6'b011011, 5'd5, 5'd2, 16'd0);
            dut.DU.IM.IM[4]  = C(6'b110000, 5'd10, 5'd31, 16'd55);
            dut.DU.IM.IM[28] = C(6'b110000, 5'd11, 5'd31, 16'd66);

            dut.DU.RF.RF[2] = 32'd28;

            $display("");
            $display("TEST 5: JMP");
            $display("IM[0]  JMP  PC=R2, R5=PC+4");
            $display("IM[4]  ADDC R10 = R31 + 55");
            $display("IM[28] ADDC R11 = R31 + 66");
            $display("Input R2=%h", dut.DU.RF.RF[2]);
            $display("Expected: annul fall-through, R10=0, R11=66, R5=4");

            apply_reset();
            run_cycles(12, "JMP_CONTROL_HAZARD");

            check_reg(5'd5, 32'd4, "JMP link R5=PC+4");
            check_reg(5'd10, 32'd0, "JMP fall-through annulled");
            check_reg(5'd11, 32'd66, "JMP target executed");
            check_annul_happened("JMP annul");
        end
    endtask

    initial begin
        $dumpfile("top_control_hazard.vcd");
        $dumpvars(0, tb_Top_Control_Hazard);

        clk = 1'b0;
        reset = 1'b0;
        cycle = 0;
        pass_count = 0;
        fail_count = 0;
        annul_count = 0;

        test_BEQ_not_taken();
        test_BEQ_taken();
        test_BNE_not_taken();
        test_BNE_taken();
        test_JMP();

        $display("");
        $display("========================================");
        $display("CONTROL HAZARD TESTS COMPLETED");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);
        $display("========================================");

        $finish;
    end

endmodule