module ripple32bit #(parameter N=32)
    (a,b,s,c_out,zero_flag, flag);
    input wire [N-1:0] a,b;
    output wire [N-1:0] s;
    output wire c_out;
    output wire flag;
    output wire zero_flag;

    wire [N-1:0] w;

    full_adder fa (.a(a[0]), .b(b[0]), .c_in(1'b0), .s(s[0]), .c_out(w[0]));

    genvar i;
    generate
        for (i=1; i<N; i = i + 1 ) begin
            full_adder faloop(.a(a[i]), .b(b[i]), .c_in(w[i-1]), .s(s[i]), .c_out(w[i]));
        end
    endgenerate
    assign c_out = w[N-1];
    assign zero_flag = (s == 0);
    assign flag = w[N-1] ^ w[N-2];
endmodule