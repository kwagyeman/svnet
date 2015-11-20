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

module svnet_ram_fifo
#(
    WIDTH = 1,
    DEPTH = 1
)
(
    input logic clk, rst_n,

    // Step 1
    output logic [$clog2(DEPTH)-0:0] free_space,
    input logic write,
    input logic [WIDTH-1:0] write_data,

    // Step 2
    output logic [$clog2(DEPTH)-0:0] used_space,
    output logic [WIDTH-1:0] read_data,
    input logic read
);

    assert property(@(posedge clk) disable iff (!rst_n)
    write |-> free_space);

    assert property(@(posedge clk) disable iff (!rst_n)
    read |-> used_space);

endmodule : svnet_ram_fifo

`define SVNET_RAM_FIFO(name, depth) name``_write_data, name``_read_data; \
logic [$clog2(depth)-0:0] name``_free_space, name``_used_space; \
logic name``_write, name``_read; \
svnet_ram_fifo #(.WIDTH($bits(name``_read_data)), .DEPTH(depth)) \
name``_ram_fifo (.clk(clk), .rst_n(rst_n), \
.write_data(name``_write_data), .read_data(name``_read_data) \
.free_space(name``_free_space), .used_space(name``_used_space), \
.write(name``_write), .read(name``_read))
