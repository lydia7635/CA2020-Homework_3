module alu #(
    parameter DATA_WIDTH = 32,
    parameter INST_WIDTH = 4
)(
    input                   i_clk,
    input                   i_rst_n,
    input  [DATA_WIDTH-1:0] i_data_a,
    input  [DATA_WIDTH-1:0] i_data_b,
    input  [INST_WIDTH-1:0] i_inst,
    input                   i_valid,
    output [DATA_WIDTH-1:0] o_data,
    output                  o_overflow,
    output                  o_valid
);

    // homework

    // parameter defined
    parameter signed_add = 4'd0;
    parameter signed_sub = 4'd1;
    parameter signed_mul = 4'd2;
    parameter signed_max = 4'd3;
    parameter signed_min = 4'd4;
    parameter unsigned_add = 4'd5;
    parameter unsigned_sub = 4'd6;
    parameter unsigned_mul = 4'd7;
    parameter unsigned_max = 4'd8;
    parameter unsigned_min = 4'd9;
    parameter and_data = 4'd10;
    parameter or_data  = 4'd11;
    parameter xor_data = 4'd12;
    parameter bitflip  = 4'd13;
    parameter bitreverse = 4'd14;

    // wires and register
    reg [DATA_WIDTH-1:0]    o_data_r, o_data_w;
    reg                     o_overflow_r, o_overflow_w;
    reg                     o_valid_r, o_valid_w;

    wire signed [DATA_WIDTH-1:0] signed_data_a, signed_data_b;
    integer i;

    // continuous assignment
    assign o_data = o_data_r;
    assign o_overflow = o_overflow_r;
    assign o_valid = o_valid_r;
    assign signed_data_a = i_data_a[DATA_WIDTH-1:0];
    assign signed_data_b = i_data_b[DATA_WIDTH-1:0];

    // combinational part
    always @(*) begin
        if(i_valid) begin
            case (i_inst)
                signed_add: begin
                    o_data_w = signed_data_a + signed_data_b;
                    if (signed_data_a[DATA_WIDTH-1] == signed_data_b[DATA_WIDTH-1]
                            && signed_data_a[DATA_WIDTH-1] != o_data_w[DATA_WIDTH-1]) begin
                        o_overflow_w = 1;
                    end else begin
                        o_overflow_w = 0;
                    end
                    o_valid_w = 1;
                end

                signed_sub: begin
                    o_data_w = signed_data_a - signed_data_b;
                    // sign: {a, b, c} = {1, 0, 0} or {0, 1, 1} => overflow
                    if (signed_data_a[DATA_WIDTH-1] != signed_data_b[DATA_WIDTH-1]
                            && signed_data_a[DATA_WIDTH-1] != o_data_w[DATA_WIDTH-1]) begin
                        o_overflow_w = 1;
                    end else begin
                        o_overflow_w = 0;
                    end
                    o_valid_w = 1;
                end

                signed_mul: begin
                    o_data_w = signed_data_a * signed_data_b;
                    if ((signed_data_a[DATA_WIDTH-1] == signed_data_b[DATA_WIDTH-1]
                            && o_data_w[DATA_WIDTH-1] == 1)
                            || (signed_data_a[DATA_WIDTH-1] != signed_data_b[DATA_WIDTH-1]
                            && o_data_w[DATA_WIDTH-1] == 0)) begin
                        o_overflow_w = 1;
                    end else begin
                        o_overflow_w = 0;
                    end
                    o_valid_w = 1;
                end

                signed_max: begin
                    if(signed_data_a > signed_data_b) begin
                        o_data_w = signed_data_a;
                    end else begin
                        o_data_w = signed_data_b;
                    end
                    o_overflow_w = 0;
                    o_valid_w = 1;
                end

                signed_min: begin
                    if(signed_data_a < signed_data_b) begin
                        o_data_w = signed_data_a;
                    end else begin
                        o_data_w = signed_data_b;
                    end
                    o_overflow_w = 0;
                    o_valid_w = 1;
                end

                unsigned_add: begin
                    {o_overflow_w, o_data_w} = i_data_a + i_data_b;
                    o_valid_w = 1;
                end

                unsigned_sub: begin
                    {o_overflow_w, o_data_w} = i_data_a - i_data_b;
                    o_valid_w = 1;
                end

                unsigned_mul: begin
                    {o_overflow_w, o_data_w} = i_data_a * i_data_b;
                    o_valid_w = 1;
                end

                unsigned_max: begin
                    if(i_data_a > i_data_b) begin
                        o_data_w = i_data_a;
                    end else begin
                        o_data_w = i_data_b;
                    end
                    o_overflow_w = 0;
                    o_valid_w = 1;
                end

                unsigned_min: begin
                    if(i_data_a < i_data_b) begin
                        o_data_w = i_data_a;
                    end else begin
                        o_data_w = i_data_b;
                    end
                    o_overflow_w = 0;
                    o_valid_w = 1;
                end

                and_data: begin
                    o_data_w = i_data_a & i_data_b;
                    o_overflow_w = 0;
                    o_valid_w = 1;
                end

                or_data: begin
                    o_data_w = i_data_a | i_data_b;
                    o_overflow_w = 0;
                    o_valid_w = 1;
                end

                xor_data: begin
                    o_data_w = i_data_a ^ i_data_b;
                    o_overflow_w = 0;
                    o_valid_w = 1;
                end

                bitflip: begin
                    o_data_w = i_data_a ^ 32'hffffffff;
                    o_overflow_w = 0;
                    o_valid_w = 1;
                end

                bitreverse: begin
                    for (i = 0; i < DATA_WIDTH; i++) begin
                        o_data_w[i] = i_data_a[DATA_WIDTH-1 - i];
                    end
                    o_overflow_w = 0;
                    o_valid_w = 1;
                end

                default: begin
                    o_overflow_w = 0;
                    o_data_w = 0;
                    o_valid_w = 1;
                end
            endcase
        end else begin
            o_overflow_w = 0;
            o_data_w = 0;
            o_valid_w = 0;
        end
    end


    // sequential part
    always @(posedge i_clk or negedge i_rst_n) begin : proc_
        if(~i_rst_n) begin
            o_data_r <= 0;
            o_overflow_r <= 0;
            o_valid_r <= 0;
        end else begin
            o_data_r <= o_data_w;
            o_overflow_r <= o_overflow_w;
            o_valid_r <= o_valid_w;
        end
    end

endmodule