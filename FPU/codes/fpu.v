module fpu #(
    parameter DATA_WIDTH = 32,
    parameter INST_WIDTH = 1
)(
    input                   i_clk,
    input                   i_rst_n,
    input  [DATA_WIDTH-1:0] i_data_a,
    input  [DATA_WIDTH-1:0] i_data_b,
    input  [INST_WIDTH-1:0] i_inst,
    input                   i_valid,
    output [DATA_WIDTH-1:0] o_data,
    output                  o_valid
);

    // homework

    // parameter defined
    parameter float_add = 1'd0;
    parameter float_mul = 1'd1;

    parameter EXPONENT = 8;
    parameter FRACTION = 49;
    // original fraction bit (23) + 01. bit (2) + signed bit (1) + (23)

    // wires and register
    reg [DATA_WIDTH-1:0]    o_data_r, o_data_w;
    reg                     o_valid_r, o_valid_w;

    wire [EXPONENT-1:0]         num_1_exp;
    wire [EXPONENT-1:0]         num_2_exp;
    wire [FRACTION-1:0]  num_1_fra_0;
    reg  [FRACTION-1:0]  num_1_fra_1;
    wire [FRACTION-1:0]  num_2_fra_0;
    reg  [FRACTION-1:0]  num_2_fra_1;

    reg [EXPONENT-1:0]         num_exp;
    reg [FRACTION-1:0]  num_fra;
    reg rounding, sticky;

    integer i;

    // continuous assignment
    assign o_data = o_data_r;
    assign o_valid = o_valid_r;

    assign num_1_exp = i_data_a[30:23];
    assign num_2_exp = i_data_b[30:23];
    assign num_1_fra_0 = {3'b001, i_data_a[22:0], 23'b00};
    assign num_2_fra_0 = {3'b001, i_data_b[22:0], 23'b00};

    // combinational part
    always @(*) begin
        if (i_valid) begin
            case (i_inst)
                float_add: begin
                    // align
                    if (num_1_exp < num_2_exp) begin
                        num_1_fra_1 = num_1_fra_0 >>> (num_2_exp - num_1_exp);
                        num_2_fra_1 = num_2_fra_0;
                        num_exp = num_2_exp;
                    end else if (num_1_exp > num_2_exp) begin
                        num_2_fra_1 = num_2_fra_0 >>> (num_1_exp - num_2_exp);
                        num_1_fra_1 = num_1_fra_0;
                        num_exp = num_1_exp;
                    end else begin
                        num_1_fra_1 = num_1_fra_0;
                        num_2_fra_1 = num_2_fra_0;
                        num_exp = num_1_exp;
                    end

                    // addition
                    if (i_data_a[31] == i_data_b[31]) begin
                        num_fra = num_1_fra_1 + num_2_fra_1;
                        num_fra[FRACTION-1] = i_data_a[31];
                    end else if (num_1_fra_1 > num_2_fra_1) begin
                        num_fra = num_1_fra_1 - num_2_fra_1;
                        num_fra[FRACTION-1] = i_data_a[31];
                    end else if (num_1_fra_1 < num_2_fra_1) begin
                        num_fra = num_2_fra_1 - num_1_fra_1;
                        num_fra[FRACTION-1] = i_data_b[31];
                    end else begin
                        num_fra = 0;
                    end

                    // normalize
                    o_data_w[31] = num_fra[FRACTION-1];
                    if (num_fra[FRACTION-2] == 1'b1) begin
                        {o_data_w[22:0], rounding, sticky} = num_fra[FRACTION-3:22];
                        o_data_w[30:23] = num_exp + 1;
                    end else if (num_fra[FRACTION-3] == 1'b0) begin
                        i = 1;
                        for (i = 0; i <= FRACTION-3 
                                && num_fra[FRACTION-3] == 1'b0; i++) begin
                            num_fra = num_fra << 1;
                            num_exp = num_exp - 1;
                        end
                        {o_data_w[22:0], rounding, sticky} = num_fra[FRACTION-4:21];
                        o_data_w[30:23] = num_exp;
                    end else begin
                        {o_data_w[22:0], rounding, sticky} = num_fra[FRACTION-4:21];
                        o_data_w[30:23] = num_exp;
                    end

                    // rounding
                    if (rounding == 1'b1) begin
                        if (!sticky == 1'b0 || !o_data_w[0] == 0) begin
                            o_data_w[22:0] = o_data_w[22:0] + 1;
                        end
                    end

                    o_valid_w = 1;
                end

                float_mul: begin
                    // exponents addition
                    // (exp_1 + bias) + (exp_2 + bias) - bias = (exp_total + bias)
                    num_exp = num_1_exp + num_2_exp - 7'h7f;
                    o_data_w[30:23] = num_exp;

                    // significands multiplication
                    num_fra = num_1_fra_0[FRACTION-1:FRACTION-26] * num_2_fra_0[FRACTION-1:FRACTION-26];

                    // normalize
                    if (num_fra[FRACTION-2:FRACTION-3] == 2'b10) begin
                        // need to be normalized
                        {o_data_w[22:0], rounding, sticky} = num_fra[FRACTION-3:FRACTION-27];
                        o_data_w[30:23] = o_data_w[30:23] + 1;
                    end else begin
                        // without normalizing
                         {o_data_w[22:0], rounding, sticky} = num_fra[FRACTION-4:FRACTION-28];
                    end
                    
                    // rounding
                        if (rounding == 1'b1) begin
                            if (!sticky == 1'b0 || !o_data_w[0] == 0) begin
                                o_data_w[22:0] = o_data_w[22:0] + 1;
                            end
                        end
                    
                    // sign determination
                    o_data_w[DATA_WIDTH-1] = (i_data_a[DATA_WIDTH-1] ^ i_data_b[DATA_WIDTH-1]);

                    o_valid_w = 1;
                end

                default: begin
                    o_valid_w = 1;
                end
            endcase
        end else begin
            o_data_w = 0;
            o_valid_w = 0;
        end
    end

    // sequential part
    always @(posedge i_clk or negedge i_rst_n) begin
        if(~i_rst_n) begin
            o_data_r <= 0;
            o_valid_r <= 0;
        end else begin
            o_data_r <= o_data_w;
            o_valid_r <= o_valid_w;
        end
    end

endmodule
