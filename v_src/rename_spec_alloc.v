`timescale 1ns/1ps
module rename_spec_alloc
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
    // input                               clk                                                                              ,// if use seq please open the commit
    // input                               rst_n                                                                            ,// if use seq please open the commit
    input      [   $clog2(PRF_NUM)-1:0] spec_alloc_write_out_ren2dis_uop_dest_preg_addr                [ FETCH_WIDTH-1:0],
    input                               spec_alloc_write_out_ren2dis_uop_dest_preg_data                [ FETCH_WIDTH-1:0],
    input                               spec_alloc_write_out_ren2dis_uop_dest_preg_en                  [ FETCH_WIDTH-1:0],    
    input      [   $clog2(PRF_NUM)-1:0] spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_addr [COMMIT_WIDTH-1:0],
    input                               spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_data [COMMIT_WIDTH-1:0],
    input                               spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_en   [COMMIT_WIDTH-1:0],
    input                               alloc_checkpoint_tag                                           [     PRF_NUM-1:0],
    input                               in_dec_bcast_mispred                                                             ,
    input                               in_rob_bcast_flush                                                               ,
    input                               spec_alloc                                                     [     PRF_NUM-1:0], // test no seq
    output                              spec_alloc_1                                                   [     PRF_NUM-1:0],
    output reg                          spec_alloc_normal                                              [     PRF_NUM-1:0]
);

// reg spec_alloc [PRF_NUM-1:0]; // if use seq please open the below

// if use seq please add comment below 
wire spec_alloc_flush   [PRF_NUM-1:0];
wire spec_alloc_mispred [PRF_NUM-1:0];
genvar n;
generate
    for(n = 0; n < PRF_NUM; n++) begin
        assign spec_alloc_flush  [n] = in_rob_bcast_flush ? 'd0 : spec_alloc[n];
        assign spec_alloc_mispred[n] = in_dec_bcast_mispred ? (spec_alloc[n] && !alloc_checkpoint_tag[n]) : spec_alloc[n];
        assign spec_alloc_1      [n] = in_rob_bcast_flush ? spec_alloc_flush[n] : (in_dec_bcast_mispred ? spec_alloc_mispred[n] : spec_alloc_normal[n]);
    end
endgenerate

integer i;
integer j;
integer addr;
always_comb begin
    for(j = 0; j < FETCH_WIDTH; j++) begin
        for(i = 0;i < PRF_NUM/FETCH_WIDTH; i++) begin
            addr = i+PRF_NUM/FETCH_WIDTH*j;
            if(spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_en[j] && spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_addr[j] == addr[$clog2(PRF_NUM)-1:0]) begin
                spec_alloc_normal[addr] = spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_data[j];
            end
            else if(spec_alloc_write_out_ren2dis_uop_dest_preg_en[j] && spec_alloc_write_out_ren2dis_uop_dest_preg_addr[j] == addr[$clog2(PRF_NUM)-1:0]) begin
                spec_alloc_normal[addr] = spec_alloc_write_out_ren2dis_uop_dest_preg_data[j];
            end
            else begin
                spec_alloc_normal[addr] = spec_alloc[addr];
            end
        end
    end
end

// if use seq please open the below
// integer k;
// always @(posedge clk) begin
//     if(~rst_n) begin
//         for(k = 0;k < PRF_NUM; k++) begin
//             spec_alloc[k] <= 'd0;
//         end
//     end
//     else begin
//         if(in_rob_bcast_flush) begin
//             for(k = 0;k < PRF_NUM; k++) begin
//                 spec_alloc[k] <= 'd0;
//             end
//         end
//         else begin
//             for(k = 0;k < PRF_NUM; k++) begin
//                 spec_alloc[k] <= spec_alloc_1[k];
//             end
//         end
//     end
// end

endmodule