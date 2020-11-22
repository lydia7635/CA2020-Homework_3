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
    parameter REG_ADDR_W = 5;
    parameter ALU_CTRL_W = 3;
    parameter ALUOP_W = 3;

    // ---- wires and register ----
    // PC
    wire valid_PC_result;
    wire [ ADDR_W-1 : 0 ] PC_result;
    
    // register
    wire [ DATA_W-1 : 0 ] reg_r_data_1, reg_r_data_2;
    wire valid_wb_reg; // from unit_mux_write_back
    wire [ DATA_W-1 : 0 ] wb_data;
    wire valid_reg_result;

    // ctrl
    wire o_finish_w;
    wire [ 1 : 0 ] ctrl_Branch;
    wire ctrl_MemRead, ctrl_MemtoReg, ctrl_MemWrite, ctrl_ALUSrc, ctrl_RegWrite;
    wire [ ALUOP_W-1 : 0 ] ctrl_ALUOP;

    // imm_gen
    wire valid_imm_gen_result;
    wire [ DATA_W-1 : 0 ] imm_gen_result;

    // mux_alu_data
    wire valid_mux_alu_data;
    wire [ DATA_W-1 : 0 ] mux_alu_data;

    // alu_ctrl
    wire [ ALU_CTRL_W-1 : 0 ] alu_ctrl;

    // alu
    wire valid_alu_result;
    wire [ DATA_W-1 : 0 ] alu_result;
    wire alu_zero;

    // add_branch
    wire valid_add_branch_result;
    wire [ DATA_W-1 : 0 ] add_branch_result;

    // pseudo_and
    wire pseudo_and_result;

    // add_pc
    wire valid_add_pc_result;
    wire [ ADDR_W-1 : 0 ] add_pc_result;

    // mux_branch
    //wire valid_mux_branch_result;
    wire [ ADDR_W-1 : 0 ] mux_branch_result;

    // ---- continuous assignments ----
    assign o_i_valid_addr = valid_PC_result;
    assign o_i_addr = PC_result;

    assign o_finish = o_finish_w;
    
    // MemWrite = unit_alu.o_valid & unit_ctrl.MemWrite
    assign o_d_MemWrite = valid_alu_result & ctrl_MemWrite;
    // MemRead = unit_alu.o_valid & unit_ctrl.MemRead
    assign o_d_MemRead = valid_alu_result & ctrl_MemRead;

    assign o_d_data = reg_r_data_2;  
    assign o_d_addr = alu_result;

    program_counter #(
        .ADDR_W(ADDR_W)
    ) unit_pc (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_addr(mux_branch_result),    // no valid check
        .o_valid(valid_PC_result),
        .o_addr(PC_result)
    );

    controller #(
        .OPCODE_W(OPCODE_W)
    ) unit_ctrl (
        .i_rst_n(i_rst_n),
        .i_valid(i_i_valid_inst),
        .i_inst(i_i_inst[ OPCODE_W-1 : 0 ]),
        .i_branch(i_i_inst[ 12 ]),    // deal with BEQ and BNE
        .o_Branch(ctrl_Branch),
        .o_MemRead(ctrl_MemRead),
        .o_MemtoReg(ctrl_MemtoReg),
        .o_ALUOP(ctrl_ALUOP),
        .o_MemWrite(ctrl_MemWrite),
        .o_ALUSrc(ctrl_ALUSrc),
        .o_RegWrite(ctrl_RegWrite),
        .o_finish(o_finish_w)
    );

    registers #(
        .REG_ADDR_W(REG_ADDR_W),
        .DATA_W(DATA_W)
    ) unit_reg (
        .i_rst_n(i_rst_n),
        .i_valid_inst_mem(i_i_valid_inst),
        .i_read_reg_1(i_i_inst[ 19 : 15 ]),
        .i_read_reg_2(i_i_inst[ 24 : 20 ]),
        .i_RegWrite(ctrl_RegWrite),
        .i_valid_write(valid_wb_reg),
        .i_write_reg(i_i_inst[ 11 : 7 ]),
        .i_write_data(wb_data),
        .o_valid_result(valid_reg_result),
        .o_read_data_1(reg_r_data_1),
        .o_read_data_2(reg_r_data_2)
    );

    imm_gen #(
        .DATA_IN_W(INST_W),
        .DATA_OUT_W(DATA_W)
    ) unit_imm_gen (
        .i_rst_n(i_rst_n),
        .i_valid(i_i_valid_inst),
        .i_inst(i_i_inst),
        .o_valid(valid_imm_gen_result),
        .o_data(imm_gen_result)
    );

    mux #(
        .DATA_W(DATA_W)
    ) unit_mux_alu_data (
        .i_rst_n(i_rst_n),
        .i_valid_data_0(valid_reg_result),
        .i_valid_data_1(valid_imm_gen_result),
        .i_data_0(reg_r_data_2),
        .i_data_1(imm_gen_result),
        .i_sel(ctrl_ALUSrc),
        .o_valid(valid_mux_alu_data),
        .o_data(mux_alu_data)
    );

    alu_controller #(
        .ALUOP_W(ALUOP_W),
        .ALU_CTRL_W(ALU_CTRL_W)
    ) unit_alu_ctrl (
        .i_valid_inst(i_i_valid_inst),
        .i_inst({i_i_inst[ 30 ], i_i_inst[ 14 : 12 ]}),
        .i_aluop(ctrl_ALUOP),
        .o_alu_ctrl(alu_ctrl)
    );

    alu #(
        .DATA_W(DATA_W),
        .ALU_CTRL_W(ALU_CTRL_W)
    ) unit_alu (
        .i_rst_n(i_rst_n),
        .i_valid_data_2(valid_mux_alu_data),
        .i_data_1(reg_r_data_1),
        .i_data_2(mux_alu_data),
        .i_alu_ctrl(alu_ctrl),
        .o_valid(valid_alu_result),
        .o_result(alu_result),
        .o_zero(alu_zero)
    );

    mux #(
        .DATA_W(DATA_W)
    ) unit_mux_write_back (
        .i_rst_n(i_rst_n),
        .i_valid_data_0(valid_alu_result),
        .i_valid_data_1((~ctrl_MemRead)? 1'b1 : i_d_valid_data),
        .i_data_0(alu_result),
        .i_data_1(i_d_data),
        .i_sel(ctrl_MemtoReg),
        .o_valid(valid_wb_reg),
        .o_data(wb_data)
    );

    alu #(
        .DATA_W(DATA_W),
        .ALU_CTRL_W(ALU_CTRL_W)
    ) unit_add_branch (
        .i_rst_n(i_rst_n),
        .i_valid_data_2(valid_imm_gen_result),
        .i_data_1(PC_result),
        .i_data_2({imm_gen_result[ DATA_W-2 : 0 ], 1'b0}),
        .i_alu_ctrl(3'b000),
        .o_valid(valid_add_branch_result),
        .o_result(add_branch_result)
    );

    pseudo_and unit_pseudo_and (
        .i_branch(ctrl_Branch),
        .i_zero(alu_zero),
        .o_sel(pseudo_and_result)
    );

    mux #(
        .DATA_W(DATA_W)
    ) unit_mux_branch (
        .i_rst_n(i_rst_n),
        .i_valid_data_0(1'b1),
        .i_valid_data_1(valid_add_branch_result),
        .i_data_0(add_pc_result),
        .i_data_1(add_branch_result),
        .i_sel(pseudo_and_result),
        //.o_valid(valid_mux_branch_result),
        .o_data(mux_branch_result)
    );

    alu #(
        .DATA_W(ADDR_W),
        .ALU_CTRL_W(ALU_CTRL_W)
    ) unit_add_pc (
        .i_valid_data_2(valid_PC_result),
        .i_data_1(64'd4),
        .i_data_2(PC_result),
        .i_alu_ctrl(3'b000),
        .o_valid(valid_add_pc_result),
        .o_result(add_pc_result)
    );

endmodule

module mux #(
    parameter DATA_W = 64
)(
    input                   i_rst_n,
    input                   i_valid_data_0,
    input                   i_valid_data_1,
    input  [ DATA_W-1 : 0 ] i_data_0,
    input  [ DATA_W-1 : 0 ] i_data_1,
    input                   i_sel,
    output                  o_valid,
    output [ DATA_W-1 : 0 ] o_data
);
    // registers
    reg                  o_valid_r;
    reg [ DATA_W-1 : 0 ] o_data_r;
    
    // continuous assignment
    assign o_valid = o_valid_r;
    assign o_data  = o_data_r;

    always @(*) begin
        if(i_valid_data_0 & i_valid_data_1) begin
            case (i_sel)
                0: begin
                    o_data_r = i_data_0;
                    o_valid_r = 1;
                end
                1: begin
                    o_data_r = i_data_1;
                    o_valid_r = 1;
                end
                default: o_valid_r = 0;
            endcase
        end else o_valid_r = 0;
    end

    always @(negedge i_rst_n) begin
        o_valid_r = 0;
    end

endmodule

module pseudo_and (
    input [ 1 : 0 ] i_branch,
    input           i_zero,
    output          o_sel
);
    assign o_sel = (i_branch[1] & ~i_zero) | (i_branch[0] & i_zero);
    // zero == false && BNE || zero == true && BEQ

endmodule

module alu #(
    parameter DATA_W = 64,
    parameter ALU_CTRL_W = 3
)(
    input                       i_rst_n,
    input                       i_valid_data_2,
    input  [ DATA_W-1 : 0 ]     i_data_1,
    input  [ DATA_W-1 : 0 ]     i_data_2,
    input  [ ALU_CTRL_W-1 : 0 ] i_alu_ctrl,
    output                      o_valid,
    output [ DATA_W-1 : 0 ]     o_result,
    output                      o_zero
);
    // parameters
    parameter Add = 3'b000;
    parameter Sub = 3'b010;
    parameter And = 3'b111;
    parameter Or  = 3'b110;
    parameter Xor = 3'b100;
    parameter Sl  = 3'b001;
    parameter Sr  = 3'b101;

    // registers and wires
    reg                          o_valid_r;
    reg         [ DATA_W-1 : 0 ] o_result_r;
    reg                          o_zero_r;
    wire signed [ DATA_W-1 : 0 ] signed_data_1, signed_data_2;

    // continuous assignment
    assign signed_data_1 = i_data_1;
    assign signed_data_2 = i_data_2;

    assign o_valid  = o_valid_r;
    assign o_result = o_result_r;
    assign o_zero   = o_zero_r;

    always @(*) begin
        if (i_valid_data_2) begin
            case (i_alu_ctrl)
                Add: o_result_r = signed_data_1 + signed_data_2;
                Sub: o_result_r = signed_data_1 - signed_data_2;
                And: o_result_r = i_data_1 & i_data_2;            
                Or:  o_result_r = i_data_1 | i_data_2;            
                Xor: o_result_r = i_data_1 ^ i_data_2;
                Sl:  o_result_r = signed_data_1 <<< signed_data_2;
                Sr:  o_result_r = signed_data_1 >>> signed_data_2;
                default: o_result_r = 0;
            endcase
            o_zero_r = (o_result_r == 0)? 1 : 0;
            o_valid_r = 1;
        end //else o_valid_r = 0;
    end

    always @(negedge i_rst_n) begin
        o_valid_r = 0;
    end

endmodule

module program_counter #(
    parameter ADDR_W = 64
)(
    input                   i_clk,
    input                   i_rst_n,
    input  [ ADDR_W-1 : 0 ] i_addr,
    output                  o_valid,
    output [ ADDR_W-1 : 0 ] o_addr
);
    // registers and wire
    reg [ ADDR_W-1 : 0 ] pc;
    reg                  o_valid_r, o_valid_w;
    reg            [3:0] cs, ns;

    assign o_addr  = pc;
    assign o_valid = o_valid_r;

    // combinational part
    always @(*) begin
        if (cs == 13) begin
            o_valid_w = 1;
        end else if (cs == 12) begin
            pc = i_addr;
        end else begin
            o_valid_w = 0;
        end
    end

    // 14 cycles per instruction
    always @(*) begin
        case (cs)
            0 : ns = 1;
            1 : ns = 2;
            2 : ns = 3;
            3 : ns = 4;
            4 : ns = 5;
            5 : ns = 6;
            6 : ns = 7;
            7 : ns = 8;
            8 : ns = 9;
            9 : ns = 10;
            10: ns = 11;
            11: ns = 12;
            12: ns = 13;
            13: ns = 0;
        endcase
    end

    // sequential part
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            pc          <= 0;
            o_valid_r   <= 0;
            cs          <= 13;
        end else begin
            o_valid_r   <= o_valid_w;
            cs          <= ns;
        end
    end

endmodule

module registers #(
    parameter REG_ADDR_W = 5,
    parameter DATA_W = 64
)(
    input                       i_rst_n,
    inout                       i_valid_inst_mem,
    input [ REG_ADDR_W-1 : 0 ]  i_read_reg_1,
    input [ REG_ADDR_W-1 : 0 ]  i_read_reg_2,
    input                       i_RegWrite,
    input                       i_valid_write,
    input [ REG_ADDR_W-1 : 0 ]  i_write_reg,
    input [ DATA_W-1 : 0 ]      i_write_data,

    output                      o_valid_result,
    output [ DATA_W-1 : 0 ]     o_read_data_1,
    output [ DATA_W-1 : 0 ]     o_read_data_2   
);
    // parameters
    parameter REG_NUM = 32;
    
    // registers and wires
    reg [ DATA_W-1 : 0 ] register [ 0 : REG_NUM-1 ];
    reg [ DATA_W-1 : 0 ] o_read_data_1_r;
    reg [ DATA_W-1 : 0 ] o_read_data_2_r;
    reg                  o_valid_result_r;

    reg  [ REG_ADDR_W-1 : 0 ] i_write_reg_r;
    wire [ REG_ADDR_W-1 : 0 ] i_write_reg_w;
    integer i;

    // continuous assignment
    assign o_read_data_1 = o_read_data_1_r;
    assign o_read_data_2 = o_read_data_2_r;
    assign o_valid_result = o_valid_result_r;
    assign i_write_reg_w = i_write_reg_r;

    // combinational part
    always @(*) begin
        if(i_valid_inst_mem) begin
            o_read_data_1_r = register[i_read_reg_1];
            o_read_data_2_r = register[i_read_reg_2];
            o_valid_result_r = 1;
        end else o_valid_result_r = 0;
    end

    always @(*) begin
        if(i_RegWrite & i_valid_write & (i_write_reg_r != 0)) begin
            register[i_write_reg_r] = i_write_data;
        end 
    end

    always @(*) begin
        if(i_valid_inst_mem) begin
            i_write_reg_r = i_write_reg;
        end else begin
            i_write_reg_r = i_write_reg_w;
        end
    
    end

    // sequential part
    always @(negedge i_rst_n) begin
        o_valid_result_r = 0;
        for (i = 0; i < REG_NUM; i++) begin
            register[i] = 0;
        end
    end

