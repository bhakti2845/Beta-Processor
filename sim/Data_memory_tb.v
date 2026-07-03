`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2026 19:39:43
// Design Name: 
// Module Name: Data_memory_tb
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


`timescale 1ns/1ps


module tb_Data_memory;

    reg         clk;
    reg  [31:0] WD;
    reg  [31:0] Addr;
    reg         RW;
    reg         OE;
    wire [31:0] RD;

    Data_memory dut (
        .clk(clk),
        .WD(WD),
        .Addr(Addr),
        .RW(RW),
        .OE(OE),
        .RD(RD)
    );

    always #5 clk = ~clk;

    task check;
        input [31:0] actual;
        input [31:0] expected;
        input [160:0] name;
        begin
            if (actual !== expected)
                $display("FAIL: %s expected=%h got=%h", name, expected, actual);
            else
                $display("PASS: %s value=%h", name, actual);
        end
    endtask

    initial begin
        $dumpfile("data_memory.vcd");
        $dumpvars(0, tb_Data_memory);

        clk = 1'b0;
        WD = 32'd0;
        Addr = 32'd0;
        RW = 1'b0;
        OE = 1'b0;

        #1;
        check(RD, 32'h0000_0000, "OE low output zero");

        @(negedge clk);
        Addr = 32'd0;
        WD = 32'hAAAA_1111;
        RW = 1'b1;
        OE = 1'b0;

        @(posedge clk);
        #1;
        RW = 1'b0;
        OE = 1'b1;
        Addr = 32'd0;
        #1;
        check(RD, 32'hAAAA_1111, "read addr 0");

        @(negedge clk);
        Addr = 32'd1;
        WD = 32'hBBBB_2222;
        RW = 1'b1;
        OE = 1'b0;

        @(posedge clk);
        #1;
        RW = 1'b0;
        OE = 1'b1;
        Addr = 32'd1;
        #1;
        check(RD, 32'hBBBB_2222, "read addr 1");

        Addr = 32'd0;
        #1;
        check(RD, 32'hAAAA_1111, "addr 0 unchanged");

        @(negedge clk);
        Addr = 32'd2;
        WD = 32'hCCCC_3333;
        RW = 1'b1;
        OE = 1'b0;

        @(posedge clk);
        #1;
        RW = 1'b0;
        OE = 1'b1;
        Addr = 32'd2;
        #1;
        check(RD, 32'hCCCC_3333, "read addr 2");

        @(negedge clk);
        Addr = 32'd1;
        WD = 32'h1234_5678;
        RW = 1'b1;
        OE = 1'b0;

        @(posedge clk);
        #1;
        RW = 1'b0;
        OE = 1'b1;
        Addr = 32'd1;
        #1;
        check(RD, 32'h1234_5678, "overwrite addr 1");

        OE = 1'b0;
        #1;
        check(RD, 32'h0000_0000, "OE low hides data");

        OE = 1'b1;
        Addr = 32'd0;
        #1;
        check(RD, 32'hAAAA_1111, "comb read addr 0");

        Addr = 32'd1;
        #1;
        check(RD, 32'h1234_5678, "comb read addr 1");

        Addr = 32'd2;
        #1;
        check(RD, 32'hCCCC_3333, "comb read addr 2");

        $display("Data memory test completed.");
        $finish;
    end

endmodule
