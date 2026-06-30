`timescale 1ns/1ps
module program_counter_tb;

    logic clk;
    logic reset;
    logic [31:0] pc_in;
    logic [31:0] pc_out;

    program_counter dut (
        .clk(clk),
        .reset(reset),
        .pc_in(pc_in),
        .pc_out(pc_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        pc_in = 32'd0;  
        #10;
        reset = 0;
        #10;
        pc_in = 32'd4;
        #40;
        $finish;
    end

endmodule