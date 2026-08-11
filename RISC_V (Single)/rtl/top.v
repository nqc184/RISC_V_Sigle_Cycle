module top (
    input clk, reset,
    output [31:0] out_result 
);
    wire [31:0] pc_current, pc_next;
    wire [31:0] instruction;
    wire        reg_write_sig;
    wire [2:0]  alu_ctrl_sig;
    wire [31:0] reg_data1, reg_data2;
    wire [31:0] alu_result;

    ripple32bit pc_adder (
        .a(pc_current), 
        .b(32'd4), 
        .sub(1'b0), 
        .s(pc_next), 
        .c_out(), 
        .zero_flag(), 
        .overflow()
    );

    program_counter PC(
        .clk(clk), 
        .reset(reset), 
        .pc_in(pc_next), 
        .pc_out(pc_current) 
    );

    instruction_memory Instruction_Memory(
        .pc_in(pc_current),       
        .readData(instruction)
    );

    control_unit Controller(
        .opcode(instruction[6:0]),        
        .funct3(instruction[14:12]),        
        .funct7_5(instruction[30]),      
        .reg_write(reg_write_sig),    
        .alu_ctrl(alu_ctrl_sig)
    );

    register_file RF(
        .clk(clk), 
        .w_en(reg_write_sig),
        .reset(reset),
        .ra1(instruction[19:15]), 
        .ra2(instruction[24:20]), 
        .wa(instruction[11:7]),   
        .d(alu_result),           
        .rd1(reg_data1), 
        .rd2(reg_data2)
    );

    alu ALU(
        .a(reg_data1), 
        .b(reg_data2),
        .sel(alu_ctrl_sig),
        .c(alu_result)
    );

    assign out_result = alu_result;

endmodule