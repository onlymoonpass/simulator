#include "TOP.h"
#include <Rename.h>
#include <config.h>
#include <cstdlib>
#include <cstring>
#include <cvt.h>
#include <util.h>

// 多个comb复用的中间信号
static wire1_t fire[FETCH_WIDTH];
static wire1_t spec_alloc_flush[PRF_NUM];
static wire1_t spec_alloc_mispred[PRF_NUM];
static wire1_t spec_alloc_normal[PRF_NUM];
static wire1_t free_vec_flush[PRF_NUM];
static wire1_t free_vec_mispred[PRF_NUM];
static wire1_t free_vec_normal[PRF_NUM];
static wire7_t spec_RAT_flush[ARF_NUM + 1];
static wire7_t spec_RAT_mispred[ARF_NUM + 1];
static wire7_t spec_RAT_normal[ARF_NUM + 1];
static wire1_t busy_table_awake[PRF_NUM];

// difftest
extern Back_Top back;
const int ALLOC_NUM =
    PRF_NUM / FETCH_WIDTH; // 分配寄存器时将preg分成FETCH_WIDTH个部分

// for Difftest va2pa_fixed() debug
int ren_commit_idx;

Rename::Rename() {
  for (int i = 0; i < PRF_NUM; i++) {
    spec_alloc[i] = false;

    // 初始化的时候平均分到free_vec的四个部分
    if (i < ARF_NUM) {
      spec_RAT[i] = (i % FETCH_WIDTH) * ALLOC_NUM + i / FETCH_WIDTH;
      arch_RAT[i] = (i % FETCH_WIDTH) * ALLOC_NUM + i / FETCH_WIDTH;
      free_vec[(i % FETCH_WIDTH) * ALLOC_NUM + i / FETCH_WIDTH] = false;
    } else {
      free_vec[(i % FETCH_WIDTH) * ALLOC_NUM + i / FETCH_WIDTH] = true;
    }
  }

  for (int i = 0; i < FETCH_WIDTH; i++) {
    inst_r[i].valid = false;
  }

  memcpy(arch_RAT_1, arch_RAT, (ARF_NUM + 1) * sizeof(reg7_t));
  memcpy(spec_RAT_1, spec_RAT, (ARF_NUM + 1) * sizeof(reg7_t));
  memcpy(spec_RAT_normal, spec_RAT, (ARF_NUM + 1) * sizeof(reg7_t));
  memcpy(spec_RAT_mispred, spec_RAT, (ARF_NUM + 1) * sizeof(reg7_t));
  memcpy(spec_RAT_flush, spec_RAT, (ARF_NUM + 1) * sizeof(reg7_t));

  memcpy(spec_alloc_mispred, spec_alloc, PRF_NUM);
  memcpy(spec_alloc_flush, spec_alloc, PRF_NUM);
  memcpy(spec_alloc_normal, spec_alloc, PRF_NUM);
  memcpy(spec_alloc_1, spec_alloc, PRF_NUM);

  memcpy(free_vec_mispred, free_vec, PRF_NUM);
  memcpy(free_vec_flush, free_vec, PRF_NUM);
  memcpy(free_vec_normal, free_vec, PRF_NUM);
  memcpy(free_vec_1, free_vec, PRF_NUM);
}

void Rename::comb_alloc() {
  // 可用寄存器个数 每周期最多使用FETCH_WIDTH个
  wire7_t alloc_reg[FETCH_WIDTH];
  alloc_reg[0] = 32;
  alloc_reg[1] = 64;
  alloc_reg[2] = 96;
  alloc_reg[3] = 0;
  wire1_t alloc_valid[FETCH_WIDTH] = {false};

  for (int i = 0; i < FETCH_WIDTH; i++) {
    for (int j = 0; j < ALLOC_NUM; j++) {
      if (free_vec[i * ALLOC_NUM + j]) {
        alloc_reg[i] = i * ALLOC_NUM + j;
        alloc_valid[i] = true;
        break;
      }
    }
  }

  // stall相当于需要查看前一条指令是否stall
  // 一条指令stall，后面的也stall
  wire1_t stall = false;
  for (int i = 0; i < FETCH_WIDTH; i++) {
    out.ren2dis->uop[i] = inst_r[i].uop;
    out.ren2dis->uop[i].dest_preg = alloc_reg[i];
    // 分配寄存器
    if (inst_r[i].valid && inst_r[i].uop.dest_en && !stall) {
      out.ren2dis->valid[i] = alloc_valid[i];
      stall = !alloc_valid[i];
    } else if (inst_r[i].valid && !inst_r[i].uop.dest_en) {
      out.ren2dis->valid[i] = !stall;
    } else {
      out.ren2dis->valid[i] = false;
    }
  }
}

void Rename::comb_wake() {
  // busy_table wake up
  if (in.prf_awake->wake.valid) {
    busy_table_awake[in.prf_awake->wake.preg] = false;
  }

  for (int i = 0; i < ALU_NUM; i++) {
    if (in.iss_awake->wake[i].valid) {
      busy_table_awake[in.iss_awake->wake[i].preg] = false;
    }
  }
}

void Rename::comb_rename() {

  wire7_t src1_preg_normal[FETCH_WIDTH];
  wire1_t src1_busy_normal[FETCH_WIDTH];
  wire7_t src1_preg_bypass[FETCH_WIDTH];
  wire1_t src1_bypass_hit[FETCH_WIDTH];

  wire7_t src2_preg_normal[FETCH_WIDTH];
  wire1_t src2_busy_normal[FETCH_WIDTH];
  wire7_t src2_preg_bypass[FETCH_WIDTH];
  wire1_t src2_bypass_hit[FETCH_WIDTH];

  wire7_t old_dest_preg_normal[FETCH_WIDTH];
  wire7_t old_dest_preg_bypass[FETCH_WIDTH];
  wire1_t old_dest_bypass_hit[FETCH_WIDTH];

  // 无waw raw的输出 读spec_RAT和busy_table
  for (int i = 0; i < FETCH_WIDTH; i++) {
    old_dest_preg_normal[i] = spec_RAT[inst_r[i].uop.dest_areg];
    src1_preg_normal[i] = spec_RAT[inst_r[i].uop.src1_areg];
    src2_preg_normal[i] = spec_RAT[inst_r[i].uop.src2_areg];
    // 用busy_table_awake  存在隐藏的唤醒的bypass
    src1_busy_normal[i] = busy_table_awake[src1_preg_normal[i]];
    src2_busy_normal[i] = busy_table_awake[src2_preg_normal[i]];
  }

  // 针对RAT 和busy_table的raw的bypass
  src1_bypass_hit[0] = false;
  src2_bypass_hit[0] = false;
  old_dest_bypass_hit[0] = false;
  for (int i = 1; i < FETCH_WIDTH; i++) {
    src1_bypass_hit[i] = false;
    src2_bypass_hit[i] = false;
    old_dest_bypass_hit[i] = false;

    // bypass选择最近的 3从012中选 2从01中选 1从0中选
    for (int j = 0; j < i; j++) {
      if (!inst_r[j].valid || !inst_r[j].uop.dest_en)
        continue;

      if (inst_r[i].uop.src1_areg == inst_r[j].uop.dest_areg) {
        src1_bypass_hit[i] = true;
        src1_preg_bypass[i] = out.ren2dis->uop[j].dest_preg;
      }

      if (inst_r[i].uop.src2_areg == inst_r[j].uop.dest_areg) {
        src2_bypass_hit[i] = true;
        src2_preg_bypass[i] = out.ren2dis->uop[j].dest_preg;
      }

      if (inst_r[i].uop.dest_areg == inst_r[j].uop.dest_areg) {
        old_dest_bypass_hit[i] = true;
        old_dest_preg_bypass[i] = out.ren2dis->uop[j].dest_preg;
      }
    }
  }

  // 根据是否bypass选择normal or bypass
  for (int i = 0; i < FETCH_WIDTH; i++) {
    if (src1_bypass_hit[i]) {
      out.ren2dis->uop[i].src1_preg = src1_preg_bypass[i];
      out.ren2dis->uop[i].src1_busy = true;
    } else {
      out.ren2dis->uop[i].src1_preg = src1_preg_normal[i];
      out.ren2dis->uop[i].src1_busy = src1_busy_normal[i];
    }

    if (src2_bypass_hit[i]) {
      out.ren2dis->uop[i].src2_preg = src2_preg_bypass[i];
      out.ren2dis->uop[i].src2_busy = true;
    } else {
      out.ren2dis->uop[i].src2_preg = src2_preg_normal[i];
      out.ren2dis->uop[i].src2_busy = src2_busy_normal[i];
    }

    if (old_dest_bypass_hit[i]) {
      out.ren2dis->uop[i].old_dest_preg = old_dest_preg_bypass[i];
    } else {
      out.ren2dis->uop[i].old_dest_preg = old_dest_preg_normal[i];
    }
  }

  // 特殊处理 临时使用的32号寄存器提交时可以直接回收物理寄存器
  for (int i = 0; i < FETCH_WIDTH; i++) {
    if (out.ren2dis->uop[i].dest_areg == 32) {
      out.ren2dis->uop[i].old_dest_preg = out.ren2dis->uop[i].dest_preg;
    }
  }
}

