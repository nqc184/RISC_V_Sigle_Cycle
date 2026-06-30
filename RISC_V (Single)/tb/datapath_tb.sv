`timescale 1ns/1ps
module tb ();
    logic clk, w_en;               
    logic [4:0] ra1, ra2, wa;
    logic [2:0] alu_ctrl;     
    logic [31:0] alu_res;

    datapath uut(
        .clk(clk), .w_en(w_en),             
        .ra1(ra1), .ra2(ra2), .wa(wa),
        .alu_ctrl(alu_ctrl),  
        .alu_res(alu_res)
    ); 

    always #5 clk = ~clk;

    initial begin
        clk = 0; w_en = 0; ra1 = 0; ra2 = 0; wa = 0; alu_ctrl = 0;
        #10;
        w_en = 1;
        alu_res = 32'd10;
        wa = 5'd1;
        #10;
        w_en = 1;
        alu_res = 32'd5;
        wa = 5'd2;
        #10;
        w_en = 0;
        ra1 = 5'd1;
        ra2 = 5'd2;
        wa = 5'd3;
        alu_ctrl = 3'b101;
        #10;
        w_en = 1;
        #10;
        w_en = 0;
        ra1 = 5'd3;
        #10;
        $finish;
    end
endmodule