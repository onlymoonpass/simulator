`timescale 1ns/1ps
module rename_pipline
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
    // input                                 clk                                              ,// if use seq please open the commit
    // input                                 rst_n                                            ,// if use seq please open the commit
    input                           in_dec_bcast_mispred                                 ,
    input                           in_rob_bcast_flush                                   ,
    input                           out_ren2dec_ready                                    ,
    input                           fire                                [FETCH_WIDTH-1:0],

	input	[        CPU_WIDTH-1:0]	in_dec2ren_uop_instruction         	[FETCH_WIDTH-1:0],
	input	[    $clog2(ARF_NUM):0]	in_dec2ren_uop_dest_areg           	[FETCH_WIDTH-1:0],
	input	[    $clog2(ARF_NUM):0]	in_dec2ren_uop_src1_areg           	[FETCH_WIDTH-1:0],
	input	[    $clog2(ARF_NUM):0]	in_dec2ren_uop_src2_areg           	[FETCH_WIDTH-1:0],
	input	[  $clog2(PRF_NUM)-1:0]	in_dec2ren_uop_dest_preg           	[FETCH_WIDTH-1:0],
	input	[  $clog2(PRF_NUM)-1:0]	in_dec2ren_uop_src1_preg           	[FETCH_WIDTH-1:0],
	input	[  $clog2(PRF_NUM)-1:0]	in_dec2ren_uop_src2_preg           	[FETCH_WIDTH-1:0],
	input	[  $clog2(PRF_NUM)-1:0]	in_dec2ren_uop_old_dest_preg       	[FETCH_WIDTH-1:0],
	input	[        CPU_WIDTH-1:0]	in_dec2ren_uop_src1_rdata          	[FETCH_WIDTH-1:0],
	input	[        CPU_WIDTH-1:0]	in_dec2ren_uop_src2_rdata          	[FETCH_WIDTH-1:0],
	input	[        CPU_WIDTH-1:0]	in_dec2ren_uop_result              	[FETCH_WIDTH-1:0],
	input	[                1-1:0] in_dec2ren_uop_pred_br_taken        [FETCH_WIDTH-1:0],
	input	[                1-1:0] in_dec2ren_uop_alt_pred             [FETCH_WIDTH-1:0],
	input	[                8-1:0]	in_dec2ren_uop_altpcpn             	[FETCH_WIDTH-1:0],
	input	[                8-1:0]	in_dec2ren_uop_pcpn                	[FETCH_WIDTH-1:0],
	input	[        CPU_WIDTH-1:0]	in_dec2ren_uop_pred_br_pc          	[FETCH_WIDTH-1:0],
	input	[                1-1:0]	in_dec2ren_uop_mispred             	[FETCH_WIDTH-1:0],
	input	[                1-1:0]	in_dec2ren_uop_br_taken            	[FETCH_WIDTH-1:0],
	input	[        CPU_WIDTH-1:0]	in_dec2ren_uop_pc_next             	[FETCH_WIDTH-1:0],
	input	[                1-1:0]	in_dec2ren_uop_dest_en             	[FETCH_WIDTH-1:0],
	input	[                1-1:0]	in_dec2ren_uop_src1_en             	[FETCH_WIDTH-1:0],
	input	[                1-1:0]	in_dec2ren_uop_src2_en             	[FETCH_WIDTH-1:0],
	input	[                1-1:0]	in_dec2ren_uop_src1_busy           	[FETCH_WIDTH-1:0],
	input	[                1-1:0]	in_dec2ren_uop_src2_busy           	[FETCH_WIDTH-1:0],
	input	[                4-1:0]	in_dec2ren_uop_src1_latency        	[FETCH_WIDTH-1:0],
	input	[                4-1:0]	in_dec2ren_uop_src2_latency        	[FETCH_WIDTH-1:0],
	input	[                1-1:0]	in_dec2ren_uop_src1_is_pc          	[FETCH_WIDTH-1:0],
	input	[                1-1:0]	in_dec2ren_uop_src2_is_imm         	[FETCH_WIDTH-1:0],
	input	[      FUNC3_WIDTH-1:0]	in_dec2ren_uop_func3               	[FETCH_WIDTH-1:0],
	input	[                1-1:0]	in_dec2ren_uop_func7_5             	[FETCH_WIDTH-1:0],
	input	[        CPU_WIDTH-1:0]	in_dec2ren_uop_imm                 	[FETCH_WIDTH-1:0],
	input	[        CPU_WIDTH-1:0]	in_dec2ren_uop_pc                  	[FETCH_WIDTH-1:0],
	input	[                4-1:0]	in_dec2ren_uop_tag                 	[FETCH_WIDTH-1:0],
	input	[        CSR_WIDTH-1:0]	in_dec2ren_uop_csr_idx             	[FETCH_WIDTH-1:0],
	input	[  $clog2(ROB_NUM)-1:0]	in_dec2ren_uop_rob_idx             	[FETCH_WIDTH-1:0],
	input	[  $clog2(STQ_NUM)-1:0]	in_dec2ren_uop_stq_idx             	[FETCH_WIDTH-1:0],
	input	[               16-1:0]	in_dec2ren_uop_pre_sta_mask        	[FETCH_WIDTH-1:0],
	input	[               16-1:0]	in_dec2ren_uop_pre_std_mask        	[FETCH_WIDTH-1:0],
	input	[                2-1:0]	in_dec2ren_uop_uop_num             	[FETCH_WIDTH-1:0],
	input	[                2-1:0]	in_dec2ren_uop_cplt_num            	[FETCH_WIDTH-1:0],
	input	[                1-1:0]	in_dec2ren_uop_rob_flag            	[FETCH_WIDTH-1:0],
	input	[                1-1:0]	in_dec2ren_uop_page_fault_inst     	[FETCH_WIDTH-1:0],
	input	[                1-1:0]	in_dec2ren_uop_page_fault_load     	[FETCH_WIDTH-1:0],
	input	[                1-1:0]	in_dec2ren_uop_page_fault_store    	[FETCH_WIDTH-1:0],
	input	[                1-1:0]	in_dec2ren_uop_illegal_inst        	[FETCH_WIDTH-1:0],
	input	[ $clog2(TYPE_NUM)-1:0]	in_dec2ren_uop_type                	[FETCH_WIDTH-1:0],
	input	[   $clog2(OP_NUM)-1:0]	in_dec2ren_uop_op                  	[FETCH_WIDTH-1:0],
	input	[$clog2(AMOOP_NUM)-1:0]	in_dec2ren_uop_amoop               	[FETCH_WIDTH-1:0],
	input	[                1-1:0]	in_dec2ren_valid                   	[FETCH_WIDTH-1:0],                                                                                            


    
    output	[        CPU_WIDTH-1:0]	inst_r_1_uop_instruction           	[FETCH_WIDTH-1:0],
    output	[    $clog2(ARF_NUM):0]	inst_r_1_uop_dest_areg             	[FETCH_WIDTH-1:0],
    output	[    $clog2(ARF_NUM):0]	inst_r_1_uop_src1_areg             	[FETCH_WIDTH-1:0],
    output	[    $clog2(ARF_NUM):0]	inst_r_1_uop_src2_areg             	[FETCH_WIDTH-1:0],
    output	[  $clog2(PRF_NUM)-1:0]	inst_r_1_uop_dest_preg             	[FETCH_WIDTH-1:0],
    output	[  $clog2(PRF_NUM)-1:0]	inst_r_1_uop_src1_preg             	[FETCH_WIDTH-1:0],
    output	[  $clog2(PRF_NUM)-1:0]	inst_r_1_uop_src2_preg             	[FETCH_WIDTH-1:0],
    output	[  $clog2(PRF_NUM)-1:0]	inst_r_1_uop_old_dest_preg         	[FETCH_WIDTH-1:0],
    output	[        CPU_WIDTH-1:0]	inst_r_1_uop_src1_rdata            	[FETCH_WIDTH-1:0],
    output	[        CPU_WIDTH-1:0]	inst_r_1_uop_src2_rdata            	[FETCH_WIDTH-1:0],
    output	[        CPU_WIDTH-1:0]	inst_r_1_uop_result                	[FETCH_WIDTH-1:0],
    output	[                1-1:0]	inst_r_1_uop_pred_br_taken         	[FETCH_WIDTH-1:0],
    output	[                1-1:0]	inst_r_1_uop_alt_pred              	[FETCH_WIDTH-1:0],
    output	[                8-1:0]	inst_r_1_uop_altpcpn               	[FETCH_WIDTH-1:0],
    output	[                8-1:0]	inst_r_1_uop_pcpn                  	[FETCH_WIDTH-1:0],
    output	[        CPU_WIDTH-1:0]	inst_r_1_uop_pred_br_pc            	[FETCH_WIDTH-1:0],
    output	[                1-1:0]	inst_r_1_uop_mispred               	[FETCH_WIDTH-1:0],
    output	[                1-1:0]	inst_r_1_uop_br_taken              	[FETCH_WIDTH-1:0],
    output	[        CPU_WIDTH-1:0]	inst_r_1_uop_pc_next               	[FETCH_WIDTH-1:0],
    output	[                1-1:0]	inst_r_1_uop_dest_en               	[FETCH_WIDTH-1:0],
    output	[                1-1:0]	inst_r_1_uop_src1_en               	[FETCH_WIDTH-1:0],
    output	[                1-1:0]	inst_r_1_uop_src2_en               	[FETCH_WIDTH-1:0],
    output	[                1-1:0]	inst_r_1_uop_src1_busy             	[FETCH_WIDTH-1:0],
    output	[                1-1:0]	inst_r_1_uop_src2_busy             	[FETCH_WIDTH-1:0],
    output	[                4-1:0]	inst_r_1_uop_src1_latency          	[FETCH_WIDTH-1:0],
    output	[                4-1:0]	inst_r_1_uop_src2_latency          	[FETCH_WIDTH-1:0],
    output	[                1-1:0]	inst_r_1_uop_src1_is_pc            	[FETCH_WIDTH-1:0],
    output	[                1-1:0]	inst_r_1_uop_src2_is_imm           	[FETCH_WIDTH-1:0],
    output	[      FUNC3_WIDTH-1:0]	inst_r_1_uop_func3                 	[FETCH_WIDTH-1:0],
    output	[                1-1:0]	inst_r_1_uop_func7_5               	[FETCH_WIDTH-1:0],
    output	[        CPU_WIDTH-1:0]	inst_r_1_uop_imm                   	[FETCH_WIDTH-1:0],
    output	[        CPU_WIDTH-1:0]	inst_r_1_uop_pc                    	[FETCH_WIDTH-1:0],
    output	[                4-1:0]	inst_r_1_uop_tag                   	[FETCH_WIDTH-1:0],
    output	[        CSR_WIDTH-1:0]	inst_r_1_uop_csr_idx               	[FETCH_WIDTH-1:0],
    output	[  $clog2(ROB_NUM)-1:0]	inst_r_1_uop_rob_idx               	[FETCH_WIDTH-1:0],
    output	[  $clog2(STQ_NUM)-1:0]	inst_r_1_uop_stq_idx               	[FETCH_WIDTH-1:0],
    output	[               16-1:0]	inst_r_1_uop_pre_sta_mask          	[FETCH_WIDTH-1:0],
    output	[               16-1:0]	inst_r_1_uop_pre_std_mask          	[FETCH_WIDTH-1:0],
    output	[                2-1:0]	inst_r_1_uop_uop_num               	[FETCH_WIDTH-1:0],
    output	[                2-1:0]	inst_r_1_uop_cplt_num              	[FETCH_WIDTH-1:0],
    output	[                1-1:0]	inst_r_1_uop_rob_flag              	[FETCH_WIDTH-1:0],
    output	[                1-1:0]	inst_r_1_uop_page_fault_inst       	[FETCH_WIDTH-1:0],
    output	[                1-1:0]	inst_r_1_uop_page_fault_load       	[FETCH_WIDTH-1:0],
    output	[                1-1:0]	inst_r_1_uop_page_fault_store      	[FETCH_WIDTH-1:0],
    output	[                1-1:0]	inst_r_1_uop_illegal_inst          	[FETCH_WIDTH-1:0],
    output	[ $clog2(TYPE_NUM)-1:0]	inst_r_1_uop_type                  	[FETCH_WIDTH-1:0],
    output	[   $clog2(OP_NUM)-1:0]	inst_r_1_uop_op                    	[FETCH_WIDTH-1:0],
    output	[$clog2(AMOOP_NUM)-1:0]	inst_r_1_uop_amoop                 	[FETCH_WIDTH-1:0],   
    output	[                1-1:0]	inst_r_1_valid                     	[FETCH_WIDTH-1:0],
  
    input	[        CPU_WIDTH-1:0]	inst_r_uop_instruction           	[FETCH_WIDTH-1:0],
    input	[    $clog2(ARF_NUM):0]	inst_r_uop_dest_areg             	[FETCH_WIDTH-1:0],
    input	[    $clog2(ARF_NUM):0]	inst_r_uop_src1_areg             	[FETCH_WIDTH-1:0],
    input	[    $clog2(ARF_NUM):0]	inst_r_uop_src2_areg             	[FETCH_WIDTH-1:0],
    input	[  $clog2(PRF_NUM)-1:0]	inst_r_uop_dest_preg             	[FETCH_WIDTH-1:0],
    input	[  $clog2(PRF_NUM)-1:0]	inst_r_uop_src1_preg             	[FETCH_WIDTH-1:0],
    input	[  $clog2(PRF_NUM)-1:0]	inst_r_uop_src2_preg             	[FETCH_WIDTH-1:0],
    input	[  $clog2(PRF_NUM)-1:0]	inst_r_uop_old_dest_preg         	[FETCH_WIDTH-1:0],
    input	[        CPU_WIDTH-1:0]	inst_r_uop_src1_rdata            	[FETCH_WIDTH-1:0],
    input	[        CPU_WIDTH-1:0]	inst_r_uop_src2_rdata            	[FETCH_WIDTH-1:0],
    input	[        CPU_WIDTH-1:0]	inst_r_uop_result                	[FETCH_WIDTH-1:0],
    input	[                1-1:0]	inst_r_uop_pred_br_taken         	[FETCH_WIDTH-1:0],
    input	[                1-1:0]	inst_r_uop_alt_pred              	[FETCH_WIDTH-1:0],
    input	[                8-1:0]	inst_r_uop_altpcpn               	[FETCH_WIDTH-1:0],
    input	[                8-1:0]	inst_r_uop_pcpn                  	[FETCH_WIDTH-1:0],
    input	[        CPU_WIDTH-1:0]	inst_r_uop_pred_br_pc            	[FETCH_WIDTH-1:0],
    input	[                1-1:0]	inst_r_uop_mispred               	[FETCH_WIDTH-1:0],
    input	[                1-1:0]	inst_r_uop_br_taken              	[FETCH_WIDTH-1:0],
    input	[        CPU_WIDTH-1:0]	inst_r_uop_pc_next               	[FETCH_WIDTH-1:0],
    input	[                1-1:0]	inst_r_uop_dest_en               	[FETCH_WIDTH-1:0],
    input	[                1-1:0]	inst_r_uop_src1_en               	[FETCH_WIDTH-1:0],
    input	[                1-1:0]	inst_r_uop_src2_en               	[FETCH_WIDTH-1:0],
    input	[                1-1:0]	inst_r_uop_src1_busy             	[FETCH_WIDTH-1:0],
    input	[                1-1:0]	inst_r_uop_src2_busy             	[FETCH_WIDTH-1:0],
    input	[                4-1:0]	inst_r_uop_src1_latency          	[FETCH_WIDTH-1:0],
    input	[                4-1:0]	inst_r_uop_src2_latency          	[FETCH_WIDTH-1:0],
    input	[                1-1:0]	inst_r_uop_src1_is_pc            	[FETCH_WIDTH-1:0],
    input	[                1-1:0]	inst_r_uop_src2_is_imm           	[FETCH_WIDTH-1:0],
    input	[      FUNC3_WIDTH-1:0]	inst_r_uop_func3                 	[FETCH_WIDTH-1:0],
    input	[                1-1:0]	inst_r_uop_func7_5               	[FETCH_WIDTH-1:0],
    input	[        CPU_WIDTH-1:0]	inst_r_uop_imm                   	[FETCH_WIDTH-1:0],
    input	[        CPU_WIDTH-1:0]	inst_r_uop_pc                    	[FETCH_WIDTH-1:0],
    input	[                4-1:0]	inst_r_uop_tag                   	[FETCH_WIDTH-1:0],
    input	[        CSR_WIDTH-1:0]	inst_r_uop_csr_idx               	[FETCH_WIDTH-1:0],
    input	[  $clog2(ROB_NUM)-1:0]	inst_r_uop_rob_idx               	[FETCH_WIDTH-1:0],
    input	[  $clog2(STQ_NUM)-1:0]	inst_r_uop_stq_idx               	[FETCH_WIDTH-1:0],
    input	[               16-1:0]	inst_r_uop_pre_sta_mask          	[FETCH_WIDTH-1:0],
    input	[               16-1:0]	inst_r_uop_pre_std_mask          	[FETCH_WIDTH-1:0],
    input	[                2-1:0]	inst_r_uop_uop_num               	[FETCH_WIDTH-1:0],
    input	[                2-1:0]	inst_r_uop_cplt_num              	[FETCH_WIDTH-1:0],
    input	[                1-1:0]	inst_r_uop_rob_flag              	[FETCH_WIDTH-1:0],
    input	[                1-1:0]	inst_r_uop_page_fault_inst       	[FETCH_WIDTH-1:0],
    input	[                1-1:0]	inst_r_uop_page_fault_load       	[FETCH_WIDTH-1:0],
    input	[                1-1:0]	inst_r_uop_page_fault_store      	[FETCH_WIDTH-1:0],
    input	[                1-1:0]	inst_r_uop_illegal_inst          	[FETCH_WIDTH-1:0],
    input	[ $clog2(TYPE_NUM)-1:0]	inst_r_uop_type                  	[FETCH_WIDTH-1:0],
    input	[   $clog2(OP_NUM)-1:0]	inst_r_uop_op                    	[FETCH_WIDTH-1:0],
    input	[$clog2(AMOOP_NUM)-1:0]	inst_r_uop_amoop                 	[FETCH_WIDTH-1:0],   
    input	[                1-1:0]	inst_r_valid                     	[FETCH_WIDTH-1:0]
);

genvar i;
generate
    for(i = 0; i < FETCH_WIDTH; i++) begin
        assign inst_r_1_valid[i] = (in_dec_bcast_mispred || in_rob_bcast_flush) ? 'd0 : (out_ren2dec_ready ? in_dec2ren_valid[i] : (inst_r_valid[i] && !fire[i]));
        assign inst_r_1_uop_instruction     [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_instruction     [i] : inst_r_uop_instruction     [i];
        assign inst_r_1_uop_dest_areg       [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_dest_areg       [i] : inst_r_uop_dest_areg       [i];
        assign inst_r_1_uop_src1_areg       [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_src1_areg       [i] : inst_r_uop_src1_areg       [i];
        assign inst_r_1_uop_src2_areg       [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_src2_areg       [i] : inst_r_uop_src2_areg       [i];
        assign inst_r_1_uop_dest_preg       [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_dest_preg       [i] : inst_r_uop_dest_preg       [i];
        assign inst_r_1_uop_src1_preg       [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_src1_preg       [i] : inst_r_uop_src1_preg       [i];
        assign inst_r_1_uop_src2_preg       [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_src2_preg       [i] : inst_r_uop_src2_preg       [i];
        assign inst_r_1_uop_old_dest_preg   [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_old_dest_preg   [i] : inst_r_uop_old_dest_preg   [i];
        assign inst_r_1_uop_src1_rdata      [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_src1_rdata      [i] : inst_r_uop_src1_rdata      [i];
        assign inst_r_1_uop_src2_rdata      [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_src2_rdata      [i] : inst_r_uop_src2_rdata      [i];
        assign inst_r_1_uop_result          [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_result          [i] : inst_r_uop_result          [i];
        assign inst_r_1_uop_pred_br_taken   [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_pred_br_taken   [i] : inst_r_uop_pred_br_taken   [i];
        assign inst_r_1_uop_alt_pred        [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_alt_pred        [i] : inst_r_uop_alt_pred        [i];
        assign inst_r_1_uop_altpcpn         [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_altpcpn         [i] : inst_r_uop_altpcpn         [i];
        assign inst_r_1_uop_pcpn            [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_pcpn            [i] : inst_r_uop_pcpn            [i];
        assign inst_r_1_uop_pred_br_pc      [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_pred_br_pc      [i] : inst_r_uop_pred_br_pc      [i];
        assign inst_r_1_uop_mispred         [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_mispred         [i] : inst_r_uop_mispred         [i];
        assign inst_r_1_uop_br_taken        [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_br_taken        [i] : inst_r_uop_br_taken        [i];
        assign inst_r_1_uop_pc_next         [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_pc_next         [i] : inst_r_uop_pc_next         [i];
        assign inst_r_1_uop_dest_en         [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_dest_en         [i] : inst_r_uop_dest_en         [i];
        assign inst_r_1_uop_src1_en         [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_src1_en         [i] : inst_r_uop_src1_en         [i];
        assign inst_r_1_uop_src2_en         [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_src2_en         [i] : inst_r_uop_src2_en         [i];
        assign inst_r_1_uop_src1_busy       [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_src1_busy       [i] : inst_r_uop_src1_busy       [i];
        assign inst_r_1_uop_src2_busy       [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_src2_busy       [i] : inst_r_uop_src2_busy       [i];
        assign inst_r_1_uop_src1_latency    [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_src1_latency    [i] : inst_r_uop_src1_latency    [i];
        assign inst_r_1_uop_src2_latency    [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_src2_latency    [i] : inst_r_uop_src2_latency    [i];
        assign inst_r_1_uop_src1_is_pc      [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_src1_is_pc      [i] : inst_r_uop_src1_is_pc      [i];
        assign inst_r_1_uop_src2_is_imm     [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_src2_is_imm     [i] : inst_r_uop_src2_is_imm     [i];
        assign inst_r_1_uop_func3           [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_func3           [i] : inst_r_uop_func3           [i];
        assign inst_r_1_uop_func7_5         [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_func7_5         [i] : inst_r_uop_func7_5         [i];
        assign inst_r_1_uop_imm             [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_imm             [i] : inst_r_uop_imm             [i];
        assign inst_r_1_uop_pc              [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_pc              [i] : inst_r_uop_pc              [i];
        assign inst_r_1_uop_tag             [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_tag             [i] : inst_r_uop_tag             [i];
        assign inst_r_1_uop_csr_idx         [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_csr_idx         [i] : inst_r_uop_csr_idx         [i];
        assign inst_r_1_uop_rob_idx         [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_rob_idx         [i] : inst_r_uop_rob_idx         [i];
        assign inst_r_1_uop_stq_idx         [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_stq_idx         [i] : inst_r_uop_stq_idx         [i];
        assign inst_r_1_uop_pre_sta_mask    [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_pre_sta_mask    [i] : inst_r_uop_pre_sta_mask    [i];
        assign inst_r_1_uop_pre_std_mask    [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_pre_std_mask    [i] : inst_r_uop_pre_std_mask    [i];
        assign inst_r_1_uop_uop_num         [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_uop_num         [i] : inst_r_uop_uop_num         [i];
        assign inst_r_1_uop_cplt_num        [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_cplt_num        [i] : inst_r_uop_cplt_num        [i];
        assign inst_r_1_uop_rob_flag        [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_rob_flag        [i] : inst_r_uop_rob_flag        [i];
        assign inst_r_1_uop_page_fault_inst [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_page_fault_inst [i] : inst_r_uop_page_fault_inst [i];
        assign inst_r_1_uop_page_fault_load [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_page_fault_load [i] : inst_r_uop_page_fault_load [i];
        assign inst_r_1_uop_page_fault_store[i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_page_fault_store[i] : inst_r_uop_page_fault_store[i];
        assign inst_r_1_uop_illegal_inst    [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_illegal_inst    [i] : inst_r_uop_illegal_inst    [i];
        assign inst_r_1_uop_type            [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_type            [i] : inst_r_uop_type            [i];
        assign inst_r_1_uop_op              [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_op              [i] : inst_r_uop_op              [i];
        assign inst_r_1_uop_amoop           [i] = (~(in_dec_bcast_mispred || in_rob_bcast_flush) && out_ren2dec_ready) ? in_dec2ren_uop_amoop           [i] : inst_r_uop_amoop           [i];
    end
endgenerate

// if use seq please open the below
// genvar j;
// generate
//     for(j = 0; j < FETCH_WIDTH; j++) begin
//         always @(posedge clk or negedge rst_n) begin
//             if(~rst_n) begin
//                 inst_r_valid               [j] = 'd0;
//                 inst_r_uop_instruction     [j] = 'd0;
//                 inst_r_uop_dest_areg       [j] = 'd0;
//                 inst_r_uop_src1_areg       [j] = 'd0;
//                 inst_r_uop_src2_areg       [j] = 'd0;
//                 inst_r_uop_dest_preg       [j] = 'd0;
//                 inst_r_uop_src1_preg       [j] = 'd0;
//                 inst_r_uop_src2_preg       [j] = 'd0;
//                 inst_r_uop_old_dest_preg   [j] = 'd0;
//                 inst_r_uop_src1_rdata      [j] = 'd0;
//                 inst_r_uop_src2_rdata      [j] = 'd0;
//                 inst_r_uop_result          [j] = 'd0;
//                 inst_r_uop_pred_br_taken   [j] = 'd0;
//                 inst_r_uop_pred_alt_pred   [j] = 'd0;
//                 inst_r_uop_pred_pcpn       [j] = 'd0;
//                 inst_r_uop_pred_br_pc      [j] = 'd0;
//                 inst_r_uop_mispred         [j] = 'd0;
//                 inst_r_uop_br_taken        [j] = 'd0;
//                 inst_r_uop_pc_next         [j] = 'd0;
//                 inst_r_uop_dest_en         [j] = 'd0;
//                 inst_r_uop_src1_en         [j] = 'd0;
//                 inst_r_uop_src2_en         [j] = 'd0;
//                 inst_r_uop_src1_busy       [j] = 'd0;
//                 inst_r_uop_src2_busy       [j] = 'd0;
//                 inst_r_uop_src1_is_pc      [j] = 'd0;
//                 inst_r_uop_src2_is_imm     [j] = 'd0;
//                 inst_r_uop_func3           [j] = 'd0;
//                 inst_r_uop_func7_5         [j] = 'd0;
//                 inst_r_uop_imm             [j] = 'd0;
//                 inst_r_uop_pc              [j] = 'd0;
//                 inst_r_uop_tag             [j] = 'd0;
//                 inst_r_uop_csr_idx         [j] = 'd0;
//                 inst_r_uop_rob_idx         [j] = 'd0;
//                 inst_r_uop_stq_idx         [j] = 'd0;
//                 inst_r_uop_pre_sta_mask    [j] = 'd0;
//                 inst_r_uop_pre_std_mask    [j] = 'd0;
//                 inst_r_uop_uop_num         [j] = 'd0;
//                 inst_r_uop_cmp_num         [j] = 'd0;
//                 inst_r_uop_page_fault_inst [j] = 'd0;
//                 inst_r_uop_page_fault_load [j] = 'd0;
//                 inst_r_uop_page_fault_store[j] = 'd0;
//                 inst_r_uop_illegal_inst    [j] = 'd0;
//                 inst_r_uop_type            [j] = 'd0;
//                 inst_r_uop_op              [j] = 'd0;
//                 inst_r_uop_amoop           [j] = 'd0;
//                 inst_r_uop_difftest_skip   [j] = 'd0;
//                 inst_r_uop_inst_idx        [j] = 'd0;
//             end
//             else begin
//                 inst_r_valid               [j] = inst_r_1_valid               [j];
//                 inst_r_uop_instruction     [j] = inst_r_1_uop_instruction     [j];
//                 inst_r_uop_dest_areg       [j] = inst_r_1_uop_dest_areg       [j];
//                 inst_r_uop_src1_areg       [j] = inst_r_1_uop_src1_areg       [j];
//                 inst_r_uop_src2_areg       [j] = inst_r_1_uop_src2_areg       [j];
//                 inst_r_uop_dest_preg       [j] = inst_r_1_uop_dest_preg       [j];
//                 inst_r_uop_src1_preg       [j] = inst_r_1_uop_src1_preg       [j];
//                 inst_r_uop_src2_preg       [j] = inst_r_1_uop_src2_preg       [j];
//                 inst_r_uop_old_dest_preg   [j] = inst_r_1_uop_old_dest_preg   [j];
//                 inst_r_uop_src1_rdata      [j] = inst_r_1_uop_src1_rdata      [j];
//                 inst_r_uop_src2_rdata      [j] = inst_r_1_uop_src2_rdata      [j];
//                 inst_r_uop_result          [j] = inst_r_1_uop_result          [j];
//                 inst_r_uop_pred_br_taken   [j] = inst_r_1_uop_pred_br_taken   [j];
//                 inst_r_uop_pred_alt_pred   [j] = inst_r_1_uop_pred_alt_pred   [j];
//                 inst_r_uop_pred_pcpn       [j] = inst_r_1_uop_pred_pcpn       [j];
//                 inst_r_uop_pred_br_pc      [j] = inst_r_1_uop_pred_br_pc      [j];
//                 inst_r_uop_mispred         [j] = inst_r_1_uop_mispred         [j];
//                 inst_r_uop_br_taken        [j] = inst_r_1_uop_br_taken        [j];
//                 inst_r_uop_pc_next         [j] = inst_r_1_uop_pc_next         [j];
//                 inst_r_uop_dest_en         [j] = inst_r_1_uop_dest_en         [j];
//                 inst_r_uop_src1_en         [j] = inst_r_1_uop_src1_en         [j];
//                 inst_r_uop_src2_en         [j] = inst_r_1_uop_src2_en         [j];
//                 inst_r_uop_src1_busy       [j] = inst_r_1_uop_src1_busy       [j];
//                 inst_r_uop_src2_busy       [j] = inst_r_1_uop_src2_busy       [j];
//                 inst_r_uop_src1_is_pc      [j] = inst_r_1_uop_src1_is_pc      [j];
//                 inst_r_uop_src2_is_imm     [j] = inst_r_1_uop_src2_is_imm     [j];
//                 inst_r_uop_func3           [j] = inst_r_1_uop_func3           [j];
//                 inst_r_uop_func7_5         [j] = inst_r_1_uop_func7_5         [j];
//                 inst_r_uop_imm             [j] = inst_r_1_uop_imm             [j];
//                 inst_r_uop_pc              [j] = inst_r_1_uop_pc              [j];
//                 inst_r_uop_tag             [j] = inst_r_1_uop_tag             [j];
//                 inst_r_uop_csr_idx         [j] = inst_r_1_uop_csr_idx         [j];
//                 inst_r_uop_rob_idx         [j] = inst_r_1_uop_rob_idx         [j];
//                 inst_r_uop_stq_idx         [j] = inst_r_1_uop_stq_idx         [j];
//                 inst_r_uop_pre_sta_mask    [j] = inst_r_1_uop_pre_sta_mask    [j];
//                 inst_r_uop_pre_std_mask    [j] = inst_r_1_uop_pre_std_mask    [j];
//                 inst_r_uop_uop_num         [j] = inst_r_1_uop_uop_num         [j];
//                 inst_r_uop_cmp_num         [j] = inst_r_1_uop_cmp_num         [j];
//                 inst_r_uop_page_fault_inst [j] = inst_r_1_uop_page_fault_inst [j];
//                 inst_r_uop_page_fault_load [j] = inst_r_1_uop_page_fault_load [j];
//                 inst_r_uop_page_fault_store[j] = inst_r_1_uop_page_fault_store[j];
//                 inst_r_uop_illegal_inst    [j] = inst_r_1_uop_illegal_inst    [j];
//                 inst_r_uop_type            [j] = inst_r_1_uop_type            [j];
//                 inst_r_uop_op              [j] = inst_r_1_uop_op              [j];
//                 inst_r_uop_amoop           [j] = inst_r_1_uop_amoop           [j];
//                 inst_r_uop_difftest_skip   [j] = inst_r_1_uop_difftest_skip   [j];
//                 inst_r_uop_inst_idx        [j] = inst_r_1_uop_inst_idx        [j];
//             end
//         end
//     end
// endgenerate
endmodule