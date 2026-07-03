`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.06.2026 10:43:21
// Design Name: 
// Module Name: Datapath_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Datapath_unit(
input clk,reset,
input [3:0]alufn,
input [1:0]wdsel,pcsel,
input werf,bsel,asel,mwr,moe,ra2sel,
output z, 
output [5:0]Out
    );
    wire annul;
    wire [31:0] IF_ID_IR_in;

    wire [31:0] PC_plus4,PC_Adder,JT,PC_in,PC_out,IF_ID_PC_out,IM_out,WD,RD1,RD2,IF_ID_IR_out;
    wire [31:0] SXT_out,LS_out,IF_EX_PC_out,A_in,A_out,B_in,B_out,D_out,Y1_in,Y1_out,EX_MEM_PC_out,ID_EX_IR_out;
    wire[31:0] EX_MEM_IR_out,D1_out,RD,WDSEL_out,MEM_WB_IR_out,MEM_WB_PC_out;
    wire [4:0]RA2SEL_out;
    wire werf_ex,werf_mem,werf_wb;
    wire moe_ex,moe_mem;
    wire mwr_ex,mwr_mem;
    wire [1:0]wdsel_ex,wdsel_mem;
    wire [3:0]alufn_ex;
    
    wire stall;
    wire [31:0] ID_EX_IR_in;
    assign ID_EX_IR_in = stall ? 32'h83FFF800 : IF_ID_IR_out;
    assign annul = (pcsel != 2'b00) && (stall == 1'b0);
    assign IF_ID_IR_in = annul ? 32'h83FFF800 : IM_out;
    wire [1:0] fwdA;
wire [1:0] fwdB;

wire [31:0] RD1_bypass;
wire [31:0] RD2_bypass;

wire [31:0] EX_bypass_data;
wire [31:0] MEM_bypass_data;
wire [31:0] WB_bypass_data;
        assign Out= IF_ID_IR_out[31:26];
    assign JT=RD1_bypass;
    assign EX_bypass_data = (wdsel_ex == 2'b00) ? IF_EX_PC_out :
                        (wdsel_ex == 2'b01) ? Y1_in :
                        32'd0;

assign MEM_bypass_data = (wdsel_mem == 2'b00) ? EX_MEM_PC_out :
                         (wdsel_mem == 2'b01) ? Y1_out :
                         32'd0;

assign WB_bypass_data = WD;

assign RD1_bypass = (fwdA == 2'b01) ? EX_bypass_data :
                    (fwdA == 2'b10) ? MEM_bypass_data :
                    (fwdA == 2'b11) ? WB_bypass_data :
                    RD1;

assign RD2_bypass = (fwdB == 2'b01) ? EX_bypass_data :
                    (fwdB == 2'b10) ? MEM_bypass_data :
                    (fwdB == 2'b11) ? WB_bypass_data :
                    RD2;
    Hazard_unit HU(
    IF_ID_IR_out,
    ID_EX_IR_out,
    EX_MEM_IR_out,
    MEM_WB_IR_out,
    werf_ex,
    werf_mem,
    werf_wb,
    stall
);
    Forward_unit FU(
    IF_ID_IR_out,
    ID_EX_IR_out,
    EX_MEM_IR_out,
    MEM_WB_IR_out,
    werf_ex,
    werf_mem,
    werf_wb,
    wdsel_ex,
    wdsel_mem,
    fwdA,
    fwdB
);
    PCSEL_mux PCSEL_multiplexer(PC_plus4,PC_Adder,JT,32'd0,pcsel,PC_in);
    Register_en PC(clk,reset,~stall,PC_in,PC_out);
    PC_4 PC_nxt(PC_out,PC_plus4);
    Register_en IF_ID_PC(clk,reset,~stall,PC_plus4,IF_ID_PC_out);
    Instruction_Memory IM(PC_out,IM_out);
    Register_en IF_ID_IR(clk,reset,~stall,IF_ID_IR_in,IF_ID_IR_out);
    Register_file RF(clk,IF_ID_IR_out[20:16],RA2SEL_out,MEM_WB_IR_out[25:21],werf_wb,WD,RD1,RD2);
    Mux_2to1_5bits RA2SEL_mux(IF_ID_IR_out[15:11],IF_ID_IR_out[25:21],ra2sel,RA2SEL_out);
    Sign_Extender SXT(IF_ID_IR_out[15:0],SXT_out);
    LS_2 Left_2(SXT_out,LS_out);
    Adder Add(LS_out,IF_ID_PC_out, PC_Adder);
    Nor_gate N(RD1_bypass,z);
    Mux_2to1 ASEL_mux(RD1_bypass,PC_Adder,asel,A_in);
    Mux_2to1 BSEL_mux(RD2_bypass,SXT_out,bsel,B_in);
    Register ID_EX_PC(clk,reset,IF_ID_PC_out,IF_EX_PC_out);
    Register ID_EX_IR(clk,reset,ID_EX_IR_in,ID_EX_IR_out);
    Register A(clk,reset,A_in,A_out);
    Register B(clk,reset,B_in,B_out);
    Register D(clk,reset,RD2_bypass,D_out);
    ALU alu(alufn_ex,A_out,B_out,Y1_in);
    Register EX_MEM_PC(clk,reset,IF_EX_PC_out,EX_MEM_PC_out);
    Register EX_MEM_IR(clk,reset,ID_EX_IR_out,EX_MEM_IR_out);
    Register Y1(clk,reset,Y1_in,Y1_out);
    Register D1(clk,reset,D_out,D1_out);
    Data_memory DM(clk,D1_out,Y1_out,mwr_mem,moe_mem,RD);
    PCSEL_mux WDSEL_mux(EX_MEM_PC_out,Y1_out,RD,32'd0,wdsel_mem,WDSEL_out);
    Register MEM_WB_IR(clk,reset,EX_MEM_IR_out,MEM_WB_IR_out);
    Register MEM_WB_PC(clk,reset,EX_MEM_PC_out,MEM_WB_PC_out);
    Register Y2(clk,reset,WDSEL_out,WD);
    
    
    
    Register_1 WERF1(clk,reset,stall ? 1'b0 : werf,werf_ex);
    Register_1 WERF2(clk,reset,werf_ex,werf_mem);
    Register_1 WERF3(clk,reset,werf_mem,werf_wb);
    
    Register_1 MOE1(clk,reset,stall ? 1'b0 : moe,moe_ex);
    Register_1 MOE2(clk,reset,moe_ex,moe_mem);
    
    Register_1 MWR1(clk,reset,stall ? 1'b0 : mwr,mwr_ex);
    Register_1 MWR2(clk,reset,mwr_ex,mwr_mem);
    
    Register_2 WDSEL1(clk,reset,stall ? 2'b00 : wdsel,wdsel_ex);
    Register_2 WDSEL2(clk,reset,wdsel_ex,wdsel_mem);
    
    Register_4 ALUFN1(clk,reset,stall ? 4'b0000 : alufn,alufn_ex);   
    
    
      
endmodule
