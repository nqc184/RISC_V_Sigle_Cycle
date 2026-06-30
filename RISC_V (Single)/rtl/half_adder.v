module half_adder (a,b,s,c_out);
    input wire a,b;
    output reg s, c_out;
    always @(a,b) begin
        s = a^b;
        c_out = a&b;
    end
endmodule
