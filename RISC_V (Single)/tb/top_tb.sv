`timescale 1ns / 1ps
module top_tb;

    logic clk, reset;
    logic [31:0] pc_current;
    logic [31:0] out_result; 

    top uut (
        .clk(clk), .reset(reset),
        .pc_current_monitor(pc_current),
        .out_result(out_result) 
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        #10
        reset = 0;
        #150;
        $finish;
    end
endmodule