endmodule

module imm_gen #(
    parameter DATA_IN_W  = 32,
    parameter DATA_OUT_W = 64
)(
    input                       i_rst_n,
    input                       i_valid,
    input  [ DATA_IN_W-1 : 0 ]  i_inst,
    output                      o_valid,
    output [ DATA_OUT_W-1 : 0 ] o_data    
);

    // parameters
    parameter Ld     = 7'b0000011;
    parameter Sd     = 7'b0100011;
    parameter Branch = 7'b1100011;
    parameter Imm    = 7'b0010011;

    // registers
    reg [ DATA_OUT_W-1 : 0 ] o_data_r;
    reg o_valid_r;

    // continuous assignment
    assign o_valid = o_valid_r;
    assign o_data = o_data_r;

    // conbinational part
    always @(*) begin
        if (i_valid) begin
            case (i_inst[ 6 : 0 ])
                Ld: begin
                    o_data_r = { 52'b0, i_inst[ 31 : 20 ] };
                end
                Sd: begin
                    o_data_r = { 52'b0, i_inst[ 31 : 25 ], i_inst[ 11 : 7 ] };
                end
                Branch: begin
                    o_data_r = { 51'b0, i_inst[ 31 ], i_inst[ 7 ],
                                 i_inst[ 30 : 25 ], i_inst[ 11 : 8 ] };
                end
                Imm: begin
                    o_data_r = { 52'b0, i_inst[ 31 : 20 ] };
                end
                default: begin
                    o_data_r = 0;
                end
            endcase
            o_valid_r = 1;
        end else o_valid_r = 0;
    end

    // sequential part
    always @(negedge i_rst_n) begin
        o_valid_r = 0;
        o_data_r = 0;
    end

endmodule

module controller #(
    parameter ALUOP_W = 3,
    parameter OPCODE_W = 7
)(
    input                     i_rst_n,
    input                     i_valid,
    input  [ OPCODE_W-1 : 0 ] i_inst,
    input                     i_branch, // to deal with BEQ and BNE
    output          [ 1 : 0 ] o_Branch,
    output                    o_MemRead,
    output                    o_MemtoReg,
    output  [ ALUOP_W-1 : 0 ] o_ALUOP,
    output                    o_MemWrite,
    output                    o_ALUSrc,
    output                    o_RegWrite,
    output                    o_finish
);

    // parameter defined
    parameter Ld     = 3'b000;
    parameter Sd     = 3'b010;
    parameter Branch = 3'b110;
    parameter Imm    = 3'b001;
    parameter Calc   = 3'b011;
    parameter Stop   = 3'b111;

    // registers and wires
    reg         [ 1 : 0 ] o_Branch_r;
    reg                   o_MemRead_r;
    reg                   o_MemtoReg_r;
    reg [ ALUOP_W-1 : 0 ] o_ALUOP_r;
    reg                   o_MemWrite_r;
    reg                   o_ALUSrc_r;
    reg                   o_RegWrite_r;
    reg                   o_finish_r;

    // continuous assignment
    assign o_Branch   = o_Branch_r;
    assign o_MemRead  = o_MemRead_r;
    assign o_MemtoReg = o_MemtoReg_r;
    assign o_ALUOP    = o_ALUOP_r;
    assign o_MemWrite = o_MemWrite_r;
    assign o_ALUSrc   = o_ALUSrc_r;
    assign o_RegWrite = o_RegWrite_r;
    assign o_finish   = o_finish_r;

    // combinational part
    always @(*) begin
        if (i_valid) begin
            case (i_inst[ 6 : 4 ])
                Ld: begin
                    o_Branch_r   <= 0;
                    o_MemRead_r  <= 1;
                    o_MemtoReg_r <= 1;
                    o_MemWrite_r <= 0;
                    o_ALUSrc_r   <= 1;
                    o_RegWrite_r <= 1;
                    o_finish_r   <= 0;
                end
                Sd: begin
                    o_Branch_r   <= 0;
                    o_MemRead_r  <= 0;
                    o_MemtoReg_r <= 0;
                    o_MemWrite_r <= 1;
                    o_ALUSrc_r   <= 1;
                    o_RegWrite_r <= 0;
                    o_finish_r   <= 0;
                end
                Branch: begin
                    o_Branch_r   <= (i_branch)? 2'b10 : 2'b01;
                    o_MemRead_r  <= 0;
                    o_MemtoReg_r <= 0;
                    o_MemWrite_r <= 0;
                    o_ALUSrc_r   <= 0;
                    o_RegWrite_r <= 0;
                    o_finish_r   <= 0;
                end
                Imm: begin
                    o_Branch_r   <= 0;
                    o_MemRead_r  <= 0;
                    o_MemtoReg_r <= 0;
                    o_MemWrite_r <= 0;
                    o_ALUSrc_r   <= 1;
                    o_RegWrite_r <= 1;
                    o_finish_r   <= 0;
                end
                Calc: begin
                    o_Branch_r   <= 0;
                    o_MemRead_r  <= 0;
                    o_MemtoReg_r <= 0;
                    o_MemWrite_r <= 0;
                    o_ALUSrc_r   <= 0;
                    o_RegWrite_r <= 1;
                    o_finish_r   <= 0;
                end
                Stop: o_finish_r <= 1;
                default: o_finish_r <= 1;
            endcase
            o_ALUOP_r = i_inst[ 6 : 4 ];
        end
    end

    // sequential part
    always @(negedge i_rst_n) begin
        o_Branch_r   <= 0;
        o_MemRead_r  <= 0;
        o_MemtoReg_r <= 0;
        o_ALUOP_r    <= 0;
        o_MemWrite_r <= 0;
        o_ALUSrc_r   <= 0;
        o_RegWrite_r <= 0;
        o_finish_r   <= 0;
    end

endmodule

module alu_controller #(
    parameter ALUOP_W = 3,
    parameter ALU_CTRL_W = 3
)(
    input                       i_valid_inst,
    input             [ 3 : 0 ] i_inst,
    input     [ ALUOP_W-1 : 0 ] i_aluop,
    output [ ALU_CTRL_W-1 : 0 ] o_alu_ctrl
);

    // parameters defined
    parameter Ld     = 3'b000;
    parameter Sd     = 3'b010;
    parameter Branch = 3'b110;
    parameter Imm    = 3'b001;
    parameter Calc   = 3'b011;

    parameter Add    = 3'b000; // maybe Sub
    parameter Sub    = 3'b010;
    parameter Xor    = 3'b100;
    parameter Or     = 3'b110;
    parameter And    = 3'b111;
    parameter Sl     = 3'b001;
    parameter Sr     = 3'b101;

    // registers and wires
    reg  [ALU_CTRL_W-1 : 0 ] o_alu_ctrl_r;

    // continuous assignment
    assign o_alu_ctrl = o_alu_ctrl_r;

    // combinational part
    always @(*) begin
        if (i_valid_inst) begin
            case (i_aluop)
                Ld:     o_alu_ctrl_r = Add;
                Sd:     o_alu_ctrl_r = Add;
                Branch: o_alu_ctrl_r = Sub;
                Imm:    o_alu_ctrl_r = i_inst[ 2 : 0 ];
                Calc: begin
                    if (i_inst[ 2 : 0 ] == Add) o_alu_ctrl_r = {1'b0, i_inst[ 3 ], 1'b0};
                    else o_alu_ctrl_r = i_inst[ 2 : 0 ];
                end
                default: o_alu_ctrl_r = 0;
            endcase
        end
    end

endmodule