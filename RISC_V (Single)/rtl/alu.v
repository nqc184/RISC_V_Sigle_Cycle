module alu (
    input [31:0] a, b,
    input [2:0] sel,

    output reg [31:0] c
);

    wire [31:0] adder_sum;
    wire adder_c_out, adder_flag;

    assign sub_signal = (sel == 3'b110);

    ripple32bit my_adder (
        .a(a), 
        .b(b), 
        .sub(sub_signal), 
        .s(adder_sum), 
        .c_out(), .zero_flag(), .overflow()
    );

    always @(*) begin
        case (sel)
            3'b000: begin
                c = a;
            end 
            3'b001: begin // not
                c = ~a;
            end
            3'b010: begin // and
                c = a & b;
            end
            3'b011: begin // or
                c = a | b;
            end
            3'b100: begin // xor
                c = a ^ b;
            end
            3'b101: begin // add
                c = adder_sum;
            end
            3'b110: begin // sub
                c = adder_sum;
            end
            default: begin
                c = 32'b0;
            end
        endcase
    end
endmodule