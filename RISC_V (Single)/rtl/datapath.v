module datapath(
    input clk, reset,
    input w_en,               
    input [4:0] ra1, ra2, wa, 
    input [2:0] alu_ctrl,     
    output [31:0] alu_res     
);
    wire [31:0] rd1, rd2;
    wire [31:0] pc_out;
    wire [31:0] pc_next;

    program_counter pc (
        .clk(clk), .reset(!w_en),
        .pc_in(pc_next),
        .pc_out(pc_out)
    );

    ripple32bit pc_adder (
        .a(pc_out), 
        .b(32'd4), 
        .sub(1'b0), 
        .s(pc_next), 
        .c_out(), 
        .zero_flag(), .overflow()
    );

    // register_file rf (
    //     .clk(clk), .w_en(w_en),
    //     .ra1(ra1), .ra2(ra2), .wa(wa),
    //     .d(alu_res), 
    //     .rd1(rd1), .rd2(rd2)
    // );

    // alu alu_dut (
    //     .a(rd1), 
    //     .b(rd2), 
    //     .sel(alu_ctrl), 
    //     .c(alu_res)
    // );
endmodule