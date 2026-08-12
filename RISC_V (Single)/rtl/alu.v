`timescale 1ns / 1ps
module alu (
    input  [31:0] a, b,
    input  [3:0]  sel,       
    output reg [31:0] c,
    output wire zero_flag     
);

    wire        sub_signal;
    wire [31:0] adder_sum;
    wire        adder_c_out, adder_overflow;

    assign sub_signal = (sel == 4'b0110); 

    ripple32bit my_adder (
        .a(a),
        .b(b),
        .sub(sub_signal),
        .s(adder_sum),
        .c_out(adder_c_out),
        .zero_flag(),
        .overflow(adder_overflow)
    );

    wire signed [31:0] a_signed = a;
    wire signed [31:0] b_signed = b;

    always @(*) begin
        case (sel)
            4'b0000: c = a;                                 
            4'b0001: c = ~a;                                  
            4'b0010: c = a & b;                               
            4'b0011: c = a | b;                              
            4'b0100: c = a ^ b;                               
            4'b0101: c = adder_sum;                           
            4'b0110: c = adder_sum;                           
            4'b0111: c = a << b[4:0];                         
            4'b1000: c = a >> b[4:0];                         
            4'b1001: c = $signed(a) >>> b[4:0];               
            4'b1010: c = (a_signed < b_signed) ? 32'd1 : 32'd0; 
            4'b1011: c = (a < b) ? 32'd1 : 32'd0;             
            default: c = 32'b0;
        endcase
    end

    assign zero_flag = (c == 32'b0);

endmodule