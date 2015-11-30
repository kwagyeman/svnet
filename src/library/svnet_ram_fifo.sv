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

    localparam B_DEPTH = `SVNET_RAM_R2V_DELAY + `SVNET_REG_FIFO_W2R_DELAY;
    localparam R_DEPTH = DEPTH - B_DEPTH;

    generate if(DEPTH <= B_DEPTH) begin

        logic [WIDTH-1:0] `SVNET_REG_FIFO(bypass, DEPTH);

        always_comb begin
            free_space = bypass_free_space;
            bypass_write = write;
            bypass_write_data = write_data;
            used_space = bypass_used_space;
            read_data = bypass_read_data;
            bypass_read = read;
        end

    end else begin

        logic [WIDTH-1:0] `SVNET_RAM(ram, R_DEPTH);
        logic [$clog2(R_DEPTH)-0:0] `SVNET_REG(ram_w2r_used_space);
        logic [`SVNET_RAM_R2V_DELAY-1:0] `SVNET_REG(ram_r2v_used_space);
        logic [$clog2(R_DEPTH)-1:0] `SVNET_REG(ram_write_pointer);
        logic [$clog2(R_DEPTH)-1:0] `SVNET_REG(ram_read_pointer);
        logic [WIDTH-1:0] `SVNET_REG_FIFO(bypass, B_DEPTH);
        logic [$clog2(DEPTH)-0:0] `SVNET_REG_OUTPUT_I(free_space, DEPTH);
        logic [$clog2(DEPTH)-0:0] `SVNET_REG_OUTPUT(used_space);

        always_comb begin

            automatic logic ram_select =
            ram_w2r_used_space_q||ram_r2v_used_space_q||(!bypass_free_space);

            ram_write = write && ram_select;
            ram_write_data = write_data;
            ram_write_address = ram_write_pointer_q;

            ram_read = ram_w2r_used_space_q && (read || bypass_free_space);
            ram_read_address = ram_read_pointer_q;

            ram_w2r_used_space =
            ram_w2r_used_space_q + ram_write - ram_read;

            ram_r2v_used_space =
            {ram_r2v_used_space_q[`SVNET_RAM_R2V_DELAY-2:0], ram_read};

            ram_write_pointer = ram_write_pointer_q + ram_write;
            if(ram_write_pointer == R_DEPTH) ram_write_pointer = '0;

            ram_read_pointer = ram_read_pointer_q + ram_read;
            if(ram_read_pointer == R_DEPTH) ram_read_pointer = '0;

            bypass_write = ram_read_data_valid || (write && (!ram_select));
            bypass_write_data = ram_read_data_valid?ram_read_data:write_data;

            read_data = bypass_read_data;
            bypass_read = read;

            free_space_d = free_space - write + read;
            used_space_d = bypass_used_space + bypass_write - bypass_read;

            if(used_space_d >= `SVNET_REG_FIFO_W2R_DELAY)
            for(int i = `SVNET_RAM_R2V_DELAY - 1,
            j = used_space_d - `SVNET_REG_FIFO_W2R_DELAY;
            i >= 0; i--)
            if(ram_r2v_used_space[i]) used_space_d += 1;
            else if(j) j -= 1; else break;

            if(used_space_d>=(`SVNET_RAM_R2V_DELAY+`SVNET_REG_FIFO_W2R_DELAY))
            used_space_d += ram_w2r_used_space; // ^ not necessarily B_DEPTH

        end

    end endgenerate

    final if(rst_n) finish_error_0 : assert(free_space == DEPTH);
    final if(rst_n) finish_error_1 : assert(!used_space);

endmodule : svnet_ram_fifo

`define SVNET_RAM_FIFO_W2R_DELAY 1 // write-to-read delay
`define SVNET_RAM_FIFO_R2V_DELAY 0 // read-to-valid delay

`define SVNET_RAM_FIFO(name, depth) name``_write_data, name``_read_data; \
logic [$clog2(depth)-0:0] name``_free_space, name``_used_space; \
logic name``_write, name``_read; \
svnet_ram_fifo #(.WIDTH($bits(name``_read_data)), .DEPTH(depth)) \
name``_ram_fifo (.clk(clk), .rst_n(rst_n), \
.write_data(name``_write_data), .read_data(name``_read_data) \
.free_space(name``_free_space), .used_space(name``_used_space), \
.write(name``_write), .read(name``_read))
