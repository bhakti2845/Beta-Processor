`timescale 1ns / 1ps

module Hazard_unit(
    input [31:0] IF_ID_IR,
    input [31:0] ID_EX_IR,
    input [31:0] EX_MEM_IR,
    input [31:0] MEM_WB_IR,
    input werf_ex,
    input werf_mem,
    input werf_wb,
    output stall
);

    wire [5:0] opcode;
    wire [4:0] src1;
    wire [4:0] src2;
    wire [4:0] dest_ex;
    wire [4:0] dest_mem;

    wire is_rtype;
    wire is_st;
    wire is_ldr_rf;

    wire src1_used;
    wire src2_used;

    wire is_load_ex;
    wire is_load_mem;

    wire h_ex_src1;
    wire h_ex_src2;
    wire h_mem_src1;
    wire h_mem_src2;

    assign opcode = IF_ID_IR[31:26];

    assign src1 = IF_ID_IR[20:16];
    assign src2 = is_st ? IF_ID_IR[25:21] : IF_ID_IR[15:11];

    assign dest_ex  = ID_EX_IR[25:21];
    assign dest_mem = EX_MEM_IR[25:21];

    assign is_rtype = (opcode[5:4] == 2'b10);
    assign is_st = (opcode == 6'b011001);
    assign is_ldr_rf = (opcode == 6'b011111);

    assign src1_used = !is_ldr_rf;
    assign src2_used = is_rtype || is_st;

    assign is_load_ex  = (ID_EX_IR[31:26] == 6'b011000) || (ID_EX_IR[31:26] == 6'b011111);
    assign is_load_mem = (EX_MEM_IR[31:26] == 6'b011000) || (EX_MEM_IR[31:26] == 6'b011111);

    assign h_ex_src1  = src1_used && werf_ex  && is_load_ex  && (src1 != 5'd31) && (dest_ex  != 5'd31) && (src1 == dest_ex);
    assign h_ex_src2  = src2_used && werf_ex  && is_load_ex  && (src2 != 5'd31) && (dest_ex  != 5'd31) && (src2 == dest_ex);

    assign h_mem_src1 = src1_used && werf_mem && is_load_mem && (src1 != 5'd31) && (dest_mem != 5'd31) && (src1 == dest_mem);
    assign h_mem_src2 = src2_used && werf_mem && is_load_mem && (src2 != 5'd31) && (dest_mem != 5'd31) && (src2 == dest_mem);

    assign stall = h_ex_src1 | h_ex_src2 | h_mem_src1 | h_mem_src2;

endmodule