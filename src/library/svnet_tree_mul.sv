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

module svent_tree_mul_int
#(
    WIDTH = 1,
    COUNT = 1
)
(
    input logic clk, rst_n,

    input logic [COUNT-1:0][WIDTH-1:0] i_data,
    output logic [(COUNT*WIDTH)-1:0] o_data
);

    generate if(COUNT == 1) begin

        logic [COUNT-1:0][WIDTH-1:0] `SVNET_REG_INPUT(i_data);
        logic [(COUNT*WIDTH)-1:0] `SVNET_REG_OUTPUT(o_data);

        always_comb o_data_d =
        i_data_q;

    end else if(COUNT == 2) begin

        logic [COUNT-1:0][WIDTH-1:0] `SVNET_REG_INPUT(i_data);
        logic [(COUNT*WIDTH)-1:0] `SVNET_REG_OUTPUT(o_data);

        always_comb o_data_d =
        $unsigned($signed(i_data_q[0]) * $signed(i_data_q[1]));

    end else begin

        localparam COUNT_A = (COUNT + 0) / 2;
        localparam COUNT_B = (COUNT + 1) / 2;
        localparam O_WIDTH_A = COUNT_A * WIDTH;
        localparam O_WIDTH_B = COUNT_B * WIDTH;

        logic [O_WIDTH_A-1:0] `SVNET_REG(i_data_a);
        logic [O_WIDTH_B-1:0] `SVNET_REG(i_data_b);
        logic [(COUNT*WIDTH)-1:0] `SVNET_REG_OUTPUT(o_data);

        always_comb o_data_d =
        $unsigned($signed(i_data_a_q) * $signed(i_data_b_q));

        svent_tree_mul
        #(
            .WIDTH(WIDTH),
            .COUNT(COUNT_A)
        )
        svent_tree_mul_a
        (
            .clk(clk),
            .rst_n(rst_n),
            .i_data(i_data[COUNT_A-1:0]),
            .o_data(i_data_a)
        );

        svent_tree_mul
        #(
            .WIDTH(WIDTH),
            .COUNT(COUNT_B)
        )
        svent_tree_mul_b
        (
            .clk(clk),
            .rst_n(rst_n),
            .i_data(i_data[COUNT_B-1:COUNT_A-0]),
            .o_data(i_data_b)
        );

    end endgenerate

endmodule : svent_tree_mul_int

`define SVNET_TREE_MUL_DELAY(count) ($clog2(count) * 2)

module svnet_tree_mul
#(
    WIDTH = 1,
    COUNT = 1
)
(
    input logic clk, rst_n,

    input logic i_valid,
    input logic [COUNT-1:0][WIDTH-1:0] i_data,

    output logic o_valid,
    output logic [(COUNT*WIDTH)-1:0] o_data
);

    logic `SVNET_REG_OUTPUT_PIPELINE(o_valid, `SVNET_TREE_MUL_DELAY(COUNT));

    always_comb o_valid_d = i_valid;

    generate if(COUNT == 1) begin
        always_comb o_data = i_data;
    end else begin
        svent_tree_mul_int
        #(
            .WIDTH(WIDTH),
            .COUNT(COUNT)
        )
        svent_tree_mul_int_i
        (
            .clk(clk),
            .rst_n(rst_n),
            .i_data(i_data),
            .o_data(o_data)
        );
    end endgenerate

endmodule : svnet_tree_mul
