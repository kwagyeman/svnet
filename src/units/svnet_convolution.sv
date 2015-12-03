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

module svnet_convolution
#(
    P_BPP = 9, // Pixmap bits per pixel - signed
    P_PPC = 1, // Pixmap pixels per clock
    P_WIDTH = 32, // Pixmap width
    P_HEIGHT = 32, // Pixmap height
    K_BPP = 9, // Kernel bits per pixel - signed
    K_WIDTH = 5, // Kernel width
    K_HEIGHT = 5 // Kernel height
)
(
    input logic clk, rst_n,

    input logic [P_PPC-1:0] i_valid,
    input logic [P_PPC-1:0] i_row_end,
    input logic [P_PPC-1:0] i_frame_end,
    input logic [P_PPC-1:0][P_BPP-1:0] i_data,

    input logic [$clog2(K_WIDTH)-0:0] i_kernel_w,
    input logic [$clog2(K_HEIGHT)-0:0] i_kernel_h,
    input logic [K_HEIGHT-1:0][K_WIDTH-1:0][K_BPP-1:0] i_kernel,

    output logic [P_PPC-1:0] o_valid,
    output logic [P_PPC-1:0] o_row_end,
    output logic [P_PPC-1:0] o_frame_end,
    output logic [P_PPC-1:0][???-1:0] o_data,
);

    i_row_end_error : assert property(@(posedge clk) disable iff (!rst_n)
    i_row_end |-> i_valid);

    i_frame_end_error : assert property(@(posedge clk) disable iff (!rst_n)
    i_frame_end |-> i_row_end);

    logic [P_PPC-1:0] `SVNET_REG_INPUT(i_valid);
    logic [P_PPC-1:0] `SVNET_REG_INPUT(i_row_end);
    logic [P_PPC-1:0] `SVNET_REG_INPUT(i_frame_end);
    logic [P_PPC-1:0][P_BPP-1:0] `SVNET_REG_INPUT(i_data);

    logic [$clog2(K_WIDTH)-0:0] `SVNET_REG_INPUT(i_kernel_w);
    logic [$clog2(K_HEIGHT)-0:0] `SVNET_REG_INPUT(i_kernel_h);
    logic [K_HEIGHT-1:0][K_WIDTH-1:0][K_BPP-1:0] `SVNET_REG_INPUT(i_kernel);

    localparam SHIFT_REG_SIZE = ((K_WIDTH + P_PPC - 1) / P_PPC) * P_PPC;

    logic [$clog2(SHIFT_REG_SIZE)-0:0] `SVNET_REG(shift_reg_counter);
    logic [SHIFT_REG_SIZE-1:0][P_BPP-1:0] `SVNET_REG(shift_reg);
    logic [P_PPC-1:0] `SVNET_REG(dispatch_valid);
    logic [P_PPC-1:0][K_WIDTH-1:0][P_BPP-1:0] `SVNET_REG(dispatch);

    always_comb begin

        shift_reg_counter = shift_reg_counter_q
        shift_reg = shift_reg_q;
        dispatch_valid = '0;
        dispatch = '0;

        for(int i = 0; i < P_PPC; i++) begin
            if(i_valid_q[i]) begin

                shift_reg[shift_reg_counter++] = i_data_q[i];

                if(shift_reg_counter >= i_kernel_w_q) begin
                    dispatch_valid[i] = 1;
                    dispatch[i] = shift_reg;
                    shift_reg = shift_reg[SHIFT_REG_SIZE-1:1];
                    shift_reg_counter -= 1;
                end

                if(i_row_end_q[i]) shift_reg_counter = 0;

            end
        end

    end

    ///////////////////////////////////////////////////////////////////////////

    logic [P_PPC-1:0] `SVNET_REG_OUTPUT(o_valid);
    logic [P_PPC-1:0] `SVNET_REG_OUTPUT(o_row_end);
    logic [P_PPC-1:0] `SVNET_REG_OUTPUT(o_frame_end);
    logic [P_PPC-1:0][???-1:0] `SVNET_REG_OUTPUT(o_data);

    generate genvar i, j, k; for(i = 0; i < P_PPC; i++) begin

        localparam I_MUL_WIDTH = `SVNET_MAX(P_BPP, K_BPP);
        localparam I_MUL_COUNT = 2;
        localparam O_MUL_WIDTH = I_MUL_COUNT * I_MUL_WIDTH;

        localparam I_ADD_WIDTH = O_MUL_WIDTH;
        localparam I_ADD_COUNT = K_WIDTH;
        localparam O_ADD_WIDTH = $clog2(I_ADD_COUNT) + I_ADD_WIDTH;

        localparam I_ADD_2_WIDTH = O_ADD_WIDTH
        localparam I_ADD_2_COUNT = K_HEIGHT;
        localparam O_ADD_2_WIDTH = $clog2(I_ADD_2_COUNT) + I_ADD_2_WIDTH;

        logic [K_HEIGHT-1:0] add_2_o_data_valids;
        `SVNET_TREE_ADD(add_2, I_ADD_WIDTH, I_ADD_COUNT);

        for(j = 0; j < K_HEIGHT; j++) begin

            logic [K_WIDTH-1:0] mul_o_data_valids;
            `SVNET_TREE_ADD(add, I_ADD_WIDTH, I_ADD_COUNT);
            logic [O_ADD_WIDTH-1:0] `SVNET_RAM_FIFO(ram,
            (((K_HEIGHT - j - 1) * P_WIDTH) + 1 + `SVNET_RAM_FIFO_W2R_DELAY));

            for(k = 0; k < K_WIDTH; k++) begin
                `SVNET_TREE_MUL(mul, I_MUL_WIDTH, I_MUL_COUNT);
                always_comb begin
                    mul_i_data_valid = dispatch_valid_q[i];
                    mul_i_data[0] = dispatch_q[i][k];
                    mul_i_data[1] = i_kernel_q[k];
                    mul_o_data_valids[k] = mul_o_data_valid;
                    add_i_data[k] = mul_o_data;
                end
            end

            always_comb begin
                add_i_data_valid = &mul_o_data_valids;
                ram_write = add_o_data_valid;
                ram_write_data = add_o_data;
                add_2_o_data_valids[j] = |ram_used_space;
                add_2_o_data[j] = ram_read_data;
                ram_read = add_2_i_data_valid;
            end

        end

        always_comb begin
            add_2_i_data_valid = &add_2_o_data_valids;
            o_valid[i] = add_2_o_data_valid;
            o_data[i] = add_2_o_data;
        end

    end endgenerate

endmodule : svnet_convolution
