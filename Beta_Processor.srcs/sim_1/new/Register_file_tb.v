`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.06.2026 19:14:00
// Design Name: 
// Module Name: Register_file_tb
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


module tb_Register_file;

    reg         clk;
    reg  [4:0] RA1;
    reg  [4:0] RA2;
    reg  [4:0] WA;
    reg        WE;
    reg  [31:0] WD;
    wire [31:0] RD1;
    wire [31:0] RD2;

    Register_file dut (
        .clk(clk),
        .RA1(RA1),
        .RA2(RA2),
        .WA(WA),
        .WE(WE),
        .WD(WD),
        .RD1(RD1),
        .RD2(RD2)
    );

    always #5 clk = ~clk;

    task check;
        input [31:0] actual;
        input [31:0] expected;
        input [160:0] test_name;
        begin
            if (actual !== expected) begin
                $display("FAIL: %s | expected = %h, got = %h", test_name, expected, actual);
            end else begin
                $display("PASS: %s | value = %h", test_name, actual);
            end
        end
    endtask

    initial begin
        $dumpfile("register_file.vcd");
        $dumpvars(0, tb_Register_file);

        clk = 0;
        RA1 = 0;
        RA2 = 0;
        WA  = 0;
        WE  = 0;
        WD  = 0;

        // Write 0xAAAA_1111 into R5
        @(negedge clk);
        WA = 5'd5;
        WD = 32'hAAAA_1111;
        WE = 1'b1;

        @(posedge clk);
        #1;
        WE = 1'b0;

        // Read R5 using port 1
        RA1 = 5'd5;
        #1;
        check(RD1, 32'hAAAA_1111, "Read R5 from RD1");

        // Write 0xBBBB_2222 into R6
        @(negedge clk);
        WA = 5'd6;
        WD = 32'hBBBB_2222;
        WE = 1'b1;

        @(posedge clk);
        #1;
        WE = 1'b0;

        // Read R5 and R6 together
        RA1 = 5'd5;
        RA2 = 5'd6;
        #1;
        check(RD1, 32'hAAAA_1111, "Read R5 from RD1 again");
        check(RD2, 32'hBBBB_2222, "Read R6 from RD2");

        // Check combinational read change without clock
        RA1 = 5'd6;
        #1;
        check(RD1, 32'hBBBB_2222, "Combinational read changes immediately");

        // Try writing with WE = 0, should not update R5
        @(negedge clk);
        WA = 5'd5;
        WD = 32'hDEAD_BEEF;
        WE = 1'b0;

        @(posedge clk);
        #1;

        RA1 = 5'd5;
        #1;
        check(RD1, 32'hAAAA_1111, "WE = 0, R5 should not change");

        // Try writing to R31, should be ignored
        @(negedge clk);
        WA = 5'd31;
        WD = 32'hFFFF_FFFF;
        WE = 1'b1;

        @(posedge clk);
        #1;
        WE = 1'b0;

        RA1 = 5'd31;
        RA2 = 5'd31;
        #1;
        check(RD1, 32'h0000_0000, "R31 always zero on RD1");
        check(RD2, 32'h0000_0000, "R31 always zero on RD2");

        // Read during write test
        @(negedge clk);
        WA  = 5'd7;
        WD  = 32'h1234_5678;
        RA1 = 5'd7;
        WE  = 1'b1;

        @(posedge clk);
        #1;
        WE = 1'b0;

        check(RD1, 32'h1234_5678, "Read same register after clocked write");

        $display("Register file test completed.");
        $finish;
    end

endmodule
