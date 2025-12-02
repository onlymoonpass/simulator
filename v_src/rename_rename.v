`timescale 1ns/1ps
module rename_rename
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
    input                              inst_r_valid                                   [FETCH_WIDTH-1:0],
    input                              inst_r_uop_dest_en                             [FETCH_WIDTH-1:0],

    output     [    $clog2(ARF_NUM):0] spec_RAT_read_inst_r_uop_dest_areg_addr        [FETCH_WIDTH-1:0],     
    input      [  $clog2(PRF_NUM)-1:0] spec_RAT_read_inst_r_uop_dest_areg_data        [FETCH_WIDTH-1:0], //不有效或者无前递的默认值
    input      [  $clog2(PRF_NUM)-1:0] out_ren2dis_uop_dest_preg                      [FETCH_WIDTH-1:0], // 如果==32则赋该值
    input      [    $clog2(ARF_NUM):0] out_ren2dis_uop_dest_areg                      [FETCH_WIDTH-1:0], // 判断==32
    input      [    $clog2(ARF_NUM):0] inst_r_uop_dest_areg                           [FETCH_WIDTH-1:0], // 前递判断相不相等
    output reg [  $clog2(PRF_NUM)-1:0] out_ren2dis_uop_old_dest_preg                  [FETCH_WIDTH-1:0],
       
    input      [    $clog2(ARF_NUM):0] inst_r_uop_src1_areg                           [FETCH_WIDTH-1:0], // 判断src和dest相不相等
    output     [    $clog2(ARF_NUM):0] spec_RAT_read_inst_r_uop_src1_areg_addr        [FETCH_WIDTH-1:0],
    input      [  $clog2(PRF_NUM)-1:0] spec_RAT_read_inst_r_uop_src1_areg_data        [FETCH_WIDTH-1:0], // spec_RAT读src1_areg
    output     [  $clog2(PRF_NUM)-1:0] busy_table_read_out_ren2dis_uop_src1_preg_addr [FETCH_WIDTH-1:0],
    input                              busy_table_read_out_ren2dis_uop_src1_preg_data [FETCH_WIDTH-1:0], // busy_table查看src1_preg是否繁忙
    input                              inst_r_uop_src1_en                             [FETCH_WIDTH-1:0], // 用于src1是否busy的计算
    output reg [  $clog2(PRF_NUM)-1:0] out_ren2dis_uop_src1_preg                      [FETCH_WIDTH-1:0],
    output reg                         out_ren2dis_uop_src1_busy                      [FETCH_WIDTH-1:0],
     
    input      [    $clog2(ARF_NUM):0] inst_r_uop_src2_areg                           [FETCH_WIDTH-1:0], // 判断src和dest相不相等
    output     [    $clog2(ARF_NUM):0] spec_RAT_read_inst_r_uop_src2_areg_addr        [FETCH_WIDTH-1:0],
    input      [  $clog2(PRF_NUM)-1:0] spec_RAT_read_inst_r_uop_src2_areg_data        [FETCH_WIDTH-1:0],
    output     [  $clog2(PRF_NUM)-1:0] busy_table_read_out_ren2dis_uop_src2_preg_addr [FETCH_WIDTH-1:0],    
    input                              busy_table_read_out_ren2dis_uop_src2_preg_data [FETCH_WIDTH-1:0], // busy_table查看src1_preg是否繁忙
    input		                       inst_r_uop_src2_en                             [FETCH_WIDTH-1:0],
    output reg [  $clog2(PRF_NUM)-1:0] out_ren2dis_uop_src2_preg                      [FETCH_WIDTH-1:0],
    output reg                         out_ren2dis_uop_src2_busy                      [FETCH_WIDTH-1:0]
);

parameter NONE 		 = 4'd0;
parameter JUMP 		 = 4'd1;
parameter ADD 		 = 4'd2;
parameter BR 		 = 4'd3;
parameter LOAD 		 = 4'd4;
parameter STA 		 = 4'd5;
parameter STD 		 = 4'd6;
parameter CSR 		 = 4'd7;
parameter ECALL    	 = 4'd8;
parameter EBREAK     = 4'd9;
parameter SFENCE_VMA = 4'd10;
parameter MRET 		 = 4'd11;
parameter SRET 		 = 4'd12;
parameter MUL  		 = 4'd13;
parameter DIV 		 = 4'd14;

parameter AMONONE = 4'd0;
parameter LR      = 4'd1;
parameter SC      = 4'd2;
parameter AMOSWAP = 4'd3;
parameter AMOADD  = 4'd4;
parameter AMOXOR  = 4'd5;
parameter AMOAND  = 4'd6;
parameter AMOOR   = 4'd7;
parameter AMOMIN  = 4'd8;
parameter AMOMAX  = 4'd9;
parameter AMOMINU = 4'd10;
parameter AMOMAXU = 4'd11;

wire [$clog2(PRF_NUM)-1:0] src1_preg_normal [FETCH_WIDTH-1:0];
reg  [$clog2(PRF_NUM)-1:0] src1_preg_bypass [FETCH_WIDTH-1:0];
reg                        src1_bypass_hit  [FETCH_WIDTH-1:0];
wire                       src1_busy_normal [FETCH_WIDTH-1:0];
wire [$clog2(PRF_NUM)-1:0] src2_preg_normal [FETCH_WIDTH-1:0];
reg  [$clog2(PRF_NUM)-1:0] src2_preg_bypass [FETCH_WIDTH-1:0];
reg                        src2_bypass_hit  [FETCH_WIDTH-1:0];
wire                       src2_busy_normal [FETCH_WIDTH-1:0];
wire [$clog2(PRF_NUM)-1:0] old_dest_preg_normal [FETCH_WIDTH-1:0];
reg  [$clog2(PRF_NUM)-1:0] old_dest_preg_bypass [FETCH_WIDTH-1:0];
reg                        old_dest_bypass_hit  [FETCH_WIDTH-1:0];

genvar i;
generate
    for(i = 0; i < FETCH_WIDTH; i++) begin
        assign spec_RAT_read_inst_r_uop_dest_areg_addr[i] = inst_r_uop_dest_areg[i];
        assign spec_RAT_read_inst_r_uop_src1_areg_addr[i] = inst_r_uop_src1_areg[i];
        assign spec_RAT_read_inst_r_uop_src2_areg_addr[i] = inst_r_uop_src2_areg[i];
        assign busy_table_read_out_ren2dis_uop_src1_preg_addr[i] = spec_RAT_read_inst_r_uop_src1_areg_data[i];
        assign busy_table_read_out_ren2dis_uop_src2_preg_addr[i] = spec_RAT_read_inst_r_uop_src2_areg_data[i];

        assign src1_preg_normal[i]     = spec_RAT_read_inst_r_uop_src1_areg_data[i];
        assign src1_busy_normal[i]     = busy_table_read_out_ren2dis_uop_src1_preg_data[i];
        assign src2_preg_normal[i]     = spec_RAT_read_inst_r_uop_src2_areg_data[i];
        assign src2_busy_normal[i]     = busy_table_read_out_ren2dis_uop_src2_preg_data[i];
        assign old_dest_preg_normal[i] = spec_RAT_read_inst_r_uop_dest_areg_data[i];
    end
endgenerate

always_comb begin
    // if(io_ren2dis_uop_dest_areg[0] == 'd32) begin
    //     io_ren2dis_uop_old_dest_preg[0] = io_ren2dis_uop_dest_preg[0];
    // end
    // else begin
    //     io_ren2dis_uop_old_dest_preg[0] = spec_RAT_read_inst_r_uop_dest_areg_data[0]; // 默认值
    // end
    old_dest_bypass_hit [0] = 'd0;
    old_dest_preg_bypass[0] = 'd0; 

    // if(io_ren2dis_uop_dest_areg[1] == 'd32) begin
    //     io_ren2dis_uop_old_dest_preg[1] = io_ren2dis_uop_dest_preg[1];
    // end
    // else begin
        if(inst_r_valid[0] && inst_r_uop_dest_en[0] && (inst_r_uop_dest_areg[1] == inst_r_uop_dest_areg[0])) begin
            // io_ren2dis_uop_old_dest_preg[1] = io_ren2dis_uop_dest_preg[0];
            old_dest_bypass_hit [1] = 'd1;
            old_dest_preg_bypass[1] = out_ren2dis_uop_dest_preg[0]; 
        end
        else begin
            // io_ren2dis_uop_old_dest_preg[1] = spec_RAT_read_inst_r_uop_dest_areg_data[1]; // 默认值
            old_dest_bypass_hit [1] = 'd0;
            old_dest_preg_bypass[1] = 'd0; 
        end
    // end

    // if(io_ren2dis_uop_dest_areg[2] == 'd32) begin
    //     io_ren2dis_uop_old_dest_preg[2] = io_ren2dis_uop_dest_preg[2];
    // end
    // else begin
        if(inst_r_valid[1] && inst_r_uop_dest_en[1] && (inst_r_uop_dest_areg[2] == inst_r_uop_dest_areg[1])) begin
            // io_ren2dis_uop_old_dest_preg[2] = io_ren2dis_uop_dest_preg[1];
            old_dest_bypass_hit [2] = 'd1;
            old_dest_preg_bypass[2] = out_ren2dis_uop_dest_preg[1]; 
        end
        else if(inst_r_valid[0] && inst_r_uop_dest_en[0] && (inst_r_uop_dest_areg[2] == inst_r_uop_dest_areg[0])) begin
            // io_ren2dis_uop_old_dest_preg[2] = io_ren2dis_uop_dest_preg[0];
            old_dest_bypass_hit [2] = 'd1;
            old_dest_preg_bypass[2] = out_ren2dis_uop_dest_preg[0]; 
        end
        else begin
            // io_ren2dis_uop_old_dest_preg[2] = spec_RAT_read_inst_r_uop_dest_areg_data[2]; // 默认值
            old_dest_bypass_hit [2] = 'd0;
            old_dest_preg_bypass[2] = 'd0; 
        end
    // end

    // if(io_ren2dis_uop_dest_areg[3] == 'd32) begin
    //     io_ren2dis_uop_old_dest_preg[3] = io_ren2dis_uop_dest_preg[3];
    // end
    // else begin
        if(inst_r_valid[2] && inst_r_uop_dest_en[2] && (inst_r_uop_dest_areg[3] == inst_r_uop_dest_areg[2])) begin
            // io_ren2dis_uop_old_dest_preg[3] = io_ren2dis_uop_dest_preg[2];
            old_dest_bypass_hit [3] = 'd1;
            old_dest_preg_bypass[3] = out_ren2dis_uop_dest_preg[2]; 
        end
        else if(inst_r_valid[1] && inst_r_uop_dest_en[1] && (inst_r_uop_dest_areg[3] == inst_r_uop_dest_areg[1])) begin
            // io_ren2dis_uop_old_dest_preg[3] = io_ren2dis_uop_dest_preg[1];
            old_dest_bypass_hit [3] = 'd1;
            old_dest_preg_bypass[3] = out_ren2dis_uop_dest_preg[1]; 
        end
        else if(inst_r_valid[0] && inst_r_uop_dest_en[0] && (inst_r_uop_dest_areg[3] == inst_r_uop_dest_areg[0])) begin
            // io_ren2dis_uop_old_dest_preg[3] = io_ren2dis_uop_dest_preg[0];
            old_dest_bypass_hit [3] = 'd1;
            old_dest_preg_bypass[3] = out_ren2dis_uop_dest_preg[0]; 
        end
        else begin
            // io_ren2dis_uop_old_dest_preg[3] = spec_RAT_read_inst_r_uop_dest_areg_data[3]; // 默认值
            old_dest_bypass_hit [3] = 'd0;
            old_dest_preg_bypass[3] = 'd0; 
        end
    // end
end

always_comb begin
    // io_ren2dis_uop_src1_preg[0] = spec_RAT_read_inst_r_uop_src1_areg_data[0];
    // io_ren2dis_uop_src1_busy[0] = busy_table_read_io_ren2dis_uop_src1_preg_data[0] && inst_r_uop_src1_en[0];
    src1_bypass_hit [0] = 'd0;
    src1_preg_bypass[0] = 'd0;

    if(inst_r_valid[0] && inst_r_uop_dest_en[0] && (inst_r_uop_src1_areg[1] == inst_r_uop_dest_areg[0])) begin
        // io_ren2dis_uop_src1_preg[1] = io_ren2dis_uop_dest_preg[0];
        // io_ren2dis_uop_src1_busy[1] = 1'b1;
        src1_bypass_hit [1] = 'd1;
        src1_preg_bypass[1] = out_ren2dis_uop_dest_preg[0];
    end
    else begin
        // io_ren2dis_uop_src1_preg[1] = spec_RAT_read_inst_r_uop_src1_areg_data[1];
        // io_ren2dis_uop_src1_busy[1] = busy_table_read_io_ren2dis_uop_src1_preg_data[1] && inst_r_uop_src1_en[1];
        src1_bypass_hit [1] = 'd0;
        src1_preg_bypass[1] = 'd0;
    end

    if(inst_r_valid[1] && inst_r_uop_dest_en[1] && (inst_r_uop_src1_areg[2] == inst_r_uop_dest_areg[1])) begin
        // io_ren2dis_uop_src1_preg[2] = io_ren2dis_uop_dest_preg[1];
        // io_ren2dis_uop_src1_busy[2] = 1'b1;
        src1_bypass_hit [2] = 'd1;
        src1_preg_bypass[2] = out_ren2dis_uop_dest_preg[1];
    end
    else if(inst_r_valid[0] && inst_r_uop_dest_en[0] && (inst_r_uop_src1_areg[2] == inst_r_uop_dest_areg[0])) begin
        // io_ren2dis_uop_src1_preg[2] = io_ren2dis_uop_dest_preg[0];
        // io_ren2dis_uop_src1_busy[2] = 1'b1;
        src1_bypass_hit [2] = 'd1;
        src1_preg_bypass[2] = out_ren2dis_uop_dest_preg[0];
    end
    else begin
        // io_ren2dis_uop_src1_preg[2] = spec_RAT_read_inst_r_uop_src1_areg_data[2];
        // io_ren2dis_uop_src1_busy[2] = busy_table_read_io_ren2dis_uop_src1_preg_data[2] && inst_r_uop_src1_en[2];
        src1_bypass_hit [2] = 'd0;
        src1_preg_bypass[2] = 'd0;
    end

    if(inst_r_valid[2] && inst_r_uop_dest_en[2] && inst_r_uop_src1_areg[3] == inst_r_uop_dest_areg[2]) begin
        // io_ren2dis_uop_src1_preg[3] = io_ren2dis_uop_dest_preg[2];
        // io_ren2dis_uop_src1_busy[3] = 1'b1;
        src1_bypass_hit [3] = 'd1;
        src1_preg_bypass[3] = out_ren2dis_uop_dest_preg[2];
    end
    else if(inst_r_valid[1] && inst_r_uop_dest_en[1] && inst_r_uop_src1_areg[3] == inst_r_uop_dest_areg[1]) begin
        // io_ren2dis_uop_src1_preg[3] = io_ren2dis_uop_dest_preg[1];
        // io_ren2dis_uop_src1_busy[3] = 1'b1;
        src1_bypass_hit [3] = 'd1;
        src1_preg_bypass[3] = out_ren2dis_uop_dest_preg[1];
    end
    else if(inst_r_valid[0] && inst_r_uop_dest_en[0] && inst_r_uop_src1_areg[3] == inst_r_uop_dest_areg[0]) begin
        // io_ren2dis_uop_src1_preg[3] = io_ren2dis_uop_dest_preg[0];
        // io_ren2dis_uop_src1_busy[3] = 1'b1;
        src1_bypass_hit [3] = 'd1;
        src1_preg_bypass[3] = out_ren2dis_uop_dest_preg[0];
    end
    else begin
        // io_ren2dis_uop_src1_preg[3] = spec_RAT_read_inst_r_uop_src1_areg_data[3];
        // io_ren2dis_uop_src1_busy[3] = busy_table_read_io_ren2dis_uop_src1_preg_data[3] && inst_r_uop_src1_en[3];
        src1_bypass_hit [3] = 'd0;
        src1_preg_bypass[3] = 'd0;
    end

    // io_ren2dis_uop_src2_preg[0] = spec_RAT_read_inst_r_uop_src2_areg_data[0];
    // io_ren2dis_uop_src2_busy[0] = busy_table_read_io_ren2dis_uop_src2_preg_data[0] && inst_r_uop_src2_en[0];
    src2_bypass_hit [0] = 'd0;
    src2_preg_bypass[0] = 'd0;

    if(inst_r_valid[0] && inst_r_uop_dest_en[0] && (inst_r_uop_src2_areg[1] == inst_r_uop_dest_areg[0])) begin
        // io_ren2dis_uop_src2_preg[1] = io_ren2dis_uop_dest_preg[0];
        // io_ren2dis_uop_src2_busy[1] = 1'b1;
        src2_bypass_hit [1] = 'd1;
        src2_preg_bypass[1] = out_ren2dis_uop_dest_preg[0];
    end
    else begin
        // io_ren2dis_uop_src2_preg[1] = spec_RAT_read_inst_r_uop_src2_areg_data[1];
        // io_ren2dis_uop_src2_busy[1] = busy_table_read_io_ren2dis_uop_src2_preg_data[1] && inst_r_uop_src2_en[1];
        src2_bypass_hit [1] = 'd0;
        src2_preg_bypass[1] = 'd0;
    end

    if(inst_r_valid[1] && inst_r_uop_dest_en[1] && (inst_r_uop_src2_areg[2] == inst_r_uop_dest_areg[1])) begin
        // io_ren2dis_uop_src2_preg[2] = io_ren2dis_uop_dest_preg[1];
        // io_ren2dis_uop_src2_busy[2] = 1'b1;
        src2_bypass_hit [2] = 'd1;
        src2_preg_bypass[2] = out_ren2dis_uop_dest_preg[1];
    end
    else if(inst_r_valid[0] && inst_r_uop_dest_en[0] && (inst_r_uop_src2_areg[2] == inst_r_uop_dest_areg[0])) begin
        // io_ren2dis_uop_src2_preg[2] = io_ren2dis_uop_dest_preg[0];
        // io_ren2dis_uop_src2_busy[2] = 1'b1;
        src2_bypass_hit [2] = 'd1;
        src2_preg_bypass[2] = out_ren2dis_uop_dest_preg[0];
    end
    else begin
        // io_ren2dis_uop_src2_preg[2] = spec_RAT_read_inst_r_uop_src2_areg_data[2];
        // io_ren2dis_uop_src2_busy[2] = busy_table_read_io_ren2dis_uop_src2_preg_data[2] && inst_r_uop_src2_en[2];
        src2_bypass_hit [2] = 'd0;
        src2_preg_bypass[2] = 'd0;
    end

    if(inst_r_valid[2] && inst_r_uop_dest_en[2] && (inst_r_uop_src2_areg[3] == inst_r_uop_dest_areg[2])) begin
        // io_ren2dis_uop_src2_preg[3] = io_ren2dis_uop_dest_preg[2];
        // io_ren2dis_uop_src2_busy[3] = 1'b1;
        src2_bypass_hit [3] = 'd1;
        src2_preg_bypass[3] = out_ren2dis_uop_dest_preg[2];
    end
    else if(inst_r_valid[1] && inst_r_uop_dest_en[1] && (inst_r_uop_src2_areg[3] == inst_r_uop_dest_areg[1])) begin
        // io_ren2dis_uop_src2_preg[3] = io_ren2dis_uop_dest_preg[1];
        // io_ren2dis_uop_src2_busy[3] = 1'b1;
        src2_bypass_hit [3] = 'd1;
        src2_preg_bypass[3] = out_ren2dis_uop_dest_preg[1];
    end
    else if(inst_r_valid[0] && inst_r_uop_dest_en[0] && (inst_r_uop_src2_areg[3] == inst_r_uop_dest_areg[0])) begin
        // io_ren2dis_uop_src2_preg[3] = io_ren2dis_uop_dest_preg[0];
        // io_ren2dis_uop_src2_busy[3] = 1'b1;
        src2_bypass_hit [3] = 'd1;
        src2_preg_bypass[3] = out_ren2dis_uop_dest_preg[0];
    end
    else begin
        // io_ren2dis_uop_src2_preg[3] = spec_RAT_read_inst_r_uop_src2_areg_data[3];
        // io_ren2dis_uop_src2_busy[3] = busy_table_read_io_ren2dis_uop_src2_preg_data[3] && inst_r_uop_src2_en[3];
        src2_bypass_hit [3] = 'd0;
        src2_preg_bypass[3] = 'd0;
    end
end

genvar j;
generate
    for(j = 0; j < FETCH_WIDTH; j++) begin
        always_comb begin
            if(src1_bypass_hit[j]) begin
                out_ren2dis_uop_src1_preg[j] = src1_preg_bypass[j];
                out_ren2dis_uop_src1_busy[j] = 'd1;
            end
            else begin
                out_ren2dis_uop_src1_preg[j] = src1_preg_normal[j];
                out_ren2dis_uop_src1_busy[j] = src1_busy_normal[j];
            end
            if(src2_bypass_hit[j]) begin
                out_ren2dis_uop_src2_preg[j] = src2_preg_bypass[j];
                out_ren2dis_uop_src2_busy[j] = 'd1;
            end
            else begin
                out_ren2dis_uop_src2_preg[j] = src2_preg_normal[j];
                out_ren2dis_uop_src2_busy[j] = src2_busy_normal[j];
            end
            if(out_ren2dis_uop_dest_areg[j] == 'd32) begin
                out_ren2dis_uop_old_dest_preg[j] = out_ren2dis_uop_dest_preg[j];
            end 
            else if(old_dest_bypass_hit[j]) begin
                out_ren2dis_uop_old_dest_preg[j] = old_dest_preg_bypass[j];
            end
            else begin
                out_ren2dis_uop_old_dest_preg[j] = old_dest_preg_normal[j];
            end
        end
    end
endgenerate

endmodule
