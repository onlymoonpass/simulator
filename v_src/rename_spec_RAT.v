`timescale 1ns/1ps
module rename_spec_RAT
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
    // input                               clk                                                       ,// if use seq please open the commit
    // input                               rst_n                                                     ,// if use seq please open the commit
    input      [     $clog2(ARF_NUM):0] spec_RAT_read_inst_r_uop_dest_areg_addr  [FETCH_WIDTH-1:0],
    output     [   $clog2(PRF_NUM)-1:0] spec_RAT_read_inst_r_uop_dest_areg_data  [FETCH_WIDTH-1:0],
                               
    input      [     $clog2(ARF_NUM):0] spec_RAT_read_inst_r_uop_src1_areg_addr  [FETCH_WIDTH-1:0],
    output     [   $clog2(PRF_NUM)-1:0] spec_RAT_read_inst_r_uop_src1_areg_data  [FETCH_WIDTH-1:0],
                               
    input      [     $clog2(ARF_NUM):0] spec_RAT_read_inst_r_uop_src2_areg_addr  [FETCH_WIDTH-1:0],
    output     [   $clog2(PRF_NUM)-1:0] spec_RAT_read_inst_r_uop_src2_areg_data  [FETCH_WIDTH-1:0],
       
    input      [     $clog2(ARF_NUM):0] spec_RAT_write_inst_r_uop_dest_areg_addr [FETCH_WIDTH-1:0],
    input      [   $clog2(PRF_NUM)-1:0] spec_RAT_write_inst_r_uop_dest_areg_data [FETCH_WIDTH-1:0],
    input                               spec_RAT_write_inst_r_uop_dest_areg_en   [FETCH_WIDTH-1:0],
       
    input                               fire                                     [FETCH_WIDTH-1:0],
    input      [  $clog2(TYPE_NUM)-1:0] inst_r_uop_type                          [FETCH_WIDTH-1:0],
    input      [$clog2(MAX_BR_NUM)-1:0] inst_r_uop_tag                           [FETCH_WIDTH-1:0],
    input                               in_dec_bcast_mispred                                      ,
    input      [$clog2(MAX_BR_NUM)-1:0] in_dec_bcast_br_tag                                       ,
    
    input                               in_rob_bcast_flush                                        ,
    input      [   $clog2(PRF_NUM)-1:0] arch_RAT_1                               [      ARF_NUM:0],
  
    // output reg [   $clog2(PRF_NUM)-1:0] RAT_checkpoint_tag                       [      ARF_NUM:0],

    input      [   $clog2(PRF_NUM)-1:0] spec_RAT                                 [      ARF_NUM:0],// test no seq
    output reg [   $clog2(PRF_NUM)-1:0] spec_RAT_1                               [      ARF_NUM:0],// test no seq
    input      [   $clog2(PRF_NUM)-1:0] RAT_checkpoint                           [(ARF_NUM+1)*MAX_BR_NUM-1:0],// test no seq
    output reg [   $clog2(PRF_NUM)-1:0] RAT_checkpoint_1                         [(ARF_NUM+1)*MAX_BR_NUM-1:0] // test no seq
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
// reg [$clog2(PRF_NUM)-1:0] spec_RAT   [ARF_NUM:0];// if use seq please open the below
// reg [$clog2(PRF_NUM)-1:0] spec_RAT_1 [ARF_NUM:0];// if use seq please open the below

reg  [$clog2(PRF_NUM)-1:0] spec_RAT_normal    [ARF_NUM:0];
reg  [$clog2(PRF_NUM)-1:0] spec_RAT_normal_0  [ARF_NUM:0];
reg  [$clog2(PRF_NUM)-1:0] spec_RAT_normal_1  [ARF_NUM:0];
reg  [$clog2(PRF_NUM)-1:0] spec_RAT_normal_2  [ARF_NUM:0];
wire [$clog2(PRF_NUM)-1:0] spec_RAT_mispred   [ARF_NUM:0];
wire [$clog2(PRF_NUM)-1:0] spec_RAT_flush     [ARF_NUM:0];
wire [$clog2(PRF_NUM)-1:0] RAT_checkpoint_tag [ARF_NUM:0];
genvar n;
generate
    for(n = 0; n < ARF_NUM; n++) begin
        assign spec_RAT_flush  [n] = in_rob_bcast_flush ? arch_RAT_1[n] : spec_RAT[n];
        assign spec_RAT_mispred[n] = in_dec_bcast_mispred ? RAT_checkpoint_tag[n] : spec_RAT[n];
        assign spec_RAT_1      [n] = in_rob_bcast_flush ? spec_RAT_flush[n] : (in_dec_bcast_mispred ? spec_RAT_mispred[n] : spec_RAT_normal[n]);
    end
endgenerate

// 写spec_RAT_1
integer k;
always_comb begin
    for(k = 0;k < ARF_NUM + 1; k++) begin
        if(spec_RAT_write_inst_r_uop_dest_areg_addr[3] == k[$clog2(ARF_NUM):0] && spec_RAT_write_inst_r_uop_dest_areg_en[3]) begin // 这里必须先寻址再判断en，其他由于分块可以先en再寻址
            spec_RAT_normal[k] = spec_RAT_write_inst_r_uop_dest_areg_data[3];
        end
        else if(spec_RAT_write_inst_r_uop_dest_areg_addr[2] == k[$clog2(ARF_NUM):0] && spec_RAT_write_inst_r_uop_dest_areg_en[2]) begin
            spec_RAT_normal[k] = spec_RAT_write_inst_r_uop_dest_areg_data[2];
        end
        else if(spec_RAT_write_inst_r_uop_dest_areg_addr[1] == k[$clog2(ARF_NUM):0] && spec_RAT_write_inst_r_uop_dest_areg_en[1]) begin
            spec_RAT_normal[k] = spec_RAT_write_inst_r_uop_dest_areg_data[1];
        end
        else if(spec_RAT_write_inst_r_uop_dest_areg_addr[0] == k[$clog2(ARF_NUM):0] && spec_RAT_write_inst_r_uop_dest_areg_en[0]) begin
            spec_RAT_normal[k] = spec_RAT_write_inst_r_uop_dest_areg_data[0];
        end
        else begin
            spec_RAT_normal[k] = spec_RAT[k];
        end
    end
end
integer a;
always_comb begin
    for(a = 0;a < ARF_NUM + 1; a++) begin
        if(spec_RAT_write_inst_r_uop_dest_areg_addr[2] == a[$clog2(ARF_NUM):0] && spec_RAT_write_inst_r_uop_dest_areg_en[2]) begin
            spec_RAT_normal_2[a] = spec_RAT_write_inst_r_uop_dest_areg_data[2];
        end
        else if(spec_RAT_write_inst_r_uop_dest_areg_addr[1] == a[$clog2(ARF_NUM):0] && spec_RAT_write_inst_r_uop_dest_areg_en[1]) begin
            spec_RAT_normal_2[a] = spec_RAT_write_inst_r_uop_dest_areg_data[1];
        end
        else if(spec_RAT_write_inst_r_uop_dest_areg_addr[0] == a[$clog2(ARF_NUM):0] && spec_RAT_write_inst_r_uop_dest_areg_en[0]) begin
            spec_RAT_normal_2[a] = spec_RAT_write_inst_r_uop_dest_areg_data[0];
        end
        else begin
            spec_RAT_normal_2[a] = spec_RAT[a];
        end
    end
end
integer b;
always_comb begin
    for(b = 0;b < ARF_NUM + 1; b++) begin
        if(spec_RAT_write_inst_r_uop_dest_areg_addr[1] == b[$clog2(ARF_NUM):0] && spec_RAT_write_inst_r_uop_dest_areg_en[1]) begin
            spec_RAT_normal_1[b] = spec_RAT_write_inst_r_uop_dest_areg_data[1];
        end
        else if(spec_RAT_write_inst_r_uop_dest_areg_addr[0] == b[$clog2(ARF_NUM):0] && spec_RAT_write_inst_r_uop_dest_areg_en[0]) begin
            spec_RAT_normal_1[b] = spec_RAT_write_inst_r_uop_dest_areg_data[0];
        end
        else begin
            spec_RAT_normal_1[b] = spec_RAT[b];
        end
    end
end
integer c;
always_comb begin
    for(c = 0;c < ARF_NUM + 1; c++) begin
        if(spec_RAT_write_inst_r_uop_dest_areg_addr[0] == c[$clog2(ARF_NUM):0] && spec_RAT_write_inst_r_uop_dest_areg_en[0]) begin
            spec_RAT_normal_0[c] = spec_RAT_write_inst_r_uop_dest_areg_data[0];
        end
        else begin
            spec_RAT_normal_0[c] = spec_RAT[c];
        end
    end
end
// 读
genvar i;
generate
	for(i = 0; i < FETCH_WIDTH; i = i + 1) begin
		assign spec_RAT_read_inst_r_uop_dest_areg_data[i] = spec_RAT[spec_RAT_read_inst_r_uop_dest_areg_addr[i]];
        assign spec_RAT_read_inst_r_uop_src1_areg_data[i] = spec_RAT[spec_RAT_read_inst_r_uop_src1_areg_addr[i]];
        assign spec_RAT_read_inst_r_uop_src2_areg_data[i] = spec_RAT[spec_RAT_read_inst_r_uop_src2_areg_addr[i]];
    end
endgenerate

// checkpoint
// reg [$clog2(PRF_NUM)-1:0] RAT_checkpoint   [(ARF_NUM+1)*MAX_BR_NUM-1:0];// if use seq please open the below
// reg [$clog2(PRF_NUM)-1:0] RAT_checkpoint_1 [(ARF_NUM+1)*MAX_BR_NUM-1:0];// if use seq please open the below
genvar l;
generate
    for(l = 0; l < ARF_NUM + 1; l = l + 1) begin
        assign RAT_checkpoint_tag[l] = RAT_checkpoint[in_dec_bcast_br_tag*(ARF_NUM+1)+l]; //RAT_checkpoint也由于fetch TODO
    end
endgenerate

integer p;
integer q;
integer r;
always_comb begin
    // for(p = 0; p < FETCH_WIDTH; p++) begin
        for(q = 0;q < MAX_BR_NUM; q++) begin
            for(r = 0;r < (ARF_NUM + 1); r++) begin
                // if((fire[0] && (inst_r_uop_type[0] == BR || inst_r_uop_type[0] == JALR || inst_r_uop_type[0] == JAL) && (inst_r_uop_tag[0] == q[$clog2(MAX_BR_NUM)-1:0])) || 
                //    (fire[1] && (inst_r_uop_type[1] == BR || inst_r_uop_type[1] == JALR || inst_r_uop_type[1] == JAL) && (inst_r_uop_tag[1] == q[$clog2(MAX_BR_NUM)-1:0])) ||
                //    (fire[2] && (inst_r_uop_type[2] == BR || inst_r_uop_type[2] == JALR || inst_r_uop_type[2] == JAL) && (inst_r_uop_tag[2] == q[$clog2(MAX_BR_NUM)-1:0])) ||
                //    (fire[3] && (inst_r_uop_type[3] == BR || inst_r_uop_type[3] == JALR || inst_r_uop_type[3] == JAL) && (inst_r_uop_tag[3] == q[$clog2(MAX_BR_NUM)-1:0]))) begin
                if(fire[3] && (inst_r_uop_type[3] == BR || inst_r_uop_type[3] == JALR || inst_r_uop_type[3] == JAL) && (inst_r_uop_tag[3] == q[$clog2(MAX_BR_NUM)-1:0])) begin
                    RAT_checkpoint_1[q*(ARF_NUM + 1)+r] = spec_RAT_normal[r];
                end
                else if(fire[2] && (inst_r_uop_type[2] == BR || inst_r_uop_type[2] == JALR || inst_r_uop_type[2] == JAL) && (inst_r_uop_tag[2] == q[$clog2(MAX_BR_NUM)-1:0])) begin
                    RAT_checkpoint_1[q*(ARF_NUM + 1)+r] = spec_RAT_normal_2[r];
                end
                else if(fire[1] && (inst_r_uop_type[1] == BR || inst_r_uop_type[1] == JALR || inst_r_uop_type[1] == JAL) && (inst_r_uop_tag[1] == q[$clog2(MAX_BR_NUM)-1:0])) begin
                    RAT_checkpoint_1[q*(ARF_NUM + 1)+r] = spec_RAT_normal_1[r];
                end
                else if(fire[0] && (inst_r_uop_type[0] == BR || inst_r_uop_type[0] == JALR || inst_r_uop_type[0] == JAL) && (inst_r_uop_tag[0] == q[$clog2(MAX_BR_NUM)-1:0])) begin
                    RAT_checkpoint_1[q*(ARF_NUM + 1)+r] = spec_RAT_normal_0[r];
                end
                else begin
                    RAT_checkpoint_1[q*(ARF_NUM + 1)+r] = RAT_checkpoint[q*(ARF_NUM + 1)+r];
                end
            end
        end
    // end
end

// if use seq please open the below
// integer j;
// integer o;
// always @(posedge clk) begin
//     if(~rst_n) begin
//         for(j = 0;j < (ARF_NUM + 1) * MAX_BR_NUM; j++) begin
//             RAT_checkpoint[j] <= 'd0;
//         end
//     end
//     else begin
//         for(j = 0;j < (ARF_NUM + 1) * MAX_BR_NUM; j++) begin
//             RAT_checkpoint[j] <= RAT_checkpoint_1[j];
//         end
//     end
// end


// if use seq please open the below
// integer m;
// integer n;
// always @(posedge clk) begin
//     if(~rst_n) begin
//         for(m = 0; m < ARF_NUM; m++) begin
//             spec_RAT[m] <= (m % FETCH_WIDTH) * PRF_NUM / FETCH_WIDTH + m / FETCH_WIDTH;
//         end
//     end
//     else begin
//         for(m = 0;m < ARF_NUM + 1; m++) begin
//             spec_RAT[m] <= spec_RAT_1[m];
//         end
//     end
// end

endmodule