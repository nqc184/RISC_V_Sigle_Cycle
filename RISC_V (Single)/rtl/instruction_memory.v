module instruction_memory (
    input [31:0] pc_in,       
    output wire [31:0] readData 
);
    reg [31:0] RAM [0:63];
    
    initial begin
        $readmemh("instruction_memory_testbench.mem", RAM);
    end
    assign readData = RAM[pc_in[7:2]];
endmodule