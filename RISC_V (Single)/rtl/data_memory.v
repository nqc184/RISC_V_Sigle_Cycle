`timescale 1ns / 1ps
module data_memory (
    input clk,
    input mem_read, mem_write,
    input [31:0] addr,
    input [31:0] write_data,
    output wire [31:0] read_data
);
    reg [31:0] RAM [0:63];

    assign read_data = mem_read ? RAM[addr[7:2]] : 32'b0;

    always @(posedge clk) begin
        if (mem_write)
            RAM[addr[7:2]] <= write_data;
    end
endmodule