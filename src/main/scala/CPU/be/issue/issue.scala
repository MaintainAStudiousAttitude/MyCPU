package MyCPU.be

import chisel3._
import chisel3.util._

import MyCPU.common._

class IssueQueueIO(implicit p: CoreParams)
extends Bundle
with MyCPU.common.constants.ScalaOpConsts
{
    val enq = Flipped(Decoupled(Vec(p.decodeWidth ,new MicroOp)))

    val iss_alu = Decoupled(new MicroOp)

    val iss_lsu = Decoupled(new MicroOp)

    val cdb = Flipped(Vec(2, Valid(new CDBIO)))

    val flush = Input(Bool())

    val flush_mispredict = Input(Bool())
    val mispredict_rob_idx = Input(UInt(p.robBits.W))
    val rob_head_idx = Input(UInt(p.robBits.W))

}

class IssueQueue(implicit p: CoreParams)
extends Module
with MyCPU.common.constants.ScalaOpConsts
with MyCPU.common.constants.RISCVConsts
{
    val io = IO(new IssueQueueIO)

    val slot_valid = RegInit(VecInit(Seq.fill(p.numIssueEntries)(false.B)))
    val slot_uop = Reg(Vec(p.numIssueEntries, new MicroOp))

    val slot_rs1_ready = Reg(Vec(p.numIssueEntries, Bool()))
    val slot_rs2_ready = Reg(Vec(p.numIssueEntries, Bool()))

    val next_rs1_ready = Wire(Vec(p.numIssueEntries, Bool()))
    val next_rs2_ready = Wire(Vec(p.numIssueEntries, Bool()))

    val slot_ready = Wire(Vec(p.numIssueEntries, Bool()))

    def is_Younger(now_idx : UInt, target_idx : UInt, head : UInt) : Bool = 
    {
        val now_age = now_idx - head
        val target_age = target_idx - head
        now_age > target_age
    }


    for(i <- 0 until p.numIssueEntries){
        val uop = slot_uop(i)

        val match_rs1_cdb0 = io.cdb(0).valid && (io.cdb(0).bits.p_rd === uop.p_rs1) && (uop.p_rs1 =/= 0.U)
        val match_rs1_cdb1 = io.cdb(1).valid && (io.cdb(1).bits.p_rd === uop.p_rs1) && (uop.p_rs1 =/= 0.U)
        val wakeup_rs1 = match_rs1_cdb0 || match_rs1_cdb1
    
        val match_rs2_cdb0 = io.cdb(0).valid && (io.cdb(0).bits.p_rd === uop.p_rs2) && (uop.p_rs2 =/= 0.U)
        val match_rs2_cdb1 = io.cdb(1).valid && (io.cdb(1).bits.p_rd === uop.p_rs2) && (uop.p_rs2 =/= 0.U)
        val wakeup_rs2 = match_rs2_cdb0 || match_rs2_cdb1

        next_rs1_ready(i) := slot_rs1_ready(i) || wakeup_rs1
        next_rs2_ready(i) := slot_rs2_ready(i) || wakeup_rs2   

        //bye bye every ghost "shaking hand"
        val is_ghost_inct = io.flush_mispredict && is_Younger(uop.rob_idx, io.mispredict_rob_idx, io.rob_head_idx)
        val real_valid = slot_valid(i) && !is_ghost_inct
        slot_ready(i) := real_valid && next_rs1_ready(i) && next_rs2_ready(i)
    }


    val alu_reqs = Wire(Vec(p.numIssueEntries, Bool()))
    val lsu_reqs = Wire(Vec(p.numIssueEntries, Bool()))

    // 2. 遍历每一个槽位，明确指定连线关系
    for (i <- 0 until p.numIssueEntries) {
      val u = slot_uop(i)
      val r = slot_ready(i)
      
      // 注意这里：ALU 端口可以处理 ALU 和 BRU 指令
      val is_alu_type = (u.fu_code === FC_ALU.U(FC_SZ.W)) || (u.fu_code === FC_BRU.U(FC_SZ.W))
      // LSU 端口只处理 MEM 指令
      val is_lsu_type = (u.fu_code === FC_MEM.U(FC_SZ.W))

      alu_reqs(i) := r && is_alu_type
      lsu_reqs(i) := r && is_lsu_type
    }

    //PE find the first one .orR make sure is truly have one
    //maybe need change 
    val sel_alu_idx = PriorityEncoder(alu_reqs)
    val sel_lsu_idx = PriorityEncoder(lsu_reqs)

    val can_iss_alu = alu_reqs.asUInt.orR
    val can_iss_lsu = lsu_reqs.asUInt.orR


    val free_slot = slot_valid.map(!_)
    val alloc_idx_0 = PriorityEncoder(free_slot)
    val free_slots_marks1 = Wire(Vec(p.numIssueEntries, Bool()))
    for (i <- 0 until p.numIssueEntries){
      free_slots_marks1(i) := free_slot(i) && (i.U =/= alloc_idx_0)
    }
    val alloc_idx_1 = PriorityEncoder(free_slots_marks1)

    val has_1_free = free_slot.reduce(_ || _)
    val has_2_free = free_slots_marks1.reduce(_ || _)

    val uop0_valid = io.enq.bits(0).valid
    val uop1_valid = io.enq.bits(1).valid
    val need_2 = uop0_valid && uop1_valid
    val need_1 = uop0_valid ^ uop1_valid


    val has_space = Mux(need_2, has_2_free, Mux(need_1, has_1_free, true.B))
    io.enq.ready := has_space && !io.flush_mispredict
    val do_alloc = io.enq.fire && !io.flush_mispredict

    val do_iss_alu = io.iss_alu.ready && can_iss_alu
    val do_iss_lsu = io.iss_lsu.ready && can_iss_lsu

    val debug_iss_inst = RegInit(VecInit(Seq.fill(p.numIssueEntries)(0.U(32.W))))
    //compress route
    val slot0_uop = Mux(uop0_valid, io.enq.bits(0), io.enq.bits(1))
    val slot0_en = uop0_valid || uop1_valid
    val slot1_uop = io.enq.bits(1)
    val slot1_en = need_2


    for (i <- 0 until p.numIssueEntries){
      val i_u = i.U

      val is_alloc_0 = do_alloc && slot0_en && (alloc_idx_0 === i_u)
      val is_alloc_1 = do_alloc && slot1_en && (alloc_idx_1 === i_u)
      val is_this_alloc = is_alloc_0 || is_alloc_1

      val alloc_uop = Mux(is_alloc_0, slot0_uop, slot1_uop)

      val is_this_iss_alu = do_iss_alu && (sel_alu_idx === i_u)
      val is_this_iss_lsu = do_iss_lsu && (sel_lsu_idx === i_u)
      val is_this_issued = is_this_iss_alu || is_this_iss_lsu

      val is_ghost = io.flush_mispredict && is_Younger(slot_uop(i).rob_idx, io.mispredict_rob_idx, io.rob_head_idx)


      val alloc_valid_val = Mux(is_alloc_0 && (alloc_idx_0 === i.U), uop0_valid,
                                                                      Mux(is_alloc_1 && (Mux(uop0_valid, alloc_idx_1, alloc_idx_0) === i.U), uop1_valid, false.B))
      //change alloc_valid_val to true.B
      slot_valid(i) := Mux(io.flush || is_ghost, false.B,
                                    Mux(is_this_issued, false.B, 
                                                        Mux(is_this_alloc, true.B, 
                                                                          slot_valid(i))))
      slot_uop(i) := Mux(is_this_alloc, alloc_uop, slot_uop(i))

      val init_rs1_ready = !alloc_uop.use_rs1 || alloc_uop.prs1_ready
      val init_rs2_ready = !alloc_uop.use_rs2 || alloc_uop.prs2_ready

      slot_rs1_ready(i) := Mux(is_this_alloc, init_rs1_ready,
                                            Mux(!is_this_issued, next_rs1_ready(i),
                                                                slot_rs1_ready(i)))
      slot_rs2_ready(i) := Mux(is_this_alloc, init_rs2_ready,
                                            Mux(!is_this_issued, next_rs2_ready(i),
                                                                slot_rs2_ready(i)))

      debug_iss_inst(i) := Mux(is_this_alloc, alloc_uop.inst, debug_iss_inst(i))
      when (slot_valid(i)) {
            printf(p"iss[$i] contains inst: 0x${Hexadecimal(debug_iss_inst(i))}\n")
        }

    }
    io.iss_alu.valid := can_iss_alu
    io.iss_alu.bits  := slot_uop(sel_alu_idx)

    io.iss_lsu.valid := can_iss_lsu
    io.iss_lsu.bits  := slot_uop(sel_lsu_idx)

    when(io.iss_lsu.valid) {
    printf("[ISSUE-LSU] Issuing to LSU! fu_code: %d, rob_idx: %d\n", io.iss_lsu.bits.fu_code, io.iss_lsu.bits.rob_idx)
    }
}       