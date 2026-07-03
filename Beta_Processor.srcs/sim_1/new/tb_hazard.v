`timescale 1ns / 1ps

module tb_Top_Data_Hazards;

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
            $display("reset=%b stall=%b z=%b", reset, dut.DU.stall, z);
            $display("PC=%h opcode=%b fetched=%h", dut.DU.PC_out, opcode, dut.DU.IM_out);
            $display("IF_ID_IR=%h ID_EX_IR=%h EX_MEM_IR=%h MEM_WB_IR=%h",
                     dut.DU.IF_ID_IR_out,
                     dut.DU.ID_EX_IR_out,
                     dut.DU.EX_MEM_IR_out,
                     dut.DU.MEM_WB_IR_out);
            $display("control alufn=%b wdsel=%b pcsel=%b werf=%b bsel=%b asel=%b mwr=%b moe=%b ra2sel=%b",
                     alufn_debug,
                     wdsel_debug,
                     pcsel_debug,
                     werf_debug,
                     bsel_debug,
                     asel_debug,
                     mwr_debug,
                     moe_debug,
                     ra2sel_debug);
            $display("RF RD1=%h RD2=%h", dut.DU.RD1, dut.DU.RD2);
            $display("EX A=%h B=%h ALU_COMB=%h ALU_REG=%h",
                     dut.DU.A_out,
                     dut.DU.B_out,
                     dut.DU.Y1_in,
                     dut.DU.Y1_out);
            $display("MEM RD=%h", dut.DU.RD);
            $display("WB WD=%h WA=%0d WERF=%b",
                     dut.DU.WD,
                     dut.DU.MEM_WB_IR_out[25:21],
                     dut.DU.werf_wb);
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

    task test_add_sub_src1_hazard;
        begin
            reset = 1'b0;
            clear_all();

            dut.DU.IM.IM[0] = R(6'b100000, 5'd1, 5'd2, 5'd3);
            dut.DU.IM.IM[4] = R(6'b100001, 5'd4, 5'd1, 5'd5);

            dut.DU.RF.RF[2] = 32'd7;
            dut.DU.RF.RF[3] = 32'd4;
            dut.DU.RF.RF[5] = 32'd2;

            $display("");
            $display("TEST 1: ADD produces R1, next SUB uses R1 as RA");
            $display("IM[0] ADD  R1 = R2 + R3");
            $display("IM[4] SUB  R4 = R1 - R5");
            $display("Input R2=%h R3=%h R5=%h", dut.DU.RF.RF[2], dut.DU.RF.RF[3], dut.DU.RF.RF[5]);

            apply_reset();
            cycle = 0;
            run_cycles(13, "ADD_SUB_SRC1_HAZARD");

            check_reg(5'd1, 32'd11, "ADD result R1");
            check_reg(5'd4, 32'd9,  "SUB uses stalled R1 as RA");
        end
    endtask

    task test_add_sub_src2_hazard;
        begin
            reset = 1'b0;
            clear_all();

            dut.DU.IM.IM[0] = R(6'b100000, 5'd1, 5'd2, 5'd3);
            dut.DU.IM.IM[4] = R(6'b100001, 5'd4, 5'd5, 5'd1);

            dut.DU.RF.RF[2] = 32'd7;
            dut.DU.RF.RF[3] = 32'd4;
            dut.DU.RF.RF[5] = 32'd20;

            $display("");
            $display("TEST 2: ADD produces R1, next SUB uses R1 as RB");
            $display("IM[0] ADD  R1 = R2 + R3");
            $display("IM[4] SUB  R4 = R5 - R1");
            $display("Input R2=%h R3=%h R5=%h", dut.DU.RF.RF[2], dut.DU.RF.RF[3], dut.DU.RF.RF[5]);

            apply_reset();
            cycle = 0;
            run_cycles(13, "ADD_SUB_SRC2_HAZARD");

            check_reg(5'd1, 32'd11, "ADD result R1");
            check_reg(5'd4, 32'd9,  "SUB uses stalled R1 as RB");
        end
    endtask

    task test_add_addc_hazard;
        begin
            reset = 1'b0;
            clear_all();

            dut.DU.IM.IM[0] = R(6'b100000, 5'd1, 5'd2, 5'd3);
            dut.DU.IM.IM[4] = C(6'b110000, 5'd4, 5'd1, 16'd5);

            dut.DU.RF.RF[2] = 32'd7;
            dut.DU.RF.RF[3] = 32'd4;

            $display("");
            $display("TEST 3: ADD produces R1, next ADDC uses R1 as RA");
            $display("IM[0] ADD  R1 = R2 + R3");
            $display("IM[4] ADDC R4 = R1 + 5");
            $display("Input R2=%h R3=%h", dut.DU.RF.RF[2], dut.DU.RF.RF[3]);

            apply_reset();
            cycle = 0;
            run_cycles(13, "ADD_ADDC_HAZARD");

            check_reg(5'd1, 32'd11, "ADD result R1");
            check_reg(5'd4, 32'd16, "ADDC uses stalled R1");
        end
    endtask

    task test_ld_add_hazard;
        begin
            reset = 1'b0;
            clear_all();

            dut.DU.IM.IM[0] = C(6'b011000, 5'd1, 5'd2, 16'd0);
            dut.DU.IM.IM[4] = R(6'b100000, 5'd4, 5'd1, 5'd3);

            dut.DU.RF.RF[2] = 32'd6;
            dut.DU.RF.RF[3] = 32'd5;
            dut.DU.DM.mem[6] = 32'd100;

            $display("");
            $display("TEST 4: LD produces R1, next ADD uses R1");
            $display("IM[0] LD   R1 = MEM[R2 + 0]");
            $display("IM[4] ADD  R4 = R1 + R3");
            $display("Input R2=%h R3=%h DM[6]=%h", dut.DU.RF.RF[2], dut.DU.RF.RF[3], dut.DU.DM.mem[6]);

            apply_reset();
            cycle = 0;
            run_cycles(14, "LD_ADD_HAZARD");

            check_reg(5'd1, 32'd100, "LD result R1");
            check_reg(5'd4, 32'd105, "ADD uses stalled loaded R1");
        end
    endtask

    task test_add_st_data_hazard;
        begin
            reset = 1'b0;
            clear_all();

            dut.DU.IM.IM[0] = R(6'b100000, 5'd1, 5'd2, 5'd3);
            dut.DU.IM.IM[4] = C(6'b011001, 5'd1, 5'd5, 16'd0);

            dut.DU.RF.RF[2] = 32'd7;
            dut.DU.RF.RF[3] = 32'd4;
            dut.DU.RF.RF[5] = 32'd9;

            $display("");
            $display("TEST 5: ADD produces R1, next ST uses R1 as store data");
            $display("IM[0] ADD  R1 = R2 + R3");
            $display("IM[4] ST   MEM[R5 + 0] = R1");
            $display("Input R2=%h R3=%h R5=%h", dut.DU.RF.RF[2], dut.DU.RF.RF[3], dut.DU.RF.RF[5]);

            apply_reset();
            cycle = 0;
            run_cycles(13, "ADD_ST_DATA_HAZARD");

            check_reg(5'd1, 32'd11, "ADD result R1");
            check_mem(32'd9, 32'd11, "ST uses stalled R1 as data");
        end
    endtask

    task test_add_st_address_hazard;
        begin
            reset = 1'b0;
            clear_all();

            dut.DU.IM.IM[0] = R(6'b100000, 5'd5, 5'd2, 5'd3);
            dut.DU.IM.IM[4] = C(6'b011001, 5'd1, 5'd5, 16'd0);

            dut.DU.RF.RF[1] = 32'h1234_5678;
            dut.DU.RF.RF[2] = 32'd7;
            dut.DU.RF.RF[3] = 32'd4;

            $display("");
            $display("TEST 6: ADD produces R5, next ST uses R5 as address base");
            $display("IM[0] ADD  R5 = R2 + R3");
            $display("IM[4] ST   MEM[R5 + 0] = R1");
            $display("Input R1=%h R2=%h R3=%h", dut.DU.RF.RF[1], dut.DU.RF.RF[2], dut.DU.RF.RF[3]);

            apply_reset();
            cycle = 0;
            run_cycles(13, "ADD_ST_ADDR_HAZARD");

            check_reg(5'd5, 32'd11, "ADD result R5");
            check_mem(32'd11, 32'h1234_5678, "ST uses stalled R5 as address");
        end
    endtask

    initial begin
        $dumpfile("top_data_hazards.vcd");
        $dumpvars(0, tb_Top_Data_Hazards);

        clk = 1'b0;
        reset = 1'b0;
        pass_count = 0;
        fail_count = 0;
        cycle = 0;

        test_add_sub_src1_hazard();
        test_add_sub_src2_hazard();
        test_add_addc_hazard();
        test_ld_add_hazard();
        test_add_st_data_hazard();
        test_add_st_address_hazard();

        $display("");
        $display("========================================");
        $display("DATA HAZARD TESTS COMPLETED");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);
        $display("========================================");

        $finish;
    end

endmodule