// SVNet (System Verilog Convolutional Neural Network)
// Copyright (C) 2015-2016 Kwabena W. Agyeman
//
// This program is used software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the used Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

module svnet_pipeline_used_space_manager
#(
    DEPTH = 1,
    DELAY = 1
)
(
    input logic clk, rst_n,

    // Connects to left side pipeline input
    input logic [$clog2(DEPTH)-0:0] source_used_space,
    input logic source_read,

    // Connects to right side pipeline output
    output logic [$clog2(DEPTH)-0:0] pipeline_used_space,
    input logic pipeline_read
);

    source_read_error : assert property(@(posedge clk) disable iff (!rst_n)
    source_read |-> source_used_space);

    pipeline_read_error : assert property(@(posedge clk) disable iff (!rst_n)
    pipeline_read |-> pipeline_used_space);

    logic [$clog2(DELAY)-0:0] `SVNET_REG(free_space);

    always_comb begin
        pipeline_used_space = source_used_space - free_space_q;
        free_space = free_space_q - source_read + pipeline_read;
    end

    final if(rst_n) finish_error : assert(!free_space_q);

endmodule : svnet_pipeline_used_space_manager

`define SVNET_PIPELINE_USED_SPACE_MANAGER(name, delay) \
logic [$bits(name``_used_space)-1:0] name``_pipeline_used_space; \
logic name``_pipeline_read; \
svnet_pipeline_used_space_manager #(.DEPTH(1<<($bits(name``_used_space)-1)), \
.DELAY(delay)) name``_pipeline_used_space_manager (.clk(clk), .rst_n(rst_n), \
.source_used_space(name``_used_space), \
.source_read(name``_read), \
.pipeline_used_space(name``_pipeline_used_space), \
.pipeline_read(name``_pipeline_read))
