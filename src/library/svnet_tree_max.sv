// SVNet (System Verilog Convolutional Neural Network)
// Copyright (C) 2015-2016 Kwabena W. Agyeman
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

module svent_tree_max
#(
    WIDTH = 1,
    COUNT = 1
)
(
    input logic clk, rst_n,

    input logic i_data_valid,
    input logic [COUNT-1:0][WIDTH-1:0] i_data,

    output logic o_data_valid,
    output logic [WIDTH-1:0] o_data
);

    generate if(COUNT == 1) begin

        logic `SVNET_REG_INPUT(i_data_valid);
        logic [COUNT-1:0][WIDTH-1:0] `SVNET_REG_INPUT_E(i_data,
        i_data_valid);

        logic `SVNET_REG_OUTPUT(o_data_valid);
        logic [WIDTH-1:0] `SVNET_REG_OUTPUT_E(o_data,
        o_data_valid_d);

        always_comb begin
            o_data_valid_d = i_data_valid_q;
            o_data_d = i_data_q;
        end

    end else if(COUNT == 2) begin

        logic `SVNET_REG_INPUT(i_data_valid);
        logic [COUNT-1:0][WIDTH-1:0] `SVNET_REG_INPUT_E(i_data,
        i_data_valid);

        logic `SVNET_REG_OUTPUT(o_data_valid);
        logic [WIDTH-1:0] `SVNET_REG_OUTPUT_E(o_data,
        o_data_valid_d);

        always_comb begin
            o_data_valid_d = i_data_valid_q;
            o_data_d = $unsigned(`SVNET_MAX($signed(i_data_q[0]),
            $signed(i_data_q[1])));
        end

    end else begin

        localparam COUNT_A = (COUNT + 0) / 2;
        localparam COUNT_B = (COUNT + 1) / 2;
        localparam O_WIDTH_A = WIDTH;
        localparam O_WIDTH_B = WIDTH;

        logic `SVNET_REG(i_data_valid_a);
        logic [O_WIDTH_A-1:0] `SVNET_REG_E(i_data_a, i_data_valid_a);

        logic `SVNET_REG(i_data_valid_b);
        logic [O_WIDTH_B-1:0] `SVNET_REG_E(i_data_b, i_data_valid_b);

        logic `SVNET_REG_OUTPUT(o_data_valid);
        logic [WIDTH-1:0] `SVNET_REG_OUTPUT_E(o_data,
        o_data_valid_d);

        valid_error_0 : assert property(@(posedge clk) disable iff (!rst_n)
        i_data_valid_a |-> i_data_valid_b);

        valid_error_1 : assert property(@(posedge clk) disable iff (!rst_n)
        i_data_valid_b |-> i_data_valid_a);

        always_comb begin
            o_data_valid_d = i_data_valid_a_q;
            o_data_d = $unsigned(`SVNET_MAX($signed(i_data_a_q),
            $signed(i_data_b_q)));
        end

        svent_tree_max
        #(
            .WIDTH(WIDTH),
            .COUNT(COUNT_A)
        )
        svent_tree_max_a
        (
            .clk(clk),
            .rst_n(rst_n),
            .i_data_valid(i_data_valid),
            .i_data(i_data[COUNT_A-1:0]),
            .o_data_valid(i_data_valid_a),
            .o_data(i_data_a)
        );

        svent_tree_max
        #(
            .WIDTH(WIDTH),
            .COUNT(COUNT_B)
        )
        svent_tree_max_b
        (
            .clk(clk),
            .rst_n(rst_n),
            .i_data_valid(i_data_valid),
            .i_data(i_data[COUNT_B-1:COUNT_A-0]),
            .o_data_valid(i_data_valid_b),
            .o_data(i_data_b)
        );

    end endgenerate

endmodule : svent_tree_max

`define SVNET_TREE_MAX_DELAY(count) ($clog2(count) * 2)

`define SVNET_TREE_MAX(name, width, count) \
logic name``_i_data_valid, name``_o_data_valid; \
logic [(count)-1:0][(width)-1:0] name``_i_data; \
logic [(width)-1:0] name``_o_data; \
svnet_tree_max #(.WIDTH(width), .COUNT(count)) \
name``_tree_max (.clk(clk), .rst_n(rst_n), \
.i_data_valid(name``_i_data_valid), .i_data(name``_i_data), \
.o_data_valid(name``_o_data_valid), .o_data(name``_o_data))
