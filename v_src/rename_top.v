`timescale 1ns/1ps
module rename_top
#(
    parameter PRF_NUM      = 128,
    parameter ROB_NUM      = 128,
    parameter STQ_NUM      = 16 ,
    parameter OP_NUM       = 14 ,
    parameter FETCH_WIDTH  = 4  ,
    parameter COMMIT_WIDTH = 4  ,
    parameter ARF_NUM      = 32 ,
    parameter MAX_BR_NUM   = 16 ,
    parameter ALU_NUM      = 2  ,
    parameter AMOOP_NUM    = 12 ,
    parameter CPU_WIDTH    = 32 ,
    parameter FUNC3_WIDTH  = 3  ,
    parameter CSR_WIDTH    = 12 ,
    parameter TYPE_NUM     = 16    
)
(
// 下面是根据C++的.h自动生成的接口
	input	[32-1:0]	in_dec2ren_uop_instruction                   	[   4-1:0],
	input	[ 6-1:0]	in_dec2ren_uop_dest_areg                     	[   4-1:0],
	input	[ 6-1:0]	in_dec2ren_uop_src1_areg                     	[   4-1:0],
	input	[ 6-1:0]	in_dec2ren_uop_src2_areg                     	[   4-1:0],
	input	[ 7-1:0]	in_dec2ren_uop_dest_preg                     	[   4-1:0],
	input	[ 7-1:0]	in_dec2ren_uop_src1_preg                     	[   4-1:0],
	input	[ 7-1:0]	in_dec2ren_uop_src2_preg                     	[   4-1:0],
	input	[ 7-1:0]	in_dec2ren_uop_old_dest_preg                 	[   4-1:0],
	input	[32-1:0]	in_dec2ren_uop_src1_rdata                    	[   4-1:0],
	input	[32-1:0]	in_dec2ren_uop_src2_rdata                    	[   4-1:0],
	input	[32-1:0]	in_dec2ren_uop_result                        	[   4-1:0],
	input	[ 1-1:0]	in_dec2ren_uop_pred_br_taken                 	[   4-1:0],
	input	[ 1-1:0]	in_dec2ren_uop_alt_pred                      	[   4-1:0],
	input	[ 8-1:0]	in_dec2ren_uop_altpcpn                       	[   4-1:0],
	input	[ 8-1:0]	in_dec2ren_uop_pcpn                          	[   4-1:0],
	input	[32-1:0]	in_dec2ren_uop_pred_br_pc                    	[   4-1:0],
	input	[ 1-1:0]	in_dec2ren_uop_mispred                       	[   4-1:0],
	input	[ 1-1:0]	in_dec2ren_uop_br_taken                      	[   4-1:0],
	input	[32-1:0]	in_dec2ren_uop_pc_next                       	[   4-1:0],
	input	[ 1-1:0]	in_dec2ren_uop_dest_en                       	[   4-1:0],
	input	[ 1-1:0]	in_dec2ren_uop_src1_en                       	[   4-1:0],
	input	[ 1-1:0]	in_dec2ren_uop_src2_en                       	[   4-1:0],
	input	[ 1-1:0]	in_dec2ren_uop_src1_busy                     	[   4-1:0],
	input	[ 1-1:0]	in_dec2ren_uop_src2_busy                     	[   4-1:0],
	input	[ 4-1:0]	in_dec2ren_uop_src1_latency                  	[   4-1:0],
	input	[ 4-1:0]	in_dec2ren_uop_src2_latency                  	[   4-1:0],
	input	[ 1-1:0]	in_dec2ren_uop_src1_is_pc                    	[   4-1:0],
	input	[ 1-1:0]	in_dec2ren_uop_src2_is_imm                   	[   4-1:0],
	input	[ 3-1:0]	in_dec2ren_uop_func3                         	[   4-1:0],
	input	[ 1-1:0]	in_dec2ren_uop_func7_5                       	[   4-1:0],
	input	[32-1:0]	in_dec2ren_uop_imm                           	[   4-1:0],
	input	[32-1:0]	in_dec2ren_uop_pc                            	[   4-1:0],
	input	[ 4-1:0]	in_dec2ren_uop_tag                           	[   4-1:0],
	input	[12-1:0]	in_dec2ren_uop_csr_idx                       	[   4-1:0],
	input	[ 7-1:0]	in_dec2ren_uop_rob_idx                       	[   4-1:0],
	input	[ 4-1:0]	in_dec2ren_uop_stq_idx                       	[   4-1:0],
	input	[16-1:0]	in_dec2ren_uop_pre_sta_mask                  	[   4-1:0],
	input	[16-1:0]	in_dec2ren_uop_pre_std_mask                  	[   4-1:0],
	input	[ 2-1:0]	in_dec2ren_uop_uop_num                       	[   4-1:0],
	input	[ 2-1:0]	in_dec2ren_uop_cplt_num                      	[   4-1:0],
	input	[ 1-1:0]	in_dec2ren_uop_rob_flag                      	[   4-1:0],
	input	[ 1-1:0]	in_dec2ren_uop_page_fault_inst               	[   4-1:0],
	input	[ 1-1:0]	in_dec2ren_uop_page_fault_load               	[   4-1:0],
	input	[ 1-1:0]	in_dec2ren_uop_page_fault_store              	[   4-1:0],
	input	[ 1-1:0]	in_dec2ren_uop_illegal_inst                  	[   4-1:0],
	input	[ 4-1:0]	in_dec2ren_uop_type                          	[   4-1:0],
	input	[ 4-1:0]	in_dec2ren_uop_op                            	[   4-1:0],
	input	[ 4-1:0]	in_dec2ren_uop_amoop                         	[   4-1:0],
	input	[ 1-1:0]	in_dec2ren_valid                             	[   4-1:0],
	input	[ 1-1:0]	in_dec_bcast_mispred                         	          ,
	input	[16-1:0]	in_dec_bcast_br_mask                         	          ,
	input	[ 4-1:0]	in_dec_bcast_br_tag                          	          ,
	input	[ 7-1:0]	in_dec_bcast_redirect_rob_idx                	          ,
	input	[ 1-1:0]	in_iss_awake_wake_valid                      	[   2-1:0],
	input	[ 7-1:0]	in_iss_awake_wake_preg                       	[   2-1:0],
	input	[ 2-1:0]	in_iss_awake_wake_latency                    	[   2-1:0],
	input	[ 1-1:0]	in_prf_awake_wake_valid                      	          ,
	input	[ 7-1:0]	in_prf_awake_wake_preg                       	          ,
	input	[ 2-1:0]	in_prf_awake_wake_latency                    	          ,
	input	[ 1-1:0]	in_dis2ren_ready                             	          ,
	input	[ 1-1:0]	in_rob_bcast_flush                           	          ,
	input	[ 1-1:0]	in_rob_bcast_mret                            	          ,
	input	[ 1-1:0]	in_rob_bcast_sret                            	          ,
	input	[ 1-1:0]	in_rob_bcast_ecall                           	          ,
	input	[ 1-1:0]	in_rob_bcast_exception                       	          ,
	input	[ 1-1:0]	in_rob_bcast_page_fault_inst                 	          ,
	input	[ 1-1:0]	in_rob_bcast_page_fault_load                 	          ,
	input	[ 1-1:0]	in_rob_bcast_page_fault_store                	          ,
	input	[ 1-1:0]	in_rob_bcast_illegal_inst                    	          ,
	input	[ 1-1:0]	in_rob_bcast_interrupt                       	          ,
	input	[32-1:0]	in_rob_bcast_trap_val                        	          ,
	input	[32-1:0]	in_rob_bcast_pc                              	          ,
	input	[ 1-1:0]	in_rob_commit_commit_entry_valid             	[   4-1:0],
	input	[32-1:0]	in_rob_commit_commit_entry_uop_instruction   	[   4-1:0],
	input	[ 6-1:0]	in_rob_commit_commit_entry_uop_dest_areg     	[   4-1:0],
	input	[ 6-1:0]	in_rob_commit_commit_entry_uop_src1_areg     	[   4-1:0],
	input	[ 6-1:0]	in_rob_commit_commit_entry_uop_src2_areg     	[   4-1:0],
	input	[ 7-1:0]	in_rob_commit_commit_entry_uop_dest_preg     	[   4-1:0],
	input	[ 7-1:0]	in_rob_commit_commit_entry_uop_src1_preg     	[   4-1:0],
	input	[ 7-1:0]	in_rob_commit_commit_entry_uop_src2_preg     	[   4-1:0],
	input	[ 7-1:0]	in_rob_commit_commit_entry_uop_old_dest_preg 	[   4-1:0],
	input	[32-1:0]	in_rob_commit_commit_entry_uop_src1_rdata    	[   4-1:0],
	input	[32-1:0]	in_rob_commit_commit_entry_uop_src2_rdata    	[   4-1:0],
	input	[32-1:0]	in_rob_commit_commit_entry_uop_result        	[   4-1:0],
	input	[ 1-1:0]	in_rob_commit_commit_entry_uop_pred_br_taken 	[   4-1:0],
	input	[ 1-1:0]	in_rob_commit_commit_entry_uop_alt_pred      	[   4-1:0],
	input	[ 8-1:0]	in_rob_commit_commit_entry_uop_altpcpn       	[   4-1:0],
	input	[ 8-1:0]	in_rob_commit_commit_entry_uop_pcpn          	[   4-1:0],
	input	[32-1:0]	in_rob_commit_commit_entry_uop_pred_br_pc    	[   4-1:0],
	input	[ 1-1:0]	in_rob_commit_commit_entry_uop_mispred       	[   4-1:0],
	input	[ 1-1:0]	in_rob_commit_commit_entry_uop_br_taken      	[   4-1:0],
	input	[32-1:0]	in_rob_commit_commit_entry_uop_pc_next       	[   4-1:0],
	input	[ 1-1:0]	in_rob_commit_commit_entry_uop_dest_en       	[   4-1:0],
	input	[ 1-1:0]	in_rob_commit_commit_entry_uop_src1_en       	[   4-1:0],
	input	[ 1-1:0]	in_rob_commit_commit_entry_uop_src2_en       	[   4-1:0],
	input	[ 1-1:0]	in_rob_commit_commit_entry_uop_src1_busy     	[   4-1:0],
	input	[ 1-1:0]	in_rob_commit_commit_entry_uop_src2_busy     	[   4-1:0],
	input	[ 4-1:0]	in_rob_commit_commit_entry_uop_src1_latency  	[   4-1:0],
	input	[ 4-1:0]	in_rob_commit_commit_entry_uop_src2_latency  	[   4-1:0],
	input	[ 1-1:0]	in_rob_commit_commit_entry_uop_src1_is_pc    	[   4-1:0],
	input	[ 1-1:0]	in_rob_commit_commit_entry_uop_src2_is_imm   	[   4-1:0],
	input	[ 3-1:0]	in_rob_commit_commit_entry_uop_func3         	[   4-1:0],
	input	[ 1-1:0]	in_rob_commit_commit_entry_uop_func7_5       	[   4-1:0],
	input	[32-1:0]	in_rob_commit_commit_entry_uop_imm           	[   4-1:0],
	input	[32-1:0]	in_rob_commit_commit_entry_uop_pc            	[   4-1:0],
	input	[ 4-1:0]	in_rob_commit_commit_entry_uop_tag           	[   4-1:0],
	input	[12-1:0]	in_rob_commit_commit_entry_uop_csr_idx       	[   4-1:0],
	input	[ 7-1:0]	in_rob_commit_commit_entry_uop_rob_idx       	[   4-1:0],
	input	[ 4-1:0]	in_rob_commit_commit_entry_uop_stq_idx       	[   4-1:0],
	input	[16-1:0]	in_rob_commit_commit_entry_uop_pre_sta_mask  	[   4-1:0],
	input	[16-1:0]	in_rob_commit_commit_entry_uop_pre_std_mask  	[   4-1:0],
	input	[ 2-1:0]	in_rob_commit_commit_entry_uop_uop_num       	[   4-1:0],
	input	[ 2-1:0]	in_rob_commit_commit_entry_uop_cplt_num      	[   4-1:0],
	input	[ 1-1:0]	in_rob_commit_commit_entry_uop_rob_flag      	[   4-1:0],
	input	[ 1-1:0]	in_rob_commit_commit_entry_uop_page_fault_inst	[   4-1:0],
	input	[ 1-1:0]	in_rob_commit_commit_entry_uop_page_fault_load	[   4-1:0],
	input	[ 1-1:0]	in_rob_commit_commit_entry_uop_page_fault_store	[   4-1:0],
	input	[ 1-1:0]	in_rob_commit_commit_entry_uop_illegal_inst  	[   4-1:0],
	input	[ 4-1:0]	in_rob_commit_commit_entry_uop_type          	[   4-1:0],
	input	[ 4-1:0]	in_rob_commit_commit_entry_uop_op            	[   4-1:0],
	input	[ 4-1:0]	in_rob_commit_commit_entry_uop_amoop         	[   4-1:0],
	input	[ 1-1:0]	inst_r_valid                                 	[   4-1:0],
	input	[32-1:0]	inst_r_uop_instruction                       	[   4-1:0],
	input	[ 6-1:0]	inst_r_uop_dest_areg                         	[   4-1:0],
	input	[ 6-1:0]	inst_r_uop_src1_areg                         	[   4-1:0],
	input	[ 6-1:0]	inst_r_uop_src2_areg                         	[   4-1:0],
	input	[ 7-1:0]	inst_r_uop_dest_preg                         	[   4-1:0],
	input	[ 7-1:0]	inst_r_uop_src1_preg                         	[   4-1:0],
	input	[ 7-1:0]	inst_r_uop_src2_preg                         	[   4-1:0],
	input	[ 7-1:0]	inst_r_uop_old_dest_preg                     	[   4-1:0],
	input	[32-1:0]	inst_r_uop_src1_rdata                        	[   4-1:0],
	input	[32-1:0]	inst_r_uop_src2_rdata                        	[   4-1:0],
	input	[32-1:0]	inst_r_uop_result                            	[   4-1:0],
	input	[ 1-1:0]	inst_r_uop_pred_br_taken                     	[   4-1:0],
	input	[ 1-1:0]	inst_r_uop_alt_pred                          	[   4-1:0],
	input	[ 8-1:0]	inst_r_uop_altpcpn                           	[   4-1:0],
	input	[ 8-1:0]	inst_r_uop_pcpn                              	[   4-1:0],
	input	[32-1:0]	inst_r_uop_pred_br_pc                        	[   4-1:0],
	input	[ 1-1:0]	inst_r_uop_mispred                           	[   4-1:0],
	input	[ 1-1:0]	inst_r_uop_br_taken                          	[   4-1:0],
	input	[32-1:0]	inst_r_uop_pc_next                           	[   4-1:0],
	input	[ 1-1:0]	inst_r_uop_dest_en                           	[   4-1:0],
	input	[ 1-1:0]	inst_r_uop_src1_en                           	[   4-1:0],
	input	[ 1-1:0]	inst_r_uop_src2_en                           	[   4-1:0],
	input	[ 1-1:0]	inst_r_uop_src1_busy                         	[   4-1:0],
	input	[ 1-1:0]	inst_r_uop_src2_busy                         	[   4-1:0],
	input	[ 4-1:0]	inst_r_uop_src1_latency                      	[   4-1:0],
	input	[ 4-1:0]	inst_r_uop_src2_latency                      	[   4-1:0],
	input	[ 1-1:0]	inst_r_uop_src1_is_pc                        	[   4-1:0],
	input	[ 1-1:0]	inst_r_uop_src2_is_imm                       	[   4-1:0],
	input	[ 3-1:0]	inst_r_uop_func3                             	[   4-1:0],
	input	[ 1-1:0]	inst_r_uop_func7_5                           	[   4-1:0],
	input	[32-1:0]	inst_r_uop_imm                               	[   4-1:0],
	input	[32-1:0]	inst_r_uop_pc                                	[   4-1:0],
	input	[ 4-1:0]	inst_r_uop_tag                               	[   4-1:0],
	input	[12-1:0]	inst_r_uop_csr_idx                           	[   4-1:0],
	input	[ 7-1:0]	inst_r_uop_rob_idx                           	[   4-1:0],
	input	[ 4-1:0]	inst_r_uop_stq_idx                           	[   4-1:0],
	input	[16-1:0]	inst_r_uop_pre_sta_mask                      	[   4-1:0],
	input	[16-1:0]	inst_r_uop_pre_std_mask                      	[   4-1:0],
	input	[ 2-1:0]	inst_r_uop_uop_num                           	[   4-1:0],
	input	[ 2-1:0]	inst_r_uop_cplt_num                          	[   4-1:0],
	input	[ 1-1:0]	inst_r_uop_rob_flag                          	[   4-1:0],
	input	[ 1-1:0]	inst_r_uop_page_fault_inst                   	[   4-1:0],
	input	[ 1-1:0]	inst_r_uop_page_fault_load                   	[   4-1:0],
	input	[ 1-1:0]	inst_r_uop_page_fault_store                  	[   4-1:0],
	input	[ 1-1:0]	inst_r_uop_illegal_inst                      	[   4-1:0],
	input	[ 4-1:0]	inst_r_uop_type                              	[   4-1:0],
	input	[ 4-1:0]	inst_r_uop_op                                	[   4-1:0],
	input	[ 4-1:0]	inst_r_uop_amoop                             	[   4-1:0],
	input	[ 7-1:0]	arch_RAT                                     	[  33-1:0],
	input	[ 7-1:0]	spec_RAT                                     	[  33-1:0],
	input	[ 7-1:0]	RAT_checkpoint                               	[ 528-1:0],
	input	[ 1-1:0]	free_vec                                     	[ 128-1:0],
	input	[ 1-1:0]	alloc_checkpoint                             	[2048-1:0],
	input	[ 1-1:0]	busy_table                                   	[ 128-1:0],
	input	[ 1-1:0]	spec_alloc                                   	[ 128-1:0],
	output	[ 1-1:0]	out_ren2dec_ready                            	          ,
	output	[32-1:0]	out_ren2dis_uop_instruction                  	[   4-1:0],
	output	[ 6-1:0]	out_ren2dis_uop_dest_areg                    	[   4-1:0],
	output	[ 6-1:0]	out_ren2dis_uop_src1_areg                    	[   4-1:0],
	output	[ 6-1:0]	out_ren2dis_uop_src2_areg                    	[   4-1:0],
	output	[ 7-1:0]	out_ren2dis_uop_dest_preg                    	[   4-1:0],
	output	[ 7-1:0]	out_ren2dis_uop_src1_preg                    	[   4-1:0],
	output	[ 7-1:0]	out_ren2dis_uop_src2_preg                    	[   4-1:0],
	output	[ 7-1:0]	out_ren2dis_uop_old_dest_preg                	[   4-1:0],
	output	[32-1:0]	out_ren2dis_uop_src1_rdata                   	[   4-1:0],
	output	[32-1:0]	out_ren2dis_uop_src2_rdata                   	[   4-1:0],
	output	[32-1:0]	out_ren2dis_uop_result                       	[   4-1:0],
	output	[ 1-1:0]	out_ren2dis_uop_pred_br_taken                	[   4-1:0],
	output	[ 1-1:0]	out_ren2dis_uop_alt_pred                     	[   4-1:0],
	output	[ 8-1:0]	out_ren2dis_uop_altpcpn                      	[   4-1:0],
	output	[ 8-1:0]	out_ren2dis_uop_pcpn                         	[   4-1:0],
	output	[32-1:0]	out_ren2dis_uop_pred_br_pc                   	[   4-1:0],
	output	[ 1-1:0]	out_ren2dis_uop_mispred                      	[   4-1:0],
	output	[ 1-1:0]	out_ren2dis_uop_br_taken                     	[   4-1:0],
	output	[32-1:0]	out_ren2dis_uop_pc_next                      	[   4-1:0],
	output	[ 1-1:0]	out_ren2dis_uop_dest_en                      	[   4-1:0],
	output	[ 1-1:0]	out_ren2dis_uop_src1_en                      	[   4-1:0],
	output	[ 1-1:0]	out_ren2dis_uop_src2_en                      	[   4-1:0],
	output	[ 1-1:0]	out_ren2dis_uop_src1_busy                    	[   4-1:0],
	output	[ 1-1:0]	out_ren2dis_uop_src2_busy                    	[   4-1:0],
	output	[ 4-1:0]	out_ren2dis_uop_src1_latency                 	[   4-1:0],
	output	[ 4-1:0]	out_ren2dis_uop_src2_latency                 	[   4-1:0],
	output	[ 1-1:0]	out_ren2dis_uop_src1_is_pc                   	[   4-1:0],
	output	[ 1-1:0]	out_ren2dis_uop_src2_is_imm                  	[   4-1:0],
	output	[ 3-1:0]	out_ren2dis_uop_func3                        	[   4-1:0],
	output	[ 1-1:0]	out_ren2dis_uop_func7_5                      	[   4-1:0],
	output	[32-1:0]	out_ren2dis_uop_imm                          	[   4-1:0],
	output	[32-1:0]	out_ren2dis_uop_pc                           	[   4-1:0],
	output	[ 4-1:0]	out_ren2dis_uop_tag                          	[   4-1:0],
	output	[12-1:0]	out_ren2dis_uop_csr_idx                      	[   4-1:0],
	output	[ 7-1:0]	out_ren2dis_uop_rob_idx                      	[   4-1:0],
	output	[ 4-1:0]	out_ren2dis_uop_stq_idx                      	[   4-1:0],
	output	[16-1:0]	out_ren2dis_uop_pre_sta_mask                 	[   4-1:0],
	output	[16-1:0]	out_ren2dis_uop_pre_std_mask                 	[   4-1:0],
	output	[ 2-1:0]	out_ren2dis_uop_uop_num                      	[   4-1:0],
	output	[ 2-1:0]	out_ren2dis_uop_cplt_num                     	[   4-1:0],
	output	[ 1-1:0]	out_ren2dis_uop_rob_flag                     	[   4-1:0],
	output	[ 1-1:0]	out_ren2dis_uop_page_fault_inst              	[   4-1:0],
	output	[ 1-1:0]	out_ren2dis_uop_page_fault_load              	[   4-1:0],
	output	[ 1-1:0]	out_ren2dis_uop_page_fault_store             	[   4-1:0],
	output	[ 1-1:0]	out_ren2dis_uop_illegal_inst                 	[   4-1:0],
	output	[ 4-1:0]	out_ren2dis_uop_type                         	[   4-1:0],
	output	[ 4-1:0]	out_ren2dis_uop_op                           	[   4-1:0],
	output	[ 4-1:0]	out_ren2dis_uop_amoop                        	[   4-1:0],
	output	[ 1-1:0]	out_ren2dis_valid                            	[   4-1:0],
	output	[ 1-1:0]	inst_r_1_valid                               	[   4-1:0],
	output	[32-1:0]	inst_r_1_uop_instruction                     	[   4-1:0],
	output	[ 6-1:0]	inst_r_1_uop_dest_areg                       	[   4-1:0],
	output	[ 6-1:0]	inst_r_1_uop_src1_areg                       	[   4-1:0],
	output	[ 6-1:0]	inst_r_1_uop_src2_areg                       	[   4-1:0],
	output	[ 7-1:0]	inst_r_1_uop_dest_preg                       	[   4-1:0],
	output	[ 7-1:0]	inst_r_1_uop_src1_preg                       	[   4-1:0],
	output	[ 7-1:0]	inst_r_1_uop_src2_preg                       	[   4-1:0],
	output	[ 7-1:0]	inst_r_1_uop_old_dest_preg                   	[   4-1:0],
	output	[32-1:0]	inst_r_1_uop_src1_rdata                      	[   4-1:0],
	output	[32-1:0]	inst_r_1_uop_src2_rdata                      	[   4-1:0],
	output	[32-1:0]	inst_r_1_uop_result                          	[   4-1:0],
	output	[ 1-1:0]	inst_r_1_uop_pred_br_taken                   	[   4-1:0],
	output	[ 1-1:0]	inst_r_1_uop_alt_pred                        	[   4-1:0],
	output	[ 8-1:0]	inst_r_1_uop_altpcpn                         	[   4-1:0],
	output	[ 8-1:0]	inst_r_1_uop_pcpn                            	[   4-1:0],
	output	[32-1:0]	inst_r_1_uop_pred_br_pc                      	[   4-1:0],
	output	[ 1-1:0]	inst_r_1_uop_mispred                         	[   4-1:0],
	output	[ 1-1:0]	inst_r_1_uop_br_taken                        	[   4-1:0],
	output	[32-1:0]	inst_r_1_uop_pc_next                         	[   4-1:0],
	output	[ 1-1:0]	inst_r_1_uop_dest_en                         	[   4-1:0],
	output	[ 1-1:0]	inst_r_1_uop_src1_en                         	[   4-1:0],
	output	[ 1-1:0]	inst_r_1_uop_src2_en                         	[   4-1:0],
	output	[ 1-1:0]	inst_r_1_uop_src1_busy                       	[   4-1:0],
	output	[ 1-1:0]	inst_r_1_uop_src2_busy                       	[   4-1:0],
	output	[ 4-1:0]	inst_r_1_uop_src1_latency                    	[   4-1:0],
	output	[ 4-1:0]	inst_r_1_uop_src2_latency                    	[   4-1:0],
	output	[ 1-1:0]	inst_r_1_uop_src1_is_pc                      	[   4-1:0],
	output	[ 1-1:0]	inst_r_1_uop_src2_is_imm                     	[   4-1:0],
	output	[ 3-1:0]	inst_r_1_uop_func3                           	[   4-1:0],
	output	[ 1-1:0]	inst_r_1_uop_func7_5                         	[   4-1:0],
	output	[32-1:0]	inst_r_1_uop_imm                             	[   4-1:0],
	output	[32-1:0]	inst_r_1_uop_pc                              	[   4-1:0],
	output	[ 4-1:0]	inst_r_1_uop_tag                             	[   4-1:0],
	output	[12-1:0]	inst_r_1_uop_csr_idx                         	[   4-1:0],
	output	[ 7-1:0]	inst_r_1_uop_rob_idx                         	[   4-1:0],
	output	[ 4-1:0]	inst_r_1_uop_stq_idx                         	[   4-1:0],
	output	[16-1:0]	inst_r_1_uop_pre_sta_mask                    	[   4-1:0],
	output	[16-1:0]	inst_r_1_uop_pre_std_mask                    	[   4-1:0],
	output	[ 2-1:0]	inst_r_1_uop_uop_num                         	[   4-1:0],
	output	[ 2-1:0]	inst_r_1_uop_cplt_num                        	[   4-1:0],
	output	[ 1-1:0]	inst_r_1_uop_rob_flag                        	[   4-1:0],
	output	[ 1-1:0]	inst_r_1_uop_page_fault_inst                 	[   4-1:0],
	output	[ 1-1:0]	inst_r_1_uop_page_fault_load                 	[   4-1:0],
	output	[ 1-1:0]	inst_r_1_uop_page_fault_store                	[   4-1:0],
	output	[ 1-1:0]	inst_r_1_uop_illegal_inst                    	[   4-1:0],
	output	[ 4-1:0]	inst_r_1_uop_type                            	[   4-1:0],
	output	[ 4-1:0]	inst_r_1_uop_op                              	[   4-1:0],
	output	[ 4-1:0]	inst_r_1_uop_amoop                           	[   4-1:0],
	output	[ 7-1:0]	arch_RAT_1                                   	[  33-1:0],
	output	[ 7-1:0]	spec_RAT_1                                   	[  33-1:0],
	output	[ 7-1:0]	RAT_checkpoint_1                             	[ 528-1:0],
	output	[ 1-1:0]	free_vec_1                                   	[ 128-1:0],
	output	[ 1-1:0]	alloc_checkpoint_1                           	[2048-1:0],
	output	[ 1-1:0]	busy_table_1                                 	[ 128-1:0],
	output	[ 1-1:0]	spec_alloc_1                                 	[ 128-1:0]
    // // inst_r
    // input                               inst_r_valid                                                     [           FETCH_WIDTH-1:0], 
    // input      [     $clog2(ARF_NUM):0] inst_r_uop_dest_areg                                             [           FETCH_WIDTH-1:0], // 前递判断相不相等
    // input      [     $clog2(ARF_NUM):0] inst_r_uop_src1_areg                                             [           FETCH_WIDTH-1:0], // 判断src和dest相不相等
    // input      [     $clog2(ARF_NUM):0] inst_r_uop_src2_areg                                             [           FETCH_WIDTH-1:0], // 判断src和dest相不相等
    // input      [   $clog2(PRF_NUM)-1:0] inst_r_uop_dest_preg                                             [           FETCH_WIDTH-1:0], 
    // input                               inst_r_uop_dest_en                                               [           FETCH_WIDTH-1:0],
    // input                               inst_r_uop_src1_en                                               [           FETCH_WIDTH-1:0], // 用于src1是否busy的计算
    // input		                        inst_r_uop_src2_en                                               [           FETCH_WIDTH-1:0],
    // input      [$clog2(MAX_BR_NUM)-1:0] inst_r_uop_tag                                                   [           FETCH_WIDTH-1:0],
    // input      [  $clog2(TYPE_NUM)-1:0] inst_r_uop_type                                                  [           FETCH_WIDTH-1:0],
    // // io_ren2dis
    // output                              io_ren2dis_valid                                                 [           FETCH_WIDTH-1:0],
    // output     [     $clog2(ARF_NUM):0] io_ren2dis_uop_dest_areg                                         [           FETCH_WIDTH-1:0], // 判断==32
    // output     [   $clog2(PRF_NUM)-1:0] io_ren2dis_uop_dest_preg                                         [           FETCH_WIDTH-1:0],
    // output     [   $clog2(PRF_NUM)-1:0] io_ren2dis_uop_src1_preg                                         [           FETCH_WIDTH-1:0],
    // output     [   $clog2(PRF_NUM)-1:0] io_ren2dis_uop_src2_preg                                         [           FETCH_WIDTH-1:0],
    // output                              io_ren2dis_uop_dest_en                                           [           FETCH_WIDTH-1:0],
    // output                              io_ren2dis_uop_src1_busy                                         [           FETCH_WIDTH-1:0],
    // output                              io_ren2dis_uop_src2_busy                                         [           FETCH_WIDTH-1:0],
    // output     [   $clog2(PRF_NUM)-1:0] io_ren2dis_uop_old_dest_preg                                     [           FETCH_WIDTH-1:0],
    // // alloc

    // // wake                              
	// input                               io_prf_awake_wake_valid                                                                      ,
	// input      [   $clog2(PRF_NUM)-1:0] io_prf_awake_wake_preg                                                                       ,
	// input                               io_iss_awake_wake_valid                                          [               ALU_NUM-1:0],
	// input      [   $clog2(PRF_NUM)-1:0] io_iss_awake_wake_preg                                           [               ALU_NUM-1:0],

    // // rename                              

    // // fire                      
    // input                               io_dis2ren_ready                                                                             ,
    // output                              fire                                                             [           FETCH_WIDTH-1:0],          
    // output                              io_ren2dec_ready                                                                             ,  
    // // spec_alloc                
    // output                              alloc_checkpoint                                                 [               PRF_NUM-1:0],                          
    // output                              spec_alloc_1                                                     [               PRF_NUM-1:0],
    // input      [$clog2(MAX_BR_NUM)-1:0] io_dec_bcast_br_tag                                                                          ,     
    // input                               spec_alloc                                                       [               PRF_NUM-1:0],// test no seq
    // // free_vec                        
    // output                              free_vec_1                                                       [               PRF_NUM-1:0],// test no seq
    // input                               free_vec                                                         [               PRF_NUM-1:0],// test no seq  
    // // spec_RAT
    // input      [   $clog2(PRF_NUM)-1:0] arch_RAT                                                         [                 ARF_NUM:0],                    
    // output     [   $clog2(PRF_NUM)-1:0] RAT_checkpoint                                                   [                 ARF_NUM:0],
    // input      [   $clog2(PRF_NUM)-1:0] spec_RAT                                                         [                 ARF_NUM:0],// test no seq
    // output     [   $clog2(PRF_NUM)-1:0] spec_RAT_1                                                       [                 ARF_NUM:0],// test no seq
    // input      [   $clog2(PRF_NUM)-1:0] RAT_checkpoint_set                                               [(ARF_NUM+1)*MAX_BR_NUM-1:0],// test no seq
    // output     [   $clog2(PRF_NUM)-1:0] RAT_checkpoint_set_1                                             [(ARF_NUM+1)*MAX_BR_NUM-1:0],// test no seq
    // // busy_table                 
    // input                               busy_table                                                       [               PRF_NUM-1:0],// test no seq
    // output                              busy_table_1                                                     [               PRF_NUM-1:0],// test no seq
    // // alloc_chekpoint                  
    // input      [      MAX_BR_NUM - 1:0] alloc_checkpoint_set                                             [             PRF_NUM - 1:0],// test no seq
    // output     [      MAX_BR_NUM - 1:0] alloc_checkpoint_set_1                                           [             PRF_NUM - 1:0],// test no seq    
    // // branch
    // input                               io_dec_bcast_mispred                                                                         ,
    // input                               io_rob_bcast_flush                                                                           ,  
    // // commit
    // input                               io_rob_commit_commit_entry_valid                                 [          COMMIT_WIDTH-1:0],
    // input                               io_rob_commit_commit_entry_uop_dest_en                           [          COMMIT_WIDTH-1:0],
    // input                               io_rob_commit_commit_entry_uop_page_fault_load                   [          COMMIT_WIDTH-1:0],
    // input                               io_rob_bcast_interrupt                                                                       ,
    // input                               io_rob_bcast_illegal_inst                                                                    ,
    // input      [   $clog2(PRF_NUM)-1:0] io_rob_commit_commit_entry_uop_old_dest_preg                     [          COMMIT_WIDTH-1:0],
    // input      [   $clog2(PRF_NUM)-1:0] io_rob_commit_commit_entry_uop_dest_preg                         [          COMMIT_WIDTH-1:0]                                  
);
// may over max in sim
wire [$clog2(ARF_NUM):0] inst_r_uop_dest_areg_mod [FETCH_WIDTH-1:0];
wire [$clog2(ARF_NUM):0] inst_r_uop_src1_areg_mod [FETCH_WIDTH-1:0];
wire [$clog2(ARF_NUM):0] inst_r_uop_src2_areg_mod [FETCH_WIDTH-1:0];
genvar j;
generate
    for(j = 0; j < FETCH_WIDTH; j++) begin
        assign inst_r_uop_dest_areg_mod[j] = inst_r_uop_dest_areg[j]%33;
        assign inst_r_uop_src1_areg_mod[j] = inst_r_uop_src1_areg[j]%33;
        assign inst_r_uop_src2_areg_mod[j] = inst_r_uop_src2_areg[j]%33;
    end 
endgenerate


wire                         alloc_reg_valid [           FETCH_WIDTH-1:0];
wire[   $clog2(PRF_NUM)-1:0] alloc_reg       [           FETCH_WIDTH-1:0]; 
rename_alloc
#(
    .PRF_NUM     (PRF_NUM     ),
    .ROB_NUM     (ROB_NUM     ),
    .STQ_NUM     (STQ_NUM     ),
    .OP_NUM      (OP_NUM      ),
    .FETCH_WIDTH (FETCH_WIDTH ),
    .COMMIT_WIDTH(COMMIT_WIDTH),
    .ARF_NUM     (ARF_NUM     ),
    .MAX_BR_NUM  (MAX_BR_NUM  ),
    .ALU_NUM     (ALU_NUM     ),
    .AMOOP_NUM   (AMOOP_NUM   ),
    .CPU_WIDTH   (CPU_WIDTH   ),
    .FUNC3_WIDTH (FUNC3_WIDTH ),
    .CSR_WIDTH   (CSR_WIDTH   ),
    .TYPE_NUM    (TYPE_NUM    )
)
uut_rename_alloc
(
    .alloc_reg_valid                 (alloc_reg_valid                 ),
    .alloc_reg                       (alloc_reg                       ),
 // .inst_r_valid                    (inst_r_valid                    ),
 // .inst_r_uop_dest_preg            (inst_r_uop_dest_preg            ),
 // .inst_r_uop_dest_en              (inst_r_uop_dest_en              ),
    .inst_r_uop_instruction          (inst_r_uop_instruction          ),
    .inst_r_uop_dest_areg            (inst_r_uop_dest_areg            ),
    .inst_r_uop_src1_areg            (inst_r_uop_src1_areg            ),
    .inst_r_uop_src2_areg            (inst_r_uop_src2_areg            ),
    .inst_r_uop_dest_preg            (inst_r_uop_dest_preg            ),
    .inst_r_uop_src1_preg            (inst_r_uop_src1_preg            ),
    .inst_r_uop_src2_preg            (inst_r_uop_src2_preg            ),
    .inst_r_uop_old_dest_preg        (inst_r_uop_old_dest_preg        ),
    .inst_r_uop_src1_rdata           (inst_r_uop_src1_rdata           ),
    .inst_r_uop_src2_rdata           (inst_r_uop_src2_rdata           ),
    .inst_r_uop_result               (inst_r_uop_result               ),
    .inst_r_uop_pred_br_taken        (inst_r_uop_pred_br_taken        ),
    .inst_r_uop_alt_pred             (inst_r_uop_alt_pred             ),
    .inst_r_uop_altpcpn              (inst_r_uop_altpcpn              ),
    .inst_r_uop_pcpn                 (inst_r_uop_pcpn                 ),
    .inst_r_uop_pred_br_pc           (inst_r_uop_pred_br_pc           ),
    .inst_r_uop_mispred              (inst_r_uop_mispred              ),
    .inst_r_uop_br_taken             (inst_r_uop_br_taken             ),
    .inst_r_uop_pc_next              (inst_r_uop_pc_next              ),
    .inst_r_uop_dest_en              (inst_r_uop_dest_en              ),
    .inst_r_uop_src1_en              (inst_r_uop_src1_en              ),
    .inst_r_uop_src2_en              (inst_r_uop_src2_en              ),
    .inst_r_uop_src1_busy            (inst_r_uop_src1_busy            ),
    .inst_r_uop_src2_busy            (inst_r_uop_src2_busy            ),
    .inst_r_uop_src1_latency         (inst_r_uop_src1_latency         ),
    .inst_r_uop_src2_latency         (inst_r_uop_src2_latency         ),
    .inst_r_uop_src1_is_pc           (inst_r_uop_src1_is_pc           ),
    .inst_r_uop_src2_is_imm          (inst_r_uop_src2_is_imm          ),
    .inst_r_uop_func3                (inst_r_uop_func3                ),
    .inst_r_uop_func7_5              (inst_r_uop_func7_5              ),
    .inst_r_uop_imm                  (inst_r_uop_imm                  ),
    .inst_r_uop_pc                   (inst_r_uop_pc                   ),
    .inst_r_uop_tag                  (inst_r_uop_tag                  ),
    .inst_r_uop_csr_idx              (inst_r_uop_csr_idx              ),
    .inst_r_uop_rob_idx              (inst_r_uop_rob_idx              ),
    .inst_r_uop_stq_idx              (inst_r_uop_stq_idx              ),
    .inst_r_uop_pre_sta_mask         (inst_r_uop_pre_sta_mask         ),
    .inst_r_uop_pre_std_mask         (inst_r_uop_pre_std_mask         ),
    .inst_r_uop_uop_num              (inst_r_uop_uop_num              ),
    .inst_r_uop_cplt_num             (inst_r_uop_cplt_num             ),
    .inst_r_uop_rob_flag             (inst_r_uop_rob_flag             ),
    .inst_r_uop_page_fault_inst      (inst_r_uop_page_fault_inst      ),
    .inst_r_uop_page_fault_load      (inst_r_uop_page_fault_load      ),
    .inst_r_uop_page_fault_store     (inst_r_uop_page_fault_store     ),
    .inst_r_uop_illegal_inst         (inst_r_uop_illegal_inst         ),
    .inst_r_uop_type                 (inst_r_uop_type                 ),
    .inst_r_uop_op                   (inst_r_uop_op                   ),
    .inst_r_uop_amoop                (inst_r_uop_amoop                ),
    .inst_r_valid                    (inst_r_valid                    ),
    .out_ren2dis_uop_instruction     (out_ren2dis_uop_instruction     ),
    .out_ren2dis_uop_dest_areg       (out_ren2dis_uop_dest_areg       ),
    .out_ren2dis_uop_src1_areg       (out_ren2dis_uop_src1_areg       ),
    .out_ren2dis_uop_src2_areg       (out_ren2dis_uop_src2_areg       ),
    .out_ren2dis_uop_dest_preg       (out_ren2dis_uop_dest_preg       ),
 // .out_ren2dis_uop_src1_preg       (out_ren2dis_uop_src1_preg       ),
 // .out_ren2dis_uop_src2_preg       (out_ren2dis_uop_src2_preg       ),
 // .out_ren2dis_uop_old_dest_preg   (out_ren2dis_uop_old_dest_preg   ),
    .out_ren2dis_uop_src1_rdata      (out_ren2dis_uop_src1_rdata      ),
    .out_ren2dis_uop_src2_rdata      (out_ren2dis_uop_src2_rdata      ),
    .out_ren2dis_uop_result          (out_ren2dis_uop_result          ),
    .out_ren2dis_uop_pred_br_taken   (out_ren2dis_uop_pred_br_taken   ),
    .out_ren2dis_uop_alt_pred        (out_ren2dis_uop_alt_pred        ),
    .out_ren2dis_uop_altpcpn         (out_ren2dis_uop_altpcpn         ),
    .out_ren2dis_uop_pcpn            (out_ren2dis_uop_pcpn            ),
    .out_ren2dis_uop_pred_br_pc      (out_ren2dis_uop_pred_br_pc      ),
    .out_ren2dis_uop_mispred         (out_ren2dis_uop_mispred         ),
    .out_ren2dis_uop_br_taken        (out_ren2dis_uop_br_taken        ),
    .out_ren2dis_uop_pc_next         (out_ren2dis_uop_pc_next         ),
    .out_ren2dis_uop_dest_en         (out_ren2dis_uop_dest_en         ),
    .out_ren2dis_uop_src1_en         (out_ren2dis_uop_src1_en         ),
    .out_ren2dis_uop_src2_en         (out_ren2dis_uop_src2_en         ),
 // .out_ren2dis_uop_src1_busy       (out_ren2dis_uop_src1_busy       ),
 // .out_ren2dis_uop_src2_busy       (out_ren2dis_uop_src2_busy       ),
    .out_ren2dis_uop_src1_latency    (out_ren2dis_uop_src1_latency    ),
    .out_ren2dis_uop_src2_latency    (out_ren2dis_uop_src2_latency    ),
    .out_ren2dis_uop_src1_is_pc      (out_ren2dis_uop_src1_is_pc      ),
    .out_ren2dis_uop_src2_is_imm     (out_ren2dis_uop_src2_is_imm     ),
    .out_ren2dis_uop_func3           (out_ren2dis_uop_func3           ),
    .out_ren2dis_uop_func7_5         (out_ren2dis_uop_func7_5         ),
    .out_ren2dis_uop_imm             (out_ren2dis_uop_imm             ),
    .out_ren2dis_uop_pc              (out_ren2dis_uop_pc              ),
    .out_ren2dis_uop_tag             (out_ren2dis_uop_tag             ),
    .out_ren2dis_uop_csr_idx         (out_ren2dis_uop_csr_idx         ),
    .out_ren2dis_uop_rob_idx         (out_ren2dis_uop_rob_idx         ),
    .out_ren2dis_uop_stq_idx         (out_ren2dis_uop_stq_idx         ),
    .out_ren2dis_uop_pre_sta_mask    (out_ren2dis_uop_pre_sta_mask    ),
    .out_ren2dis_uop_pre_std_mask    (out_ren2dis_uop_pre_std_mask    ),
    .out_ren2dis_uop_uop_num         (out_ren2dis_uop_uop_num         ),
    .out_ren2dis_uop_cplt_num        (out_ren2dis_uop_cplt_num        ),
    .out_ren2dis_uop_rob_flag        (out_ren2dis_uop_rob_flag        ),
    .out_ren2dis_uop_page_fault_inst (out_ren2dis_uop_page_fault_inst ),
    .out_ren2dis_uop_page_fault_load (out_ren2dis_uop_page_fault_load ),
    .out_ren2dis_uop_page_fault_store(out_ren2dis_uop_page_fault_store),
    .out_ren2dis_uop_illegal_inst    (out_ren2dis_uop_illegal_inst    ),
    .out_ren2dis_uop_type            (out_ren2dis_uop_type            ),
    .out_ren2dis_uop_op              (out_ren2dis_uop_op              ),
    .out_ren2dis_uop_amoop           (out_ren2dis_uop_amoop           ),
    .out_ren2dis_valid               (out_ren2dis_valid               )
    // .out_ren2dis_valid               (out_ren2dis_valid               ),
    // .out_ren2dis_uop_dest_preg       (out_ren2dis_uop_dest_preg       )
);

wire [   $clog2(PRF_NUM)-1:0] busy_table_write_in_prf_awake_wake_preg_addr                             ;
wire                          busy_table_write_in_prf_awake_wake_preg_en                               ;
wire                          busy_table_write_in_prf_awake_wake_preg_data                             ;
wire [   $clog2(PRF_NUM)-1:0] busy_table_write_in_iss_awake_wake_preg_addr [               ALU_NUM-1:0]; // 不会有都valid，且地址相同的情况
wire                          busy_table_write_in_iss_awake_wake_preg_en   [               ALU_NUM-1:0];
wire                          busy_table_write_in_iss_awake_wake_preg_data [               ALU_NUM-1:0];
rename_wake
#(
    .PRF_NUM     (PRF_NUM     ),
    .ROB_NUM     (ROB_NUM     ),
    .STQ_NUM     (STQ_NUM     ),
    .OP_NUM      (OP_NUM      ),
    .FETCH_WIDTH (FETCH_WIDTH ),
    .COMMIT_WIDTH(COMMIT_WIDTH),
    .ARF_NUM     (ARF_NUM     ),
    .MAX_BR_NUM  (MAX_BR_NUM  ),
    .ALU_NUM     (ALU_NUM     ),
    .AMOOP_NUM   (AMOOP_NUM   ),
    .CPU_WIDTH   (CPU_WIDTH   ),
    .FUNC3_WIDTH (FUNC3_WIDTH ),
    .CSR_WIDTH   (CSR_WIDTH   ),
    .TYPE_NUM    (TYPE_NUM    )
)
uut_rename_wake
(
    .in_prf_awake_wake_valid                     (in_prf_awake_wake_valid                     ),
    .in_prf_awake_wake_preg                      (in_prf_awake_wake_preg                      ),
    .in_iss_awake_wake_valid                     (in_iss_awake_wake_valid                     ),
    .in_iss_awake_wake_preg                      (in_iss_awake_wake_preg                      ),
    .busy_table_write_in_prf_awake_wake_preg_addr(busy_table_write_in_prf_awake_wake_preg_addr),
    .busy_table_write_in_prf_awake_wake_preg_en  (busy_table_write_in_prf_awake_wake_preg_en  ),
    .busy_table_write_in_prf_awake_wake_preg_data(busy_table_write_in_prf_awake_wake_preg_data),
    .busy_table_write_in_iss_awake_wake_preg_addr(busy_table_write_in_iss_awake_wake_preg_addr),
    .busy_table_write_in_iss_awake_wake_preg_en  (busy_table_write_in_iss_awake_wake_preg_en  ),
    .busy_table_write_in_iss_awake_wake_preg_data(busy_table_write_in_iss_awake_wake_preg_data)
);

genvar i;
generate
    for(i = 0; i < FETCH_WIDTH; i++) begin
        assign out_ren2dis_uop_dest_areg[i] = inst_r_uop_dest_areg_mod[i];
        // assign io_ren2dis_uop_dest_areg[i] = inst_r_uop_dest_areg[i];
    end 
endgenerate

wire [     $clog2(ARF_NUM):0] spec_RAT_read_inst_r_uop_dest_areg_addr       [           FETCH_WIDTH-1:0];                               
wire [   $clog2(PRF_NUM)-1:0] spec_RAT_read_inst_r_uop_dest_areg_data       [           FETCH_WIDTH-1:0]; //不有效或者无前递的默认值
wire [     $clog2(ARF_NUM):0] spec_RAT_read_inst_r_uop_src1_areg_addr       [           FETCH_WIDTH-1:0];
wire [   $clog2(PRF_NUM)-1:0] spec_RAT_read_inst_r_uop_src1_areg_data       [           FETCH_WIDTH-1:0]; // spec_RAT读src1_areg
wire [   $clog2(PRF_NUM)-1:0] busy_table_read_out_ren2dis_uop_src1_preg_addr [           FETCH_WIDTH-1:0];
wire                          busy_table_read_out_ren2dis_uop_src1_preg_data [           FETCH_WIDTH-1:0]; // busy_table查看src1_preg是否繁忙
wire [     $clog2(ARF_NUM):0] spec_RAT_read_inst_r_uop_src2_areg_addr       [           FETCH_WIDTH-1:0];
wire [   $clog2(PRF_NUM)-1:0] spec_RAT_read_inst_r_uop_src2_areg_data       [           FETCH_WIDTH-1:0];
wire [   $clog2(PRF_NUM)-1:0] busy_table_read_out_ren2dis_uop_src2_preg_addr [           FETCH_WIDTH-1:0];
wire                          busy_table_read_out_ren2dis_uop_src2_preg_data [           FETCH_WIDTH-1:0]; // busy_table查看src1_preg是否繁忙
rename_rename
#(
    .PRF_NUM     (PRF_NUM     ),
    .ROB_NUM     (ROB_NUM     ),
    .STQ_NUM     (STQ_NUM     ),
    .OP_NUM      (OP_NUM      ),
    .FETCH_WIDTH (FETCH_WIDTH ),
    .COMMIT_WIDTH(COMMIT_WIDTH),
    .ARF_NUM     (ARF_NUM     ),
    .MAX_BR_NUM  (MAX_BR_NUM  ),
    .ALU_NUM     (ALU_NUM     ),
    .AMOOP_NUM   (AMOOP_NUM   ),
    .CPU_WIDTH   (CPU_WIDTH   ),
    .FUNC3_WIDTH (FUNC3_WIDTH ),
    .CSR_WIDTH   (CSR_WIDTH   ),
    .TYPE_NUM    (TYPE_NUM    )
)
uut_rename_rename
(
    .inst_r_valid                                  (inst_r_valid                                 ),
    .inst_r_uop_dest_en                            (inst_r_uop_dest_en                           ),
    .spec_RAT_read_inst_r_uop_dest_areg_addr       (spec_RAT_read_inst_r_uop_dest_areg_addr      ),
    .spec_RAT_read_inst_r_uop_dest_areg_data       (spec_RAT_read_inst_r_uop_dest_areg_data      ),
    .out_ren2dis_uop_dest_preg                     (out_ren2dis_uop_dest_preg                     ),
    .out_ren2dis_uop_dest_areg                     (out_ren2dis_uop_dest_areg                     ),
    .inst_r_uop_dest_areg                          (inst_r_uop_dest_areg_mod                     ),
 // .inst_r_uop_dest_areg                          (inst_r_uop_dest_areg                     ),
    .out_ren2dis_uop_old_dest_preg                 (out_ren2dis_uop_old_dest_preg                 ),
    .inst_r_uop_src1_areg                          (inst_r_uop_src1_areg_mod                     ),
 // .inst_r_uop_src1_areg                          (inst_r_uop_src1_areg                     ),
    .spec_RAT_read_inst_r_uop_src1_areg_addr       (spec_RAT_read_inst_r_uop_src1_areg_addr      ),
    .spec_RAT_read_inst_r_uop_src1_areg_data       (spec_RAT_read_inst_r_uop_src1_areg_data      ),
    .busy_table_read_out_ren2dis_uop_src1_preg_addr(busy_table_read_out_ren2dis_uop_src1_preg_addr),
    .busy_table_read_out_ren2dis_uop_src1_preg_data(busy_table_read_out_ren2dis_uop_src1_preg_data),
    .inst_r_uop_src1_en                            (inst_r_uop_src1_en                           ),
    .out_ren2dis_uop_src1_preg                     (out_ren2dis_uop_src1_preg                     ),
    .out_ren2dis_uop_src1_busy                     (out_ren2dis_uop_src1_busy                     ),
    .inst_r_uop_src2_areg                          (inst_r_uop_src2_areg_mod                     ),
 // .inst_r_uop_src2_areg                          (inst_r_uop_src2_areg                     ),
    .spec_RAT_read_inst_r_uop_src2_areg_addr       (spec_RAT_read_inst_r_uop_src2_areg_addr      ),
    .spec_RAT_read_inst_r_uop_src2_areg_data       (spec_RAT_read_inst_r_uop_src2_areg_data      ),
    .busy_table_read_out_ren2dis_uop_src2_preg_addr(busy_table_read_out_ren2dis_uop_src2_preg_addr),
    .busy_table_read_out_ren2dis_uop_src2_preg_data(busy_table_read_out_ren2dis_uop_src2_preg_data),
    .inst_r_uop_src2_en                            (inst_r_uop_src2_en                           ),
    .out_ren2dis_uop_src2_preg                     (out_ren2dis_uop_src2_preg                     ),
    .out_ren2dis_uop_src2_busy                     (out_ren2dis_uop_src2_busy                     )
);

generate
    for(i = 0; i < FETCH_WIDTH; i++) begin
        assign out_ren2dis_uop_dest_en[i] = inst_r_uop_dest_en[i];
    end 
endgenerate


wire [  $clog2(PRF_NUM)-1:0]  spec_alloc_write_out_ren2dis_uop_dest_preg_addr       [           FETCH_WIDTH-1:0];
wire                          spec_alloc_write_out_ren2dis_uop_dest_preg_data       [           FETCH_WIDTH-1:0];
wire                          spec_alloc_write_out_ren2dis_uop_dest_preg_en         [           FETCH_WIDTH-1:0]; 
wire [  $clog2(PRF_NUM)-1:0]  free_vec_write_out_ren2dis_uop_dest_preg_addr         [           FETCH_WIDTH-1:0];// fire  
wire                          free_vec_write_out_ren2dis_uop_dest_preg_data         [           FETCH_WIDTH-1:0];
wire                          free_vec_write_out_ren2dis_uop_dest_preg_en           [           FETCH_WIDTH-1:0]; 
wire [    $clog2(ARF_NUM):0]  spec_RAT_write_inst_r_uop_dest_areg_addr              [           FETCH_WIDTH-1:0];
wire [  $clog2(PRF_NUM)-1:0]  spec_RAT_write_inst_r_uop_dest_areg_data              [           FETCH_WIDTH-1:0];
wire                          spec_RAT_write_inst_r_uop_dest_areg_en                [           FETCH_WIDTH-1:0];
wire [  $clog2(PRF_NUM)-1:0]  busy_table_write_out_ren2dis_uop_dest_preg_addr       [           FETCH_WIDTH-1:0];
wire                          busy_table_write_out_ren2dis_uop_dest_preg_data       [           FETCH_WIDTH-1:0];
wire                          busy_table_write_out_ren2dis_uop_dest_preg_en         [           FETCH_WIDTH-1:0];
wire [  $clog2(PRF_NUM)-1:0]  alloc_checkpoint_write_out_ren2dis_uop_dest_preg_addr [           FETCH_WIDTH-1:0];
wire                          alloc_checkpoint_write_out_ren2dis_uop_dest_preg_data [           FETCH_WIDTH-1:0];
wire                          alloc_checkpoint_write_out_ren2dis_uop_dest_preg_en   [           FETCH_WIDTH-1:0]; 

wire                          fire                                                  [           FETCH_WIDTH-1:0];
rename_fire
#(
    .PRF_NUM     (PRF_NUM     ),
    .ROB_NUM     (ROB_NUM     ),
    .STQ_NUM     (STQ_NUM     ),
    .OP_NUM      (OP_NUM      ),
    .FETCH_WIDTH (FETCH_WIDTH ),
    .COMMIT_WIDTH(COMMIT_WIDTH),
    .ARF_NUM     (ARF_NUM     ),
    .MAX_BR_NUM  (MAX_BR_NUM  ),
    .ALU_NUM     (ALU_NUM     ),
    .AMOOP_NUM   (AMOOP_NUM   ),
    .CPU_WIDTH   (CPU_WIDTH   ),
    .FUNC3_WIDTH (FUNC3_WIDTH ),
    .CSR_WIDTH   (CSR_WIDTH   ),
    .TYPE_NUM    (TYPE_NUM    )
)
uut_rename_fire
(
    .out_ren2dis_valid                                    (out_ren2dis_valid                                    ),
    .in_dis2ren_ready                                     (in_dis2ren_ready                                     ),
    .inst_r_valid                                         (inst_r_valid                                         ),
    .fire                                                 (fire                                                 ),
    .out_ren2dis_uop_dest_en                              (out_ren2dis_uop_dest_en                              ),
    .inst_r_uop_type                                      (inst_r_uop_type                                      ),
    .inst_r_uop_dest_areg                                 (inst_r_uop_dest_areg_mod                             ),
 // .inst_r_uop_dest_areg                                 (inst_r_uop_dest_areg                                 ),
    .out_ren2dis_uop_dest_preg                            (out_ren2dis_uop_dest_preg                            ),
    .spec_alloc_write_out_ren2dis_uop_dest_preg_addr      (spec_alloc_write_out_ren2dis_uop_dest_preg_addr      ),
    .spec_alloc_write_out_ren2dis_uop_dest_preg_data      (spec_alloc_write_out_ren2dis_uop_dest_preg_data      ),
    .spec_alloc_write_out_ren2dis_uop_dest_preg_en        (spec_alloc_write_out_ren2dis_uop_dest_preg_en        ),
    .free_vec_write_out_ren2dis_uop_dest_preg_addr        (free_vec_write_out_ren2dis_uop_dest_preg_addr        ),
    .free_vec_write_out_ren2dis_uop_dest_preg_data        (free_vec_write_out_ren2dis_uop_dest_preg_data        ),
    .free_vec_write_out_ren2dis_uop_dest_preg_en          (free_vec_write_out_ren2dis_uop_dest_preg_en          ),
    .spec_RAT_write_inst_r_uop_dest_areg_addr             (spec_RAT_write_inst_r_uop_dest_areg_addr             ),
    .spec_RAT_write_inst_r_uop_dest_areg_data             (spec_RAT_write_inst_r_uop_dest_areg_data             ),
    .spec_RAT_write_inst_r_uop_dest_areg_en               (spec_RAT_write_inst_r_uop_dest_areg_en               ),
    .busy_table_write_out_ren2dis_uop_dest_preg_addr      (busy_table_write_out_ren2dis_uop_dest_preg_addr      ),
    .busy_table_write_out_ren2dis_uop_dest_preg_data      (busy_table_write_out_ren2dis_uop_dest_preg_data      ),
    .busy_table_write_out_ren2dis_uop_dest_preg_en        (busy_table_write_out_ren2dis_uop_dest_preg_en        ),
    .alloc_checkpoint_write_out_ren2dis_uop_dest_preg_addr(alloc_checkpoint_write_out_ren2dis_uop_dest_preg_addr),
    .alloc_checkpoint_write_out_ren2dis_uop_dest_preg_data(alloc_checkpoint_write_out_ren2dis_uop_dest_preg_data),
    .alloc_checkpoint_write_out_ren2dis_uop_dest_preg_en  (alloc_checkpoint_write_out_ren2dis_uop_dest_preg_en  ),
    .out_ren2dec_ready                                    (out_ren2dec_ready                                    )
);

wire alloc_checkpoint_tag [PRF_NUM-1:0];
wire [   $clog2(PRF_NUM)-1:0] spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_addr   [          COMMIT_WIDTH-1:0];
wire                          spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_data   [          COMMIT_WIDTH-1:0];
wire                          spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_en     [          COMMIT_WIDTH-1:0];
wire                          spec_alloc_normal                                                [               PRF_NUM-1:0];
rename_spec_alloc
#(
    .PRF_NUM     (PRF_NUM     ),
    .ROB_NUM     (ROB_NUM     ),
    .STQ_NUM     (STQ_NUM     ),
    .OP_NUM      (OP_NUM      ),
    .FETCH_WIDTH (FETCH_WIDTH ),
    .COMMIT_WIDTH(COMMIT_WIDTH),
    .ARF_NUM     (ARF_NUM     ),
    .MAX_BR_NUM  (MAX_BR_NUM  ),
    .ALU_NUM     (ALU_NUM     ),
    .AMOOP_NUM   (AMOOP_NUM   ),
    .CPU_WIDTH   (CPU_WIDTH   ),
    .FUNC3_WIDTH (FUNC3_WIDTH ),
    .CSR_WIDTH   (CSR_WIDTH   ),
    .TYPE_NUM    (TYPE_NUM    )
)
uut_rename_spec_alloc
(
 // .clk                                                            (clk                                                            ),// if use seq please open the commit
 // .rst                                                            (rst                                                            ),// if use seq please open the commit
    .spec_alloc_write_out_ren2dis_uop_dest_preg_addr                (spec_alloc_write_out_ren2dis_uop_dest_preg_addr                ),
    .spec_alloc_write_out_ren2dis_uop_dest_preg_data                (spec_alloc_write_out_ren2dis_uop_dest_preg_data                ),
    .spec_alloc_write_out_ren2dis_uop_dest_preg_en                  (spec_alloc_write_out_ren2dis_uop_dest_preg_en                  ),
    .spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_addr (spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_addr ),
    .spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_data (spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_data ),
    .spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_en   (spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_en   ),
    .alloc_checkpoint_tag                                           (alloc_checkpoint_tag                                           ),
    .in_dec_bcast_mispred                                           (in_dec_bcast_mispred                                           ),
    .in_rob_bcast_flush                                             (in_rob_bcast_flush                                             ),
    .spec_alloc                                                     (spec_alloc                                                     ),// test no seq
    .spec_alloc_1                                                   (spec_alloc_1                                                   ),
    .spec_alloc_normal                                              (spec_alloc_normal                                              )
);


wire [   $clog2(PRF_NUM)-1:0] free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_addr [          COMMIT_WIDTH-1:0];// commit
wire                          free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_data [          COMMIT_WIDTH-1:0];
wire                          free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_en   [          COMMIT_WIDTH-1:0];   
wire [PRF_NUM-1:0] free_vec_arry;
genvar k;
generate
    for(k = 0; k < PRF_NUM; k++) begin
        assign free_vec_arry[k] = free_vec[k];
    end
endgenerate
rename_free_vec
#(
    .PRF_NUM     (PRF_NUM     ),
    .ROB_NUM     (ROB_NUM     ),
    .STQ_NUM     (STQ_NUM     ),
    .OP_NUM      (OP_NUM      ),
    .FETCH_WIDTH (FETCH_WIDTH ),
    .COMMIT_WIDTH(COMMIT_WIDTH),
    .ARF_NUM     (ARF_NUM     ),
    .MAX_BR_NUM  (MAX_BR_NUM  ),
    .ALU_NUM     (ALU_NUM     ),
    .AMOOP_NUM   (AMOOP_NUM   ),
    .CPU_WIDTH   (CPU_WIDTH   ),
    .FUNC3_WIDTH (FUNC3_WIDTH ),
    .CSR_WIDTH   (CSR_WIDTH   ),
    .TYPE_NUM    (TYPE_NUM    )
)
uut_rename_free_vec
(
    // .clk                                                             (clk                                                             ),// if use seq please open the commit
    // .rst                                                             (rst                                                             ),// if use seq please open the commit
    .free_vec_write_out_ren2dis_uop_dest_preg_addr                    (free_vec_write_out_ren2dis_uop_dest_preg_addr                    ),
    .free_vec_write_out_ren2dis_uop_dest_preg_data                    (free_vec_write_out_ren2dis_uop_dest_preg_data                    ),
    .free_vec_write_out_ren2dis_uop_dest_preg_en                      (free_vec_write_out_ren2dis_uop_dest_preg_en                      ),
    .free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_addr (free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_addr ),
    .free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_data (free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_data ),
    .free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_en   (free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_en   ),
    .alloc_checkpoint_tag                                             (alloc_checkpoint_tag                                             ),    
    .in_dec_bcast_mispred                                             (in_dec_bcast_mispred                                             ),
    .in_rob_bcast_flush                                               (in_rob_bcast_flush                                               ),
    .spec_alloc_normal                                                (spec_alloc_normal                                                ),
    .free_vec                                                         (free_vec                                                         ),// test no seq
    .free_vec_1                                                       (free_vec_1                                                       ),// test no seq
    .alloc_reg_valid                                                  (alloc_reg_valid                                                  ),
    .alloc_reg                                                        (alloc_reg                                                        )
);


rename_spec_RAT
#(
    .PRF_NUM     (PRF_NUM     ),
    .ROB_NUM     (ROB_NUM     ),
    .STQ_NUM     (STQ_NUM     ),
    .OP_NUM      (OP_NUM      ),
    .FETCH_WIDTH (FETCH_WIDTH ),
    .COMMIT_WIDTH(COMMIT_WIDTH),
    .ARF_NUM     (ARF_NUM     ),
    .MAX_BR_NUM  (MAX_BR_NUM  ),
    .ALU_NUM     (ALU_NUM     ),
    .AMOOP_NUM   (AMOOP_NUM   ),
    .CPU_WIDTH   (CPU_WIDTH   ),
    .FUNC3_WIDTH (FUNC3_WIDTH ),
    .CSR_WIDTH   (CSR_WIDTH   ),
    .TYPE_NUM    (TYPE_NUM    )
)
uut_rename_spec_RAT
(
    // .clk                                     (clk                                     ),// if use seq please open the commit
    // .rst                                     (rst                                     ),// if use seq please open the commit
    .spec_RAT_read_inst_r_uop_dest_areg_addr (spec_RAT_read_inst_r_uop_dest_areg_addr ),
    .spec_RAT_read_inst_r_uop_dest_areg_data (spec_RAT_read_inst_r_uop_dest_areg_data ),
    .spec_RAT_read_inst_r_uop_src1_areg_addr (spec_RAT_read_inst_r_uop_src1_areg_addr ),
    .spec_RAT_read_inst_r_uop_src1_areg_data (spec_RAT_read_inst_r_uop_src1_areg_data ),
    .spec_RAT_read_inst_r_uop_src2_areg_addr (spec_RAT_read_inst_r_uop_src2_areg_addr ),
    .spec_RAT_read_inst_r_uop_src2_areg_data (spec_RAT_read_inst_r_uop_src2_areg_data ),
    .spec_RAT_write_inst_r_uop_dest_areg_addr(spec_RAT_write_inst_r_uop_dest_areg_addr),
    .spec_RAT_write_inst_r_uop_dest_areg_data(spec_RAT_write_inst_r_uop_dest_areg_data),
    .spec_RAT_write_inst_r_uop_dest_areg_en  (spec_RAT_write_inst_r_uop_dest_areg_en  ),
    .fire                                    (fire                                    ),
    .inst_r_uop_type                         (inst_r_uop_type                         ),
    .inst_r_uop_tag                          (inst_r_uop_tag                          ),
    .in_dec_bcast_mispred                    (in_dec_bcast_mispred                    ),
    .in_dec_bcast_br_tag                     (in_dec_bcast_br_tag                     ),
    .in_rob_bcast_flush                      (in_rob_bcast_flush                      ),
    .arch_RAT_1                              (arch_RAT_1                              ),
    // .RAT_checkpoint_tag                      (RAT_checkpoint_tag                      ),
    .spec_RAT                                (spec_RAT                                ),// test no seq
    .spec_RAT_1                              (spec_RAT_1                              ),// test no seq
    .RAT_checkpoint                          (RAT_checkpoint                          ),// test no seq
    .RAT_checkpoint_1                        (RAT_checkpoint_1                        ) // test no seq
);

rename_busy_table
#(
    .PRF_NUM     (PRF_NUM     ),
    .ROB_NUM     (ROB_NUM     ),
    .STQ_NUM     (STQ_NUM     ),
    .OP_NUM      (OP_NUM      ),
    .FETCH_WIDTH (FETCH_WIDTH ),
    .COMMIT_WIDTH(COMMIT_WIDTH),
    .ARF_NUM     (ARF_NUM     ),
    .MAX_BR_NUM  (MAX_BR_NUM  ),
    .ALU_NUM     (ALU_NUM     ),
    .AMOOP_NUM   (AMOOP_NUM   ),
    .CPU_WIDTH   (CPU_WIDTH   ),
    .FUNC3_WIDTH (FUNC3_WIDTH ),
    .CSR_WIDTH   (CSR_WIDTH   ),
    .TYPE_NUM    (TYPE_NUM    )
)
uut_rename_busy_table
(
    // .clk                                           (clk                                           ),// if use seq please open the commit
    // .rst                                           (rst                                           ),// if use seq please open the commit
    .busy_table_write_in_prf_awake_wake_preg_addr   (busy_table_write_in_prf_awake_wake_preg_addr   ),
    .busy_table_write_in_prf_awake_wake_preg_data   (busy_table_write_in_prf_awake_wake_preg_data   ),
    .busy_table_write_in_prf_awake_wake_preg_en     (busy_table_write_in_prf_awake_wake_preg_en     ),
    .busy_table_write_in_iss_awake_wake_preg_addr   (busy_table_write_in_iss_awake_wake_preg_addr   ),
    .busy_table_write_in_iss_awake_wake_preg_data   (busy_table_write_in_iss_awake_wake_preg_data   ),
    .busy_table_write_in_iss_awake_wake_preg_en     (busy_table_write_in_iss_awake_wake_preg_en     ),
    .busy_table_read_out_ren2dis_uop_src1_preg_addr (busy_table_read_out_ren2dis_uop_src1_preg_addr ),
    .busy_table_read_out_ren2dis_uop_src1_preg_data (busy_table_read_out_ren2dis_uop_src1_preg_data ),
    .busy_table_read_out_ren2dis_uop_src2_preg_addr (busy_table_read_out_ren2dis_uop_src2_preg_addr ),
    .busy_table_read_out_ren2dis_uop_src2_preg_data (busy_table_read_out_ren2dis_uop_src2_preg_data ),
    .busy_table_write_out_ren2dis_uop_dest_preg_addr(busy_table_write_out_ren2dis_uop_dest_preg_addr),
    .busy_table_write_out_ren2dis_uop_dest_preg_data(busy_table_write_out_ren2dis_uop_dest_preg_data),
    .busy_table_write_out_ren2dis_uop_dest_preg_en  (busy_table_write_out_ren2dis_uop_dest_preg_en  ),
    .busy_table                                     (busy_table                                     ),// test no seq
    .busy_table_1                                   (busy_table_1                                   ) // test no seq
);

// wire [PRF_NUM-1:0] alloc_checkpoint_set_arry   [MAX_BR_NUM-1:0];
// wire [PRF_NUM-1:0] alloc_checkpoint_set_1_arry [MAX_BR_NUM-1:0];
// generate
//     for(i = 0; i < MAX_BR_NUM; i++) begin
//         for(j = 0; j < PRF_NUM; j++) begin
//             assign alloc_checkpoint_set_arry  [i][j] = alloc_checkpoint_set  [j][i];
//             assign alloc_checkpoint_set_1_arry[i][j] = alloc_checkpoint_set_1[j][i];
//         end
//     end
// endgenerate



rename_alloc_checkpoint
#(
    .PRF_NUM     (PRF_NUM     ),
    .ROB_NUM     (ROB_NUM     ),
    .STQ_NUM     (STQ_NUM     ),
    .OP_NUM      (OP_NUM      ),
    .FETCH_WIDTH (FETCH_WIDTH ),
    .COMMIT_WIDTH(COMMIT_WIDTH),
    .ARF_NUM     (ARF_NUM     ),
    .MAX_BR_NUM  (MAX_BR_NUM  ),
    .ALU_NUM     (ALU_NUM     ),
    .AMOOP_NUM   (AMOOP_NUM   ),
    .CPU_WIDTH   (CPU_WIDTH   ),
    .FUNC3_WIDTH (FUNC3_WIDTH ),
    .CSR_WIDTH   (CSR_WIDTH   ),
    .TYPE_NUM    (TYPE_NUM    )
)
uut_rename_alloc_checkpoint
(
    // .clk                                                 (clk                                                 ),// if use seq please open the commit
    // .rst                                                 (rst                                                 ),// if use seq please open the commit
    .alloc_checkpoint_write_out_ren2dis_uop_dest_preg_addr(alloc_checkpoint_write_out_ren2dis_uop_dest_preg_addr),
    .alloc_checkpoint_write_out_ren2dis_uop_dest_preg_data(alloc_checkpoint_write_out_ren2dis_uop_dest_preg_data),
    .alloc_checkpoint_write_out_ren2dis_uop_dest_preg_en  (alloc_checkpoint_write_out_ren2dis_uop_dest_preg_en  ),
    .fire                                                 (fire                                                 ),
    .inst_r_uop_type                                      (inst_r_uop_type                                      ),
    .inst_r_uop_tag                                       (inst_r_uop_tag                                       ),
    .alloc_checkpoint_tag                                 (alloc_checkpoint_tag                                 ),
    .in_dec_bcast_br_tag                                  (in_dec_bcast_br_tag                                  ),
    .alloc_checkpoint                                     (alloc_checkpoint                                     ),// test no seq
    .alloc_checkpoint_1                                   (alloc_checkpoint_1                                   ) // test no seq
);

wire [  $clog2(ARF_NUM):0] arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_addr     [COMMIT_WIDTH-1:0];
wire [$clog2(PRF_NUM)-1:0] arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_data     [COMMIT_WIDTH-1:0];
wire                       arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_en       [COMMIT_WIDTH-1:0];

rename_commit
#(
    .PRF_NUM     (PRF_NUM     ),
    .ROB_NUM     (ROB_NUM     ),
    .STQ_NUM     (STQ_NUM     ),
    .OP_NUM      (OP_NUM      ),
    .FETCH_WIDTH (FETCH_WIDTH ),
    .COMMIT_WIDTH(COMMIT_WIDTH),
    .ARF_NUM     (ARF_NUM     ),
    .MAX_BR_NUM  (MAX_BR_NUM  ),
    .ALU_NUM     (ALU_NUM     ),
    .AMOOP_NUM   (AMOOP_NUM   ),
    .CPU_WIDTH   (CPU_WIDTH   ),
    .FUNC3_WIDTH (FUNC3_WIDTH ),
    .CSR_WIDTH   (CSR_WIDTH   ),
    .TYPE_NUM    (TYPE_NUM    )
)
uut_rename_commit
(
    .in_rob_commit_commit_entry_valid                                (in_rob_commit_commit_entry_valid                                ),
    .in_rob_commit_commit_entry_uop_dest_en                          (in_rob_commit_commit_entry_uop_dest_en                          ),
    .in_rob_commit_commit_entry_uop_page_fault_load                  (in_rob_commit_commit_entry_uop_page_fault_load                  ),
    .in_rob_bcast_interrupt                                          (in_rob_bcast_interrupt                                          ),
    .in_rob_bcast_illegal_inst                                       (in_rob_bcast_illegal_inst                                       ),
    .in_rob_commit_commit_entry_uop_old_dest_preg                    (in_rob_commit_commit_entry_uop_old_dest_preg                    ),
    .free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_addr(free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_addr),
    .free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_data(free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_data),
    .free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_en  (free_vec_write_in_rob_commit_commit_entry_uop_old_dest_preg_en  ),
    .in_rob_commit_commit_entry_uop_dest_preg                        (in_rob_commit_commit_entry_uop_dest_preg                        ),
    .spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_addr  (spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_addr  ),
    .spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_data  (spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_data  ),
    .spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_en    (spec_alloc_write_in_rob_commit_commit_entry_uop_dest_preg_en    ),
    .in_rob_commit_commit_entry_uop_dest_areg     	                 (in_rob_commit_commit_entry_uop_dest_areg     	                  ),
    .arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_addr    (arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_addr    ),
    .arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_data    (arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_data    ),
    .arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_en      (arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_en      )
);

rename_arch_RAT
#(
    .PRF_NUM     (PRF_NUM     ),
    .ROB_NUM     (ROB_NUM     ),
    .STQ_NUM     (STQ_NUM     ),
    .OP_NUM      (OP_NUM      ),
    .FETCH_WIDTH (FETCH_WIDTH ),
    .COMMIT_WIDTH(COMMIT_WIDTH),
    .ARF_NUM     (ARF_NUM     ),
    .MAX_BR_NUM  (MAX_BR_NUM  ),
    .ALU_NUM     (ALU_NUM     ),
    .AMOOP_NUM   (AMOOP_NUM   ),
    .CPU_WIDTH   (CPU_WIDTH   ),
    .FUNC3_WIDTH (FUNC3_WIDTH ),
    .CSR_WIDTH   (CSR_WIDTH   ),
    .TYPE_NUM    (TYPE_NUM    )
)
uut_rename_arch_RAT
(
    .arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_addr(arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_addr),
    .arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_data(arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_data),
    .arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_en  (arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_en  ),
    .arch_RAT                                                    (arch_RAT                                                    ),
    .arch_RAT_1                                                  (arch_RAT_1                                                  )
);

rename_pipline
#(
    .PRF_NUM     (PRF_NUM     ),
    .ROB_NUM     (ROB_NUM     ),
    .STQ_NUM     (STQ_NUM     ),
    .OP_NUM      (OP_NUM      ),
    .FETCH_WIDTH (FETCH_WIDTH ),
    .COMMIT_WIDTH(COMMIT_WIDTH),
    .ARF_NUM     (ARF_NUM     ),
    .MAX_BR_NUM  (MAX_BR_NUM  ),
    .ALU_NUM     (ALU_NUM     ),
    .AMOOP_NUM   (AMOOP_NUM   ),
    .CPU_WIDTH   (CPU_WIDTH   ),
    .FUNC3_WIDTH (FUNC3_WIDTH ),
    .CSR_WIDTH   (CSR_WIDTH   ),
    .TYPE_NUM    (TYPE_NUM    )
)
uut_rename_pipline
(
    .in_dec_bcast_mispred           (in_dec_bcast_mispred           ),
    .in_rob_bcast_flush             (in_rob_bcast_flush             ),
    .out_ren2dec_ready              (out_ren2dec_ready              ),
    .fire                           (fire                           ),
    .in_dec2ren_uop_instruction     (in_dec2ren_uop_instruction     ),
    .in_dec2ren_uop_dest_areg       (in_dec2ren_uop_dest_areg       ),
    .in_dec2ren_uop_src1_areg       (in_dec2ren_uop_src1_areg       ),
    .in_dec2ren_uop_src2_areg       (in_dec2ren_uop_src2_areg       ),
    .in_dec2ren_uop_dest_preg       (in_dec2ren_uop_dest_preg       ),
    .in_dec2ren_uop_src1_preg       (in_dec2ren_uop_src1_preg       ),
    .in_dec2ren_uop_src2_preg       (in_dec2ren_uop_src2_preg       ),
    .in_dec2ren_uop_old_dest_preg   (in_dec2ren_uop_old_dest_preg   ),
    .in_dec2ren_uop_src1_rdata      (in_dec2ren_uop_src1_rdata      ),
    .in_dec2ren_uop_src2_rdata      (in_dec2ren_uop_src2_rdata      ),
    .in_dec2ren_uop_result          (in_dec2ren_uop_result          ),
    .in_dec2ren_uop_pred_br_taken   (in_dec2ren_uop_pred_br_taken   ),
    .in_dec2ren_uop_alt_pred        (in_dec2ren_uop_alt_pred        ),
    .in_dec2ren_uop_altpcpn         (in_dec2ren_uop_altpcpn         ),
    .in_dec2ren_uop_pcpn            (in_dec2ren_uop_pcpn            ),
    .in_dec2ren_uop_pred_br_pc      (in_dec2ren_uop_pred_br_pc      ),
    .in_dec2ren_uop_mispred         (in_dec2ren_uop_mispred         ),
    .in_dec2ren_uop_br_taken        (in_dec2ren_uop_br_taken        ),
    .in_dec2ren_uop_pc_next         (in_dec2ren_uop_pc_next         ),
    .in_dec2ren_uop_dest_en         (in_dec2ren_uop_dest_en         ),
    .in_dec2ren_uop_src1_en         (in_dec2ren_uop_src1_en         ),
    .in_dec2ren_uop_src2_en         (in_dec2ren_uop_src2_en         ),
    .in_dec2ren_uop_src1_busy       (in_dec2ren_uop_src1_busy       ),
    .in_dec2ren_uop_src2_busy       (in_dec2ren_uop_src2_busy       ),
    .in_dec2ren_uop_src1_latency    (in_dec2ren_uop_src1_latency    ),
    .in_dec2ren_uop_src2_latency    (in_dec2ren_uop_src2_latency    ),
    .in_dec2ren_uop_src1_is_pc      (in_dec2ren_uop_src1_is_pc      ),
    .in_dec2ren_uop_src2_is_imm     (in_dec2ren_uop_src2_is_imm     ),
    .in_dec2ren_uop_func3           (in_dec2ren_uop_func3           ),
    .in_dec2ren_uop_func7_5         (in_dec2ren_uop_func7_5         ),
    .in_dec2ren_uop_imm             (in_dec2ren_uop_imm             ),
    .in_dec2ren_uop_pc              (in_dec2ren_uop_pc              ),
    .in_dec2ren_uop_tag             (in_dec2ren_uop_tag             ),
    .in_dec2ren_uop_csr_idx         (in_dec2ren_uop_csr_idx         ),
    .in_dec2ren_uop_rob_idx         (in_dec2ren_uop_rob_idx         ),
    .in_dec2ren_uop_stq_idx         (in_dec2ren_uop_stq_idx         ),
    .in_dec2ren_uop_pre_sta_mask    (in_dec2ren_uop_pre_sta_mask    ),
    .in_dec2ren_uop_pre_std_mask    (in_dec2ren_uop_pre_std_mask    ),
    .in_dec2ren_uop_uop_num         (in_dec2ren_uop_uop_num         ),
    .in_dec2ren_uop_cplt_num        (in_dec2ren_uop_cplt_num        ),
    .in_dec2ren_uop_rob_flag        (in_dec2ren_uop_rob_flag        ),
    .in_dec2ren_uop_page_fault_inst (in_dec2ren_uop_page_fault_inst ),
    .in_dec2ren_uop_page_fault_load (in_dec2ren_uop_page_fault_load ),
    .in_dec2ren_uop_page_fault_store(in_dec2ren_uop_page_fault_store),
    .in_dec2ren_uop_illegal_inst    (in_dec2ren_uop_illegal_inst    ),
    .in_dec2ren_uop_type            (in_dec2ren_uop_type            ),
    .in_dec2ren_uop_op              (in_dec2ren_uop_op              ),
    .in_dec2ren_uop_amoop           (in_dec2ren_uop_amoop           ),
    .in_dec2ren_valid               (in_dec2ren_valid               ),
    .inst_r_1_uop_instruction       (inst_r_1_uop_instruction       ),
    .inst_r_1_uop_dest_areg         (inst_r_1_uop_dest_areg         ),
    .inst_r_1_uop_src1_areg         (inst_r_1_uop_src1_areg         ),
    .inst_r_1_uop_src2_areg         (inst_r_1_uop_src2_areg         ),
    .inst_r_1_uop_dest_preg         (inst_r_1_uop_dest_preg         ),
    .inst_r_1_uop_src1_preg         (inst_r_1_uop_src1_preg         ),
    .inst_r_1_uop_src2_preg         (inst_r_1_uop_src2_preg         ),
    .inst_r_1_uop_old_dest_preg     (inst_r_1_uop_old_dest_preg     ),
    .inst_r_1_uop_src1_rdata        (inst_r_1_uop_src1_rdata        ),
    .inst_r_1_uop_src2_rdata        (inst_r_1_uop_src2_rdata        ),
    .inst_r_1_uop_result            (inst_r_1_uop_result            ),
    .inst_r_1_uop_pred_br_taken     (inst_r_1_uop_pred_br_taken     ),
    .inst_r_1_uop_alt_pred          (inst_r_1_uop_alt_pred          ),
    .inst_r_1_uop_altpcpn           (inst_r_1_uop_altpcpn           ),
    .inst_r_1_uop_pcpn              (inst_r_1_uop_pcpn              ),
    .inst_r_1_uop_pred_br_pc        (inst_r_1_uop_pred_br_pc        ),
    .inst_r_1_uop_mispred           (inst_r_1_uop_mispred           ),
    .inst_r_1_uop_br_taken          (inst_r_1_uop_br_taken          ),
    .inst_r_1_uop_pc_next           (inst_r_1_uop_pc_next           ),
    .inst_r_1_uop_dest_en           (inst_r_1_uop_dest_en           ),
    .inst_r_1_uop_src1_en           (inst_r_1_uop_src1_en           ),
    .inst_r_1_uop_src2_en           (inst_r_1_uop_src2_en           ),
    .inst_r_1_uop_src1_busy         (inst_r_1_uop_src1_busy         ),
    .inst_r_1_uop_src2_busy         (inst_r_1_uop_src2_busy         ),
    .inst_r_1_uop_src1_latency      (inst_r_1_uop_src1_latency      ),
    .inst_r_1_uop_src2_latency      (inst_r_1_uop_src2_latency      ),
    .inst_r_1_uop_src1_is_pc        (inst_r_1_uop_src1_is_pc        ),
    .inst_r_1_uop_src2_is_imm       (inst_r_1_uop_src2_is_imm       ),
    .inst_r_1_uop_func3             (inst_r_1_uop_func3             ),
    .inst_r_1_uop_func7_5           (inst_r_1_uop_func7_5           ),
    .inst_r_1_uop_imm               (inst_r_1_uop_imm               ),
    .inst_r_1_uop_pc                (inst_r_1_uop_pc                ),
    .inst_r_1_uop_tag               (inst_r_1_uop_tag               ),
    .inst_r_1_uop_csr_idx           (inst_r_1_uop_csr_idx           ),
    .inst_r_1_uop_rob_idx           (inst_r_1_uop_rob_idx           ),
    .inst_r_1_uop_stq_idx           (inst_r_1_uop_stq_idx           ),
    .inst_r_1_uop_pre_sta_mask      (inst_r_1_uop_pre_sta_mask      ),
    .inst_r_1_uop_pre_std_mask      (inst_r_1_uop_pre_std_mask      ),
    .inst_r_1_uop_uop_num           (inst_r_1_uop_uop_num           ),
    .inst_r_1_uop_cplt_num          (inst_r_1_uop_cplt_num          ),
    .inst_r_1_uop_rob_flag          (inst_r_1_uop_rob_flag          ),
    .inst_r_1_uop_page_fault_inst   (inst_r_1_uop_page_fault_inst   ),
    .inst_r_1_uop_page_fault_load   (inst_r_1_uop_page_fault_load   ),
    .inst_r_1_uop_page_fault_store  (inst_r_1_uop_page_fault_store  ),
    .inst_r_1_uop_illegal_inst      (inst_r_1_uop_illegal_inst      ),
    .inst_r_1_uop_type              (inst_r_1_uop_type              ),
    .inst_r_1_uop_op                (inst_r_1_uop_op                ),
    .inst_r_1_uop_amoop             (inst_r_1_uop_amoop             ),
    .inst_r_1_valid                 (inst_r_1_valid                 ),
    .inst_r_uop_instruction         (inst_r_uop_instruction         ),
    .inst_r_uop_dest_areg           (inst_r_uop_dest_areg           ),
    .inst_r_uop_src1_areg           (inst_r_uop_src1_areg           ),
    .inst_r_uop_src2_areg           (inst_r_uop_src2_areg           ),
    .inst_r_uop_dest_preg           (inst_r_uop_dest_preg           ),
    .inst_r_uop_src1_preg           (inst_r_uop_src1_preg           ),
    .inst_r_uop_src2_preg           (inst_r_uop_src2_preg           ),
    .inst_r_uop_old_dest_preg       (inst_r_uop_old_dest_preg       ),
    .inst_r_uop_src1_rdata          (inst_r_uop_src1_rdata          ),
    .inst_r_uop_src2_rdata          (inst_r_uop_src2_rdata          ),
    .inst_r_uop_result              (inst_r_uop_result              ),
    .inst_r_uop_pred_br_taken       (inst_r_uop_pred_br_taken       ),
    .inst_r_uop_alt_pred            (inst_r_uop_alt_pred            ),
    .inst_r_uop_altpcpn             (inst_r_uop_altpcpn             ),
    .inst_r_uop_pcpn                (inst_r_uop_pcpn                ),
    .inst_r_uop_pred_br_pc          (inst_r_uop_pred_br_pc          ),
    .inst_r_uop_mispred             (inst_r_uop_mispred             ),
    .inst_r_uop_br_taken            (inst_r_uop_br_taken            ),
    .inst_r_uop_pc_next             (inst_r_uop_pc_next             ),
    .inst_r_uop_dest_en             (inst_r_uop_dest_en             ),
    .inst_r_uop_src1_en             (inst_r_uop_src1_en             ),
    .inst_r_uop_src2_en             (inst_r_uop_src2_en             ),
    .inst_r_uop_src1_busy           (inst_r_uop_src1_busy           ),
    .inst_r_uop_src2_busy           (inst_r_uop_src2_busy           ),
    .inst_r_uop_src1_latency        (inst_r_uop_src1_latency        ),
    .inst_r_uop_src2_latency        (inst_r_uop_src2_latency        ),
    .inst_r_uop_src1_is_pc          (inst_r_uop_src1_is_pc          ),
    .inst_r_uop_src2_is_imm         (inst_r_uop_src2_is_imm         ),
    .inst_r_uop_func3               (inst_r_uop_func3               ),
    .inst_r_uop_func7_5             (inst_r_uop_func7_5             ),
    .inst_r_uop_imm                 (inst_r_uop_imm                 ),
    .inst_r_uop_pc                  (inst_r_uop_pc                  ),
    .inst_r_uop_tag                 (inst_r_uop_tag                 ),
    .inst_r_uop_csr_idx             (inst_r_uop_csr_idx             ),
    .inst_r_uop_rob_idx             (inst_r_uop_rob_idx             ),
    .inst_r_uop_stq_idx             (inst_r_uop_stq_idx             ),
    .inst_r_uop_pre_sta_mask        (inst_r_uop_pre_sta_mask        ),
    .inst_r_uop_pre_std_mask        (inst_r_uop_pre_std_mask        ),
    .inst_r_uop_uop_num             (inst_r_uop_uop_num             ),
    .inst_r_uop_cplt_num            (inst_r_uop_cplt_num            ),
    .inst_r_uop_rob_flag            (inst_r_uop_rob_flag            ),
    .inst_r_uop_page_fault_inst     (inst_r_uop_page_fault_inst     ),
    .inst_r_uop_page_fault_load     (inst_r_uop_page_fault_load     ),
    .inst_r_uop_page_fault_store    (inst_r_uop_page_fault_store    ),
    .inst_r_uop_illegal_inst        (inst_r_uop_illegal_inst        ),
    .inst_r_uop_type                (inst_r_uop_type                ),
    .inst_r_uop_op                  (inst_r_uop_op                  ),
    .inst_r_uop_amoop               (inst_r_uop_amoop               ),
    .inst_r_valid                   (inst_r_valid                   )
);

endmodule