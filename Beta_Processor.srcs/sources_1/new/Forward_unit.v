`timescale 1ns / 1ps

module Forward_unit(
    input [31:0] IF_ID_IR,
    input [31:0] ID_EX_IR,
    input [31:0] EX_MEM_IR,
    input [31:0] MEM_WB_IR,
    input werf_ex,
    input werf_mem,
    input werf_wb,
    input [1:0] wdsel_ex,
    input [1:0] wdsel_mem,
    output [1:0] fwdA,
    output [1:0] fwdB
);

    wire [5:0] opcode;
    wire [4:0] src1;
    wire [4:0] src2;
    wire [4:0] dest_ex;
    wire [4:0] dest_mem;
    wire [4:0] dest_wb;

    wire is_rtype;
    wire is_st;
    wire is_ldr;

    wire src1_used;
    wire src2_used;

    wire ex_available;
    wire mem_available;
    wire wb_available;

    wire ex_src1;
    wire ex_src2;
    wire mem_src1;
    wire mem_src2;
    wire wb_src1;
    wire wb_src2;

    assign opcode = IF_ID_IR[31:26];

    assign src1 = IF_ID_IR[20:16];
    assign src2 = is_st ? IF_ID_IR[25:21] : IF_ID_IR[15:11];

    assign dest_ex  = ID_EX_IR[25:21];
    assign dest_mem = EX_MEM_IR[25:21];
    assign dest_wb  = MEM_WB_IR[25:21];

    assign is_rtype = (opcode[5:4] == 2'b10);
    assign is_st = (opcode == 6'b011001);
    assign is_ldr = (opcode == 6'b011111);

    assign src1_used = !is_ldr;
    assign src2_used = is_rtype || is_st;

    assign ex_available  = werf_ex  && (wdsel_ex  != 2'b10);
    assign mem_available = werf_mem && (wdsel_mem != 2'b10);
    assign wb_available  = werf_wb;

    assign ex_src1  = src1_used && ex_available  && (src1 != 5'd31) && (dest_ex  != 5'd31) && (src1 == dest_ex);
    assign ex_src2  = src2_used && ex_available  && (src2 != 5'd31) && (dest_ex  != 5'd31) && (src2 == dest_ex);

    assign mem_src1 = src1_used && mem_available && (src1 != 5'd31) && (dest_mem != 5'd31) && (src1 == dest_mem);
    assign mem_src2 = src2_used && mem_available && (src2 != 5'd31) && (dest_mem != 5'd31) && (src2 == dest_mem);

    assign wb_src1  = src1_used && wb_available  && (src1 != 5'd31) && (dest_wb  != 5'd31) && (src1 == dest_wb);
    assign wb_src2  = src2_used && wb_available  && (src2 != 5'd31) && (dest_wb  != 5'd31) && (src2 == dest_wb);

    assign fwdA = ex_src1 ? 2'b01 :
                  mem_src1 ? 2'b10 :
                  wb_src1 ? 2'b11 :
                  2'b00;

    assign fwdB = ex_src2 ? 2'b01 :
                  mem_src2 ? 2'b10 :
                  wb_src2 ? 2'b11 :
                  2'b00;

endmodule