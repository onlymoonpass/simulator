`timescale 1ns/1ps
module rename_fire
#(
    parameter PRF_NUM      = 128,
    parameter ROB_NUM      = 128,
    parameter STQ_NUM      = 16 ,
    parameter OP_NUM       = 13 ,
    parameter FETCH_WIDTH  = 4  ,
    parameter COMMIT_WIDTH = 4  ,
    parameter ARF_NUM      = 32 ,
    parameter MAX_BR_NUM   = 16 ,
    parameter ALU_NUM      = 4  ,
    parameter AMOOP_NUM    = 12 ,
    parameter CPU_WIDTH    = 32 ,
    parameter FUNC3_WIDTH  = 3  ,
    parameter CSR_WIDTH    = 12 ,
    parameter TYPE_NUM     = 16 
)
(
    input                             out_ren2dis_valid                                     [FETCH_WIDTH-1:0],
    input                             in_dis2ren_ready                                                       ,
    input                             inst_r_valid                                          [FETCH_WIDTH-1:0],
    output                            fire                                                  [FETCH_WIDTH-1:0],
    input                             out_ren2dis_uop_dest_en                               [FETCH_WIDTH-1:0],
    input      [$clog2(TYPE_NUM)-1:0] inst_r_uop_type                                       [FETCH_WIDTH-1:0],

    input      [  $clog2(ARF_NUM):0]  inst_r_uop_dest_areg                                  [FETCH_WIDTH-1:0],
    input      [$clog2(PRF_NUM)-1:0]  out_ren2dis_uop_dest_preg                             [FETCH_WIDTH-1:0],
    output reg [$clog2(PRF_NUM)-1:0]  spec_alloc_write_out_ren2dis_uop_dest_preg_addr       [FETCH_WIDTH-1:0],
    output reg                        spec_alloc_write_out_ren2dis_uop_dest_preg_data       [FETCH_WIDTH-1:0],
    output reg                        spec_alloc_write_out_ren2dis_uop_dest_preg_en         [FETCH_WIDTH-1:0], 
    output reg [$clog2(PRF_NUM)-1:0]  free_vec_write_out_ren2dis_uop_dest_preg_addr         [FETCH_WIDTH-1:0],// fire  
    output reg                        free_vec_write_out_ren2dis_uop_dest_preg_data         [FETCH_WIDTH-1:0],
    output reg                        free_vec_write_out_ren2dis_uop_dest_preg_en           [FETCH_WIDTH-1:0], 
    output reg [  $clog2(ARF_NUM):0]  spec_RAT_write_inst_r_uop_dest_areg_addr              [FETCH_WIDTH-1:0],
    output reg [$clog2(PRF_NUM)-1:0]  spec_RAT_write_inst_r_uop_dest_areg_data              [FETCH_WIDTH-1:0],
    output reg                        spec_RAT_write_inst_r_uop_dest_areg_en                [FETCH_WIDTH-1:0],
    output reg [$clog2(PRF_NUM)-1:0]  busy_table_write_out_ren2dis_uop_dest_preg_addr       [FETCH_WIDTH-1:0],
    output reg                        busy_table_write_out_ren2dis_uop_dest_preg_data       [FETCH_WIDTH-1:0],
    output reg                        busy_table_write_out_ren2dis_uop_dest_preg_en         [FETCH_WIDTH-1:0],
    output reg [$clog2(PRF_NUM)-1:0]  alloc_checkpoint_write_out_ren2dis_uop_dest_preg_addr [FETCH_WIDTH-1:0],
    output reg                        alloc_checkpoint_write_out_ren2dis_uop_dest_preg_data [FETCH_WIDTH-1:0],
    output reg                        alloc_checkpoint_write_out_ren2dis_uop_dest_preg_en   [FETCH_WIDTH-1:0],     
    
    output                            out_ren2dec_ready                                            
);

parameter NONE 		 = 4'd0;
parameter JAL 		 = 4'd1;
parameter JALR 		 = 4'd2;
parameter ADD 		 = 4'd3;
parameter BR 		 = 4'd4;
parameter LOAD 		 = 4'd5;
parameter STORE 	 = 4'd6;
parameter CSR 		 = 4'd7;
parameter ECALL 	 = 4'd8;
parameter EBREAK     = 4'd9;
parameter SFENCE_VMA = 4'd10;
parameter MRET       = 4'd11;
parameter SRET 		 = 4'd12;
parameter MUL 		 = 4'd13;
parameter DIV  		 = 4'd14;
parameter AMO 		 = 4'd15;

genvar i;
generate
    for(i = 0; i < FETCH_WIDTH; i++) begin
        assign fire[i] = out_ren2dis_valid[i] && in_dis2ren_ready;
    end
endgenerate

integer j;
always_comb begin
    for(j = 0; j < FETCH_WIDTH; j++) begin
        spec_alloc_write_out_ren2dis_uop_dest_preg_addr      [j] = out_ren2dis_uop_dest_preg[j];
        spec_alloc_write_out_ren2dis_uop_dest_preg_data      [j] = 1'b1;
        spec_alloc_write_out_ren2dis_uop_dest_preg_en        [j] = fire[j] && out_ren2dis_uop_dest_en[j];
        free_vec_write_out_ren2dis_uop_dest_preg_addr        [j] =  out_ren2dis_uop_dest_preg[j];
        free_vec_write_out_ren2dis_uop_dest_preg_data        [j] = 1'b0;
        free_vec_write_out_ren2dis_uop_dest_preg_en          [j] = fire[j] && out_ren2dis_uop_dest_en[j];
        spec_RAT_write_inst_r_uop_dest_areg_addr             [j] = inst_r_uop_dest_areg[j];
        spec_RAT_write_inst_r_uop_dest_areg_data             [j] = out_ren2dis_uop_dest_preg[j];
        spec_RAT_write_inst_r_uop_dest_areg_en               [j] = fire[j] && out_ren2dis_uop_dest_en[j];
        busy_table_write_out_ren2dis_uop_dest_preg_addr      [j] = out_ren2dis_uop_dest_preg[j];
        busy_table_write_out_ren2dis_uop_dest_preg_data      [j] = 1'b1;
        busy_table_write_out_ren2dis_uop_dest_preg_en        [j] = fire[j] && out_ren2dis_uop_dest_en[j];
        alloc_checkpoint_write_out_ren2dis_uop_dest_preg_addr[j] = out_ren2dis_uop_dest_preg[j];
        alloc_checkpoint_write_out_ren2dis_uop_dest_preg_data[j] = 1'b1;
        alloc_checkpoint_write_out_ren2dis_uop_dest_preg_en  [j] = fire[j] && out_ren2dis_uop_dest_en[j];
    end
end

wire out_ren2dec_ready_buf [ FETCH_WIDTH-1:0]/*verilator split_var*/;
assign out_ren2dec_ready_buf[0] =                    1'b1 && (fire[0] || !inst_r_valid[0]);
assign out_ren2dec_ready_buf[1] = out_ren2dec_ready_buf[0] && (fire[1] || !inst_r_valid[1]);
assign out_ren2dec_ready_buf[2] = out_ren2dec_ready_buf[1] && (fire[2] || !inst_r_valid[2]);
assign out_ren2dec_ready_buf[3] = out_ren2dec_ready_buf[2] && (fire[3] || !inst_r_valid[3]);

assign out_ren2dec_ready = out_ren2dec_ready_buf[3];

endmodule