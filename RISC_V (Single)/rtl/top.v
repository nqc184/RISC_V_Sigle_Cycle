`timescale 1ns / 1ps
module top (
    input clk, reset,
    output [31:0] pc_current_monitor,
    output [31:0] out_result 
);
    wire [31:0] pc_current, pc_next;
    wire [31:0] instruction;
    wire        reg_write_sig, alu_src_sig;
    wire        mem_read_sig, mem_write_sig, mem_to_reg_sig, branch_sig, jump_sig;
    wire [3:0]  alu_ctrl_sig;
    wire [31:0] reg_data1, reg_data2;
    wire [31:0] imm_value, alu_b_in, alu_result;
    wire        alu_zero_flag;
    wire [31:0] mem_read_data, write_back_data;

    assign pc_current_monitor = pc_current;

    ripple32bit pc_adder (
        .a(pc_current), .b(32'd4), .sub(1'b0), 
        .s(pc_next), .c_out(), .zero_flag(), .overflow()
    );

    program_counter PC(
        .clk(clk), .reset(reset), .pc_in(pc_next), .pc_out(pc_current) 
    );

    instruction_memory Instruction_Memory(
        .pc_in(pc_current), .readData(instruction)
    );

    imm_gen ImmGen (
        .instruction(instruction), .imm_out(imm_value)
    );

    control_unit Controller(
        .opcode(instruction[6:0]),        
        .funct3(instruction[14:12]),        
        .funct7_5(instruction[30]),      
        .reg_write(reg_write_sig),
        .alu_src(alu_src_sig),
        .mem_read(mem_read_sig),
        .mem_write(mem_write_sig),
        .mem_to_reg(mem_to_reg_sig),
        .branch(branch_sig),
        .jump(jump_sig),
        .alu_ctrl(alu_ctrl_sig)
    );

    register_file RF(
        .clk(clk), 
        .w_en(reg_write_sig),
        .reset(reset),
        .ra1(instruction[19:15]), 
        .ra2(instruction[24:20]), 
        .wa(instruction[11:7]),   
        .d(write_back_data),    
        .rd1(reg_data1), 
        .rd2(reg_data2)
    );

    assign alu_b_in = alu_src_sig ? imm_value : reg_data2;

    alu ALU(
        .a(reg_data1), 
        .b(alu_b_in),
        .sel(alu_ctrl_sig),
        .c(alu_result),
        .zero_flag(alu_zero_flag)
    );

    data_memory DMEM (
        .clk(clk),
        .mem_read(mem_read_sig),
        .mem_write(mem_write_sig),
        .addr(alu_result),      
        .write_data(reg_data2),   
        .read_data(mem_read_data)
    );

    assign write_back_data = mem_to_reg_sig ? mem_read_data : alu_result;

    assign out_result = write_back_data;

endmodule