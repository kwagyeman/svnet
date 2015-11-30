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
                begin
                    if(DEPTH > 1) q_int[DEPTH-1:1] <= q_int[DEPTH-2:0];
                    q_int[0] <= d;
                end
            end
        always_comb q = q_int[DEPTH-1];
    end else always_comb q = d; endgenerate

endmodule : svnet_reg

`define SVNET_REG(variable) variable, variable``_q; \
svnet_reg #(.WIDTH($bits(variable))) \
variable``_reg (.clk(clk), .rst_n(rst_n), .d(variable), .q(variable``_q))

`define SVNET_REG_PIPELINE(variable, depth) variable, variable``_q; \
svnet_reg #(.WIDTH($bits(variable)), .DEPTH(depth)) \
variable``_reg (.clk(clk), .rst_n(rst_n), .d(variable), .q(variable``_q))

`define SVNET_REG_SYNCHRONIZER(variable) variable, variable``_q; \
svnet_reg #(.WIDTH($bits(variable)), .DEPTH(2), .SYNC(1)) \
variable``_reg (.clk(clk), .rst_n(rst_n), .d(variable), .q(variable``_q))

`define SVNET_REG_INPUT(variable) variable``_q; \
svnet_reg #(.WIDTH($bits(variable))) \
variable``_reg (.clk(clk), .rst_n(rst_n), .d(variable), .q(variable``_q))

`define SVNET_REG_INPUT_PIPELINE(variable, depth) variable``_q; \
svnet_reg #(.WIDTH($bits(variable)), .DEPTH(depth)) \
variable``_reg (.clk(clk), .rst_n(rst_n), .d(variable), .q(variable``_q))

`define SVNET_REG_INPUT_SYNCHRONIZER(variable) variable``_q; \
svnet_reg #(.WIDTH($bits(variable)), .DEPTH(2), .SYNC(1)) \
variable``_reg (.clk(clk), .rst_n(rst_n), .d(variable), .q(variable``_q))

`define SVNET_REG_OUTPUT(variable) variable``_d; \
svnet_reg #(.WIDTH($bits(variable))) \
variable``_reg (.clk(clk), .rst_n(rst_n), .d(variable``_d), .q(variable))

`define SVNET_REG_OUTPUT_PIPELINE(variable, depth) variable``_d; \
svnet_reg #(.WIDTH($bits(variable)), .DEPTH(depth)) \
variable``_reg (.clk(clk), .rst_n(rst_n), .d(variable``_d), .q(variable))

`define SVNET_REG_OUTPUT_SYNCHRONIZER(variable) variable``_d; \
svnet_reg #(.WIDTH($bits(variable)), .DEPTH(2), .SYNC(1)) \
variable``_reg (.clk(clk), .rst_n(rst_n), .d(variable``_d), .q(variable))

`define SVNET_REG_I(variable, init) variable, variable``_q; \
svnet_reg #(.WIDTH($bits(variable)), .INIT(init)) \
variable``_reg (.clk(clk), .rst_n(rst_n), .d(variable), .q(variable``_q))

`define SVNET_REG_PIPELINE_I(variable, depth, init) variable, variable``_q; \
svnet_reg #(.WIDTH($bits(variable)), .DEPTH(depth), .INIT(init)) \
variable``_reg (.clk(clk), .rst_n(rst_n), .d(variable), .q(variable``_q))

`define SVNET_REG_SYNCHRONIZER_I(variable, init) variable, variable``_q; \
svnet_reg #(.WIDTH($bits(variable)), .DEPTH(2), .INIT(init), .SYNC(1)) \
variable``_reg (.clk(clk), .rst_n(rst_n), .d(variable), .q(variable``_q))

`define SVNET_REG_INPUT_I(variable, init) variable``_q; \
svnet_reg #(.WIDTH($bits(variable)), .INIT(init)) \
variable``_reg (.clk(clk), .rst_n(rst_n), .d(variable), .q(variable``_q))

`define SVNET_REG_INPUT_PIPELINE_I(variable, depth, init) variable``_q; \
svnet_reg #(.WIDTH($bits(variable)), .DEPTH(depth), .INIT(init)) \
variable``_reg (.clk(clk), .rst_n(rst_n), .d(variable), .q(variable``_q))

`define SVNET_REG_INPUT_SYNCHRONIZER_I(variable, init) variable``_q; \
svnet_reg #(.WIDTH($bits(variable)), .DEPTH(2), .INIT(init), .SYNC(1)) \
variable``_reg (.clk(clk), .rst_n(rst_n), .d(variable), .q(variable``_q))

`define SVNET_REG_OUTPUT_I(variable, init) variable``_d; \
svnet_reg #(.WIDTH($bits(variable)), .INIT(init)) \
variable``_reg (.clk(clk), .rst_n(rst_n), .d(variable``_d), .q(variable))

`define SVNET_REG_OUTPUT_PIPELINE_I(variable, depth, init) variable``_d; \
svnet_reg #(.WIDTH($bits(variable)), .DEPTH(depth), .INIT(init)) \
variable``_reg (.clk(clk), .rst_n(rst_n), .d(variable``_d), .q(variable))

`define SVNET_REG_OUTPUT_SYNCHRONIZER_I(variable, init) variable``_d; \
svnet_reg #(.WIDTH($bits(variable)), .DEPTH(2), .INIT(init), .SYNC(1)) \
variable``_reg (.clk(clk), .rst_n(rst_n), .d(variable``_d), .q(variable))
