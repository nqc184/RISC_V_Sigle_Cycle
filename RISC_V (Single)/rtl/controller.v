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
    output reg [3:0] alu_ctrl
);
    // Bảng mã ALU:
    // 0000: A          0001: NOT        0010: AND        0011: OR
    // 0100: XOR        0101: ADD        0110: SUB        0111: SLL
    // 1000: SRL        1001: SRA        1010: SLT        1011: SLTU

    always @(*) begin
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_ctrl   = 4'b0000;

        case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1'b1;
                case (funct3)
                    3'b000: alu_ctrl = funct7_5 ? 4'b0110 : 4'b0101; // SUB : ADD
                    3'b001: alu_ctrl = 4'b0111; // SLL
                    3'b010: alu_ctrl = 4'b1010; // SLT
                    3'b011: alu_ctrl = 4'b1011; // SLTU
                    3'b100: alu_ctrl = 4'b0100; // XOR
                    3'b101: alu_ctrl = funct7_5 ? 4'b1001 : 4'b1000; // SRA : SRL
                    3'b110: alu_ctrl = 4'b0011; // OR
                    3'b111: alu_ctrl = 4'b0010; // AND
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            7'b0010011: begin // I-type ALU (ADDI, SLTI, SLLI, SRLI, SRAI, ANDI, ORI, XORI)
                reg_write = 1'b1;
                alu_src   = 1'b1;
                case (funct3)
                    3'b000: alu_ctrl = 4'b0101; // ADDI
                    3'b001: alu_ctrl = 4'b0111; // SLLI
                    3'b010: alu_ctrl = 4'b1010; // SLTI
                    3'b011: alu_ctrl = 4'b1011; // SLTIU
                    3'b100: alu_ctrl = 4'b0100; // XORI
                    3'b101: alu_ctrl = funct7_5 ? 4'b1001 : 4'b1000; // SRAI : SRLI
                    3'b110: alu_ctrl = 4'b0011; // ORI
                    3'b111: alu_ctrl = 4'b0010; // ANDI
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            7'b0000011: begin // I-type Load (LW, LH, LB, LHU, LBU)
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_ctrl   = 4'b0101; 
            end

            7'b0100011: begin // S-type (SW, SH, SB)
                alu_src   = 1'b1;
                mem_write = 1'b1;
                alu_ctrl  = 4'b0101; 
            end

            7'b1100011: begin // B-type (BEQ, BNE, BLT, BGE, BLTU, BGEU)
                branch = 1'b1;
                case (funct3)
                    3'b000: alu_ctrl = 4'b0110; // BEQ  -> SUB
                    3'b001: alu_ctrl = 4'b0110; // BNE  -> SUB
                    3'b100: alu_ctrl = 4'b1010; // BLT  -> SLT
                    3'b101: alu_ctrl = 4'b1010; // BGE  -> SLT 
                    3'b110: alu_ctrl = 4'b1011; // BLTU -> SLTU
                    3'b111: alu_ctrl = 4'b1011; // BGEU -> SLTU 
                    default: alu_ctrl = 4'b0110;
                endcase
            end

            7'b1101111: begin // J-type (JAL)
                reg_write  = 1'b1;
                jump       = 1'b1;
                mem_to_reg = 1'b0; 
            end

            7'b1100111: begin // I-type (JALR)
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                jump       = 1'b1;
                alu_ctrl   = 4'b0101;
            end

            7'b0110111: begin // U-type (LUI)
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_ctrl  = 4'b0000; 
            end

            7'b0010111: begin // U-type (AUIPC)
                reg_write = 1'b1;
            end

            default: begin
                reg_write = 1'b0;
                alu_ctrl  = 4'b0000;
            end
        endcase
    end
endmodule