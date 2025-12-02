`timescale 1ns/1ps
module rename_free_vec
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
    // input                              clk                                                                               ,// if use seq please open the commit
    // input                              rst_n                                                                             ,// if use seq please open the commit
    input      [  $clog2(PRF_NUM)-1:0] free_vec_write_out_ren2dis_uop_dest_preg_addr                     [ FETCH_WIDTH-1:0],// fire  
    input                              free_vec_write_out_ren2dis_uop_dest_preg_data                     [ FETCH_WIDTH-1:0],
    input                              free_vec_write_out_ren2dis_uop_dest_preg_en                       [ FETCH_WIDTH-1:0],     
    input      [  $clog2(PRF_NUM)-1:0] free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_addr  [COMMIT_WIDTH-1:0],// commit
    input                              free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_data  [COMMIT_WIDTH-1:0],
    input                              free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_en    [COMMIT_WIDTH-1:0],      
    input                              alloc_checkpoint_tag                                              [     PRF_NUM-1:0], 
    input                              in_dec_bcast_mispred                                                                ,             
    input                              in_rob_bcast_flush                                                                            ,// flush恢复
    input                              spec_alloc_normal                                                 [     PRF_NUM-1:0],
    input                              free_vec                                                          [     PRF_NUM-1:0],// test no seq
    output                             free_vec_1                                                        [     PRF_NUM-1:0],// test no seq
    output reg                         alloc_reg_valid                                                   [ FETCH_WIDTH-1:0],// 吐出4个或4个以下4个空闲寄存器的地址
    output reg [  $clog2(PRF_NUM)-1:0] alloc_reg                                                         [ FETCH_WIDTH-1:0]
);

reg [PRF_NUM-1:0] free_vec_arry;
genvar o;
generate
    for(o = 0; o < PRF_NUM; o++) begin
        assign free_vec_arry[o] = free_vec[o];
    end
endgenerate

// 输出前四个或四个以下空闲寄存器地址，并且输出有几个空闲寄存器
// reg [PRF_NUM-1:0] free_vec; // if use seq please open the below

reg [PRF_NUM-1:0] free_vec_n;
reg [PRF_NUM-1:0] one_hot_sub_1;
reg [$clog2(PRF_NUM)-1:0]  one_hot_add [PRF_NUM-1:0];
integer i;
integer j;
integer bank_shift;
always_comb begin // TODO,如果需要综合的话，这一段逻辑要改
    for(j = 0; j < FETCH_WIDTH; j++) begin
        bank_shift = (PRF_NUM/FETCH_WIDTH) * j;
        alloc_reg_valid[j] = |free_vec_arry[bank_shift+:(PRF_NUM/FETCH_WIDTH)];
        free_vec_n[bank_shift+:(PRF_NUM/FETCH_WIDTH)] = ~free_vec_arry[bank_shift+:(PRF_NUM/FETCH_WIDTH)] + 'd1;
        one_hot_sub_1[bank_shift+:(PRF_NUM/FETCH_WIDTH)] = (free_vec_n[bank_shift+:(PRF_NUM/FETCH_WIDTH)] & free_vec_arry[bank_shift+:(PRF_NUM/FETCH_WIDTH)]) - 'd1;
        one_hot_add[PRF_NUM/FETCH_WIDTH*j] = {6'd0, one_hot_sub_1[PRF_NUM/FETCH_WIDTH*j]};
        for(i = 0; i < PRF_NUM/FETCH_WIDTH - 1; i++) begin
            one_hot_add[i + bank_shift + 1] = one_hot_add[i + bank_shift] +{6'd0, one_hot_sub_1[i + bank_shift + 1]};
        end
        alloc_reg[j] = one_hot_add[PRF_NUM/FETCH_WIDTH*(j+1)-1] + bank_shift[$clog2(PRF_NUM)-1:0];
    end
end

// if use seq please add comment below 
reg free_vec_mispred [PRF_NUM-1:0];
reg free_vec_flush   [PRF_NUM-1:0];
reg free_vec_normal [PRF_NUM-1:0];
genvar n;
generate
    for(n = 0; n < PRF_NUM; n++) begin
        assign free_vec_flush  [n] = in_rob_bcast_flush ? (free_vec_normal[n] || spec_alloc_normal[n]) : free_vec[n];
        assign free_vec_mispred[n] = in_dec_bcast_mispred ? free_vec[n] || alloc_checkpoint_tag[n] : free_vec[n];
        assign free_vec_1      [n] = in_rob_bcast_flush ? free_vec_flush[n] : (in_dec_bcast_mispred ? free_vec_mispred[n] : free_vec_normal[n]);
    end
endgenerate

//reg free_vec_1 [PRF_NUM-1:0]; // if use seq please open the below comment
integer l;
integer m;
integer addr;

always_comb begin
    // for(m = 0; m < FETCH_WIDTH; m++) begin
        for(l = 0; l < PRF_NUM; l++) begin
            addr = l;
            if(free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_en[3] && free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_addr[3] == addr[$clog2(PRF_NUM)-1:0]) begin
                free_vec_normal[addr] = free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_data[3];
            end
            else if(free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_en[2] && free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_addr[2] == addr[$clog2(PRF_NUM)-1:0]) begin
                free_vec_normal[addr] = free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_data[2];
            end
            else if(free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_en[1] && free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_addr[1] == addr[$clog2(PRF_NUM)-1:0]) begin
                free_vec_normal[addr] = free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_data[1];
            end
            else if(free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_en[0] && free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_addr[0] == addr[$clog2(PRF_NUM)-1:0]) begin
                free_vec_normal[addr] = free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_data[0];
            end
            else if(free_vec_write_out_ren2dis_uop_dest_preg_en[3] && free_vec_write_out_ren2dis_uop_dest_preg_addr[3] == addr[$clog2(PRF_NUM)-1:0]) begin             
                free_vec_normal[addr] = free_vec_write_out_ren2dis_uop_dest_preg_data[3];
            end
            else if(free_vec_write_out_ren2dis_uop_dest_preg_en[2] && free_vec_write_out_ren2dis_uop_dest_preg_addr[2] == addr[$clog2(PRF_NUM)-1:0]) begin             
                free_vec_normal[addr] = free_vec_write_out_ren2dis_uop_dest_preg_data[2];
            end
            else if(free_vec_write_out_ren2dis_uop_dest_preg_en[1] && free_vec_write_out_ren2dis_uop_dest_preg_addr[1] == addr[$clog2(PRF_NUM)-1:0]) begin             
                free_vec_normal[addr] = free_vec_write_out_ren2dis_uop_dest_preg_data[1];
            end
            else if(free_vec_write_out_ren2dis_uop_dest_preg_en[0] && free_vec_write_out_ren2dis_uop_dest_preg_addr[0] == addr[$clog2(PRF_NUM)-1:0]) begin             
                free_vec_normal[addr] = free_vec_write_out_ren2dis_uop_dest_preg_data[0];
            end
            else begin
                free_vec_normal[addr] = free_vec[addr];
            end
        end
    // end
end




// if use seq please open the below
// integer k;
// always @(posedge clk or negedge rst_n) begin
//     if(~rst_n) begin
//         for(k = 0;k < PRF_NUM; k++) begin
//             if(k < ARF_NUM) begin
//                 free_vec[(k % FETCH_WIDTH) *  PRF_NUM / FETCH_WIDTH + k / FETCH_WIDTH] <= 'd0;
//             end
//             else begin
//                 free_vec[(k % FETCH_WIDTH) *  PRF_NUM / FETCH_WIDTH + k / FETCH_WIDTH] <= 'd1;
//             end
//         end
//     end
//     else begin
//         if(io_rob_bcast_flush) begin
//             for(k = 0; k < PRF_NUM; k++) begin
//                 free_vec[k] <= free_vec_1[k] || spec_alloc_1[k];
//             end
//         end
//         else begin
//             for(k = 0; k < PRF_NUM; k++) begin
//                 free_vec[k] <= free_vec_1[k];
//             end
//         end
//     end
// end

endmodule