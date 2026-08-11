`timescale 1ns/1ps
module tb;
    logic clk; 
    logic reset;
    logic [31:0] out_result; 

    top risc_v(
        .clk(clk), 
        .reset(reset),
        .out_result(out_result) 
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        #20;
        reset = 0;
        #50;
        $finish;
    end

    initial begin
        if (!reset) begin
            $display("Time = %0t ns | Result = %0d", $time, out_result);
        end
    end
endmodule
