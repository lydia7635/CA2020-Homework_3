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

module mux #(
    parameter DATA_W = 64
)(
    input  [ DATA_W-1 : 0 ] i_data_0,
    input  [ DATA_W-1 : 0 ] i_data_1,
    input                   control,
    output [ DATA_W-1 : 0 ] o_data
);

    if (control) begin
        assign o_data = i_data_1;
    end else begin
        assign o_data = i_data_0;
    end

endmodule

module alu #(
    parameter DATA_W = 64,
    parameter ALU_CTRL_W = 4
)(
    input  [ DATA_W-1 : 0 ]     i_data_1,
    input  [ DATA_W-1 : 0 ]     i_data_2,
    input  [ ALU_CTRL_W-1 : 0 ] i_alu_ctrl,
    output [ DATA_W-1 : 0 ]     o_result,
    output                      o_zero
);
    // parameters
    parameter Add = 4'b0010;
    parameter Sub = 4'b0110;
    parameter And = 4'b0000;
    parameter Or  = 4'b0001;
    parameter Xor = 4'b0101;

    case (i_alu_ctrl)
        Add: begin
            o_result = i_data_1 + i_data_2;
        end
        Sub: begin
            o_result = i_data_1 - i_data_2;
        end
        And: begin
            o_result = i_data_1 & i_data_2;            
        end
        Or: begin
            o_result = i_data_1 | i_data_2;            
        end
        Xor: begin
            o_result = i_data_1 ^ i_data_2;
        end
        default: begin
            o_result = 0;
        end
    endcase
endmodule

module program_counter #(
    parameter ADDR_W = 64
)(
    input                   i_rst_n,
    input  [ ADDR_W-1 : 0 ] i_addr,
    input                   i_inst_mem_valid, // if true, then o_valid = false
    output [ ADDR_W-1 : 0 ] o_addr,
    output                  o_valid
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

module registers #(
    parameter REG_ADDR_W = 5,
    parameter DATA_W = 64
)(
    input                       i_clk,
    input                       i_rst_n,
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
    
    // registers and wires
    reg [ DATA_W-1 : 0 ] register [ 0 : REG_NUM-1 ];
    integer i;

    // continuous assignment
    assign o_read_data_1 = register[i_read_reg_1];
    assign o_read_data_2 = register[i_read_reg_2];

    // combinational part
    always @(*) begin
        if(i_write_valid) begin
            register[i_write_reg] = i_write_data;
        end 
    end

    // sequential part
    always @(posedge i_clk or negedge i_rst_n) begin
        if(~i_rst_n) begin
            for (i = 0; i < REG_NUM; i++) begin
                register[i] = 0;
            end
        end
    end

endmodule

module imm_gen #(
    parameter DATA_IN_W  = 32,
    parameter DATA_OUT_W = 64
)(
    input  [ DATA_IN_W-1 : 0 ]  i_instruction,
    output [ DATA_OUT_W-1 : 0 ] o_data    
);

    assign o_data = { 32'hffffffff, i_instruction };

endmodule

module controller #(
    parameter OPCODE_W = 7
)(
    input                     i_clk,
    input                     i_rst_n,
    input  [ OPCODE_W-1 : 0 ] i_inst,
    input                     i_valid,
    output                    o_finish
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