`timescale 1ns / 1ps
module register_file (
    input clk, w_en,
    input reset,
    input [4:0] ra1, ra2, wa,
    input [31:0] d,
    output wire [31:0] rd1, rd2
);
    reg [31:0] mem [0:31];
    integer i;
    assign rd1 = (ra1==5'd0) ? 32'd0 : mem[ra1];
    assign rd2 = (ra2==5'd0) ? 32'd0 : mem[ra2];
    always @(posedge clk) begin 
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                mem[i] <= 32'd0;
            end
        end 
        else if (w_en && (wa != 5'd0)) begin 
            mem[wa] <= d;
        end
    end
endmodule