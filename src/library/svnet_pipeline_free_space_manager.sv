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

module svnet_pipeline_free_space_manager
#(
    DEPTH = 1,
    DELAY = 1
)
(
    input logic clk, rst_n,

    // Connects to left side pipeline input
    output logic [$clog2(DEPTH)-0:0] pipeline_free_space,
    input logic pipeline_write,

    // Connects to right side pipeline output
    input logic [$clog2(DEPTH)-0:0] target_free_space,
    input logic target_write
);

    pipeline_write_error : assert property(@(posedge clk) disable iff (!rst_n)
    pipeline_write |-> pipeline_free_space);

    target_write_error : assert property(@(posedge clk) disable iff (!rst_n)
    target_write |-> target_free_space);

    logic [$clog2(DELAY)-0:0] `SVNET_REG(used_space);

    always_comb begin
        pipeline_free_space = target_free_space - used_space_q;
        used_space = used_space_q + pipeline_write - target_write;
    end

    final if(rst_n) finish_error : assert(!used_space_q);

endmodule : svnet_pipeline_free_space_manager

`define SVNET_PIPELINE_FREE_SPACE_MANAGER(name, delay) \
logic [$bits(name``_free_space)-1:0] name``_pipeline_free_space; \
logic name``_pipeline_write; \
svnet_pipeline_free_space_manager #(.DEPTH(1<<($bits(name``_free_space)-1)), \
.DELAY(delay)) name``_pipeline_free_space_manager (.clk(clk), .rst_n(rst_n), \
.pipeline_free_space(name``_pipeline_free_space), \
.pipeline_write(name``_pipeline_write), \
.target_free_space(name``_free_space), \
.target_write(name``_write))
