module cpu #( // Do not modify interface
	parameter ADDR_W = 64,
	parameter INST_W = 32,
	parameter DATA_W = 64
)(
    input                   i_clk,
    input                   i_rst_n,
    input                   i_i_valid_inst, // from instruction memory
    input  [ INST_W-1 : 0 ] i_i_inst,       // from instruction memory
    input                   i_d_valid_data, // from data memory
    input  [ DATA_W-1 : 0 ] i_d_data,       // from data memory
    output                  o_i_valid_addr, // to instruction memory
    output [ ADDR_W-1 : 0 ] o_i_addr,       // to instruction memory
    output [ DATA_W-1 : 0 ] o_d_data,       // to data memory
    output [ ADDR_W-1 : 0 ] o_d_addr,       // to data memory
    output                  o_d_MemRead,    // to data memory
    output                  o_d_MemWrite,   // to data memory
    output                  o_finish
);

    // homework

    // parameters defined
    parameter MAX_INST = 16;
    parameter OPCODE_W = 7;

    // wires and register
    reg o_finish_r;
    wire o_finish_w;
    wire [ ADDR_W-1 : 0 ] to_PC_addr;
    /*reg o_i_valid_addr_r, o_i_valid_addr_w;
    reg [ ADDR_W-1 : 0 ] o_i_addr_r, o_i_addr_w;
    reg [ DATA_W-1 : 0 ] o_d_data_r, o_d_data_w;
    reg [ ADDR_W-1 : 0 ] o_d_addr_r, o_d_addr_w;
    reg o_d_Memread_r, o_d_Memread_w;
    reg o_d_MemWrite_r, o_d_MemWrite_w;*/

    // continuous assignment
    assign o_finish = o_finish_r;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            o_finish_r = 0;
        end else begin
            o_finish_r = o_finish_w;
        end
    end

    program_counter #(
        .ADDR_W(ADDR_W)
    ) unit_pc (
        .i_rst_n(i_rst_n),
        .i_addr(to_PC_addr),
        .i_inst_mem_valid(i_i_valid_inst),
        .o_addr(o_i_addr),
        .o_valid(o_i_valid_addr)
    );

    controller #(
        .OPCODE_W(OPCODE_W)
    ) unit_controller (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_inst(i_i_inst[ OPCODE_W-1 : 0 ]),
        .i_valid(i_i_valid_inst),
        .o_finish(o_finish_w)
    );

endmodule

module program_counter #(
    parameter ADDR_W = 64
)(
    input                 i_rst_n,
    input  [ ADDR_W-1:0 ] i_addr,
    input                 i_inst_mem_valid, // if true, then o_valid = false
    output [ ADDR_W-1:0 ] o_addr,
    output                o_valid
);
    reg [ ADDR_W-1 : 0 ] PC;
    reg o_valid_r;

    assign o_addr = PC;
    assign o_valid = o_valid_r;

    always @(*) begin
        PC = i_addr;
        o_valid_r = 1;
    end

    always @(posedge i_inst_mem_valid) begin
        o_valid_r = 0;
    end

    always @(negedge i_rst_n) begin
        PC = 0;
        o_valid_r = 1;
    end

endmodule

/*module registers #(
    parameter REG_ADDR_W = 5,
    parameter DATA_W = 64
)(
    input [ REG_ADDR_W-1 : 0 ]  i_read_reg_1,
    input [ REG_ADDR_W-1 : 0 ]  i_read_reg_2,
    input [ REG_ADDR_W-1 : 0 ]  i_write_reg,
    input [ DATA_W-1 : 0 ]      i_write_data,
    input                       i_write_valid,

    output [ DATA_W-1 : 0 ]     o_read_data_1,
    output [ DATA_W-1 : 0 ]     o_read_data_2,    
);

    // parameters
    parameter REG_NUM = 32;
    integer i;

    reg [ DATA_W-1 : 0 ] register [ 0 : REG_NUM-1 ];


    initial begin
        for (i = 0; i < REG_NUM; i++) begin
            register[i] = 0;
        end
    end

endmodule*/

module controller #(
    parameter OPCODE_W = 7
)(
    input  i_clk,
    input  i_rst_n,
    input [ OPCODE_W-1 : 0 ] i_inst,
    input  i_valid,
    output o_finish
);

    // parameter defined
    parameter stop = 7'b1111111;

    // registers and wires
    reg o_finish_r, o_finish_w;

    // continuous assignment
    assign o_finish = o_finish_r;

    // combinational part
    always @(*) begin
        if (i_valid) begin
            case (i_inst)
                stop: begin
                    o_finish_w = 1;
                end
            endcase
        end else begin
            o_finish_w = 0;
        end
    end

    // sequential part
    always @(posedge i_clk or negedge i_rst_n) begin
        if(~i_rst_n) begin
           o_finish_r  <= 0;
        end else begin
            o_finish_r <= o_finish_w;
        end
    end

endmodule