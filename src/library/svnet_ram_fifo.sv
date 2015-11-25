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

    write_error : assert property(@(posedge clk) disable iff (!rst_n)
    write |-> free_space);

    read_error : assert property(@(posedge clk) disable iff (!rst_n)
    read |-> used_space);

    localparam B_DEPTH =
    `SVNET_REG_FIFO_R2R_DELAY+`SVNET_RAM_R2R_DELAY+`SVNET_REG_FIFO_W2W_DELAY;

    localparam R_DEPTH =
    DEPTH - B_DEPTH;

    logic [$clog2(DEPTH)-0:0] `SVNET_REG(space);
    logic [WIDTH-1:0] `SVNET_RAM(ram, R_DEPTH);
    logic [$clog2(R_DEPTH)-1:0] `SVNET_REG(ram_write_pointer);
    logic [$clog2(R_DEPTH)-1:0] `SVNET_REG(ram_read_pointer);
    logic [$clog2(R_DEPTH)-0:0] `SVNET_REG(ram_space);
    logic [WIDTH-1:0] `SVNET_REG_FIFO(bypass, B_DEPTH);

    always_comb begin
        automatic logic ram_select = ram_space_q||(bypass_used_space==B_DEPTH); // broken???
        free_space = DEPTH - space_q; // broken (gap errors)
        used_space = space_q; // broken (gap errors)
        space = space_q + write - read; // broken (gap errors)
        ram_write = write && ram_select;
        ram_write_address = ram_write_pointer_q;
        ram_write_data = write_data;
        ram_read = ram_space_q && (bypass_used_space != B_DEPTH); // broken???
        ram_read_address = ram_read_pointer_q;
        ram_write_pointer = ram_write_pointer_q + ram_write;
        if(ram_write_pointer == R_DEPTH) ram_write_pointer = '0;
        ram_read_pointer = ram_read_pointer_q + ram_read;
        if(ram_read_pointer == R_DEPTH) ram_read_pointer = '0;
        ram_space = ram_space_q + ram_write - ram_read_data_valid; // broken (gap errors)
        bypass_write = ram_read_data_valid || (write && (!ram_select));
        bypass_write_data = ram_read_data_valid ? ram_read_data : write_data;
        read_data = bypass_read_data;
        bypass_read = read;
    end

    final if(rst_n) finish_error : assert(!space_q);
    final if(rst_n) finish_error_2 : assert(!ram_space_q);

endmodule : svnet_ram_fifo

`define SVNET_RAM_FIFO_W2W_DELAY 1 // write-to-write delay
`define SVNET_RAM_FIFO_R2R_DELAY 1 // read-to-read delay

`define SVNET_RAM_FIFO(name, depth) name``_write_data, name``_read_data; \
logic [$clog2(depth)-0:0] name``_free_space, name``_used_space; \
logic name``_write, name``_read; \
svnet_ram_fifo #(.WIDTH($bits(name``_read_data)), .DEPTH(depth)) \
name``_ram_fifo (.clk(clk), .rst_n(rst_n), \
.write_data(name``_write_data), .read_data(name``_read_data) \
.free_space(name``_free_space), .used_space(name``_used_space), \
.write(name``_write), .read(name``_read))
