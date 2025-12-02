`timescale 1ns/1ps
module rename_busy_table
#(
    parameter PRF_NUM      = 128,
    parameter ROB_NUM      = 128,
    parameter STQ_NUM      = 16 ,
    parameter OP_NUM       = 13 ,
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
    // input                        clk                                                             ,// if use seq please open the commit
    // input                        rst_n                                                           ,// if use seq please open the commit

    input  [$clog2(PRF_NUM)-1:0] busy_table_write_in_prf_awake_wake_preg_addr                    ,
    input                        busy_table_write_in_prf_awake_wake_preg_data                    ,
    input                        busy_table_write_in_prf_awake_wake_preg_en                      ,
 
    input  [$clog2(PRF_NUM)-1:0] busy_table_write_in_iss_awake_wake_preg_addr   [    ALU_NUM-1:0],
    input                        busy_table_write_in_iss_awake_wake_preg_data   [    ALU_NUM-1:0],
    input                        busy_table_write_in_iss_awake_wake_preg_en     [    ALU_NUM-1:0],
  
    input  [$clog2(PRF_NUM)-1:0] busy_table_read_out_ren2dis_uop_src1_preg_addr  [FETCH_WIDTH-1:0],
    output                       busy_table_read_out_ren2dis_uop_src1_preg_data  [FETCH_WIDTH-1:0],
 
    input  [$clog2(PRF_NUM)-1:0] busy_table_read_out_ren2dis_uop_src2_preg_addr  [FETCH_WIDTH-1:0],
    output                       busy_table_read_out_ren2dis_uop_src2_preg_data  [FETCH_WIDTH-1:0],

    input  [$clog2(PRF_NUM)-1:0] busy_table_write_out_ren2dis_uop_dest_preg_addr [FETCH_WIDTH-1:0],
    input                        busy_table_write_out_ren2dis_uop_dest_preg_data [FETCH_WIDTH-1:0],
    input                        busy_table_write_out_ren2dis_uop_dest_preg_en   [FETCH_WIDTH-1:0],

    input                        busy_table                                     [    PRF_NUM-1:0],// test no seq
    output reg                   busy_table_1                                   [    PRF_NUM-1:0] // test no seq
);

// reg busy_table   [PRF_NUM-1:0];// if use seq please open the below
// reg busy_table_1 [PRF_NUM-1:0];// if use seq please open the below

genvar k;
generate
	for(k = 0; k < FETCH_WIDTH; k = k + 1) begin
		assign busy_table_read_out_ren2dis_uop_src1_preg_data[k] = busy_table_1[busy_table_read_out_ren2dis_uop_src1_preg_addr[k]];
        assign busy_table_read_out_ren2dis_uop_src2_preg_data[k] = busy_table_1[busy_table_read_out_ren2dis_uop_src2_preg_addr[k]];
    end
endgenerate

integer i;
integer j;
integer addr;
// always_comb begin
//     for(j = 0; j < FETCH_WIDTH; j++) begin
//         for(i = 0;i < PRF_NUM/FETCH_WIDTH; i++) begin
//             addr = i+PRF_NUM/FETCH_WIDTH*j;
//             if(busy_table_write_out_ren2dis_uop_dest_preg_en[j] && (busy_table_write_out_ren2dis_uop_dest_preg_addr[j] == addr[$clog2(PRF_NUM)-1:0])) begin
//                 busy_table_1[addr] = busy_table_write_out_ren2dis_uop_dest_preg_data[j];
//             end
//             else if(busy_table_write_in_iss_awake_wake_preg_en[j] && (busy_table_write_in_iss_awake_wake_preg_addr[j] == addr[$clog2(PRF_NUM)-1:0])) begin
//                 busy_table_1[addr] = busy_table_write_in_iss_awake_wake_preg_data[j];
//             end
//             else if(busy_table_write_in_prf_awake_wake_preg_en && (busy_table_write_in_prf_awake_wake_preg_addr == addr[$clog2(PRF_NUM)-1:0])) begin               
//                 busy_table_1[addr] = busy_table_write_in_prf_awake_wake_preg_data;
//             end
//             else begin
//                 busy_table_1[addr] = busy_table[addr];
//             end
//         end
//     end
// end

always_comb begin
    for(j = 0; j < FETCH_WIDTH; j++) begin
        for(i = 0;i < PRF_NUM/FETCH_WIDTH; i++) begin
            addr = i+PRF_NUM/FETCH_WIDTH*j;
            if(busy_table_write_out_ren2dis_uop_dest_preg_en[j] && (busy_table_write_out_ren2dis_uop_dest_preg_addr[j] == addr[$clog2(PRF_NUM)-1:0])) begin
                busy_table_1[addr] = busy_table_write_out_ren2dis_uop_dest_preg_data[j];
            end
            else if(busy_table_write_in_iss_awake_wake_preg_en[1] && (busy_table_write_in_iss_awake_wake_preg_addr[1] == addr[$clog2(PRF_NUM)-1:0])) begin // cannot modified by parameter
                busy_table_1[addr] = busy_table_write_in_iss_awake_wake_preg_data[1];
            end
            else if(busy_table_write_in_iss_awake_wake_preg_en[0] && (busy_table_write_in_iss_awake_wake_preg_addr[0] == addr[$clog2(PRF_NUM)-1:0])) begin
                busy_table_1[addr] = busy_table_write_in_iss_awake_wake_preg_data[0];
            end
            else if(busy_table_write_in_prf_awake_wake_preg_en && (busy_table_write_in_prf_awake_wake_preg_addr == addr[$clog2(PRF_NUM)-1:0])) begin               
                busy_table_1[addr] = busy_table_write_in_prf_awake_wake_preg_data;
            end
            else begin
                busy_table_1[addr] = busy_table[addr];
            end
        end
    end
end

// if use seq please open the below
// integer l;
// // 这9个preg不会有相同的情况
// always @(posedge clk) begin
//     if(~rst_n) begin
//         for(l = 0;l < PRF_NUM; l++) begin
//             busy_table[l] <= 'd0;
//         end
//     end
//     else begin
//         for(l = 0;l < PRF_NUM; l++) begin
//             busy_table[l] <= busy_table_1[l];
//         end
//     end
// end

endmodule