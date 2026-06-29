`timescale 1ns/1ps

module tb ();
    logic clktb, w_entb;
    logic [4:0] ra1tb, ra2tb, watb;
    logic [31:0] dtb;
    logic [31:0] rd1tb, rd2tb;

    register_file rf(
        .clk(clktb),
        .w_en(w_entb),
        .ra1(ra1tb), .ra2(ra2tb),
        .wa(watb),
        .d(dtb),
        .rd1(rd1tb), .rd2(rd2tb)
    );

    always #5 clktb = ~clktb;

    initial begin
        clktb = 0;
        w_entb = 0;
        ra1tb = 0; ra2tb = 0; 
        watb = 0; 
        dtb = 0;

        #10;
        w_entb = 1;
        watb = 5'd5;
        dtb = 32'hABCD;
        #10; 

        w_entb = 0;
        ra1tb = 5'd5;
        #10;

        #10;
        w_entb = 1;
        watb = 5'd2;
        dtb = 32'hDCAB;
        #10;

        w_entb = 0;
        ra2tb = 5'd2;
        #10;

        ra1tb = 5'd0;
        #10;
        $finish;

    end
endmodule