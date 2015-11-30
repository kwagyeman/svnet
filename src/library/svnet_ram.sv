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

module svnet_ram
#(
    WIDTH = 1,
    DEPTH = 1
)
(
    input logic clk, rst_n,

    // Step 1
    input logic write,
    input logic [$clog2(DEPTH)-1:0] write_address,
    input logic [WIDTH-1:0] write_data,

    // Step 2
    input logic read,
    input logic [$clog2(DEPTH)-1:0] read_address,

    // Step 3
    output logic read_data_valid,
    output logic [WIDTH-1:0] read_data
);

    write_error : assert property(@(posedge clk) disable iff (!rst_n)
    write |-> (write_address < DEPTH));

    read_error : assert property(@(posedge clk) disable iff (!rst_n)
    read |-> (read_address < DEPTH));

    logic `SVNET_REG_INPUT(write);
    logic [$clog2(DEPTH)-1:0] `SVNET_REG_INPUT(write_address);
    logic [WIDTH-1:0] `SVNET_REG_INPUT(write_data);
    logic `SVNET_REG_INPUT(read);
    logic [$clog2(DEPTH)-1:0] `SVNET_REG_INPUT(read_address);
    logic `SVNET_REG_OUTPUT(read_data_valid);
    logic [WIDTH-1:0] `SVNET_REG_OUTPUT(read_data);
    logic [DEPTH-1:0][WIDTH-1:0] ram =
    `ifndef SVNET_NO_RESET 'x `else '0 `endif;

    always_ff @(posedge clk) begin
        if(write_q) ram[write_address_q] <= write_data_q;
    end

    always_comb begin
        read_data_valid_d = read_q;
        read_data_d = ram[read_address_q];
    end

endmodule : svnet_ram

`define SVNET_RAM_W2R_DELAY 1 // write-to-read delay
`define SVNET_RAM_R2V_DELAY 2 // read-to-valid delay

`define SVNET_RAM(name, depth) name``_write_data, name``_read_data; \
logic name``_write, name``_read, name``_read_data_valid; \
logic [$clog2(DEPTH)-1:0] name``_write_address, name``_read_address; \
svnet_ram #(.WIDTH($bits(name``_read_data)), .DEPTH(depth)) \
name``_ram (.clk(clk), .rst_n(rst_n), \
.write_data(name``_write_data), .read_data(name``_read_data), \
.write(name``_write), .read(name``_read), \
.write_address(name``_write_address), .read_address(name``_read_address), \
.read_data_valid(name``_read_data_valid))
