`timescale 1ns/1ps
module rename_wake
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
	input                            in_prf_awake_wake_valid                                   ,
	input      [$clog2(PRF_NUM)-1:0] in_prf_awake_wake_preg                                    ,
	input                            in_iss_awake_wake_valid                      [ALU_NUM-1:0],
	input      [$clog2(PRF_NUM)-1:0] in_iss_awake_wake_preg                       [ALU_NUM-1:0],
    output reg [$clog2(PRF_NUM)-1:0] busy_table_write_in_prf_awake_wake_preg_addr              ,
    output reg                       busy_table_write_in_prf_awake_wake_preg_en                ,
    output reg                       busy_table_write_in_prf_awake_wake_preg_data              ,
    output reg [$clog2(PRF_NUM)-1:0] busy_table_write_in_iss_awake_wake_preg_addr [ALU_NUM-1:0], // 不会有都valid，且地址相同的情况
    output reg                       busy_table_write_in_iss_awake_wake_preg_en   [ALU_NUM-1:0],
    output reg                       busy_table_write_in_iss_awake_wake_preg_data [ALU_NUM-1:0]
);

integer i;
always_comb begin
    for(i = 0; i < ALU_NUM; i++) begin
        busy_table_write_in_iss_awake_wake_preg_addr[i] = in_iss_awake_wake_preg[i];
        busy_table_write_in_iss_awake_wake_preg_data[i] = 1'b0;
        busy_table_write_in_iss_awake_wake_preg_en  [i] = in_iss_awake_wake_valid[i];
    end
end

reg [ALU_NUM-1:0] same_addr_comp_pos;
wire              same_addr_comp;
assign same_addr_comp = |same_addr_comp_pos;
integer j;
always_comb begin
    for(j = 0; j < ALU_NUM; j++) begin
        if(in_iss_awake_wake_valid[j] && in_prf_awake_wake_valid && in_prf_awake_wake_preg == in_iss_awake_wake_preg[j]) begin
            same_addr_comp_pos[j] = 1'b1;
        end
        else begin
            same_addr_comp_pos[j] = 1'b0;
        end
    end
end
always_comb begin
    busy_table_write_in_prf_awake_wake_preg_addr = in_prf_awake_wake_preg;
    busy_table_write_in_prf_awake_wake_preg_data = 1'b0;
    if(same_addr_comp) begin
        busy_table_write_in_prf_awake_wake_preg_en = 1'b0;
    end
    else begin
        busy_table_write_in_prf_awake_wake_preg_en = in_prf_awake_wake_valid;
    end
end

endmodule