`timescale 1ns/1ps
module rename_alloc
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
    input                               alloc_reg_valid                         [FETCH_WIDTH-1:0],
    input       [  $clog2(PRF_NUM)-1:0] alloc_reg                               [FETCH_WIDTH-1:0],
    input                               inst_r_valid                            [FETCH_WIDTH-1:0], // used
    input       [  $clog2(PRF_NUM)-1:0] inst_r_uop_dest_preg                    [FETCH_WIDTH-1:0], // used
    input                               inst_r_uop_dest_en                      [FETCH_WIDTH-1:0], // used
    
    input	    [        CPU_WIDTH-1:0]	inst_r_uop_instruction           	    [FETCH_WIDTH-1:0],
    input	    [    $clog2(ARF_NUM):0]	inst_r_uop_dest_areg             	    [FETCH_WIDTH-1:0],
    input	    [    $clog2(ARF_NUM):0]	inst_r_uop_src1_areg             	    [FETCH_WIDTH-1:0],
    input	    [    $clog2(ARF_NUM):0]	inst_r_uop_src2_areg             	    [FETCH_WIDTH-1:0],
 // input	    [  $clog2(PRF_NUM)-1:0]	inst_r_uop_dest_preg             	    [FETCH_WIDTH-1:0],
    input	    [  $clog2(PRF_NUM)-1:0]	inst_r_uop_src1_preg             	    [FETCH_WIDTH-1:0],
    input	    [  $clog2(PRF_NUM)-1:0]	inst_r_uop_src2_preg             	    [FETCH_WIDTH-1:0],
    input	    [  $clog2(PRF_NUM)-1:0]	inst_r_uop_old_dest_preg         	    [FETCH_WIDTH-1:0],
    input	    [        CPU_WIDTH-1:0]	inst_r_uop_src1_rdata            	    [FETCH_WIDTH-1:0],
    input	    [        CPU_WIDTH-1:0]	inst_r_uop_src2_rdata            	    [FETCH_WIDTH-1:0],
    input	    [        CPU_WIDTH-1:0]	inst_r_uop_result                	    [FETCH_WIDTH-1:0],
    input	    [                1-1:0]	inst_r_uop_pred_br_taken         	    [FETCH_WIDTH-1:0],
    input	    [                1-1:0]	inst_r_uop_alt_pred              	    [FETCH_WIDTH-1:0],
    input	    [                8-1:0]	inst_r_uop_altpcpn               	    [FETCH_WIDTH-1:0],
    input	    [                8-1:0]	inst_r_uop_pcpn                  	    [FETCH_WIDTH-1:0],
    input	    [        CPU_WIDTH-1:0]	inst_r_uop_pred_br_pc            	    [FETCH_WIDTH-1:0],
    input	    [                1-1:0]	inst_r_uop_mispred               	    [FETCH_WIDTH-1:0],
    input	    [                1-1:0]	inst_r_uop_br_taken              	    [FETCH_WIDTH-1:0],
    input	    [        CPU_WIDTH-1:0]	inst_r_uop_pc_next               	    [FETCH_WIDTH-1:0],
 // input	    [                1-1:0]	inst_r_uop_dest_en               	    [FETCH_WIDTH-1:0],
    input	    [                1-1:0]	inst_r_uop_src1_en               	    [FETCH_WIDTH-1:0],
    input	    [                1-1:0]	inst_r_uop_src2_en               	    [FETCH_WIDTH-1:0],
    input	    [                1-1:0]	inst_r_uop_src1_busy             	    [FETCH_WIDTH-1:0],
    input	    [                1-1:0]	inst_r_uop_src2_busy             	    [FETCH_WIDTH-1:0],
    input	    [                4-1:0]	inst_r_uop_src1_latency          	    [FETCH_WIDTH-1:0],
    input	    [                4-1:0]	inst_r_uop_src2_latency          	    [FETCH_WIDTH-1:0],
    input	    [                1-1:0]	inst_r_uop_src1_is_pc            	    [FETCH_WIDTH-1:0],
    input	    [                1-1:0]	inst_r_uop_src2_is_imm           	    [FETCH_WIDTH-1:0],
    input	    [      FUNC3_WIDTH-1:0]	inst_r_uop_func3                 	    [FETCH_WIDTH-1:0],
    input	    [                1-1:0]	inst_r_uop_func7_5               	    [FETCH_WIDTH-1:0],
    input	    [        CPU_WIDTH-1:0]	inst_r_uop_imm                   	    [FETCH_WIDTH-1:0],
    input	    [        CPU_WIDTH-1:0]	inst_r_uop_pc                    	    [FETCH_WIDTH-1:0],
    input	    [                4-1:0]	inst_r_uop_tag                   	    [FETCH_WIDTH-1:0],
    input	    [        CSR_WIDTH-1:0]	inst_r_uop_csr_idx               	    [FETCH_WIDTH-1:0],
    input	    [  $clog2(ROB_NUM)-1:0]	inst_r_uop_rob_idx               	    [FETCH_WIDTH-1:0],
    input	    [  $clog2(STQ_NUM)-1:0]	inst_r_uop_stq_idx               	    [FETCH_WIDTH-1:0],
    input	    [               16-1:0]	inst_r_uop_pre_sta_mask          	    [FETCH_WIDTH-1:0],
    input	    [               16-1:0]	inst_r_uop_pre_std_mask          	    [FETCH_WIDTH-1:0],
    input	    [                2-1:0]	inst_r_uop_uop_num               	    [FETCH_WIDTH-1:0],
    input	    [                2-1:0]	inst_r_uop_cplt_num              	    [FETCH_WIDTH-1:0],
    input	    [                1-1:0]	inst_r_uop_rob_flag              	    [FETCH_WIDTH-1:0],
    input	    [                1-1:0]	inst_r_uop_page_fault_inst       	    [FETCH_WIDTH-1:0],
    input	    [                1-1:0]	inst_r_uop_page_fault_load       	    [FETCH_WIDTH-1:0],
    input	    [                1-1:0]	inst_r_uop_page_fault_store      	    [FETCH_WIDTH-1:0],
    input	    [                1-1:0]	inst_r_uop_illegal_inst          	    [FETCH_WIDTH-1:0],
    input	    [ $clog2(TYPE_NUM)-1:0]	inst_r_uop_type                  	    [FETCH_WIDTH-1:0],
    input	    [   $clog2(OP_NUM)-1:0]	inst_r_uop_op                    	    [FETCH_WIDTH-1:0],
    input	    [$clog2(AMOOP_NUM)-1:0]	inst_r_uop_amoop                 	    [FETCH_WIDTH-1:0],   
 // input	    [                1-1:0]	inst_r_valid                     	    [FETCH_WIDTH-1:0]

	output reg	[        CPU_WIDTH-1:0]	out_ren2dis_uop_instruction         	[FETCH_WIDTH-1:0],
	output reg	[    $clog2(ARF_NUM):0]	out_ren2dis_uop_dest_areg           	[FETCH_WIDTH-1:0],
	output reg	[    $clog2(ARF_NUM):0]	out_ren2dis_uop_src1_areg           	[FETCH_WIDTH-1:0],
	output reg	[    $clog2(ARF_NUM):0]	out_ren2dis_uop_src2_areg           	[FETCH_WIDTH-1:0],
 // output reg	[  $clog2(PRF_NUM)-1:0]	out_ren2dis_uop_dest_preg           	[FETCH_WIDTH-1:0],
 // output reg	[  $clog2(PRF_NUM)-1:0]	out_ren2dis_uop_src1_preg           	[FETCH_WIDTH-1:0],
 // output reg	[  $clog2(PRF_NUM)-1:0]	out_ren2dis_uop_src2_preg           	[FETCH_WIDTH-1:0],
 // output reg	[  $clog2(PRF_NUM)-1:0]	out_ren2dis_uop_old_dest_preg       	[FETCH_WIDTH-1:0],
	output reg	[        CPU_WIDTH-1:0]	out_ren2dis_uop_src1_rdata          	[FETCH_WIDTH-1:0],
	output reg	[        CPU_WIDTH-1:0]	out_ren2dis_uop_src2_rdata          	[FETCH_WIDTH-1:0],
	output reg	[        CPU_WIDTH-1:0]	out_ren2dis_uop_result              	[FETCH_WIDTH-1:0],
	output reg	[                1-1:0] out_ren2dis_uop_pred_br_taken           [FETCH_WIDTH-1:0],
	output reg	[                1-1:0] out_ren2dis_uop_alt_pred                [FETCH_WIDTH-1:0],
	output reg	[                8-1:0]	out_ren2dis_uop_altpcpn             	[FETCH_WIDTH-1:0],
	output reg	[                8-1:0]	out_ren2dis_uop_pcpn                	[FETCH_WIDTH-1:0],
	output reg	[        CPU_WIDTH-1:0]	out_ren2dis_uop_pred_br_pc          	[FETCH_WIDTH-1:0],
	output reg	[                1-1:0]	out_ren2dis_uop_mispred             	[FETCH_WIDTH-1:0],
	output reg	[                1-1:0]	out_ren2dis_uop_br_taken            	[FETCH_WIDTH-1:0],
	output reg	[        CPU_WIDTH-1:0]	out_ren2dis_uop_pc_next             	[FETCH_WIDTH-1:0],
	output reg	[                1-1:0]	out_ren2dis_uop_dest_en             	[FETCH_WIDTH-1:0],
	output reg	[                1-1:0]	out_ren2dis_uop_src1_en             	[FETCH_WIDTH-1:0],
	output reg	[                1-1:0]	out_ren2dis_uop_src2_en             	[FETCH_WIDTH-1:0],
 // output reg	[                1-1:0]	out_ren2dis_uop_src1_busy           	[FETCH_WIDTH-1:0],
 // output reg	[                1-1:0]	out_ren2dis_uop_src2_busy           	[FETCH_WIDTH-1:0],
	output reg	[                4-1:0]	out_ren2dis_uop_src1_latency        	[FETCH_WIDTH-1:0],
	output reg	[                4-1:0]	out_ren2dis_uop_src2_latency        	[FETCH_WIDTH-1:0],
	output reg	[                1-1:0]	out_ren2dis_uop_src1_is_pc          	[FETCH_WIDTH-1:0],
	output reg	[                1-1:0]	out_ren2dis_uop_src2_is_imm         	[FETCH_WIDTH-1:0],
	output reg	[      FUNC3_WIDTH-1:0]	out_ren2dis_uop_func3               	[FETCH_WIDTH-1:0],
	output reg	[                1-1:0]	out_ren2dis_uop_func7_5             	[FETCH_WIDTH-1:0],
	output reg	[        CPU_WIDTH-1:0]	out_ren2dis_uop_imm                 	[FETCH_WIDTH-1:0],
	output reg	[        CPU_WIDTH-1:0]	out_ren2dis_uop_pc                  	[FETCH_WIDTH-1:0],
	output reg	[                4-1:0]	out_ren2dis_uop_tag                 	[FETCH_WIDTH-1:0],
	output reg	[        CSR_WIDTH-1:0]	out_ren2dis_uop_csr_idx             	[FETCH_WIDTH-1:0],
	output reg	[  $clog2(ROB_NUM)-1:0]	out_ren2dis_uop_rob_idx             	[FETCH_WIDTH-1:0],
	output reg	[  $clog2(STQ_NUM)-1:0]	out_ren2dis_uop_stq_idx             	[FETCH_WIDTH-1:0],
	output reg	[               16-1:0]	out_ren2dis_uop_pre_sta_mask        	[FETCH_WIDTH-1:0],
	output reg	[               16-1:0]	out_ren2dis_uop_pre_std_mask        	[FETCH_WIDTH-1:0],
	output reg	[                2-1:0]	out_ren2dis_uop_uop_num             	[FETCH_WIDTH-1:0],
	output reg	[                2-1:0]	out_ren2dis_uop_cplt_num            	[FETCH_WIDTH-1:0],
	output reg	[                1-1:0]	out_ren2dis_uop_rob_flag            	[FETCH_WIDTH-1:0],
	output reg	[                1-1:0]	out_ren2dis_uop_page_fault_inst     	[FETCH_WIDTH-1:0],
	output reg	[                1-1:0]	out_ren2dis_uop_page_fault_load     	[FETCH_WIDTH-1:0],
	output reg	[                1-1:0]	out_ren2dis_uop_page_fault_store    	[FETCH_WIDTH-1:0],
	output reg	[                1-1:0]	out_ren2dis_uop_illegal_inst        	[FETCH_WIDTH-1:0],
	output reg	[ $clog2(TYPE_NUM)-1:0]	out_ren2dis_uop_type                	[FETCH_WIDTH-1:0],
	output reg	[   $clog2(OP_NUM)-1:0]	out_ren2dis_uop_op                  	[FETCH_WIDTH-1:0],
	output reg	[$clog2(AMOOP_NUM)-1:0]	out_ren2dis_uop_amoop               	[FETCH_WIDTH-1:0],
 // output reg	[                1-1:0]	out_ren2dis_valid                   	[FETCH_WIDTH-1:0], 


    output reg                          out_ren2dis_valid                       [FETCH_WIDTH-1:0],
    output reg [   $clog2(PRF_NUM)-1:0] out_ren2dis_uop_dest_preg               [FETCH_WIDTH-1:0]

);

integer i;
always @(*) begin
	for(i = 0; i < FETCH_WIDTH; i++) begin
        out_ren2dis_uop_instruction     [i] = inst_r_uop_instruction     [i];
        out_ren2dis_uop_dest_areg       [i] = inst_r_uop_dest_areg       [i];
        out_ren2dis_uop_src1_areg       [i] = inst_r_uop_src1_areg       [i];
        out_ren2dis_uop_src2_areg       [i] = inst_r_uop_src2_areg       [i];
        // out_ren2dis_uop_dest_preg       [i] = inst_r_uop_dest_preg       [i];
        // out_ren2dis_uop_src1_preg       [i] = inst_r_uop_src1_preg       [i];
        // out_ren2dis_uop_src2_preg       [i] = inst_r_uop_src2_preg       [i];
        // out_ren2dis_uop_old_dest_preg   [i] = inst_r_uop_old_dest_preg   [i];
        out_ren2dis_uop_src1_rdata      [i] = inst_r_uop_src1_rdata      [i];
        out_ren2dis_uop_src2_rdata      [i] = inst_r_uop_src2_rdata      [i];
        out_ren2dis_uop_result          [i] = inst_r_uop_result          [i];
        out_ren2dis_uop_pred_br_taken   [i] = inst_r_uop_pred_br_taken   [i];
        out_ren2dis_uop_alt_pred        [i] = inst_r_uop_alt_pred        [i];
        out_ren2dis_uop_altpcpn         [i] = inst_r_uop_altpcpn         [i];
        out_ren2dis_uop_pcpn            [i] = inst_r_uop_pcpn            [i];
        out_ren2dis_uop_pred_br_pc      [i] = inst_r_uop_pred_br_pc      [i];
        out_ren2dis_uop_mispred         [i] = inst_r_uop_mispred         [i];
        out_ren2dis_uop_br_taken        [i] = inst_r_uop_br_taken        [i];
        out_ren2dis_uop_pc_next         [i] = inst_r_uop_pc_next         [i];
        out_ren2dis_uop_dest_en         [i] = inst_r_uop_dest_en         [i];
        out_ren2dis_uop_src1_en         [i] = inst_r_uop_src1_en         [i];
        out_ren2dis_uop_src2_en         [i] = inst_r_uop_src2_en         [i];
        // out_ren2dis_uop_src1_busy       [i] = inst_r_uop_src1_busy       [i];
        // out_ren2dis_uop_src2_busy       [i] = inst_r_uop_src2_busy       [i];
        out_ren2dis_uop_src1_latency    [i] = inst_r_uop_src1_latency    [i];
        out_ren2dis_uop_src2_latency    [i] = inst_r_uop_src2_latency    [i];
        out_ren2dis_uop_src1_is_pc      [i] = inst_r_uop_src1_is_pc      [i];
        out_ren2dis_uop_src2_is_imm     [i] = inst_r_uop_src2_is_imm     [i];
        out_ren2dis_uop_func3           [i] = inst_r_uop_func3           [i];
        out_ren2dis_uop_func7_5         [i] = inst_r_uop_func7_5         [i];
        out_ren2dis_uop_imm             [i] = inst_r_uop_imm             [i];
        out_ren2dis_uop_pc              [i] = inst_r_uop_pc              [i];
        out_ren2dis_uop_tag             [i] = inst_r_uop_tag             [i];
        out_ren2dis_uop_csr_idx         [i] = inst_r_uop_csr_idx         [i];
        out_ren2dis_uop_rob_idx         [i] = inst_r_uop_rob_idx         [i];
        out_ren2dis_uop_stq_idx         [i] = inst_r_uop_stq_idx         [i];
        out_ren2dis_uop_pre_sta_mask    [i] = inst_r_uop_pre_sta_mask    [i];
        out_ren2dis_uop_pre_std_mask    [i] = inst_r_uop_pre_std_mask    [i];
        out_ren2dis_uop_uop_num         [i] = inst_r_uop_uop_num         [i];
        out_ren2dis_uop_cplt_num        [i] = inst_r_uop_cplt_num        [i];
        out_ren2dis_uop_rob_flag        [i] = inst_r_uop_rob_flag        [i];
        out_ren2dis_uop_page_fault_inst [i] = inst_r_uop_page_fault_inst [i];
        out_ren2dis_uop_page_fault_load [i] = inst_r_uop_page_fault_load [i];
        out_ren2dis_uop_page_fault_store[i] = inst_r_uop_page_fault_store[i];
        out_ren2dis_uop_illegal_inst    [i] = inst_r_uop_illegal_inst    [i];
        out_ren2dis_uop_type            [i] = inst_r_uop_type            [i];
        out_ren2dis_uop_op              [i] = inst_r_uop_op              [i];
        out_ren2dis_uop_amoop           [i] = inst_r_uop_amoop           [i];
	end
end	

integer k;
reg stall [FETCH_WIDTH:0];
always_comb begin
    stall[0] = 'd0;
    for(k = 0; k < FETCH_WIDTH; k++) begin
        out_ren2dis_uop_dest_preg[k] = alloc_reg[k];
        if(inst_r_valid[k] && inst_r_uop_dest_en[k] && !stall[k]) begin
            out_ren2dis_valid[k] = alloc_reg_valid[k]; 
            stall[k+1] = !alloc_reg_valid[k];
        end
        else if(inst_r_valid[k] && !inst_r_uop_dest_en[k]) begin
            out_ren2dis_valid[k] = !stall[k];
            stall[k+1] = stall[k];
        end
        else begin
            out_ren2dis_valid[k] = 'd0;
            stall[k+1] = stall[k];
        end
    end
end

endmodule
 
      