void Rename::comb_fire() {
  memcpy(busy_table_1, busy_table_awake, sizeof(wire1_t) * PRF_NUM);
  for (int i = 0; i < FETCH_WIDTH; i++) {
    fire[i] = out.ren2dis->valid[i] && in.dis2ren->ready;
  }

  for (int i = 0; i < FETCH_WIDTH; i++) {
    if (fire[i] && out.ren2dis->uop[i].dest_en) {
      int dest_preg = out.ren2dis->uop[i].dest_preg;
      spec_alloc_normal[dest_preg] = true;
      free_vec_normal[dest_preg] = false;
      spec_RAT_normal[inst_r[i].uop.dest_areg] = dest_preg;
      busy_table_1[dest_preg] = true;
      for (int j = 0; j < MAX_BR_NUM; j++)
        alloc_checkpoint_1[j][dest_preg] = true;
    }

    // 保存checkpoint
    if (fire[i] && is_branch(inst_r[i].uop.type)) {
      for (int j = 0; j < ARF_NUM + 1; j++) {
        // 注意这里存在隐藏的旁路
        // 保存的是本条指令完成后的spec_RAT，不包括同一周期后续指令对spec_RAT的影响
        RAT_checkpoint_1[inst_r[i].uop.tag][j] = spec_RAT_normal[j];
      }

      for (int j = 0; j < PRF_NUM; j++) {
        alloc_checkpoint_1[inst_r[i].uop.tag][j] = false;
      }
    }
  }

  out.ren2dec->ready = true;
  for (int i = 0; i < FETCH_WIDTH; i++) {
    out.ren2dec->ready &= fire[i] || !inst_r[i].valid;
  }
}

// mispred和flush不会同时发生
void Rename::comb_branch() {
  // 分支处理
  if (in.dec_bcast->mispred) { // 硬件永远都会生成xx_mispred和xx_flush，然后选择
                               // 模拟器判断一下为了不做无用功跑快点
    // 恢复重命名表
    for (int i = 0; i < ARF_NUM + 1; i++) {
      spec_RAT_mispred[i] = RAT_checkpoint[in.dec_bcast->br_tag][i];
    }

    // 恢复free_list
    for (int j = 0; j < PRF_NUM; j++) {
      free_vec_mispred[j] =
          free_vec[j] || alloc_checkpoint[in.dec_bcast->br_tag][j];
      spec_alloc_mispred[j] =
          spec_alloc[j] && !alloc_checkpoint[in.dec_bcast->br_tag][j];
    }
  }
}

void Rename ::comb_flush() {
  if (in.rob_bcast->flush) {
    // 恢复重命名表
    for (int i = 0; i < ARF_NUM + 1; i++) {
      spec_RAT_flush[i] = arch_RAT_1[i];
    }

    // 恢复free_list
    for (int j = 0; j < PRF_NUM; j++) {
      // 使用free_vec_normal  当前周期提交的指令释放的寄存器(例如CSRR)要考虑
      free_vec_flush[j] = free_vec_normal[j] || spec_alloc_normal[j];
      spec_alloc_flush[j] = false;
    }
  }
}

void Rename ::comb_commit() {
  // 提交指令修改RAT
  for (int i = 0; i < COMMIT_WIDTH; i++) {
    if (in.rob_commit->commit_entry[i].valid) {
      perf.commit_num++;
      Inst_uop *inst = &in.rob_commit->commit_entry[i].uop;
      if (inst->dest_en) {

        // free_vec_normal在异常指令提交时对应位不会置为true，不会释放dest_areg的原有映射的寄存器
        // spec_alloc_normal在异常指令提交时对应位不会置为false，这样该指令的dest_preg才能正确在free_vec中被回收
        // 异常指令要看上去没有执行一样
        if (!inst->page_fault_load && !in.rob_bcast->interrupt &&
            !in.rob_bcast->illegal_inst) {
          free_vec_normal[inst->old_dest_preg] = true;
          spec_alloc_normal[inst->dest_preg] = false;
        }
      }

      if (LOG) {
        cout << "ROB commit PC 0x" << hex << inst->pc << " idx "
             << inst->inst_idx << endl;
      }
      ren_commit_idx = i;
      if (inst->dest_en && !inst->page_fault_load && !in.rob_bcast->interrupt) {
        arch_RAT_1[inst->dest_areg] = inst->dest_preg;
      }
      // back.difftest_inst(inst);
    }
  }

#ifdef CONFIG_DIFFTEST

  back.difftest_cycle();
#endif
}

void Rename ::comb_pipeline() {
  for (int i = 0; i < FETCH_WIDTH; i++) {
    if (in.rob_bcast->flush || in.dec_bcast->mispred) {
      inst_r_1[i].valid = false;
    } else if (out.ren2dec->ready) {
      inst_r_1[i].uop = in.dec2ren->uop[i];
      inst_r_1[i].valid = in.dec2ren->valid[i];
    } else {
      inst_r_1[i].valid = inst_r[i].valid && !fire[i];
    }
  }

  if (in.rob_bcast->flush) {
    memcpy(spec_alloc_1, spec_alloc_flush, PRF_NUM);
    memcpy(free_vec_1, free_vec_flush, PRF_NUM);
    memcpy(spec_RAT_1, spec_RAT_flush, (ARF_NUM + 1) * sizeof(reg7_t));
  } else if (in.dec_bcast->mispred) {
    memcpy(spec_alloc_1, spec_alloc_mispred, PRF_NUM);
    memcpy(free_vec_1, free_vec_mispred, PRF_NUM);
    memcpy(spec_RAT_1, spec_RAT_mispred, (ARF_NUM + 1) * sizeof(reg7_t));
  } else {
    memcpy(spec_alloc_1, spec_alloc_normal, PRF_NUM);
    memcpy(free_vec_1, free_vec_normal, PRF_NUM);
    memcpy(spec_RAT_1, spec_RAT_normal, (ARF_NUM + 1) * sizeof(reg7_t));
  }
}

void Rename ::seq() {

  memcpy(inst_r, inst_r_1, FETCH_WIDTH * sizeof(Inst_entry));
  memcpy(spec_RAT, spec_RAT_1, (ARF_NUM + 1) * sizeof(reg7_t));
  memcpy(arch_RAT, arch_RAT_1, (ARF_NUM + 1) * sizeof(reg7_t));

  memcpy(free_vec, free_vec_1, PRF_NUM);
  memcpy(busy_table, busy_table_1, PRF_NUM);
  memcpy(spec_alloc, spec_alloc_1, PRF_NUM);

  memcpy(RAT_checkpoint, RAT_checkpoint_1,
         MAX_BR_NUM * (ARF_NUM + 1) * sizeof(reg7_t));
  memcpy(alloc_checkpoint, alloc_checkpoint_1,
         MAX_BR_NUM * PRF_NUM * sizeof(reg1_t));

  memcpy(spec_alloc_normal, spec_alloc, PRF_NUM);
  // memcpy(spec_alloc_mispred, spec_alloc, PRF_NUM);
  // memcpy(spec_alloc_flush, spec_alloc, PRF_NUM); //

  memcpy(free_vec_normal, free_vec, PRF_NUM);
  // memcpy(free_vec_mispred, free_vec, PRF_NUM);
  // memcpy(free_vec_flush, free_vec, PRF_NUM);

  memcpy(spec_RAT_normal, spec_RAT, (ARF_NUM + 1) * sizeof(reg7_t));
  // memcpy(spec_RAT_flush, spec_RAT, (ARF_NUM + 1) * sizeof(reg7_t));
  // memcpy(spec_RAT_mispred, spec_RAT, (ARF_NUM + 1) * sizeof(reg7_t));
  memcpy(busy_table_awake, busy_table, PRF_NUM * sizeof(wire1_t));

  // 监控是否产生寄存器泄露
  // 每次flush时 free_vec_num应该等于 PRF_NUM - ARF_NUM
  // static int count = 0;
  // if (in.rob_bcast->flush) {
  //   count++;
  //   if (count % 100 == 0) {
  //     int free_vec_num = 0;
  //     for (int i = 0; i < PRF_NUM; i++) {
  //       if (free_vec[i])
  //         free_vec_num++;
  //     }
  //
  //     assert(free_vec_num == PRF_NUM - ARF_NUM);
  // cout << "free_vec num: " << hex << free_vec_num << endl;
  // }
  // }
}

