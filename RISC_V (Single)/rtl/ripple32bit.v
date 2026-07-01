module ripple32bit #(parameter N=32)
(
    input wire [N-1:0] a, b,
    input wire sub,             
    output wire [N-1:0] s,
    output wire c_out,
    output wire zero_flag,
    output wire overflow         
);
    wire [N-1:0] b_xor;        
    wire [N-1:0] w;

    assign b_xor = b ^ {N{sub}}; 

    full_adder fa (.a(a[0]), .b(b_xor[0]), .c_in(sub), .s(s[0]), .c_out(w[0]));

    genvar i;
    generate
        for (i=1; i<N; i = i + 1 ) begin
            full_adder faloop(.a(a[i]), .b(b_xor[i]), .c_in(w[i-1]), .s(s[i]), .c_out(w[i]));
        end
    endgenerate

    assign c_out = w[N-1];
    assign zero_flag = (s == 0);
    assign overflow = w[N-1] ^ w[N-2]; 
endmodule