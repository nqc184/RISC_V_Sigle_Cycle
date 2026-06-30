module program_counter(
    input clk, reset, 
    input [31:0] pc_in, 
    output reg [31:0] pc_out 
);
    always@(posedge clk)
    if (reset) begin 
        pc_out<=pc_in;
    end 
    else begin
        pc_out<=pc_in;
    end  
endmodule