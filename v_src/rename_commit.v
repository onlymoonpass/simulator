`timescale 1ns/1ps
module rename_commit
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
    input                        in_rob_commit_commit_entry_valid                                 [COMMIT_WIDTH-1:0],
    input                        in_rob_commit_commit_entry_uop_dest_en                           [COMMIT_WIDTH-1:0],
    input                        in_rob_commit_commit_entry_uop_page_fault_load                   [COMMIT_WIDTH-1:0],
    input                        in_rob_bcast_interrupt                                                             ,
    input                        in_rob_bcast_illegal_inst                                                          ,

    input  [$clog2(PRF_NUM)-1:0] in_rob_commit_commit_entry_uop_old_dest_preg                     [COMMIT_WIDTH-1:0],
    output [$clog2(PRF_NUM)-1:0] free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_addr [COMMIT_WIDTH-1:0],
    output                       free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_data [COMMIT_WIDTH-1:0],
    output                       free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_en   [COMMIT_WIDTH-1:0], 

    input  [$clog2(PRF_NUM)-1:0] in_rob_commit_commit_entry_uop_dest_preg                         [COMMIT_WIDTH-1:0],
    output [$clog2(PRF_NUM)-1:0] spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_addr   [COMMIT_WIDTH-1:0],
    output                       spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_data   [COMMIT_WIDTH-1:0],
    output                       spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_en     [COMMIT_WIDTH-1:0],

    input  [  $clog2(ARF_NUM):0] in_rob_commit_commit_entry_uop_dest_areg     	                  [COMMIT_WIDTH-1:0],
    output [  $clog2(ARF_NUM):0] arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_addr     [COMMIT_WIDTH-1:0],
    output [$clog2(PRF_NUM)-1:0] arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_data     [COMMIT_WIDTH-1:0],
    output                       arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_en       [COMMIT_WIDTH-1:0]
);

genvar i;
generate
    for(i = 0; i < COMMIT_WIDTH; i++) begin
        assign free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_addr[i] = in_rob_commit_commit_entry_uop_old_dest_preg[i];
        assign free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_data[i] = 'd1;
        assign free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_en  [i] = in_rob_commit_commit_entry_valid[i] && 
                                                                                     in_rob_commit_commit_entry_uop_dest_en[i] &&
                                                                                     ~in_rob_commit_commit_entry_uop_page_fault_load[i] &&
                                                                                     ~in_rob_bcast_interrupt &&
                                                                                     ~in_rob_bcast_illegal_inst;
        assign spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_addr[i] = in_rob_commit_commit_entry_uop_dest_preg[i];
        assign spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_data[i] = 'd0;
        assign spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_en  [i] = in_rob_commit_commit_entry_valid[i] && 
                                                                                   in_rob_commit_commit_entry_uop_dest_en[i] &&
                                                                                   ~in_rob_commit_commit_entry_uop_page_fault_load[i] &&
                                                                                   ~in_rob_bcast_interrupt &&
                                                                                   ~in_rob_bcast_illegal_inst;    
        assign arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_addr[i] = in_rob_commit_commit_entry_uop_dest_areg[i];
        assign arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_data[i] = in_rob_commit_commit_entry_uop_dest_preg[i];
        assign arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_en  [i] = in_rob_commit_commit_entry_valid[i] && 
                                                                                   in_rob_commit_commit_entry_uop_dest_en[i] &&
                                                                                   ~in_rob_commit_commit_entry_uop_page_fault_load[i] &&
                                                                                   ~in_rob_bcast_interrupt;   
    end
endgenerate

endmodule