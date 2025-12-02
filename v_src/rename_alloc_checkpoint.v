`timescale 1ns/1ps
module rename_alloc_checkpoint
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
    // input                               clk                                                                          ,// if use seq please open the commit
    // input                               rst_n                                                                        ,// if use seq please open the commit
    input      [   $clog2(PRF_NUM)-1:0] alloc_checkpoint_write_out_ren2dis_uop_dest_preg_addr [       FETCH_WIDTH-1:0],
    input                               alloc_checkpoint_write_out_ren2dis_uop_dest_preg_data [       FETCH_WIDTH-1:0],
    input                               alloc_checkpoint_write_out_ren2dis_uop_dest_preg_en   [       FETCH_WIDTH-1:0],    

    input                               fire                                                  [       FETCH_WIDTH-1:0],
    input      [  $clog2(TYPE_NUM)-1:0] inst_r_uop_type                                       [       FETCH_WIDTH-1:0],
    input      [$clog2(MAX_BR_NUM)-1:0] inst_r_uop_tag                                        [       FETCH_WIDTH-1:0],

    output                              alloc_checkpoint_tag                                  [           PRF_NUM-1:0],                          
    input      [$clog2(MAX_BR_NUM)-1:0] in_dec_bcast_br_tag                                                           ,
     
    input                               alloc_checkpoint                                      [MAX_BR_NUM*PRF_NUM-1:0],// test no seq
    output reg                          alloc_checkpoint_1                                    [MAX_BR_NUM*PRF_NUM-1:0] // test no seq
                              
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
// reg [PRF_NUM - 1:0] alloc_checkpoint   [MAX_BR_NUM - 1:0];// if use seq please open the below
// reg [PRF_NUM - 1:0] alloc_checkpoint_1 [MAX_BR_NUM - 1:0];// if use seq please open the below

genvar j;
generate
    for(j = 0;j < PRF_NUM; j++) begin
        assign alloc_checkpoint_tag[j] = alloc_checkpoint[in_dec_bcast_br_tag*PRF_NUM+j];
    end
endgenerate

integer m;
integer o;
integer n;


always_comb begin
    for(n = 0;n < MAX_BR_NUM; n++) begin
        // for(m = 0; m < FETCH_WIDTH; m++) begin
            for(o = 0;o < PRF_NUM; o++) begin
                // if((fire[0] && (inst_r_uop_type[0] == BR || inst_r_uop_type[0] == JALR || inst_r_uop_type[0] == JAL) && (inst_r_uop_tag[0] == n[$clog2(MAX_BR_NUM)-1:0])) ||
                //    (fire[1] && (inst_r_uop_type[1] == BR || inst_r_uop_type[1] == JALR || inst_r_uop_type[1] == JAL) && (inst_r_uop_tag[1] == n[$clog2(MAX_BR_NUM)-1:0])) ||
                //    (fire[2] && (inst_r_uop_type[2] == BR || inst_r_uop_type[2] == JALR || inst_r_uop_type[2] == JAL) && (inst_r_uop_tag[2] == n[$clog2(MAX_BR_NUM)-1:0])) ||
                //    (fire[3] && (inst_r_uop_type[3] == BR || inst_r_uop_type[3] == JALR || inst_r_uop_type[3] == JAL) && (inst_r_uop_tag[3] == n[$clog2(MAX_BR_NUM)-1:0]))) begin
                //     if(inst_r_uop_tag[m] == n[$clog2(MAX_BR_NUM)-1:0]) begin
                //         alloc_checkpoint_1[n*PRF_NUM+o] = 'd0;
                //     end
                //     else begin
                //         if((alloc_checkpoint_write_out_ren2dis_uop_dest_preg_addr[3] == o[$clog2(PRF_NUM)-1:0] && alloc_checkpoint_write_out_ren2dis_uop_dest_preg_en[3]) ||
                //         (alloc_checkpoint_write_out_ren2dis_uop_dest_preg_addr[2] == o[$clog2(PRF_NUM)-1:0] && alloc_checkpoint_write_out_ren2dis_uop_dest_preg_en[2]) ||
                //         (alloc_checkpoint_write_out_ren2dis_uop_dest_preg_addr[1] == o[$clog2(PRF_NUM)-1:0] && alloc_checkpoint_write_out_ren2dis_uop_dest_preg_en[1]) ||
                //         (alloc_checkpoint_write_out_ren2dis_uop_dest_preg_addr[0] == o[$clog2(PRF_NUM)-1:0] && alloc_checkpoint_write_out_ren2dis_uop_dest_preg_en[0])) begin
                //             alloc_checkpoint_1[n*PRF_NUM+o] = 'd1;
                //         end
                //         else begin
                //             alloc_checkpoint_1[n*PRF_NUM+o] = alloc_checkpoint[n*PRF_NUM+o];
                //         end
                //     end
                // end
                if(fire[3] && (inst_r_uop_type[3] == BR || inst_r_uop_type[3] == JALR || inst_r_uop_type[3] == JAL) && (inst_r_uop_tag[3] == n[$clog2(MAX_BR_NUM)-1:0])) begin
                    alloc_checkpoint_1[n*PRF_NUM+o] = 'd0;
                end
                else if(alloc_checkpoint_write_out_ren2dis_uop_dest_preg_addr[3] == o[$clog2(PRF_NUM)-1:0] && alloc_checkpoint_write_out_ren2dis_uop_dest_preg_en[3]) begin
                    alloc_checkpoint_1[n*PRF_NUM+o] = 'd1;
                end
                else if(fire[2] && (inst_r_uop_type[2] == BR || inst_r_uop_type[2] == JALR || inst_r_uop_type[2] == JAL) && (inst_r_uop_tag[2] == n[$clog2(MAX_BR_NUM)-1:0])) begin
                    alloc_checkpoint_1[n*PRF_NUM+o] = 'd0;
                end
                else if(alloc_checkpoint_write_out_ren2dis_uop_dest_preg_addr[2] == o[$clog2(PRF_NUM)-1:0] && alloc_checkpoint_write_out_ren2dis_uop_dest_preg_en[2]) begin
                    alloc_checkpoint_1[n*PRF_NUM+o] = 'd1;
                end
                else if(fire[1] && (inst_r_uop_type[1] == BR || inst_r_uop_type[1] == JALR || inst_r_uop_type[1] == JAL) && (inst_r_uop_tag[1] == n[$clog2(MAX_BR_NUM)-1:0])) begin
                    alloc_checkpoint_1[n*PRF_NUM+o] = 'd0;
                end
                else if(alloc_checkpoint_write_out_ren2dis_uop_dest_preg_addr[1] == o[$clog2(PRF_NUM)-1:0] && alloc_checkpoint_write_out_ren2dis_uop_dest_preg_en[1]) begin
                    alloc_checkpoint_1[n*PRF_NUM+o] = 'd1;
                end
                else if(fire[0] && (inst_r_uop_type[0] == BR || inst_r_uop_type[0] == JALR || inst_r_uop_type[0] == JAL) && (inst_r_uop_tag[0] == n[$clog2(MAX_BR_NUM)-1:0])) begin
                    alloc_checkpoint_1[n*PRF_NUM+o] = 'd0;
                end
                else if(alloc_checkpoint_write_out_ren2dis_uop_dest_preg_addr[0] == o[$clog2(PRF_NUM)-1:0] && alloc_checkpoint_write_out_ren2dis_uop_dest_preg_en[0]) begin
                    alloc_checkpoint_1[n*PRF_NUM+o] = 'd1;
                end
                else begin
                    alloc_checkpoint_1[n*PRF_NUM+o] = alloc_checkpoint[n*PRF_NUM+o];
                end
                // else begin
                //     if((alloc_checkpoint_write_out_ren2dis_uop_dest_preg_addr[3] == o[$clog2(PRF_NUM)-1:0] && alloc_checkpoint_write_out_ren2dis_uop_dest_preg_en[3]) ||
                //        (alloc_checkpoint_write_out_ren2dis_uop_dest_preg_addr[2] == o[$clog2(PRF_NUM)-1:0] && alloc_checkpoint_write_out_ren2dis_uop_dest_preg_en[2]) ||
                //        (alloc_checkpoint_write_out_ren2dis_uop_dest_preg_addr[1] == o[$clog2(PRF_NUM)-1:0] && alloc_checkpoint_write_out_ren2dis_uop_dest_preg_en[1]) ||
                //        (alloc_checkpoint_write_out_ren2dis_uop_dest_preg_addr[0] == o[$clog2(PRF_NUM)-1:0] && alloc_checkpoint_write_out_ren2dis_uop_dest_preg_en[0])) begin
                //         alloc_checkpoint_1[n*PRF_NUM+o] = 'd1;
                //     end
                //     else begin
                //         alloc_checkpoint_1[n*PRF_NUM+o] = alloc_checkpoint[n*PRF_NUM+o];
                //     end
                // end
            end
        // end
    end
end



// genvar i;
// generate
//     for(i = 0;i < MAX_BR_NUM; i++) begin
//         always @(posedge clk) begin
//             if(~rst_n) begin
//                 alloc_checkpoint[i] <= 'd0;
//             end
//             else begin
//                 alloc_checkpoint[i] <= alloc_checkpoint_1[i];
//             end
//         end
//     end
// endgenerate

endmodule