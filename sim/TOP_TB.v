`timescale 1ns / 1ps

module tb_Top;

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

    initial begin
        $dumpfile("top.vcd");
        $dumpvars(0, tb_Top);

        clk = 1'b0;
        reset = 1'b0;
        cycle = 0;

        for (i = 0; i < 32; i = i + 1) begin
            dut.DU.IM.IM[i] = 32'h00000000;
        end

        for (i = 0; i < 32; i = i + 1) begin
            dut.DU.RF.RF[i] = 32'h00000000;
        end

        for (i = 0; i < 1024; i = i + 1) begin
            dut.DU.DM.mem[i] = 32'h00000000;
        end

        // Instruction 1: ADD  R1  = R2  + R3
        dut.DU.IM.IM[0] = R(6'b100000, 5'd1, 5'd2, 5'd3);

        // Instruction 2: SUB  R6  = R4  - R5
        dut.DU.IM.IM[4] = R(6'b100001, 5'd6, 5'd4, 5'd5);

        // Instruction 3: AND  R9  = R7  & R8
        dut.DU.IM.IM[8] = R(6'b101000, 5'd9, 5'd7, 5'd8);

        // Instruction 4: OR   R12 = R10 | R11
        dut.DU.IM.IM[12] = R(6'b101001, 5'd12, 5'd10, 5'd11);

        // Instruction 5: ADDC R14 = R13 + 5
        dut.DU.IM.IM[16] = C(6'b110000, 5'd14, 5'd13, 16'd5);

        // Instruction 6: LD   R16 = MEM[R15 + 0]
        dut.DU.IM.IM[20] = C(6'b011000, 5'd16, 5'd15, 16'd0);

        // Instruction 7: ST   MEM[R18 + 0] = R17
        dut.DU.IM.IM[24] = C(6'b011001, 5'd17, 5'd18, 16'd0);

        dut.DU.RF.RF[2]  = 32'd7;
        dut.DU.RF.RF[3]  = 32'd4;
        dut.DU.RF.RF[4]  = 32'd20;
        dut.DU.RF.RF[5]  = 32'd8;
        dut.DU.RF.RF[7]  = 32'hF0F0_F0F0;
        dut.DU.RF.RF[8]  = 32'h0F0F_0F0F;
        dut.DU.RF.RF[10] = 32'hF0F0_F0F0;
        dut.DU.RF.RF[11] = 32'h0F0F_0F0F;
        dut.DU.RF.RF[13] = 32'd100;
        dut.DU.RF.RF[15] = 32'd3;
        dut.DU.RF.RF[17] = 32'h1234_5678;
        dut.DU.RF.RF[18] = 32'd5;

        dut.DU.DM.mem[3] = 32'hA5A5_5A5A;

        $display("INPUT PROGRAM");
        $display("IM[0]  ADD  R1  = R2  + R3       instruction = %h", dut.DU.IM.IM[0]);
        $display("IM[4]  SUB  R6  = R4  - R5       instruction = %h", dut.DU.IM.IM[4]);
        $display("IM[8]  AND  R9  = R7  & R8       instruction = %h", dut.DU.IM.IM[8]);
        $display("IM[12] OR   R12 = R10 | R11      instruction = %h", dut.DU.IM.IM[12]);
        $display("IM[16] ADDC R14 = R13 + 5        instruction = %h", dut.DU.IM.IM[16]);
        $display("IM[20] LD   R16 = MEM[R15 + 0]   instruction = %h", dut.DU.IM.IM[20]);
        $display("IM[24] ST   MEM[R18 + 0] = R17   instruction = %h", dut.DU.IM.IM[24]);
        $display("");

        $display("INPUT REGISTER VALUES");
        $display("R2  = %h, R3  = %h", dut.DU.RF.RF[2], dut.DU.RF.RF[3]);
        $display("R4  = %h, R5  = %h", dut.DU.RF.RF[4], dut.DU.RF.RF[5]);
        $display("R7  = %h, R8  = %h", dut.DU.RF.RF[7], dut.DU.RF.RF[8]);
        $display("R10 = %h, R11 = %h", dut.DU.RF.RF[10], dut.DU.RF.RF[11]);
        $display("R13 = %h", dut.DU.RF.RF[13]);
        $display("R15 = %h", dut.DU.RF.RF[15]);
        $display("R17 = %h, R18 = %h", dut.DU.RF.RF[17], dut.DU.RF.RF[18]);
        $display("DM[3] = %h", dut.DU.DM.mem[3]);
        $display("");

        #20;
        reset = 1'b1;

        #250;

        $display("");
        $display("FINAL OUTPUT VALUES");
        $display("R1  = %h expected 0000000b", dut.DU.RF.RF[1]);
        $display("R6  = %h expected 0000000c", dut.DU.RF.RF[6]);
        $display("R9  = %h expected 00000000", dut.DU.RF.RF[9]);
        $display("R12 = %h expected ffffffff", dut.DU.RF.RF[12]);
        $display("R14 = %h expected 00000069", dut.DU.RF.RF[14]);
        $display("R16 = %h expected a5a55a5a", dut.DU.RF.RF[16]);
        $display("DM[5] = %h expected 12345678", dut.DU.DM.mem[5]);

        if (dut.DU.RF.RF[1]  == 32'h0000000b) $display("PASS ADD");
        else $display("FAIL ADD");

        if (dut.DU.RF.RF[6]  == 32'h0000000c) $display("PASS SUB");
        else $display("FAIL SUB");

        if (dut.DU.RF.RF[9]  == 32'h00000000) $display("PASS AND");
        else $display("FAIL AND");

        if (dut.DU.RF.RF[12] == 32'hffffffff) $display("PASS OR");
        else $display("FAIL OR");

        if (dut.DU.RF.RF[14] == 32'h00000069) $display("PASS ADDC");
        else $display("FAIL ADDC");

        if (dut.DU.RF.RF[16] == 32'ha5a55a5a) $display("PASS LD");
        else $display("FAIL LD");

        if (dut.DU.DM.mem[5] == 32'h12345678) $display("PASS ST");
        else $display("FAIL ST");

        $display("");
        $display("Top test completed");
        $finish;
    end

    always @(posedge clk) begin
        #1;
        cycle = cycle + 1;

        $display("CYCLE %0d", cycle);
        $display("reset=%b", reset);
        $display("PC=%h FETCH_INSTR=%h IF_ID_IR=%h OPCODE=%b", dut.DU.PC_out, dut.DU.IM_out, dut.DU.IF_ID_IR_out, opcode);
        $display("CONTROL alufn=%b wdsel=%b pcsel=%b werf=%b bsel=%b asel=%b mwr=%b moe=%b ra2sel=%b",
                 alufn_debug, wdsel_debug, pcsel_debug, werf_debug, bsel_debug, asel_debug, mwr_debug, moe_debug, ra2sel_debug);
        $display("RF RD1=%h RD2=%h", dut.DU.RD1, dut.DU.RD2);
        $display("EX A_OUT=%h B_OUT=%h ALU_COMB_OUT=%h ALU_REG_OUT=%h", dut.DU.A_out, dut.DU.B_out, dut.DU.Y1_in, dut.DU.Y1_out);
        $display("MEM RD=%h", dut.DU.RD);
        $display("WB WD=%h WA=%d WERF=%b", dut.DU.WD, dut.DU.MEM_WB_IR_out[25:21], dut.DU.werf_wb);
        $display("");
    end

endmodule