void Rename ::verilator_module(int debug) {
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_instruction[i] = in.dec2ren->uop[i].instruction;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_dest_areg[i] = in.dec2ren->uop[i].dest_areg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_src1_areg[i] = in.dec2ren->uop[i].src1_areg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_src2_areg[i] = in.dec2ren->uop[i].src2_areg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_dest_preg[i] = in.dec2ren->uop[i].dest_preg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_src1_preg[i] = in.dec2ren->uop[i].src1_preg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_src2_preg[i] = in.dec2ren->uop[i].src2_preg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_old_dest_preg[i] = in.dec2ren->uop[i].old_dest_preg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_src1_rdata[i] = in.dec2ren->uop[i].src1_rdata;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_src2_rdata[i] = in.dec2ren->uop[i].src2_rdata;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_result[i] = in.dec2ren->uop[i].result;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_pred_br_taken[i] = in.dec2ren->uop[i].pred_br_taken;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_alt_pred[i] = in.dec2ren->uop[i].alt_pred;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_altpcpn[i] = in.dec2ren->uop[i].altpcpn;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_pcpn[i] = in.dec2ren->uop[i].pcpn;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_pred_br_pc[i] = in.dec2ren->uop[i].pred_br_pc;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_mispred[i] = in.dec2ren->uop[i].mispred;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_br_taken[i] = in.dec2ren->uop[i].br_taken;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_pc_next[i] = in.dec2ren->uop[i].pc_next;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_dest_en[i] = in.dec2ren->uop[i].dest_en;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_src1_en[i] = in.dec2ren->uop[i].src1_en;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_src2_en[i] = in.dec2ren->uop[i].src2_en;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_src1_busy[i] = in.dec2ren->uop[i].src1_busy;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_src2_busy[i] = in.dec2ren->uop[i].src2_busy;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_src1_latency[i] = in.dec2ren->uop[i].src1_latency;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_src2_latency[i] = in.dec2ren->uop[i].src2_latency;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_src1_is_pc[i] = in.dec2ren->uop[i].src1_is_pc;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_src2_is_imm[i] = in.dec2ren->uop[i].src2_is_imm;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_func3[i] = in.dec2ren->uop[i].func3;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_func7_5[i] = in.dec2ren->uop[i].func7_5;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_imm[i] = in.dec2ren->uop[i].imm;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_pc[i] = in.dec2ren->uop[i].pc;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_tag[i] = in.dec2ren->uop[i].tag;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_csr_idx[i] = in.dec2ren->uop[i].csr_idx;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_rob_idx[i] = in.dec2ren->uop[i].rob_idx;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_stq_idx[i] = in.dec2ren->uop[i].stq_idx;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_pre_sta_mask[i] = in.dec2ren->uop[i].pre_sta_mask;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_pre_std_mask[i] = in.dec2ren->uop[i].pre_std_mask;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_uop_num[i] = in.dec2ren->uop[i].uop_num;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_cplt_num[i] = in.dec2ren->uop[i].cplt_num;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_rob_flag[i] = in.dec2ren->uop[i].rob_flag;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_page_fault_inst[i] = in.dec2ren->uop[i].page_fault_inst;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_page_fault_load[i] = in.dec2ren->uop[i].page_fault_load;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_page_fault_store[i] = in.dec2ren->uop[i].page_fault_store;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_illegal_inst[i] = in.dec2ren->uop[i].illegal_inst;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_type[i] = in.dec2ren->uop[i].type;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_op[i] = in.dec2ren->uop[i].op;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_uop_amoop[i] = in.dec2ren->uop[i].amoop;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_dec2ren_valid[i] = in.dec2ren->valid[i];
  }
  rename_interface->in_dec_bcast_mispred = in.dec_bcast->mispred;
  rename_interface->in_dec_bcast_br_mask = in.dec_bcast->br_mask;
  rename_interface->in_dec_bcast_br_tag = in.dec_bcast->br_tag;
  rename_interface->in_dec_bcast_redirect_rob_idx = in.dec_bcast->redirect_rob_idx;
  for(int i = 0; i < 2; i++) {
      rename_interface->in_iss_awake_wake_valid[i] = in.iss_awake->wake[i].valid;
  }
  for(int i = 0; i < 2; i++) {
      rename_interface->in_iss_awake_wake_preg[i] = in.iss_awake->wake[i].preg;
  }
  for(int i = 0; i < 2; i++) {
      rename_interface->in_iss_awake_wake_latency[i] = in.iss_awake->wake[i].latency;
  }
  rename_interface->in_prf_awake_wake_valid = in.prf_awake->wake.valid;
  rename_interface->in_prf_awake_wake_preg = in.prf_awake->wake.preg;
  rename_interface->in_prf_awake_wake_latency = in.prf_awake->wake.latency;
  rename_interface->in_dis2ren_ready = in.dis2ren->ready;
  rename_interface->in_rob_bcast_flush = in.rob_bcast->flush;
  rename_interface->in_rob_bcast_mret = in.rob_bcast->mret;
  rename_interface->in_rob_bcast_sret = in.rob_bcast->sret;
  rename_interface->in_rob_bcast_ecall = in.rob_bcast->ecall;
  rename_interface->in_rob_bcast_exception = in.rob_bcast->exception;
  rename_interface->in_rob_bcast_page_fault_inst = in.rob_bcast->page_fault_inst;
  rename_interface->in_rob_bcast_page_fault_load = in.rob_bcast->page_fault_load;
  rename_interface->in_rob_bcast_page_fault_store = in.rob_bcast->page_fault_store;
  rename_interface->in_rob_bcast_illegal_inst = in.rob_bcast->illegal_inst;
  rename_interface->in_rob_bcast_interrupt = in.rob_bcast->interrupt;
  rename_interface->in_rob_bcast_trap_val = in.rob_bcast->trap_val;
  rename_interface->in_rob_bcast_pc = in.rob_bcast->pc;
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_valid[i] = in.rob_commit->commit_entry[i].valid;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_instruction[i] = in.rob_commit->commit_entry[i].uop.instruction;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_dest_areg[i] = in.rob_commit->commit_entry[i].uop.dest_areg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_src1_areg[i] = in.rob_commit->commit_entry[i].uop.src1_areg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_src2_areg[i] = in.rob_commit->commit_entry[i].uop.src2_areg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_dest_preg[i] = in.rob_commit->commit_entry[i].uop.dest_preg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_src1_preg[i] = in.rob_commit->commit_entry[i].uop.src1_preg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_src2_preg[i] = in.rob_commit->commit_entry[i].uop.src2_preg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_old_dest_preg[i] = in.rob_commit->commit_entry[i].uop.old_dest_preg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_src1_rdata[i] = in.rob_commit->commit_entry[i].uop.src1_rdata;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_src2_rdata[i] = in.rob_commit->commit_entry[i].uop.src2_rdata;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_result[i] = in.rob_commit->commit_entry[i].uop.result;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_pred_br_taken[i] = in.rob_commit->commit_entry[i].uop.pred_br_taken;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_alt_pred[i] = in.rob_commit->commit_entry[i].uop.alt_pred;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_altpcpn[i] = in.rob_commit->commit_entry[i].uop.altpcpn;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_pcpn[i] = in.rob_commit->commit_entry[i].uop.pcpn;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_pred_br_pc[i] = in.rob_commit->commit_entry[i].uop.pred_br_pc;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_mispred[i] = in.rob_commit->commit_entry[i].uop.mispred;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_br_taken[i] = in.rob_commit->commit_entry[i].uop.br_taken;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_pc_next[i] = in.rob_commit->commit_entry[i].uop.pc_next;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_dest_en[i] = in.rob_commit->commit_entry[i].uop.dest_en;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_src1_en[i] = in.rob_commit->commit_entry[i].uop.src1_en;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_src2_en[i] = in.rob_commit->commit_entry[i].uop.src2_en;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_src1_busy[i] = in.rob_commit->commit_entry[i].uop.src1_busy;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_src2_busy[i] = in.rob_commit->commit_entry[i].uop.src2_busy;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_src1_latency[i] = in.rob_commit->commit_entry[i].uop.src1_latency;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_src2_latency[i] = in.rob_commit->commit_entry[i].uop.src2_latency;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_src1_is_pc[i] = in.rob_commit->commit_entry[i].uop.src1_is_pc;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_src2_is_imm[i] = in.rob_commit->commit_entry[i].uop.src2_is_imm;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_func3[i] = in.rob_commit->commit_entry[i].uop.func3;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_func7_5[i] = in.rob_commit->commit_entry[i].uop.func7_5;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_imm[i] = in.rob_commit->commit_entry[i].uop.imm;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_pc[i] = in.rob_commit->commit_entry[i].uop.pc;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_tag[i] = in.rob_commit->commit_entry[i].uop.tag;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_csr_idx[i] = in.rob_commit->commit_entry[i].uop.csr_idx;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_rob_idx[i] = in.rob_commit->commit_entry[i].uop.rob_idx;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_stq_idx[i] = in.rob_commit->commit_entry[i].uop.stq_idx;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_pre_sta_mask[i] = in.rob_commit->commit_entry[i].uop.pre_sta_mask;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_pre_std_mask[i] = in.rob_commit->commit_entry[i].uop.pre_std_mask;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_uop_num[i] = in.rob_commit->commit_entry[i].uop.uop_num;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_cplt_num[i] = in.rob_commit->commit_entry[i].uop.cplt_num;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_rob_flag[i] = in.rob_commit->commit_entry[i].uop.rob_flag;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_page_fault_inst[i] = in.rob_commit->commit_entry[i].uop.page_fault_inst;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_page_fault_load[i] = in.rob_commit->commit_entry[i].uop.page_fault_load;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_page_fault_store[i] = in.rob_commit->commit_entry[i].uop.page_fault_store;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_illegal_inst[i] = in.rob_commit->commit_entry[i].uop.illegal_inst;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_type[i] = in.rob_commit->commit_entry[i].uop.type;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_op[i] = in.rob_commit->commit_entry[i].uop.op;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->in_rob_commit_commit_entry_uop_amoop[i] = in.rob_commit->commit_entry[i].uop.amoop;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_valid[i] = inst_r[i].valid;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_instruction[i] = inst_r[i].uop.instruction;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_dest_areg[i] = inst_r[i].uop.dest_areg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_src1_areg[i] = inst_r[i].uop.src1_areg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_src2_areg[i] = inst_r[i].uop.src2_areg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_dest_preg[i] = inst_r[i].uop.dest_preg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_src1_preg[i] = inst_r[i].uop.src1_preg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_src2_preg[i] = inst_r[i].uop.src2_preg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_old_dest_preg[i] = inst_r[i].uop.old_dest_preg;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_src1_rdata[i] = inst_r[i].uop.src1_rdata;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_src2_rdata[i] = inst_r[i].uop.src2_rdata;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_result[i] = inst_r[i].uop.result;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_pred_br_taken[i] = inst_r[i].uop.pred_br_taken;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_alt_pred[i] = inst_r[i].uop.alt_pred;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_altpcpn[i] = inst_r[i].uop.altpcpn;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_pcpn[i] = inst_r[i].uop.pcpn;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_pred_br_pc[i] = inst_r[i].uop.pred_br_pc;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_mispred[i] = inst_r[i].uop.mispred;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_br_taken[i] = inst_r[i].uop.br_taken;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_pc_next[i] = inst_r[i].uop.pc_next;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_dest_en[i] = inst_r[i].uop.dest_en;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_src1_en[i] = inst_r[i].uop.src1_en;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_src2_en[i] = inst_r[i].uop.src2_en;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_src1_busy[i] = inst_r[i].uop.src1_busy;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_src2_busy[i] = inst_r[i].uop.src2_busy;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_src1_latency[i] = inst_r[i].uop.src1_latency;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_src2_latency[i] = inst_r[i].uop.src2_latency;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_src1_is_pc[i] = inst_r[i].uop.src1_is_pc;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_src2_is_imm[i] = inst_r[i].uop.src2_is_imm;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_func3[i] = inst_r[i].uop.func3;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_func7_5[i] = inst_r[i].uop.func7_5;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_imm[i] = inst_r[i].uop.imm;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_pc[i] = inst_r[i].uop.pc;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_tag[i] = inst_r[i].uop.tag;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_csr_idx[i] = inst_r[i].uop.csr_idx;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_rob_idx[i] = inst_r[i].uop.rob_idx;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_stq_idx[i] = inst_r[i].uop.stq_idx;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_pre_sta_mask[i] = inst_r[i].uop.pre_sta_mask;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_pre_std_mask[i] = inst_r[i].uop.pre_std_mask;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_uop_num[i] = inst_r[i].uop.uop_num;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_cplt_num[i] = inst_r[i].uop.cplt_num;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_rob_flag[i] = inst_r[i].uop.rob_flag;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_page_fault_inst[i] = inst_r[i].uop.page_fault_inst;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_page_fault_load[i] = inst_r[i].uop.page_fault_load;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_page_fault_store[i] = inst_r[i].uop.page_fault_store;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_illegal_inst[i] = inst_r[i].uop.illegal_inst;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_type[i] = inst_r[i].uop.type;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_op[i] = inst_r[i].uop.op;
  }
  for(int i = 0; i < 4; i++) {
      rename_interface->inst_r_uop_amoop[i] = inst_r[i].uop.amoop;
  }
  for(int i = 0; i < 33; i++) {
      rename_interface->arch_RAT[i] = arch_RAT[i];
  }
  for(int i = 0; i < 33; i++) {
      rename_interface->spec_RAT[i] = spec_RAT[i];
  }
  for(int i = 0; i < 16; i++) {
      for(int j = 0; j < 33; j++) {
          rename_interface->RAT_checkpoint[i * 33 + j] = RAT_checkpoint[i][j];
      }
  }
  for(int i = 0; i < 128; i++) {
      rename_interface->free_vec[i] = free_vec[i];
  }
  for(int i = 0; i < 16; i++) {
      for(int j = 0; j < 128; j++) {
          rename_interface->alloc_checkpoint[i * 128 + j] = alloc_checkpoint[i][j];
      }
  }
  for(int i = 0; i < 128; i++) {
      rename_interface->busy_table[i] = busy_table[i];
  }
  for(int i = 0; i < 128; i++) {
      rename_interface->spec_alloc[i] = spec_alloc[i];
  }
  uint64_t buffer;
  rename_interface->eval();
  #ifdef VERILATOR_VCD
    m_trace->dump(vcd_time);
    vcd_time = vcd_time + 1;
    m_trace->dump(vcd_time);
    vcd_time = vcd_time + 1;
  #endif
