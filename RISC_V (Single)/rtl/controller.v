`timescale 1ns / 1ps
module control_unit (
    input  [6:0] opcode,
    input  [2:0] funct3,
    input        funct7_5,
    output reg   reg_write,
    output reg   alu_src,      // 0: reg_data2, 1: immediate
    output reg   mem_read,
    output reg   mem_write,
    output reg   mem_to_reg,   // 0: alu_result, 1: mem_data
    output reg   branch,
    output reg   jump,
    output reg [2:0] alu_ctrl
);
    always @(*) begin
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_ctrl   = 3'b000;

        case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1'b1;
                case (funct3)
                    3'b000: alu_ctrl = funct7_5 ? 3'b110 : 3'b101; // SUB : ADD
                    3'b111: alu_ctrl = 3'b010; // AND
                    3'b110: alu_ctrl = 3'b011; // OR
                    3'b100: alu_ctrl = 3'b100; // XOR
                    default: alu_ctrl = 3'b000;
                endcase
            end

            7'b0010011: begin // I-type ALU (ADDI, ANDI, ORI, XORI...)
                reg_write = 1'b1;
                alu_src   = 1'b1;
                case (funct3)
                    3'b000: alu_ctrl = 3'b101; // ADDI
                    3'b111: alu_ctrl = 3'b010; // ANDI
                    3'b110: alu_ctrl = 3'b011; // ORI
                    3'b100: alu_ctrl = 3'b100; // XORI
                    default: alu_ctrl = 3'b000;
                endcase
            end

            7'b0000011: begin // I-type Load (LW)
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_ctrl   = 3'b101; // dùng ADD để tính địa chỉ = rs1 + imm
            end

            7'b0100011: begin // S-type (SW)
                alu_src   = 1'b1;
                mem_write = 1'b1;
                alu_ctrl  = 3'b101; // ADD để tính địa chỉ = rs1 + imm
            end

            7'b1100011: begin // B-type (BEQ, BNE...)
                branch   = 1'b1;
                alu_ctrl = 3'b110; // dùng SUB để so sánh (zero_flag)
            end

            7'b1101111: begin // J-type (JAL)
                reg_write  = 1'b1;
                jump       = 1'b1;
                mem_to_reg = 1'b0; // ghi pc+4, xử lý riêng ở mux WB
            end

            default: begin
                reg_write = 1'b0;
                alu_ctrl  = 3'b000;
            end
        endcase
    end
endmodule