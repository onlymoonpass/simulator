`timescale 1ns/1ps
module rename_arch_RAT
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
    input      [  $clog2(ARF_NUM):0] arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_addr     [COMMIT_WIDTH-1:0],
    input      [$clog2(PRF_NUM)-1:0] arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_data     [COMMIT_WIDTH-1:0],
    input                            arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_en       [COMMIT_WIDTH-1:0],

    input      [$clog2(PRF_NUM)-1:0] arch_RAT                                                         [      ARF_NUM:0],// test no seq
    output reg [$clog2(PRF_NUM)-1:0] arch_RAT_1                                                       [      ARF_NUM:0] // test no seq
);


// 写arch_RAT_1
integer k;
always_comb begin
    for(k = 0;k < ARF_NUM + 1; k++) begin
        if(arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_addr[3] == k[$clog2(ARF_NUM):0] && arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_en[3]) begin // 这里必须先寻址再判断en，其他由于分块可以先en再寻址
            arch_RAT_1[k] = arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_data[3];
        end
        else if(arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_addr[2] == k[$clog2(ARF_NUM):0] && arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_en[2]) begin // 这里必须先寻址再判断en，其他由于分块可以先en再寻址
            arch_RAT_1[k] = arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_data[2];
        end
        else if(arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_addr[1] == k[$clog2(ARF_NUM):0] && arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_en[1]) begin // 这里必须先寻址再判断en，其他由于分块可以先en再寻址
            arch_RAT_1[k] = arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_data[1];
        end
        else if(arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_addr[0] == k[$clog2(ARF_NUM):0] && arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_en[0]) begin // 这里必须先寻址再判断en，其他由于分块可以先en再寻址
            arch_RAT_1[k] = arch_RAT_write_in_rob_commit_commit_entry_uop_dest_areg_data[0];
        end
        else begin
            arch_RAT_1[k] = arch_RAT[k];
        end
    end
end


endmodule