//   m_trace->close();
  if(debug == 1) {
      buffer = rename_interface->out_ren2dec_ready;
      if(out.ren2dec->ready == buffer) {
          out.ren2dec->ready = rename_interface->out_ren2dec_ready;
      }
      else {
          cout << "out.ren2dec->ready == " << uint32_t(out.ren2dec->ready) << endl;
          exit(1);
      }
  }
  else {
      out.ren2dec->ready = rename_interface->out_ren2dec_ready;
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_instruction[i];
          if(out.ren2dis->uop[i].instruction == buffer) {
              out.ren2dis->uop[i].instruction = rename_interface->out_ren2dis_uop_instruction[i];
          }
          else {
              cout << "out.ren2dis->uop[i].instruction == " << uint32_t(out.ren2dis->uop[i].instruction) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].instruction = rename_interface->out_ren2dis_uop_instruction[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_dest_areg[i];
          if(out.ren2dis->uop[i].dest_areg == buffer) {
              out.ren2dis->uop[i].dest_areg = rename_interface->out_ren2dis_uop_dest_areg[i];
          }
          else {
              cout << "out.ren2dis->uop[i].dest_areg == " << uint32_t(out.ren2dis->uop[i].dest_areg) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].dest_areg = rename_interface->out_ren2dis_uop_dest_areg[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_src1_areg[i];
          if(out.ren2dis->uop[i].src1_areg == buffer) {
              out.ren2dis->uop[i].src1_areg = rename_interface->out_ren2dis_uop_src1_areg[i];
          }
          else {
              cout << "out.ren2dis->uop[i].src1_areg == " << uint32_t(out.ren2dis->uop[i].src1_areg) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].src1_areg = rename_interface->out_ren2dis_uop_src1_areg[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_src2_areg[i];
          if(out.ren2dis->uop[i].src2_areg == buffer) {
              out.ren2dis->uop[i].src2_areg = rename_interface->out_ren2dis_uop_src2_areg[i];
          }
          else {
              cout << "out.ren2dis->uop[i].src2_areg == " << uint32_t(out.ren2dis->uop[i].src2_areg) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].src2_areg = rename_interface->out_ren2dis_uop_src2_areg[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_dest_preg[i];
          if(out.ren2dis->uop[i].dest_preg == buffer) {
              out.ren2dis->uop[i].dest_preg = rename_interface->out_ren2dis_uop_dest_preg[i];
          }
          else {
              cout << "out.ren2dis->uop[i].dest_preg == " << uint32_t(out.ren2dis->uop[i].dest_preg) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].dest_preg = rename_interface->out_ren2dis_uop_dest_preg[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_src1_preg[i];
          if(out.ren2dis->uop[i].src1_preg == buffer) {
              out.ren2dis->uop[i].src1_preg = rename_interface->out_ren2dis_uop_src1_preg[i];
          }
          else {
              cout << "out.ren2dis->uop[i].src1_preg == " << uint32_t(out.ren2dis->uop[i].src1_preg) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].src1_preg = rename_interface->out_ren2dis_uop_src1_preg[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_src2_preg[i];
          if(out.ren2dis->uop[i].src2_preg == buffer) {
              out.ren2dis->uop[i].src2_preg = rename_interface->out_ren2dis_uop_src2_preg[i];
          }
          else {
              cout << "out.ren2dis->uop[i].src2_preg == " << uint32_t(out.ren2dis->uop[i].src2_preg) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].src2_preg = rename_interface->out_ren2dis_uop_src2_preg[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_old_dest_preg[i];
          if(out.ren2dis->uop[i].old_dest_preg == buffer) {
              out.ren2dis->uop[i].old_dest_preg = rename_interface->out_ren2dis_uop_old_dest_preg[i];
          }
          else {
              cout << "out.ren2dis->uop[i].old_dest_preg == " << uint32_t(out.ren2dis->uop[i].old_dest_preg) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].old_dest_preg = rename_interface->out_ren2dis_uop_old_dest_preg[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_src1_rdata[i];
          if(out.ren2dis->uop[i].src1_rdata == buffer) {
              out.ren2dis->uop[i].src1_rdata = rename_interface->out_ren2dis_uop_src1_rdata[i];
          }
          else {
              cout << "out.ren2dis->uop[i].src1_rdata == " << uint32_t(out.ren2dis->uop[i].src1_rdata) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].src1_rdata = rename_interface->out_ren2dis_uop_src1_rdata[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_src2_rdata[i];
          if(out.ren2dis->uop[i].src2_rdata == buffer) {
              out.ren2dis->uop[i].src2_rdata = rename_interface->out_ren2dis_uop_src2_rdata[i];
          }
          else {
              cout << "out.ren2dis->uop[i].src2_rdata == " << uint32_t(out.ren2dis->uop[i].src2_rdata) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].src2_rdata = rename_interface->out_ren2dis_uop_src2_rdata[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_result[i];
          if(out.ren2dis->uop[i].result == buffer) {
              out.ren2dis->uop[i].result = rename_interface->out_ren2dis_uop_result[i];
          }
          else {
              cout << "out.ren2dis->uop[i].result == " << uint32_t(out.ren2dis->uop[i].result) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].result = rename_interface->out_ren2dis_uop_result[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_pred_br_taken[i];
          if(out.ren2dis->uop[i].pred_br_taken == buffer) {
              out.ren2dis->uop[i].pred_br_taken = rename_interface->out_ren2dis_uop_pred_br_taken[i];
          }
          else {
              cout << "out.ren2dis->uop[i].pred_br_taken == " << uint32_t(out.ren2dis->uop[i].pred_br_taken) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].pred_br_taken = rename_interface->out_ren2dis_uop_pred_br_taken[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_alt_pred[i];
          if(out.ren2dis->uop[i].alt_pred == buffer) {
              out.ren2dis->uop[i].alt_pred = rename_interface->out_ren2dis_uop_alt_pred[i];
          }
          else {
              cout << "out.ren2dis->uop[i].alt_pred == " << uint32_t(out.ren2dis->uop[i].alt_pred) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].alt_pred = rename_interface->out_ren2dis_uop_alt_pred[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_altpcpn[i];
          if(out.ren2dis->uop[i].altpcpn == buffer) {
              out.ren2dis->uop[i].altpcpn = rename_interface->out_ren2dis_uop_altpcpn[i];
          }
          else {
              cout << "out.ren2dis->uop[i].altpcpn == " << uint32_t(out.ren2dis->uop[i].altpcpn) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].altpcpn = rename_interface->out_ren2dis_uop_altpcpn[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_pcpn[i];
          if(out.ren2dis->uop[i].pcpn == buffer) {
              out.ren2dis->uop[i].pcpn = rename_interface->out_ren2dis_uop_pcpn[i];
          }
          else {
              cout << "out.ren2dis->uop[i].pcpn == " << uint32_t(out.ren2dis->uop[i].pcpn) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].pcpn = rename_interface->out_ren2dis_uop_pcpn[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_pred_br_pc[i];
          if(out.ren2dis->uop[i].pred_br_pc == buffer) {
              out.ren2dis->uop[i].pred_br_pc = rename_interface->out_ren2dis_uop_pred_br_pc[i];
          }
          else {
              cout << "out.ren2dis->uop[i].pred_br_pc == " << uint32_t(out.ren2dis->uop[i].pred_br_pc) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].pred_br_pc = rename_interface->out_ren2dis_uop_pred_br_pc[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_mispred[i];
          if(out.ren2dis->uop[i].mispred == buffer) {
              out.ren2dis->uop[i].mispred = rename_interface->out_ren2dis_uop_mispred[i];
          }
          else {
              cout << "out.ren2dis->uop[i].mispred == " << uint32_t(out.ren2dis->uop[i].mispred) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].mispred = rename_interface->out_ren2dis_uop_mispred[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_br_taken[i];
          if(out.ren2dis->uop[i].br_taken == buffer) {
              out.ren2dis->uop[i].br_taken = rename_interface->out_ren2dis_uop_br_taken[i];
          }
          else {
              cout << "out.ren2dis->uop[i].br_taken == " << uint32_t(out.ren2dis->uop[i].br_taken) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].br_taken = rename_interface->out_ren2dis_uop_br_taken[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_pc_next[i];
          if(out.ren2dis->uop[i].pc_next == buffer) {
              out.ren2dis->uop[i].pc_next = rename_interface->out_ren2dis_uop_pc_next[i];
          }
          else {
              cout << "out.ren2dis->uop[i].pc_next == " << uint32_t(out.ren2dis->uop[i].pc_next) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].pc_next = rename_interface->out_ren2dis_uop_pc_next[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_dest_en[i];
          if(out.ren2dis->uop[i].dest_en == buffer) {
              out.ren2dis->uop[i].dest_en = rename_interface->out_ren2dis_uop_dest_en[i];
          }
          else {
              cout << "out.ren2dis->uop[i].dest_en == " << uint32_t(out.ren2dis->uop[i].dest_en) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].dest_en = rename_interface->out_ren2dis_uop_dest_en[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_src1_en[i];
          if(out.ren2dis->uop[i].src1_en == buffer) {
              out.ren2dis->uop[i].src1_en = rename_interface->out_ren2dis_uop_src1_en[i];
          }
          else {
              cout << "out.ren2dis->uop[i].src1_en == " << uint32_t(out.ren2dis->uop[i].src1_en) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].src1_en = rename_interface->out_ren2dis_uop_src1_en[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_src2_en[i];
          if(out.ren2dis->uop[i].src2_en == buffer) {
              out.ren2dis->uop[i].src2_en = rename_interface->out_ren2dis_uop_src2_en[i];
          }
          else {
              cout << "out.ren2dis->uop[i].src2_en == " << uint32_t(out.ren2dis->uop[i].src2_en) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].src2_en = rename_interface->out_ren2dis_uop_src2_en[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_src1_busy[i];
          if(out.ren2dis->uop[i].src1_busy == buffer) {
              out.ren2dis->uop[i].src1_busy = rename_interface->out_ren2dis_uop_src1_busy[i];
          }
          else {
              cout << "out.ren2dis->uop[i].src1_busy == " << uint32_t(out.ren2dis->uop[i].src1_busy) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].src1_busy = rename_interface->out_ren2dis_uop_src1_busy[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_src2_busy[i];
          if(out.ren2dis->uop[i].src2_busy == buffer) {
              out.ren2dis->uop[i].src2_busy = rename_interface->out_ren2dis_uop_src2_busy[i];
          }
          else {
              cout << "out.ren2dis->uop[i].src2_busy == " << uint32_t(out.ren2dis->uop[i].src2_busy) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].src2_busy = rename_interface->out_ren2dis_uop_src2_busy[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_src1_latency[i];
          if(out.ren2dis->uop[i].src1_latency == buffer) {
              out.ren2dis->uop[i].src1_latency = rename_interface->out_ren2dis_uop_src1_latency[i];
          }
          else {
              cout << "out.ren2dis->uop[i].src1_latency == " << uint32_t(out.ren2dis->uop[i].src1_latency) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].src1_latency = rename_interface->out_ren2dis_uop_src1_latency[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_src2_latency[i];
          if(out.ren2dis->uop[i].src2_latency == buffer) {
              out.ren2dis->uop[i].src2_latency = rename_interface->out_ren2dis_uop_src2_latency[i];
          }
          else {
              cout << "out.ren2dis->uop[i].src2_latency == " << uint32_t(out.ren2dis->uop[i].src2_latency) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].src2_latency = rename_interface->out_ren2dis_uop_src2_latency[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_src1_is_pc[i];
          if(out.ren2dis->uop[i].src1_is_pc == buffer) {
              out.ren2dis->uop[i].src1_is_pc = rename_interface->out_ren2dis_uop_src1_is_pc[i];
          }
          else {
              cout << "out.ren2dis->uop[i].src1_is_pc == " << uint32_t(out.ren2dis->uop[i].src1_is_pc) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].src1_is_pc = rename_interface->out_ren2dis_uop_src1_is_pc[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_src2_is_imm[i];
          if(out.ren2dis->uop[i].src2_is_imm == buffer) {
              out.ren2dis->uop[i].src2_is_imm = rename_interface->out_ren2dis_uop_src2_is_imm[i];
          }
          else {
              cout << "out.ren2dis->uop[i].src2_is_imm == " << uint32_t(out.ren2dis->uop[i].src2_is_imm) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].src2_is_imm = rename_interface->out_ren2dis_uop_src2_is_imm[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_func3[i];
          if(out.ren2dis->uop[i].func3 == buffer) {
              out.ren2dis->uop[i].func3 = rename_interface->out_ren2dis_uop_func3[i];
          }
          else {
              cout << "out.ren2dis->uop[i].func3 == " << uint32_t(out.ren2dis->uop[i].func3) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].func3 = rename_interface->out_ren2dis_uop_func3[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_func7_5[i];
          if(out.ren2dis->uop[i].func7_5 == buffer) {
              out.ren2dis->uop[i].func7_5 = rename_interface->out_ren2dis_uop_func7_5[i];
          }
          else {
              cout << "out.ren2dis->uop[i].func7_5 == " << uint32_t(out.ren2dis->uop[i].func7_5) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].func7_5 = rename_interface->out_ren2dis_uop_func7_5[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_imm[i];
          if(out.ren2dis->uop[i].imm == buffer) {
              out.ren2dis->uop[i].imm = rename_interface->out_ren2dis_uop_imm[i];
          }
          else {
              cout << "out.ren2dis->uop[i].imm == " << uint32_t(out.ren2dis->uop[i].imm) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].imm = rename_interface->out_ren2dis_uop_imm[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_pc[i];
          if(out.ren2dis->uop[i].pc == buffer) {
              out.ren2dis->uop[i].pc = rename_interface->out_ren2dis_uop_pc[i];
          }
          else {
              cout << "out.ren2dis->uop[i].pc == " << uint32_t(out.ren2dis->uop[i].pc) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].pc = rename_interface->out_ren2dis_uop_pc[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_tag[i];
          if(out.ren2dis->uop[i].tag == buffer) {
              out.ren2dis->uop[i].tag = rename_interface->out_ren2dis_uop_tag[i];
          }
          else {
              cout << "out.ren2dis->uop[i].tag == " << uint32_t(out.ren2dis->uop[i].tag) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].tag = rename_interface->out_ren2dis_uop_tag[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_csr_idx[i];
          if(out.ren2dis->uop[i].csr_idx == buffer) {
              out.ren2dis->uop[i].csr_idx = rename_interface->out_ren2dis_uop_csr_idx[i];
          }
          else {
              cout << "out.ren2dis->uop[i].csr_idx == " << uint32_t(out.ren2dis->uop[i].csr_idx) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].csr_idx = rename_interface->out_ren2dis_uop_csr_idx[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_rob_idx[i];
          if(out.ren2dis->uop[i].rob_idx == buffer) {
              out.ren2dis->uop[i].rob_idx = rename_interface->out_ren2dis_uop_rob_idx[i];
          }
          else {
              cout << "out.ren2dis->uop[i].rob_idx == " << uint32_t(out.ren2dis->uop[i].rob_idx) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].rob_idx = rename_interface->out_ren2dis_uop_rob_idx[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_stq_idx[i];
          if(out.ren2dis->uop[i].stq_idx == buffer) {
              out.ren2dis->uop[i].stq_idx = rename_interface->out_ren2dis_uop_stq_idx[i];
          }
          else {
              cout << "out.ren2dis->uop[i].stq_idx == " << uint32_t(out.ren2dis->uop[i].stq_idx) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].stq_idx = rename_interface->out_ren2dis_uop_stq_idx[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_pre_sta_mask[i];
          if(out.ren2dis->uop[i].pre_sta_mask == buffer) {
              out.ren2dis->uop[i].pre_sta_mask = rename_interface->out_ren2dis_uop_pre_sta_mask[i];
          }
          else {
              cout << "out.ren2dis->uop[i].pre_sta_mask == " << uint32_t(out.ren2dis->uop[i].pre_sta_mask) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].pre_sta_mask = rename_interface->out_ren2dis_uop_pre_sta_mask[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_pre_std_mask[i];
          if(out.ren2dis->uop[i].pre_std_mask == buffer) {
              out.ren2dis->uop[i].pre_std_mask = rename_interface->out_ren2dis_uop_pre_std_mask[i];
          }
          else {
              cout << "out.ren2dis->uop[i].pre_std_mask == " << uint32_t(out.ren2dis->uop[i].pre_std_mask) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].pre_std_mask = rename_interface->out_ren2dis_uop_pre_std_mask[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_uop_num[i];
          if(out.ren2dis->uop[i].uop_num == buffer) {
              out.ren2dis->uop[i].uop_num = rename_interface->out_ren2dis_uop_uop_num[i];
          }
          else {
              cout << "out.ren2dis->uop[i].uop_num == " << uint32_t(out.ren2dis->uop[i].uop_num) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].uop_num = rename_interface->out_ren2dis_uop_uop_num[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_cplt_num[i];
          if(out.ren2dis->uop[i].cplt_num == buffer) {
              out.ren2dis->uop[i].cplt_num = rename_interface->out_ren2dis_uop_cplt_num[i];
          }
          else {
              cout << "out.ren2dis->uop[i].cplt_num == " << uint32_t(out.ren2dis->uop[i].cplt_num) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].cplt_num = rename_interface->out_ren2dis_uop_cplt_num[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_rob_flag[i];
          if(out.ren2dis->uop[i].rob_flag == buffer) {
              out.ren2dis->uop[i].rob_flag = rename_interface->out_ren2dis_uop_rob_flag[i];
          }
          else {
              cout << "out.ren2dis->uop[i].rob_flag == " << uint32_t(out.ren2dis->uop[i].rob_flag) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].rob_flag = rename_interface->out_ren2dis_uop_rob_flag[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_page_fault_inst[i];
          if(out.ren2dis->uop[i].page_fault_inst == buffer) {
              out.ren2dis->uop[i].page_fault_inst = rename_interface->out_ren2dis_uop_page_fault_inst[i];
          }
          else {
              cout << "out.ren2dis->uop[i].page_fault_inst == " << uint32_t(out.ren2dis->uop[i].page_fault_inst) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].page_fault_inst = rename_interface->out_ren2dis_uop_page_fault_inst[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_page_fault_load[i];
          if(out.ren2dis->uop[i].page_fault_load == buffer) {
              out.ren2dis->uop[i].page_fault_load = rename_interface->out_ren2dis_uop_page_fault_load[i];
          }
          else {
              cout << "out.ren2dis->uop[i].page_fault_load == " << uint32_t(out.ren2dis->uop[i].page_fault_load) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].page_fault_load = rename_interface->out_ren2dis_uop_page_fault_load[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_page_fault_store[i];
          if(out.ren2dis->uop[i].page_fault_store == buffer) {
              out.ren2dis->uop[i].page_fault_store = rename_interface->out_ren2dis_uop_page_fault_store[i];
          }
          else {
              cout << "out.ren2dis->uop[i].page_fault_store == " << uint32_t(out.ren2dis->uop[i].page_fault_store) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].page_fault_store = rename_interface->out_ren2dis_uop_page_fault_store[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_illegal_inst[i];
          if(out.ren2dis->uop[i].illegal_inst == buffer) {
              out.ren2dis->uop[i].illegal_inst = rename_interface->out_ren2dis_uop_illegal_inst[i];
          }
          else {
              cout << "out.ren2dis->uop[i].illegal_inst == " << uint32_t(out.ren2dis->uop[i].illegal_inst) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].illegal_inst = rename_interface->out_ren2dis_uop_illegal_inst[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_type[i];
          if(out.ren2dis->uop[i].type == buffer) {
              out.ren2dis->uop[i].type = rename_interface->out_ren2dis_uop_type[i];
          }
          else {
              cout << "out.ren2dis->uop[i].type == " << uint32_t(out.ren2dis->uop[i].type) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].type = rename_interface->out_ren2dis_uop_type[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_op[i];
          if(out.ren2dis->uop[i].op == buffer) {
              out.ren2dis->uop[i].op = rename_interface->out_ren2dis_uop_op[i];
          }
          else {
              cout << "out.ren2dis->uop[i].op == " << uint32_t(out.ren2dis->uop[i].op) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].op = rename_interface->out_ren2dis_uop_op[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_uop_amoop[i];
          if(out.ren2dis->uop[i].amoop == buffer) {
              out.ren2dis->uop[i].amoop = rename_interface->out_ren2dis_uop_amoop[i];
          }
          else {
              cout << "out.ren2dis->uop[i].amoop == " << uint32_t(out.ren2dis->uop[i].amoop) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->uop[i].amoop = rename_interface->out_ren2dis_uop_amoop[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->out_ren2dis_valid[i];
          if(out.ren2dis->valid[i] == buffer) {
              out.ren2dis->valid[i] = rename_interface->out_ren2dis_valid[i];
          }
          else {
              cout << "out.ren2dis->valid[i] == " << uint32_t(out.ren2dis->valid[i]) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          out.ren2dis->valid[i] = rename_interface->out_ren2dis_valid[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_valid[i];
          if(inst_r_1[i].valid == buffer) {
              inst_r_1[i].valid = rename_interface->inst_r_1_valid[i];
          }
          else {
              cout << "inst_r_1[i].valid == " << uint32_t(inst_r_1[i].valid) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].valid = rename_interface->inst_r_1_valid[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_instruction[i];
          if(inst_r_1[i].uop.instruction == buffer) {
              inst_r_1[i].uop.instruction = rename_interface->inst_r_1_uop_instruction[i];
          }
          else {
              cout << "inst_r_1[i].uop.instruction == " << uint32_t(inst_r_1[i].uop.instruction) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.instruction = rename_interface->inst_r_1_uop_instruction[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_dest_areg[i];
          if(inst_r_1[i].uop.dest_areg == buffer) {
              inst_r_1[i].uop.dest_areg = rename_interface->inst_r_1_uop_dest_areg[i];
          }
          else {
              cout << "inst_r_1[i].uop.dest_areg == " << uint32_t(inst_r_1[i].uop.dest_areg) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.dest_areg = rename_interface->inst_r_1_uop_dest_areg[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_src1_areg[i];
          if(inst_r_1[i].uop.src1_areg == buffer) {
              inst_r_1[i].uop.src1_areg = rename_interface->inst_r_1_uop_src1_areg[i];
          }
          else {
              cout << "inst_r_1[i].uop.src1_areg == " << uint32_t(inst_r_1[i].uop.src1_areg) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.src1_areg = rename_interface->inst_r_1_uop_src1_areg[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_src2_areg[i];
          if(inst_r_1[i].uop.src2_areg == buffer) {
              inst_r_1[i].uop.src2_areg = rename_interface->inst_r_1_uop_src2_areg[i];
          }
          else {
              cout << "inst_r_1[i].uop.src2_areg == " << uint32_t(inst_r_1[i].uop.src2_areg) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.src2_areg = rename_interface->inst_r_1_uop_src2_areg[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_dest_preg[i];
          if(inst_r_1[i].uop.dest_preg == buffer) {
              inst_r_1[i].uop.dest_preg = rename_interface->inst_r_1_uop_dest_preg[i];
          }
          else {
              cout << "inst_r_1[i].uop.dest_preg == " << uint32_t(inst_r_1[i].uop.dest_preg) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.dest_preg = rename_interface->inst_r_1_uop_dest_preg[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_src1_preg[i];
          if(inst_r_1[i].uop.src1_preg == buffer) {
              inst_r_1[i].uop.src1_preg = rename_interface->inst_r_1_uop_src1_preg[i];
          }
          else {
              cout << "inst_r_1[i].uop.src1_preg == " << uint32_t(inst_r_1[i].uop.src1_preg) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.src1_preg = rename_interface->inst_r_1_uop_src1_preg[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_src2_preg[i];
          if(inst_r_1[i].uop.src2_preg == buffer) {
              inst_r_1[i].uop.src2_preg = rename_interface->inst_r_1_uop_src2_preg[i];
          }
          else {
              cout << "inst_r_1[i].uop.src2_preg == " << uint32_t(inst_r_1[i].uop.src2_preg) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.src2_preg = rename_interface->inst_r_1_uop_src2_preg[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_old_dest_preg[i];
          if(inst_r_1[i].uop.old_dest_preg == buffer) {
              inst_r_1[i].uop.old_dest_preg = rename_interface->inst_r_1_uop_old_dest_preg[i];
          }
          else {
              cout << "inst_r_1[i].uop.old_dest_preg == " << uint32_t(inst_r_1[i].uop.old_dest_preg) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.old_dest_preg = rename_interface->inst_r_1_uop_old_dest_preg[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_src1_rdata[i];
          if(inst_r_1[i].uop.src1_rdata == buffer) {
              inst_r_1[i].uop.src1_rdata = rename_interface->inst_r_1_uop_src1_rdata[i];
          }
          else {
              cout << "inst_r_1[i].uop.src1_rdata == " << uint32_t(inst_r_1[i].uop.src1_rdata) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.src1_rdata = rename_interface->inst_r_1_uop_src1_rdata[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_src2_rdata[i];
          if(inst_r_1[i].uop.src2_rdata == buffer) {
              inst_r_1[i].uop.src2_rdata = rename_interface->inst_r_1_uop_src2_rdata[i];
          }
          else {
              cout << "inst_r_1[i].uop.src2_rdata == " << uint32_t(inst_r_1[i].uop.src2_rdata) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.src2_rdata = rename_interface->inst_r_1_uop_src2_rdata[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_result[i];
          if(inst_r_1[i].uop.result == buffer) {
              inst_r_1[i].uop.result = rename_interface->inst_r_1_uop_result[i];
          }
          else {
              cout << "inst_r_1[i].uop.result == " << uint32_t(inst_r_1[i].uop.result) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.result = rename_interface->inst_r_1_uop_result[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_pred_br_taken[i];
          if(inst_r_1[i].uop.pred_br_taken == buffer) {
              inst_r_1[i].uop.pred_br_taken = rename_interface->inst_r_1_uop_pred_br_taken[i];
          }
          else {
              cout << "inst_r_1[i].uop.pred_br_taken == " << uint32_t(inst_r_1[i].uop.pred_br_taken) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.pred_br_taken = rename_interface->inst_r_1_uop_pred_br_taken[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_alt_pred[i];
          if(inst_r_1[i].uop.alt_pred == buffer) {
              inst_r_1[i].uop.alt_pred = rename_interface->inst_r_1_uop_alt_pred[i];
          }
          else {
              cout << "inst_r_1[i].uop.alt_pred == " << uint32_t(inst_r_1[i].uop.alt_pred) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.alt_pred = rename_interface->inst_r_1_uop_alt_pred[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_altpcpn[i];
          if(inst_r_1[i].uop.altpcpn == buffer) {
              inst_r_1[i].uop.altpcpn = rename_interface->inst_r_1_uop_altpcpn[i];
          }
          else {
              cout << "inst_r_1[i].uop.altpcpn == " << uint32_t(inst_r_1[i].uop.altpcpn) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.altpcpn = rename_interface->inst_r_1_uop_altpcpn[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_pcpn[i];
          if(inst_r_1[i].uop.pcpn == buffer) {
              inst_r_1[i].uop.pcpn = rename_interface->inst_r_1_uop_pcpn[i];
          }
          else {
              cout << "inst_r_1[i].uop.pcpn == " << uint32_t(inst_r_1[i].uop.pcpn) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.pcpn = rename_interface->inst_r_1_uop_pcpn[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_pred_br_pc[i];
          if(inst_r_1[i].uop.pred_br_pc == buffer) {
              inst_r_1[i].uop.pred_br_pc = rename_interface->inst_r_1_uop_pred_br_pc[i];
          }
          else {
              cout << "inst_r_1[i].uop.pred_br_pc == " << uint32_t(inst_r_1[i].uop.pred_br_pc) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.pred_br_pc = rename_interface->inst_r_1_uop_pred_br_pc[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_mispred[i];
          if(inst_r_1[i].uop.mispred == buffer) {
              inst_r_1[i].uop.mispred = rename_interface->inst_r_1_uop_mispred[i];
          }
          else {
              cout << "inst_r_1[i].uop.mispred == " << uint32_t(inst_r_1[i].uop.mispred) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.mispred = rename_interface->inst_r_1_uop_mispred[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_br_taken[i];
          if(inst_r_1[i].uop.br_taken == buffer) {
              inst_r_1[i].uop.br_taken = rename_interface->inst_r_1_uop_br_taken[i];
          }
          else {
              cout << "inst_r_1[i].uop.br_taken == " << uint32_t(inst_r_1[i].uop.br_taken) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.br_taken = rename_interface->inst_r_1_uop_br_taken[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_pc_next[i];
          if(inst_r_1[i].uop.pc_next == buffer) {
              inst_r_1[i].uop.pc_next = rename_interface->inst_r_1_uop_pc_next[i];
          }
          else {
              cout << "inst_r_1[i].uop.pc_next == " << uint32_t(inst_r_1[i].uop.pc_next) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.pc_next = rename_interface->inst_r_1_uop_pc_next[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_dest_en[i];
          if(inst_r_1[i].uop.dest_en == buffer) {
              inst_r_1[i].uop.dest_en = rename_interface->inst_r_1_uop_dest_en[i];
          }
          else {
              cout << "inst_r_1[i].uop.dest_en == " << uint32_t(inst_r_1[i].uop.dest_en) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.dest_en = rename_interface->inst_r_1_uop_dest_en[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_src1_en[i];
          if(inst_r_1[i].uop.src1_en == buffer) {
              inst_r_1[i].uop.src1_en = rename_interface->inst_r_1_uop_src1_en[i];
          }
          else {
              cout << "inst_r_1[i].uop.src1_en == " << uint32_t(inst_r_1[i].uop.src1_en) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.src1_en = rename_interface->inst_r_1_uop_src1_en[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_src2_en[i];
          if(inst_r_1[i].uop.src2_en == buffer) {
              inst_r_1[i].uop.src2_en = rename_interface->inst_r_1_uop_src2_en[i];
          }
          else {
              cout << "inst_r_1[i].uop.src2_en == " << uint32_t(inst_r_1[i].uop.src2_en) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.src2_en = rename_interface->inst_r_1_uop_src2_en[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_src1_busy[i];
          if(inst_r_1[i].uop.src1_busy == buffer) {
              inst_r_1[i].uop.src1_busy = rename_interface->inst_r_1_uop_src1_busy[i];
          }
          else {
              cout << "inst_r_1[i].uop.src1_busy == " << uint32_t(inst_r_1[i].uop.src1_busy) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.src1_busy = rename_interface->inst_r_1_uop_src1_busy[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_src2_busy[i];
          if(inst_r_1[i].uop.src2_busy == buffer) {
              inst_r_1[i].uop.src2_busy = rename_interface->inst_r_1_uop_src2_busy[i];
          }
          else {
              cout << "inst_r_1[i].uop.src2_busy == " << uint32_t(inst_r_1[i].uop.src2_busy) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.src2_busy = rename_interface->inst_r_1_uop_src2_busy[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_src1_latency[i];
          if(inst_r_1[i].uop.src1_latency == buffer) {
              inst_r_1[i].uop.src1_latency = rename_interface->inst_r_1_uop_src1_latency[i];
          }
          else {
              cout << "inst_r_1[i].uop.src1_latency == " << uint32_t(inst_r_1[i].uop.src1_latency) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.src1_latency = rename_interface->inst_r_1_uop_src1_latency[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_src2_latency[i];
          if(inst_r_1[i].uop.src2_latency == buffer) {
              inst_r_1[i].uop.src2_latency = rename_interface->inst_r_1_uop_src2_latency[i];
          }
          else {
              cout << "inst_r_1[i].uop.src2_latency == " << uint32_t(inst_r_1[i].uop.src2_latency) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.src2_latency = rename_interface->inst_r_1_uop_src2_latency[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_src1_is_pc[i];
          if(inst_r_1[i].uop.src1_is_pc == buffer) {
              inst_r_1[i].uop.src1_is_pc = rename_interface->inst_r_1_uop_src1_is_pc[i];
          }
          else {
              cout << "inst_r_1[i].uop.src1_is_pc == " << uint32_t(inst_r_1[i].uop.src1_is_pc) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.src1_is_pc = rename_interface->inst_r_1_uop_src1_is_pc[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_src2_is_imm[i];
          if(inst_r_1[i].uop.src2_is_imm == buffer) {
              inst_r_1[i].uop.src2_is_imm = rename_interface->inst_r_1_uop_src2_is_imm[i];
          }
          else {
              cout << "inst_r_1[i].uop.src2_is_imm == " << uint32_t(inst_r_1[i].uop.src2_is_imm) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.src2_is_imm = rename_interface->inst_r_1_uop_src2_is_imm[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_func3[i];
          if(inst_r_1[i].uop.func3 == buffer) {
              inst_r_1[i].uop.func3 = rename_interface->inst_r_1_uop_func3[i];
          }
          else {
              cout << "inst_r_1[i].uop.func3 == " << uint32_t(inst_r_1[i].uop.func3) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.func3 = rename_interface->inst_r_1_uop_func3[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_func7_5[i];
          if(inst_r_1[i].uop.func7_5 == buffer) {
              inst_r_1[i].uop.func7_5 = rename_interface->inst_r_1_uop_func7_5[i];
          }
          else {
              cout << "inst_r_1[i].uop.func7_5 == " << uint32_t(inst_r_1[i].uop.func7_5) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.func7_5 = rename_interface->inst_r_1_uop_func7_5[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_imm[i];
          if(inst_r_1[i].uop.imm == buffer) {
              inst_r_1[i].uop.imm = rename_interface->inst_r_1_uop_imm[i];
          }
          else {
              cout << "inst_r_1[i].uop.imm == " << uint32_t(inst_r_1[i].uop.imm) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.imm = rename_interface->inst_r_1_uop_imm[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_pc[i];
          if(inst_r_1[i].uop.pc == buffer) {
              inst_r_1[i].uop.pc = rename_interface->inst_r_1_uop_pc[i];
          }
          else {
              cout << "inst_r_1[i].uop.pc == " << uint32_t(inst_r_1[i].uop.pc) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.pc = rename_interface->inst_r_1_uop_pc[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_tag[i];
          if(inst_r_1[i].uop.tag == buffer) {
              inst_r_1[i].uop.tag = rename_interface->inst_r_1_uop_tag[i];
          }
          else {
              cout << "inst_r_1[i].uop.tag == " << uint32_t(inst_r_1[i].uop.tag) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.tag = rename_interface->inst_r_1_uop_tag[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_csr_idx[i];
          if(inst_r_1[i].uop.csr_idx == buffer) {
              inst_r_1[i].uop.csr_idx = rename_interface->inst_r_1_uop_csr_idx[i];
          }
          else {
              cout << "inst_r_1[i].uop.csr_idx == " << uint32_t(inst_r_1[i].uop.csr_idx) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.csr_idx = rename_interface->inst_r_1_uop_csr_idx[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_rob_idx[i];
          if(inst_r_1[i].uop.rob_idx == buffer) {
              inst_r_1[i].uop.rob_idx = rename_interface->inst_r_1_uop_rob_idx[i];
          }
          else {
              cout << "inst_r_1[i].uop.rob_idx == " << uint32_t(inst_r_1[i].uop.rob_idx) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.rob_idx = rename_interface->inst_r_1_uop_rob_idx[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_stq_idx[i];
          if(inst_r_1[i].uop.stq_idx == buffer) {
              inst_r_1[i].uop.stq_idx = rename_interface->inst_r_1_uop_stq_idx[i];
          }
          else {
              cout << "inst_r_1[i].uop.stq_idx == " << uint32_t(inst_r_1[i].uop.stq_idx) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.stq_idx = rename_interface->inst_r_1_uop_stq_idx[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_pre_sta_mask[i];
          if(inst_r_1[i].uop.pre_sta_mask == buffer) {
              inst_r_1[i].uop.pre_sta_mask = rename_interface->inst_r_1_uop_pre_sta_mask[i];
          }
          else {
              cout << "inst_r_1[i].uop.pre_sta_mask == " << uint32_t(inst_r_1[i].uop.pre_sta_mask) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.pre_sta_mask = rename_interface->inst_r_1_uop_pre_sta_mask[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_pre_std_mask[i];
          if(inst_r_1[i].uop.pre_std_mask == buffer) {
              inst_r_1[i].uop.pre_std_mask = rename_interface->inst_r_1_uop_pre_std_mask[i];
          }
          else {
              cout << "inst_r_1[i].uop.pre_std_mask == " << uint32_t(inst_r_1[i].uop.pre_std_mask) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.pre_std_mask = rename_interface->inst_r_1_uop_pre_std_mask[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_uop_num[i];
          if(inst_r_1[i].uop.uop_num == buffer) {
              inst_r_1[i].uop.uop_num = rename_interface->inst_r_1_uop_uop_num[i];
          }
          else {
              cout << "inst_r_1[i].uop.uop_num == " << uint32_t(inst_r_1[i].uop.uop_num) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.uop_num = rename_interface->inst_r_1_uop_uop_num[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_cplt_num[i];
          if(inst_r_1[i].uop.cplt_num == buffer) {
              inst_r_1[i].uop.cplt_num = rename_interface->inst_r_1_uop_cplt_num[i];
          }
          else {
              cout << "inst_r_1[i].uop.cplt_num == " << uint32_t(inst_r_1[i].uop.cplt_num) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.cplt_num = rename_interface->inst_r_1_uop_cplt_num[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_rob_flag[i];
          if(inst_r_1[i].uop.rob_flag == buffer) {
              inst_r_1[i].uop.rob_flag = rename_interface->inst_r_1_uop_rob_flag[i];
          }
          else {
              cout << "inst_r_1[i].uop.rob_flag == " << uint32_t(inst_r_1[i].uop.rob_flag) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.rob_flag = rename_interface->inst_r_1_uop_rob_flag[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_page_fault_inst[i];
          if(inst_r_1[i].uop.page_fault_inst == buffer) {
              inst_r_1[i].uop.page_fault_inst = rename_interface->inst_r_1_uop_page_fault_inst[i];
          }
          else {
              cout << "inst_r_1[i].uop.page_fault_inst == " << uint32_t(inst_r_1[i].uop.page_fault_inst) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.page_fault_inst = rename_interface->inst_r_1_uop_page_fault_inst[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_page_fault_load[i];
          if(inst_r_1[i].uop.page_fault_load == buffer) {
              inst_r_1[i].uop.page_fault_load = rename_interface->inst_r_1_uop_page_fault_load[i];
          }
          else {
              cout << "inst_r_1[i].uop.page_fault_load == " << uint32_t(inst_r_1[i].uop.page_fault_load) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.page_fault_load = rename_interface->inst_r_1_uop_page_fault_load[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_page_fault_store[i];
          if(inst_r_1[i].uop.page_fault_store == buffer) {
              inst_r_1[i].uop.page_fault_store = rename_interface->inst_r_1_uop_page_fault_store[i];
          }
          else {
              cout << "inst_r_1[i].uop.page_fault_store == " << uint32_t(inst_r_1[i].uop.page_fault_store) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.page_fault_store = rename_interface->inst_r_1_uop_page_fault_store[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_illegal_inst[i];
          if(inst_r_1[i].uop.illegal_inst == buffer) {
              inst_r_1[i].uop.illegal_inst = rename_interface->inst_r_1_uop_illegal_inst[i];
          }
          else {
              cout << "inst_r_1[i].uop.illegal_inst == " << uint32_t(inst_r_1[i].uop.illegal_inst) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.illegal_inst = rename_interface->inst_r_1_uop_illegal_inst[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_type[i];
          if(inst_r_1[i].uop.type == buffer) {
              inst_r_1[i].uop.type = rename_interface->inst_r_1_uop_type[i];
          }
          else {
              cout << "inst_r_1[i].uop.type == " << uint32_t(inst_r_1[i].uop.type) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.type = rename_interface->inst_r_1_uop_type[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_op[i];
          if(inst_r_1[i].uop.op == buffer) {
              inst_r_1[i].uop.op = rename_interface->inst_r_1_uop_op[i];
          }
          else {
              cout << "inst_r_1[i].uop.op == " << uint32_t(inst_r_1[i].uop.op) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.op = rename_interface->inst_r_1_uop_op[i];
      }
  }
  for(int i = 0; i < 4; i++) {
      if(debug == 1) {
          buffer = rename_interface->inst_r_1_uop_amoop[i];
          if(inst_r_1[i].uop.amoop == buffer) {
              inst_r_1[i].uop.amoop = rename_interface->inst_r_1_uop_amoop[i];
          }
          else {
              cout << "inst_r_1[i].uop.amoop == " << uint32_t(inst_r_1[i].uop.amoop) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          inst_r_1[i].uop.amoop = rename_interface->inst_r_1_uop_amoop[i];
      }
  }
  for(int i = 0; i < 33; i++) {
      if(debug == 1) {
          buffer = rename_interface->arch_RAT_1[i];
          if(arch_RAT_1[i] == buffer) {
              arch_RAT_1[i] = rename_interface->arch_RAT_1[i];
          }
          else {
              cout << "arch_RAT_1[i] == " << uint32_t(arch_RAT_1[i]) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          arch_RAT_1[i] = rename_interface->arch_RAT_1[i];
      }
  }
  for(int i = 0; i < 33; i++) {
      if(debug == 1) {
          buffer = rename_interface->spec_RAT_1[i];
          if(spec_RAT_1[i] == buffer) {
              spec_RAT_1[i] = rename_interface->spec_RAT_1[i];
          }
          else {
              cout << "spec_RAT_1[i] == " << uint32_t(spec_RAT_1[i]) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          spec_RAT_1[i] = rename_interface->spec_RAT_1[i];
      }
  }
  for(int i = 0; i < 16; i++) {
      for(int j = 0; j < 33; j++) {
          if(debug == 1) {
              buffer = rename_interface->RAT_checkpoint_1[i * 33 + j];
              if(RAT_checkpoint_1[i][j] == buffer) {
                  RAT_checkpoint_1[i][j] = rename_interface->RAT_checkpoint_1[i * 33 + j];
              }
              else {
                  cout << "RAT_checkpoint_1[i][j] == " << uint32_t(RAT_checkpoint_1[i][j]) << " i = " << i << " j = " << j << endl;
                  exit(1);
              }
          }
          else {
              RAT_checkpoint_1[i][j] = rename_interface->RAT_checkpoint_1[i * 33 + j];
          }
      }
  }
  for(int i = 0; i < 128; i++) {
      if(debug == 1) {
          buffer = rename_interface->free_vec_1[i];
          if(free_vec_1[i] == buffer) {
              free_vec_1[i] = rename_interface->free_vec_1[i];
          }
          else {
              cout << "free_vec_1[i] == " << uint32_t(free_vec_1[i]) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          free_vec_1[i] = rename_interface->free_vec_1[i];
      }
  }
  for(int i = 0; i < 16; i++) {
      for(int j = 0; j < 128; j++) {
          if(debug == 1) {
              buffer = rename_interface->alloc_checkpoint_1[i * 128 + j];
              if(alloc_checkpoint_1[i][j] == buffer) {
                  alloc_checkpoint_1[i][j] = rename_interface->alloc_checkpoint_1[i * 128 + j];
              }
              else {
                  cout << "alloc_checkpoint_1[i][j] == " << uint32_t(alloc_checkpoint_1[i][j]) << " i = " << i << " j = " << j << endl;
                  exit(1);
              }
          }
          else {
              alloc_checkpoint_1[i][j] = rename_interface->alloc_checkpoint_1[i * 128 + j];
          }
      }
  }
  for(int i = 0; i < 128; i++) {
      if(debug == 1) {
          buffer = rename_interface->busy_table_1[i];
          if(busy_table_1[i] == buffer) {
              busy_table_1[i] = rename_interface->busy_table_1[i];
          }
          else {
              cout << "busy_table_1[i] == " << uint32_t(busy_table_1[i]) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          busy_table_1[i] = rename_interface->busy_table_1[i];
      }
  }
  for(int i = 0; i < 128; i++) {
      if(debug == 1) {
          buffer = rename_interface->spec_alloc_1[i];
          if(spec_alloc_1[i] == buffer) {
              spec_alloc_1[i] = rename_interface->spec_alloc_1[i];
          }
          else {
              cout << "spec_alloc_1[i] == " << uint32_t(spec_alloc_1[i]) << " i = " << i << endl;
              exit(1);
          }
      }
      else {
          spec_alloc_1[i] = rename_interface->spec_alloc_1[i];
      }
  }
}
