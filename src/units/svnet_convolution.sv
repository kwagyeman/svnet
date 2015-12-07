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

`define SVNET_CONVOLUTION_BPP(P_BPP, K_BPP, K_WIDTH, K_HEIGHT) \
((P_BPP - 1) + (K_BPP - 1) + $clog2(K_WIDTH * K_HEIGHT))

`define SVNET_CONVOLUTION_BPP_INT \
`SVNET_CONVOLUTION_BPP(P_BPP, K_BPP, K_WIDTH, K_HEIGHT)

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
    input logic [$clog2(P_WIDTH)-0:0] i_kernel_w_stride,
    input logic [$clog2(P_HEIGHT)-0:0] i_kernel_h_stride,
    input logic [K_HEIGHT-1:0][K_WIDTH-1:0][K_BPP-1:0] i_kernel,
    output logic o_kernel_settings_next,

    output logic [P_PPC-1:0] o_valid,
    output logic [P_PPC-1:0] o_row_end,
    output logic [P_PPC-1:0] o_frame_end,
    output logic [P_PPC-1:0][`SVNET_CONVOLUTION_BPP_INT-1:0] o_data
);

    genvar gv_i, gv_j, gv_k;

    logic [P_PPC-1:0] `SVNET_REG_INPUT(i_valid);
    logic [P_PPC-1:0] i_row_end_q;
    logic [P_PPC-1:0] i_frame_end_q;
    logic [P_PPC-1:0][P_BPP-1:0] i_data_q;

    generate for(gv_i = 0; gv_i < P_PPC; gv_i++) begin

        i_row_end_error : assert property(@(posedge clk) disable iff (!rst_n)
        i_row_end[gv_i] |-> i_valid[gv_i]);

        i_frame_end_error : assert property(@(posedge clk) disable iff (!rst_n)
        i_frame_end[gv_i] |-> i_row_end[gv_i]);

        logic `SVNET_REG_E(gen_i_row_end, i_valid[gv_i]);
        logic `SVNET_REG_E(gen_i_frame_end, i_valid[gv_i]);
        logic [P_BPP-1:0] `SVNET_REG_E(gen_i_data, i_valid[gv_i]);

        always_comb begin
            gen_i_row_end = i_row_end[gv_i];
            i_row_end_q[gv_i] = gen_i_row_end_q;
            gen_i_frame_end = i_frame_end[gv_i];
            i_frame_end_q[gv_i] = gen_i_frame_end_q;
            gen_i_data = i_data[gv_i];
            i_data_q[gv_i] = gen_i_data_q;
        end

    end endgenerate

    ///////////////////////////////////////////////////////////////////////////

    localparam SHIFT_REG_SIZE = ((K_WIDTH + P_PPC - 1) / P_PPC) * P_PPC;

    logic [$clog2(K_WIDTH)-0:0] `SVNET_REG(w_counter);
    logic [$clog2(K_HEIGHT)-0:0] `SVNET_REG(h_counter);
    logic [$clog2(P_WIDTH)-0:0] `SVNET_REG(w_stride_counter);
    logic [$clog2(P_HEIGHT)-0:0] `SVNET_REG(h_stride_counter);

    logic [$clog2(SHIFT_REG_SIZE)-0:0] `SVNET_REG(shift_reg_counter);
    logic [SHIFT_REG_SIZE-1:0][P_BPP-1:0] `SVNET_REG(shift_reg);

    logic [P_PPC-1:0][K_HEIGHT-1:0] `SVNET_REG(dispatch_valid);
    logic [P_PPC-1:0] `SVNET_REG(dispatch_row_end);
    logic [P_PPC-1:0] `SVNET_REG(dispatch_frame_end);
    logic [P_PPC-1:0][K_WIDTH-1:0][P_BPP-1:0] `SVNET_REG(dispatch_data);

    always_comb begin

        w_counter = w_counter_q;
        h_counter = h_counter_q;
        w_stride_counter = w_stride_counter_q;
        h_stride_counter = h_stride_counter_q;

        shift_reg_counter = shift_reg_counter_q;
        shift_reg = shift_reg_q;

        dispatch_valid = '0;
        dispatch_row_end = '0;
        dispatch_frame_end = '0;
        dispatch_data = '0;

        for(int i = 0; i < P_PPC; i++) begin
            if(i_valid_q[i]) begin

                shift_reg[w_counter] = i_data_q[i];
                w_counter += 1;

                if(w_counter >= i_kernel_w) begin
                    w_stride_counter -= |w_stride_counter;
                    if(!w_stride_counter) begin
                        dispatch_valid[i] = 1;
                        dispatch_row_end[i] = i_row_end_q[i];
                        dispatch_frame_end[i] = i_frame_end_q[i];
                        dispatch_data[i] = shift_reg;
                        w_stride_counter = i_kernel_w_stride;
                    end
                    shift_reg = shift_reg[SHIFT_REG_SIZE-1:1];
                    w_counter -= 1;
                end

                if(i_row_end_q[i]) begin
                    w_counter = '0;
                    w_stride_counter = '0;
                    h_counter += 1;
                end

                if(i_frame_end_q[i]) begin
                    h_counter = '0;
                    h_stride_counter = '0;
                end

            end
        end

    end

    ///////////////////////////////////////////////////////////////////////////

    localparam I_MUL_WIDTH = `SVNET_MAX(P_BPP, K_BPP);
    localparam I_MUL_COUNT = 2;
    localparam O_MUL_WIDTH = I_MUL_COUNT * I_MUL_WIDTH;

    localparam I_W_ADD_WIDTH = O_MUL_WIDTH;
    localparam I_W_ADD_COUNT = K_WIDTH;
    localparam O_W_ADD_WIDTH = $clog2(I_W_ADD_COUNT) + I_W_ADD_WIDTH;

    localparam I_H_ADD_WIDTH = O_W_ADD_WIDTH;
    localparam I_H_ADD_COUNT = K_HEIGHT;
    localparam O_H_ADD_WIDTH = $clog2(I_H_ADD_COUNT) + I_H_ADD_WIDTH;

    localparam DELAY =
    `SVNET_TREE_MUL_DELAY(I_MUL_COUNT) +
    `SVNET_TREE_ADD_DELAY(I_W_ADD_COUNT) +
    `SVNET_RAM_FIFO_W2R_DELAY +
    `SVNET_TREE_ADD_DELAY(I_H_ADD_COUNT);

    generate for(gv_i = 0; gv_i < P_PPC; gv_i++) begin

        logic [K_HEIGHT-1:0] w_add_o_data_valids;
        `SVNET_TREE_ADD(h_add, I_H_ADD_WIDTH, I_H_ADD_COUNT);

        logic `SVNET_REG_PIPELINE(row_end_delay, DELAY);
        logic `SVNET_REG_PIPELINE(frame_end_delay, DELAY);

        for(gv_j = 0; gv_j < K_HEIGHT; gv_j++) begin

            localparam RAM_DEPTH = `SVNET_RAM_FIFO_W2R_DELAY + 1 +
            (((P_WIDTH - K_WIDTH + P_PPC) / P_PPC) * (K_HEIGHT - 1 - gv_j));

            logic [K_WIDTH-1:0] mul_o_data_valids;
            `SVNET_TREE_ADD(w_add, I_W_ADD_WIDTH, I_W_ADD_COUNT);
            logic [O_W_ADD_WIDTH-1:0] `SVNET_RAM_FIFO(ram, RAM_DEPTH);

            for(gv_k = 0; gv_k < K_WIDTH; gv_k++) begin

                `SVNET_TREE_MUL(mul, I_MUL_WIDTH, I_MUL_COUNT);

                always_comb begin
                    mul_i_data_valid = dispatch_valid_q[gv_i][gv_j];
                    mul_i_data[0] = dispatch_data_q[gv_i][gv_k];
                    mul_i_data[1] = i_kernel[gv_k];
                    mul_o_data_valids[gv_k] = mul_o_data_valid;
                    w_add_i_data[gv_k] = mul_o_data;
                end

            end

            always_comb begin
                w_add_i_data_valid = mul_o_data_valids;
                ram_write = w_add_o_data_valid;
                ram_write_data = w_add_o_data;
                w_add_o_data_valids[gv_j] = |ram_used_space;
                h_add_o_data[gv_j] = ram_read_data;
                ram_read = h_add_i_data_valid;
            end

        end

        always_comb begin
            h_add_i_data_valid = &w_add_o_data_valids;
            o_valid[gv_i] = h_add_o_data_valid;
            o_data[gv_i] = h_add_o_data;
            row_end_delay = dispatch_row_end_q[gv_i];
            o_row_end[gv_i] = row_end_delay_q;
            frame_end_delay = dispatch_frame_end_q[gv_i];
            o_frame_end[gv_i] = frame_end_delay_q;
        end

    end endgenerate

endmodule : svnet_convolution
