package MyCPU.bpu

import chisel3._
import chisel3.util._

import MyCPU.common._

class BpuIO(implicit p: BpuParams)
extends Bundle
{

    val pc_reg = Input(UInt(p.xLen.W))
    val if1_fire = Input(Bool())
    val bpu_update = Flipped(Valid(new BpuUpdate))

    val pred_target = Output(UInt(p.xLen.W))
    val pred_slot = Output(Bool()) //f = 0 , t = 1
    val pred_taken = Output(Bool())
}

class BPU(implicit p: BpuParams)
extends Module
with MyCPU.common.constants.ScalaOpConsts
with MyCPU.common.constants.RISCVConsts
{
    val io = IO(new BpuIO)
    val pc_reg = io.pc_reg

    val btb_size = p.btb_size
    val bht_size = btb_size * 2
    val idx_w = log2Ceil(btb_size)
    
    val btb_valid = RegInit(VecInit(Seq.fill(p.btb_size)(false.B)))
    val btb_tag = Reg(Vec(btb_size, UInt((p.xLen - idx_w - 3 ).W)))
    val btb_target = Reg(Vec(btb_size, UInt(p.xLen.W)))
    val btb_slot = Reg(Vec(btb_size, Bool()))
    val btb_is_branch = Reg(Vec(btb_size, Bool())) // cond br or uncond br

    val bht = RegInit(VecInit(Seq.fill(bht_size)(1.U(2.W))))

    val fetch_idx = pc_reg(idx_w + 2, 3)
    val fetch_tag = pc_reg(p.xLen - 1, idx_w + 3)

    val target_cand = btb_target(fetch_idx) 
    val slot_cand = btb_slot(fetch_idx)
    val is_branch = btb_is_branch(fetch_idx)

    val tag_match = btb_valid(fetch_idx) && (btb_tag(fetch_idx) === fetch_tag)

    val slot_valid = !pc_reg(2) || (pred_slot === true.B)
    val btb_hit = tag_match && slot_valid

    val bht_fetch_idx = Cat(fetch_idx, slot_cand)
    val bht_counter = bht(bht_fetch_idx)
    val bht_taken = bht_counter(1)

    val pred_taken = btb_hit && (!is_branch || bht_taken)

    when(io.bpu_update.valid)
    {
        val up_pc = io.bpu_update.bits.pc
        val up_idx = up_pc(idx_w + 2, 3)
        val up_tag = up_pc(p.xLen - 1, idx_w + 3)
        val up_slot = up_pc(2)
        val up_taken = io.bpu_update.bits.taken
        val up_br_type = io.bpu_update.bits.br_type

        val up_is_cond_br = isCondBranch(up_br_type) 
        val up_is_jump = isJump(up_br_type)

        when(up_taken || up_is_jump)//btb update
        {
            btb_valid(up_idx) := true.B
            btb_tag(up_idx) := up_tag
            btb_target(up_idx) := io.bpu_update.bits.target
            btb_slot(up_idx) := up_slot
            btb_is_branch := up_is_cond_br
        }
        when(up_is_cond_br)//bht update
        {
            val up_bht_idx = up_pc(idx_w + 2, 2)
            val old_cnt = bht(up_bht_idx)

            when(up_taken)
            {
                when(old_cnt =/= 3.U)
                {
                    bht(up_bht_idx) := old_cnt + 1.U
                }.otherwise
                {
                    when(old_cnt =/= 0.U)
                    {
                        bht(up_bht_idx) := old_cnt - 1.U
                    }
                }
            }
        }
    }

    io.pred_target := target_cand
    io.pred_slot := slot_cand
    io.pred_taken := pred_taken

}
