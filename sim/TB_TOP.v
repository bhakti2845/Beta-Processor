`timescale 1ns / 1ps

module tb_Top_Branch_Memory;

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
    integer pass_count;
    integer fail_count;

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
                dut.DU.IM.IM[i] = 32'h00000000;
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
            #17;
            reset = 1'b1;
            #3;
        end
    endtask

    task run_cycles;
        input integer n;
        begin
            repeat(n) begin
                @(posedge clk);
                #1;
            end
        end
    endtask

    task check_reg;
        input [4:0] reg_no;
        input [31:0] expected;
        input [255:0] name;
        begin
            if (dut.DU.RF.RF[reg_no] === expected) begin
                $display("PASS %-30s R%0d=%h expected=%h", name, reg_no, dut.DU.RF.RF[reg_no], expected);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL %-30s R%0d=%h expected=%h", name, reg_no, dut.DU.RF.RF[reg_no], expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_mem;
        input [31:0] addr;
        input [31:0] expected;
        input [255:0] name;
        begin
            if (dut.DU.DM.mem[addr] === expected) begin
                $display("PASS %-30s DM[%0d]=%h expected=%h", name, addr, dut.DU.DM.mem[addr], expected);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL %-30s DM[%0d]=%h expected=%h", name, addr, dut.DU.DM.mem[addr], expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task test_LD;
        begin
            clear_all();

            // LD R1 = MEM[R2 + 0]
            dut.DU.IM.IM[0] = C(6'b011000, 5'd1, 5'd2, 16'd0);

            dut.DU.RF.RF[2] = 32'd3;
            dut.DU.DM.mem[3] = 32'hA5A5_5A5A;

            $display("");
            $display("TEST LD");
            $display("Instruction: LD R1 = MEM[R2 + 0]");
            $display("Instruction hex = %h", dut.DU.IM.IM[0]);
            $display("Input R2=%h", dut.DU.RF.RF[2]);
            $display("Input DM[3]=%h", dut.DU.DM.mem[3]);

            apply_reset();
            run_cycles(9);

            check_reg(5'd1, 32'hA5A5_5A5A, "LD R1=MEM[R2+0]");
        end
    endtask

    task test_ST;
        begin
            clear_all();

            // ST MEM[R2 + 0] = R1
            dut.DU.IM.IM[0] = C(6'b011001, 5'd1, 5'd2, 16'd0);

            dut.DU.RF.RF[1] = 32'h1234_5678;
            dut.DU.RF.RF[2] = 32'd5;

            $display("");
            $display("TEST ST");
            $display("Instruction: ST MEM[R2 + 0] = R1");
            $display("Instruction hex = %h", dut.DU.IM.IM[0]);
            $display("Input R1=%h", dut.DU.RF.RF[1]);
            $display("Input R2=%h", dut.DU.RF.RF[2]);

            apply_reset();
            run_cycles(8);

            check_mem(32'd5, 32'h1234_5678, "ST MEM[R2+0]=R1");
        end
    endtask

    task test_LDR;
        begin
            clear_all();

            // LDR R1 = MEM[PC-relative address]
            // Current datapath test uses literal 0
            dut.DU.IM.IM[0] = C(6'b011111, 5'd1, 5'd0, 16'd0);

            dut.DU.DM.mem[4] = 32'hDEAD_BEEF;

            $display("");
            $display("TEST LDR");
            $display("Instruction: LDR R1 = MEM[PC-relative address]");
            $display("Instruction hex = %h", dut.DU.IM.IM[0]);
            $display("Input DM[4]=%h", dut.DU.DM.mem[4]);

            apply_reset();
            run_cycles(9);

            check_reg(5'd1, 32'hDEAD_BEEF, "LDR R1=MEM[4]");
        end
    endtask

    task test_JMP;
        begin
            clear_all();

            // JMP PC = R2, R5 = PC + 4
            dut.DU.IM.IM[0] = C(6'b011011, 5'd5, 5'd2, 16'd0);

            // ADDC R22 = R30 + 55 at jump target PC = 16
            dut.DU.IM.IM[16] = C(6'b110000, 5'd22, 5'd30, 16'd55);

            dut.DU.RF.RF[2] = 32'd16;
            dut.DU.RF.RF[30] = 32'd0;

            $display("");
            $display("TEST JMP");
            $display("Instruction 1: JMP PC = R2, R5 = PC + 4");
            $display("Instruction 2: ADDC R22 = R30 + 55 at target PC=16");
            $display("Instruction IM[0]  = %h", dut.DU.IM.IM[0]);
            $display("Instruction IM[16] = %h", dut.DU.IM.IM[16]);
            $display("Input R2=%h", dut.DU.RF.RF[2]);

            apply_reset();
            run_cycles(12);

            check_reg(5'd5, 32'h00000004, "JMP link R5=PC+4");
            check_reg(5'd22, 32'h00000037, "JMP target executed");
        end
    endtask

    task test_BEQ_taken;
        begin
            clear_all();

            // BEQ if R2 == 0, branch to PC + 4 + 4*3 = 16, R5 = PC + 4
            dut.DU.IM.IM[0] = C(6'b011100, 5'd5, 5'd2, 16'd3);

            // ADDC R22 = R30 + 99 at branch target PC = 16
            dut.DU.IM.IM[16] = C(6'b110000, 5'd22, 5'd30, 16'd99);

            dut.DU.RF.RF[2] = 32'd0;
            dut.DU.RF.RF[30] = 32'd0;

            $display("");
            $display("TEST BEQ TAKEN");
            $display("Instruction 1: BEQ R2 == 0, branch target PC=16, R5=PC+4");
            $display("Instruction 2: ADDC R22 = R30 + 99 at target PC=16");
            $display("Instruction IM[0]  = %h", dut.DU.IM.IM[0]);
            $display("Instruction IM[16] = %h", dut.DU.IM.IM[16]);
            $display("Input R2=%h", dut.DU.RF.RF[2]);

            apply_reset();
            run_cycles(12);

            check_reg(5'd5, 32'h00000004, "BEQ taken link");
            check_reg(5'd22, 32'h00000063, "BEQ taken target");
        end
    endtask

    task test_BEQ_not_taken;
        begin
            clear_all();

            // BEQ not taken because R2 != 0
            dut.DU.IM.IM[0] = C(6'b011100, 5'd5, 5'd2, 16'd3);

            // ADDC R23 = R30 + 77 at sequential PC = 4
            dut.DU.IM.IM[4] = C(6'b110000, 5'd23, 5'd30, 16'd77);

            dut.DU.RF.RF[2] = 32'd9;
            dut.DU.RF.RF[30] = 32'd0;

            $display("");
            $display("TEST BEQ NOT TAKEN");
            $display("Instruction 1: BEQ R2 == 0, not taken because R2 != 0");
            $display("Instruction 2: ADDC R23 = R30 + 77 at sequential PC=4");
            $display("Instruction IM[0] = %h", dut.DU.IM.IM[0]);
            $display("Instruction IM[4] = %h", dut.DU.IM.IM[4]);
            $display("Input R2=%h", dut.DU.RF.RF[2]);

            apply_reset();
            run_cycles(9);

            check_reg(5'd5, 32'h00000000, "BEQ not taken no link");
            check_reg(5'd23, 32'h0000004D, "BEQ not taken sequential");
        end
    endtask

    task test_BNE_taken;
        begin
            clear_all();

            // BNE if R2 != 0, branch to PC + 4 + 4*3 = 16, R5 = PC + 4
            dut.DU.IM.IM[0] = C(6'b011101, 5'd5, 5'd2, 16'd3);

            // ADDC R22 = R30 + 88 at branch target PC = 16
            dut.DU.IM.IM[16] = C(6'b110000, 5'd22, 5'd30, 16'd88);

            dut.DU.RF.RF[2] = 32'd9;
            dut.DU.RF.RF[30] = 32'd0;

            $display("");
            $display("TEST BNE TAKEN");
            $display("Instruction 1: BNE R2 != 0, branch target PC=16, R5=PC+4");
            $display("Instruction 2: ADDC R22 = R30 + 88 at target PC=16");
            $display("Instruction IM[0]  = %h", dut.DU.IM.IM[0]);
            $display("Instruction IM[16] = %h", dut.DU.IM.IM[16]);
            $display("Input R2=%h", dut.DU.RF.RF[2]);

            apply_reset();
            run_cycles(12);

            check_reg(5'd5, 32'h00000004, "BNE taken link");
            check_reg(5'd22, 32'h00000058, "BNE taken target");
        end
    endtask

    task test_BNE_not_taken;
        begin
            clear_all();

            // BNE not taken because R2 == 0
            dut.DU.IM.IM[0] = C(6'b011101, 5'd5, 5'd2, 16'd3);

            // ADDC R23 = R30 + 66 at sequential PC = 4
            dut.DU.IM.IM[4] = C(6'b110000, 5'd23, 5'd30, 16'd66);

            dut.DU.RF.RF[2] = 32'd0;
            dut.DU.RF.RF[30] = 32'd0;

            $display("");
            $display("TEST BNE NOT TAKEN");
            $display("Instruction 1: BNE R2 != 0, not taken because R2 == 0");
            $display("Instruction 2: ADDC R23 = R30 + 66 at sequential PC=4");
            $display("Instruction IM[0] = %h", dut.DU.IM.IM[0]);
            $display("Instruction IM[4] = %h", dut.DU.IM.IM[4]);
            $display("Input R2=%h", dut.DU.RF.RF[2]);

            apply_reset();
            run_cycles(9);

            check_reg(5'd5, 32'h00000000, "BNE not taken no link");
            check_reg(5'd23, 32'h00000042, "BNE not taken sequential");
        end
    endtask

    initial begin
        $dumpfile("top_branch_memory.vcd");
        $dumpvars(0, tb_Top_Branch_Memory);

        clk = 1'b0;
        reset = 1'b0;
        pass_count = 0;
        fail_count = 0;

        test_LD();
        test_ST();
        test_LDR();
        test_JMP();
        test_BEQ_taken();
        test_BEQ_not_taken();
        test_BNE_taken();
        test_BNE_not_taken();

        $display("");
        $display("========================================");
        $display("BRANCH AND MEMORY TESTS COMPLETED");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);
        $display("========================================");

        $finish;
    end

endmodule