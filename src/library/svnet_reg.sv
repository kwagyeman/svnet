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

module svnet_reg
#(
    WIDTH = 1,
    DEPTH = 1,
    INIT = '0,
    SYNC = 0
)
(
    input logic clk, rst_n,

    input logic enable,

    input logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);

    generate if(DEPTH) begin
        `ifndef SVNET_NO_RESET
            logic [DEPTH-1:0][WIDTH-1:0] q_int = 'x;
            `ifndef SYNTHESIS
                always_latch if(!rst_n) force q_int = INIT; else release q_int;
            `endif
            always_ff @(posedge clk or negedge rst_n) begin
                if(!rst_n) q_int <= INIT; else
        `else
            logic [DEPTH-1:0][WIDTH-1:0] q_int = INIT;
            always_ff @(posedge clk) begin
        `endif
                if(enable) begin
                    if(DEPTH > 1) q_int[DEPTH-1:1] <= q_int[DEPTH-2:0];
                    q_int[0] <= d;
                end
            end
        always_comb q = q_int[DEPTH-1];
    end else always_comb q = d; endgenerate

endmodule : svnet_reg

`define SVNET_REG(name) name, name``_q; \
svnet_reg #(.WIDTH($bits(name))) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable('1), .d(name), .q(name``_q))

`define SVNET_REG_PIPELINE(name, depth) name, name``_q; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(depth)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable('1), .d(name), .q(name``_q))

`define SVNET_REG_SYNCHRONIZER(name) name, name``_q; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(2), .SYNC(1)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable('1), .d(name), .q(name``_q))

`define SVNET_REG_INPUT(name) name``_q; \
svnet_reg #(.WIDTH($bits(name))) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable('1), .d(name), .q(name``_q))

`define SVNET_REG_INPUT_PIPELINE(name, depth) name``_q; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(depth)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable('1), .d(name), .q(name``_q))

`define SVNET_REG_INPUT_SYNCHRONIZER(name) name``_q; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(2), .SYNC(1)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable('1), .d(name), .q(name``_q))

`define SVNET_REG_OUTPUT(name) name``_d; \
svnet_reg #(.WIDTH($bits(name))) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable('1), .d(name``_d), .q(name))

`define SVNET_REG_OUTPUT_PIPELINE(name, depth) name``_d; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(depth)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable('1), .d(name``_d), .q(name))

`define SVNET_REG_OUTPUT_SYNCHRONIZER(name) name``_d; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(2), .SYNC(1)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable('1), .d(name``_d), .q(name))

///////////////////////////////////////////////////////////////////////////////

`define SVNET_REG_E(name, en) name, name``_q; \
svnet_reg #(.WIDTH($bits(name))) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable(en), .d(name), .q(name``_q))

`define SVNET_REG_PIPELINE_E(name, depth, en) name, name``_q; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(depth)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable(en), .d(name), .q(name``_q))

`define SVNET_REG_SYNCHRONIZER_E(name, en) name, name``_q; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(2), .SYNC(1)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable(en), .d(name), .q(name``_q))

`define SVNET_REG_INPUT_E(name, en) name``_q; \
svnet_reg #(.WIDTH($bits(name))) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable(en), .d(name), .q(name``_q))

`define SVNET_REG_INPUT_PIPELINE_E(name, depth, en) name``_q; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(depth)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable(en), .d(name), .q(name``_q))

`define SVNET_REG_INPUT_SYNCHRONIZER_E(name, en) name``_q; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(2), .SYNC(1)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable(en), .d(name), .q(name``_q))

`define SVNET_REG_OUTPUT_E(name, en) name``_d; \
svnet_reg #(.WIDTH($bits(name))) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable(en), .d(name``_d), .q(name))

`define SVNET_REG_OUTPUT_PIPELINE_E(name, depth, en) name``_d; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(depth)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable(en), .d(name``_d), .q(name))

`define SVNET_REG_OUTPUT_SYNCHRONIZER_E(name, en) name``_d; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(2), .SYNC(1)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable(en), .d(name``_d), .q(name))

///////////////////////////////////////////////////////////////////////////////

`define SVNET_REG_I(name, init) name, name``_q; \
svnet_reg #(.WIDTH($bits(name)), .INIT(init)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable('1), .d(name), .q(name``_q))

`define SVNET_REG_PIPELINE_I(name, depth, init) name, name``_q; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(depth), .INIT(init)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable('1), .d(name), .q(name``_q))

`define SVNET_REG_SYNCHRONIZER_I(name, init) name, name``_q; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(2), .INIT(init), .SYNC(1)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable('1), .d(name), .q(name``_q))

`define SVNET_REG_INPUT_I(name, init) name``_q; \
svnet_reg #(.WIDTH($bits(name)), .INIT(init)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable('1), .d(name), .q(name``_q))

`define SVNET_REG_INPUT_PIPELINE_I(name, depth, init) name``_q; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(depth), .INIT(init)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable('1), .d(name), .q(name``_q))

`define SVNET_REG_INPUT_SYNCHRONIZER_I(name, init) name``_q; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(2), .INIT(init), .SYNC(1)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable('1), .d(name), .q(name``_q))

`define SVNET_REG_OUTPUT_I(name, init) name``_d; \
svnet_reg #(.WIDTH($bits(name)), .INIT(init)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable('1), .d(name``_d), .q(name))

`define SVNET_REG_OUTPUT_PIPELINE_I(name, depth, init) name``_d; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(depth), .INIT(init)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable('1), .d(name``_d), .q(name))

`define SVNET_REG_OUTPUT_SYNCHRONIZER_I(name, init) name``_d; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(2), .INIT(init), .SYNC(1)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable('1), .d(name``_d), .q(name))

///////////////////////////////////////////////////////////////////////////////

`define SVNET_REG_E_I(name, en, init) name, name``_q; \
svnet_reg #(.WIDTH($bits(name)), .INIT(init)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable(en), .d(name), .q(name``_q))

`define SVNET_REG_PIPELINE_E_I(name, depth, en, init) name, name``_q; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(depth), .INIT(init)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable(en), .d(name), .q(name``_q))

`define SVNET_REG_SYNCHRONIZER_E_I(name, en, init) name, name``_q; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(2), .INIT(init), .SYNC(1)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable(en), .d(name), .q(name``_q))

`define SVNET_REG_INPUT_E_I(name, en, init) name``_q; \
svnet_reg #(.WIDTH($bits(name)), .INIT(init)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable(en), .d(name), .q(name``_q))

`define SVNET_REG_INPUT_PIPELINE_E_I(name, depth, en, init) name``_q; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(depth), .INIT(init)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable(en), .d(name), .q(name``_q))

`define SVNET_REG_INPUT_SYNCHRONIZER_E_I(name, en, init) name``_q; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(2), .INIT(init), .SYNC(1)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable(en), .d(name), .q(name``_q))

`define SVNET_REG_OUTPUT_E_I(name, en, init) name``_d; \
svnet_reg #(.WIDTH($bits(name)), .INIT(init)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable(en), .d(name``_d), .q(name))

`define SVNET_REG_OUTPUT_PIPELINE_E_I(name, depth, en, init) name``_d; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(depth), .INIT(init)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable(en), .d(name``_d), .q(name))

`define SVNET_REG_OUTPUT_SYNCHRONIZER_E_I(name, en, init) name``_d; \
svnet_reg #(.WIDTH($bits(name)), .DEPTH(2), .INIT(init), .SYNC(1)) \
name``_reg (.clk(clk), .rst_n(rst_n), .enable(en), .d(name``_d), .q(name))
