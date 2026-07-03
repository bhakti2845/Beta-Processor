`timescale 1ns / 1ps

module tb_Top_Forward_Stall;

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
    integer stall_count;

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

    function [31:0] R;
        input [5:0] op;
        input [4:0] rc;
        input [4:0] ra;
        input [4:0] rb;
        begin
            R = {op, rc, ra, rb, 11'd0};
        end
    endfunction

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
            $display("reset=%b stall=%b fwdA=%b fwdB=%b z=%b", reset, dut.DU.stall, dut.DU.fwdA, dut.DU.fwdB, z);
            $display("PC=%h fetched=%h opcode=%b", dut.DU.PC_out, dut.DU.IM_out, opcode);
            $display("IF_ID_IR=%h", dut.DU.IF_ID_IR_out);
            $display("ID_EX_IR=%h", dut.DU.ID_EX_IR_out);
            $display("EX_MEM_IR=%h", dut.DU.EX_MEM_IR_out);
            $display("MEM_WB_IR=%h", dut.DU.MEM_WB_IR_out);
            $display("RD1=%h RD2=%h RD1_bypass=%h RD2_bypass=%h", dut.DU.RD1, dut.DU.RD2, dut.DU.RD1_bypass, dut.DU.RD2_bypass);
            $display("A_OUT=%h B_OUT=%h ALU_COMB=%h ALU_REG=%h", dut.DU.A_out, dut.DU.B_out, dut.DU.Y1_in, dut.DU.Y1_out);
            $display("MEM_RD=%h WB_WD=%h WB_WA=%0d WB_WERF=%b", dut.DU.RD, dut.DU.WD, dut.DU.MEM_WB_IR_out[25:21], dut.DU.werf_wb);
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

                if (dut.DU.stall == 1'b1)
                    stall_count = stall_count + 1;

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

    task check_mem;
        input [31:0] addr;
        input [31:0] expected;
        input [255:0] name;
        begin
            if (dut.DU.DM.mem[addr] === expected) begin
                $display("PASS %-40s DM[%0d]=%h expected=%h", name, addr, dut.DU.DM.mem[addr], expected);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL %-40s DM[%0d]=%h expected=%h", name, addr, dut.DU.DM.mem[addr], expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_no_stall;
        input [255:0] name;
        begin
            if (stall_count == 0) begin
                $display("PASS %-40s stall_count=%0d expected=0", name, stall_count);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL %-40s stall_count=%0d expected=0", name, stall_count);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_stall_happened;
        input [255:0] name;
        begin
            if (stall_count > 0) begin
                $display("PASS %-40s stall_count=%0d expected>0", name, stall_count);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL %-40s stall_count=%0d expected>0", name, stall_count);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task test_forward_alu_src1;
        begin
            reset = 1'b0;
            clear_all();
            stall_count = 0;

            dut.DU.IM.IM[0] = R(6'b100000, 5'd1, 5'd2, 5'd3);
            dut.DU.IM.IM[4] = R(6'b100001, 5'd4, 5'd1, 5'd5);

            dut.DU.RF.RF[2] = 32'd7;
            dut.DU.RF.RF[3] = 32'd4;
            dut.DU.RF.RF[5] = 32'd2;

            $display("");
            $display("TEST 1: ALU forwarding to RA");
            $display("IM[0] ADD R1 = R2 + R3");
            $display("IM[4] SUB R4 = R1 - R5");
            $display("Expected no stall, R1=11, R4=9");

            apply_reset();
            cycle = 0;
            run_cycles(11, "FORWARD_ALU_SRC1");

            check_reg(5'd1, 32'd11, "ADD result R1");
            check_reg(5'd4, 32'd9,  "SUB got R1 by forwarding");
            check_no_stall("ALU to RA forwarding");
        end
    endtask

    task test_forward_alu_src2;
        begin
            reset = 1'b0;
            clear_all();
            stall_count = 0;

            dut.DU.IM.IM[0] = R(6'b100000, 5'd1, 5'd2, 5'd3);
            dut.DU.IM.IM[4] = R(6'b100001, 5'd4, 5'd5, 5'd1);

            dut.DU.RF.RF[2] = 32'd7;
            dut.DU.RF.RF[3] = 32'd4;
            dut.DU.RF.RF[5] = 32'd20;

            $display("");
            $display("TEST 2: ALU forwarding to RB");
            $display("IM[0] ADD R1 = R2 + R3");
            $display("IM[4] SUB R4 = R5 - R1");
            $display("Expected no stall, R1=11, R4=9");

            apply_reset();
            cycle = 0;
            run_cycles(11, "FORWARD_ALU_SRC2");

            check_reg(5'd1, 32'd11, "ADD result R1");
            check_reg(5'd4, 32'd9,  "SUB got R1 by forwarding");
            check_no_stall("ALU to RB forwarding");
        end
    endtask

    task test_forward_alu_const;
        begin
            reset = 1'b0;
            clear_all();
            stall_count = 0;

            dut.DU.IM.IM[0] = R(6'b100000, 5'd1, 5'd2, 5'd3);
            dut.DU.IM.IM[4] = C(6'b110000, 5'd4, 5'd1, 16'd5);

            dut.DU.RF.RF[2] = 32'd7;
            dut.DU.RF.RF[3] = 32'd4;

            $display("");
            $display("TEST 3: ALU forwarding to constant instruction");
            $display("IM[0] ADD  R1 = R2 + R3");
            $display("IM[4] ADDC R4 = R1 + 5");
            $display("Expected no stall, R1=11, R4=16");

            apply_reset();
            cycle = 0;
            run_cycles(11, "FORWARD_ALU_CONST");

            check_reg(5'd1, 32'd11, "ADD result R1");
            check_reg(5'd4, 32'd16, "ADDC got R1 by forwarding");
            check_no_stall("ALU to ADDC forwarding");
        end
    endtask

    task test_forward_priority;
        begin
            reset = 1'b0;
            clear_all();
            stall_count = 0;

            dut.DU.IM.IM[0] = C(6'b110000, 5'd1, 5'd31, 16'd10);
            dut.DU.IM.IM[4] = C(6'b110000, 5'd1, 5'd31, 16'd20);
            dut.DU.IM.IM[8] = C(6'b110000, 5'd2, 5'd1, 16'd5);

            $display("");
            $display("TEST 4: Forwarding priority EX > MEM > WB");
            $display("IM[0] ADDC R1 = R31 + 10");
            $display("IM[4] ADDC R1 = R31 + 20");
            $display("IM[8] ADDC R2 = R1  + 5");
            $display("Expected no stall, R2=25 using most recent R1=20");

            apply_reset();
            cycle = 0;
            run_cycles(12, "FORWARD_PRIORITY");

            check_reg(5'd1, 32'd20, "Latest R1 value");
            check_reg(5'd2, 32'd25, "Forward priority result R2");
            check_no_stall("Forward priority");
        end
    endtask

    task test_forward_st_data;
        begin
            reset = 1'b0;
            clear_all();
            stall_count = 0;

            dut.DU.IM.IM[0] = R(6'b100000, 5'd1, 5'd2, 5'd3);
            dut.DU.IM.IM[4] = C(6'b011001, 5'd1, 5'd5, 16'd0);

            dut.DU.RF.RF[2] = 32'd7;
            dut.DU.RF.RF[3] = 32'd4;
            dut.DU.RF.RF[5] = 32'd9;

            $display("");
            $display("TEST 5: Forwarding into ST store data");
            $display("IM[0] ADD R1 = R2 + R3");
            $display("IM[4] ST  MEM[R5 + 0] = R1");
            $display("Expected no stall, DM[9]=11");

            apply_reset();
            cycle = 0;
            run_cycles(11, "FORWARD_ST_DATA");

            check_reg(5'd1, 32'd11, "ADD result R1");
            check_mem(32'd9, 32'd11, "ST got store data by forwarding");
            check_no_stall("ALU to ST data forwarding");
        end
    endtask

    task test_forward_st_address;
        begin
            reset = 1'b0;
            clear_all();
            stall_count = 0;

            dut.DU.IM.IM[0] = R(6'b100000, 5'd5, 5'd2, 5'd3);
            dut.DU.IM.IM[4] = C(6'b011001, 5'd1, 5'd5, 16'd0);

            dut.DU.RF.RF[1] = 32'h12345678;
            dut.DU.RF.RF[2] = 32'd7;
            dut.DU.RF.RF[3] = 32'd4;

            $display("");
            $display("TEST 6: Forwarding into ST address base");
            $display("IM[0] ADD R5 = R2 + R3");
            $display("IM[4] ST  MEM[R5 + 0] = R1");
            $display("Expected no stall, DM[11]=12345678");

            apply_reset();
            cycle = 0;
            run_cycles(11, "FORWARD_ST_ADDRESS");

            check_reg(5'd5, 32'd11, "ADD result R5");
            check_mem(32'd11, 32'h12345678, "ST got address by forwarding");
            check_no_stall("ALU to ST address forwarding");
        end
    endtask

    task test_load_use_add_stall;
        begin
            reset = 1'b0;
            clear_all();
            stall_count = 0;

            dut.DU.IM.IM[0] = C(6'b011000, 5'd1, 5'd2, 16'd0);
            dut.DU.IM.IM[4] = R(6'b100000, 5'd4, 5'd1, 5'd3);

            dut.DU.RF.RF[2] = 32'd6;
            dut.DU.RF.RF[3] = 32'd5;
            dut.DU.DM.mem[6] = 32'd100;

            $display("");
            $display("TEST 7: Load-use hazard stall");
            $display("IM[0] LD  R1 = MEM[R2 + 0]");
            $display("IM[4] ADD R4 = R1 + R3");
            $display("Expected stall, R1=100, R4=105");

            apply_reset();
            cycle = 0;
            run_cycles(14, "LOAD_USE_ADD_STALL");

            check_reg(5'd1, 32'd100, "LD result R1");
            check_reg(5'd4, 32'd105, "ADD got loaded R1 after stall");
            check_stall_happened("LD to ADD stall");
        end
    endtask

    task test_load_use_st_data_stall;
        begin
            reset = 1'b0;
            clear_all();
            stall_count = 0;

            dut.DU.IM.IM[0] = C(6'b011000, 5'd1, 5'd2, 16'd0);
            dut.DU.IM.IM[4] = C(6'b011001, 5'd1, 5'd5, 16'd0);

            dut.DU.RF.RF[2] = 32'd6;
            dut.DU.RF.RF[5] = 32'd9;
            dut.DU.DM.mem[6] = 32'hA5A55A5A;

            $display("");
            $display("TEST 8: Load-use hazard into ST data");
            $display("IM[0] LD R1 = MEM[R2 + 0]");
            $display("IM[4] ST MEM[R5 + 0] = R1");
            $display("Expected stall, DM[9]=A5A55A5A");

            apply_reset();
            cycle = 0;
            run_cycles(14, "LOAD_USE_ST_DATA_STALL");

            check_reg(5'd1, 32'hA5A55A5A, "LD result R1");
            check_mem(32'd9, 32'hA5A55A5A, "ST got loaded data after stall");
            check_stall_happened("LD to ST data stall");
        end
    endtask

    task test_load_use_st_address_stall;
        begin
            reset = 1'b0;
            clear_all();
            stall_count = 0;

            dut.DU.IM.IM[0] = C(6'b011000, 5'd5, 5'd2, 16'd0);
            dut.DU.IM.IM[4] = C(6'b011001, 5'd1, 5'd5, 16'd0);

            dut.DU.RF.RF[1] = 32'h12345678;
            dut.DU.RF.RF[2] = 32'd6;
            dut.DU.DM.mem[6] = 32'd11;

            $display("");
            $display("TEST 9: Load-use hazard into ST address");
            $display("IM[0] LD R5 = MEM[R2 + 0]");
            $display("IM[4] ST MEM[R5 + 0] = R1");
            $display("Expected stall, DM[11]=12345678");

            apply_reset();
            cycle = 0;
            run_cycles(14, "LOAD_USE_ST_ADDRESS_STALL");

            check_reg(5'd5, 32'd11, "LD result R5");
            check_mem(32'd11, 32'h12345678, "ST got loaded address after stall");
            check_stall_happened("LD to ST address stall");
        end
    endtask

    initial begin
        $dumpfile("top_forward_stall.vcd");
        $dumpvars(0, tb_Top_Forward_Stall);

        clk = 1'b0;
        reset = 1'b0;
        cycle = 0;
        pass_count = 0;
        fail_count = 0;
        stall_count = 0;

        test_forward_alu_src1();
        test_forward_alu_src2();
        test_forward_alu_const();
        test_forward_priority();
        test_forward_st_data();
        test_forward_st_address();

        test_load_use_add_stall();
        test_load_use_st_data_stall();
        test_load_use_st_address_stall();

        $display("");
        $display("========================================");
        $display("FORWARDING AND STALL TESTS COMPLETED");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);
        $display("========================================");

        $finish;
    end

endmodule