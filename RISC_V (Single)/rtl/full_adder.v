module full_adder (a,b,c_in,s,c_out);
    input wire a,b,c_in;
    output wire s, c_out;

    wire [2:0] w;
    half_adder ha1 (.a(a), .b(b), .s(w[0]), .c_out(w[1]));
    half_adder ha2 (.a(w[0]), .b(c_in), .s(s), .c_out(w[2]));

    assign c_out = w[1] | w[2];
endmodule