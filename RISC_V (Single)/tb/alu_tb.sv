`timescale 1ns/1ps

module tb_alu ();
    logic [31:0] a, b;
    logic [3:0]  sel;
    logic [31:0] c;
    logic zero_flag;

    alu dut (
        .a(a), 
        .b(b), 
        .sel(sel), 
        .c(c), 
        .zero_flag(zero_flag)
    );

    function automatic [31:0] alu_model(input[31:0]a, b, input [3:0] sel);
        case (sel)
            4'b0000: alu_model = a;
            4'b0001: alu_model = ~a;
            4'b0010: alu_model = a & b;
            4'b0011: alu_model = a | b;
            4'b0100: alu_model = a ^ b;
            4'b0101: alu_model = a + b;
            4'b0110: alu_model = a - b;
            4'b0111: alu_model = a << b[4:0];
            4'b1000: alu_model = a >> b[4:0];
            4'b1001: alu_model = $signed(a) >>> b[4:0];
            4'b1010: alu_model = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            4'b1011: alu_model = (a < b) ? 32'd1 : 32'd0;
            default: alu_model = 32'd0;
        endcase
    endfunction

    task automatic check(input [31:0] ta, tb, input [3:0] tsel);
        automatic logic [31:0] expected;
        a = ta, b = tb, sel = tsel;
        #1;
        expected = alu_model(ta,tb,tsel);
        if (c !== expected) begin
            $error("FAIL sel = %b a = %0d b = %0d | got = %0d exp = %0d", tsel, ta, tb, c, expected);
        end
        else begin
            $display("PASS sel = %b a = %0d b = %0d | c = %0d", tsel, ta, tb, c);
        end
    endtask 

    initial begin
        check(32'd10, 32'd3, 4'b0101); // ADD
        check(32'd10, 32'd3, 4'b0110); // SUB
        check(32'd10, 32'd3, 4'b0010); // AND

        // Random test
        repeat (50) begin
            automatic logic [31:0] ra = $urandom;
            automatic logic [31:0] rb = $urandom;
            automatic logic [3:0]  rs = $urandom_range(0,11);
            check(ra, rb, rs);
        end
        $finish;
    end
    
endmodule