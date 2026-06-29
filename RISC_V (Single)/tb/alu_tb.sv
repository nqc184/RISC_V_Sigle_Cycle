`timescale 1ns/1ps

module tb ();
    logic [31:0] atb, btb;
    logic [2:0] seltb;
    logic [31:0] ctb;

    alu uut (
        .a(atb),
        .b(btb),
        .sel(seltb),
        .c(ctb)
    );

    initial begin
        atb = 0;
        btb = 0;
        seltb = 0;
        $monitor("Time=%0t | sel=%b | a=%d | b=%d | c=%d", $time, seltb, atb, btb, ctb);
        #10; atb = 10; btb = 5;  seltb = 3'b101; 
        #10; atb = 10; btb = 5;  seltb = 3'b110; 
        #10; atb = 8;  btb = 2;  seltb = 3'b010; 
        #10; atb = 8;  btb = 2;  seltb = 3'b011; 
        #10; $finish;
    end

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);
    end
endmodule