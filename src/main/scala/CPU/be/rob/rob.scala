package MyCPU.be

import chisel3._
import chisel3.util._
import chisel3.dontTouch

import MyCPU.common._


class RobIO(implicit p:CoreParams)
extends Bundle
{
    //alloc
    val enq = Flipped(Decoupled(Vec(p.decodeWidth, new MicroOp)))

    val rob_idx_alloc = Output(Vec(p.decodeWidth, UInt(p.robBits.W)))

    //write back
    val cdb = Flipped(Vec(2, Valid(new CDBIO)))
    //commit
    val commit_free = Output(Vec(p.decodeWidth, Valid(UInt(p.pRegBits.W))))
    //flush
    val flush_pipeline = Output(Bool())

    val commit_store = Output(Vec(p.decodeWidth, Valid(UInt(p.robBits.W))))


    //ROB roll back
    val br_res = Flipped(Valid(new BranchResolution))

    val rbk_active = Output(Bool())
    val rbk_valid = Output(Bool())
    val rbk_l_rd = Output(UInt(p.lRegBits.W))
    val rbk_p_rd = Output(UInt(p.pRegBits.W))
    val rbk_stale_p_rd = Output(UInt(p.pRegBits.W))
    
    val rob_head_idx = Output(UInt(p.robBits.W))

    val commit_num = Output(UInt(2.W))

    val debug_commit = Output(Vec(p.decodeWidth, new CommitDebug))

    //test
    val bpu_update = Output(Valid(new BpuUpdate))

    //difftest tv
    //val commit_valid = Output(Bool())
    //val commit_pc = Output(Bool())
    //val commit_inst = Output(Bool())
    //val commit_l_rp
    //val commit_rd_wen
    //val commit_result = Output(UInt())
    
}

//class RobEntry(implicit p: CoreParams)
//extends Bundle
//{
//    val busy = Bool()   //entry valid
//    val complete = Bool()   //unit complete
//    val exception = Bool() //exception
//    val uop = new MicroOp //microOp
//
//}

class Rob(implicit p: CoreParams) extends Module
with MyCPU.common.constants.ScalaOpConsts
with MyCPU.common.constants.RISCVConsts {
    val io = IO(new RobIO)

    val rob_busy     = RegInit(VecInit(Seq.fill(p.numRobEntries)(false.B)))
    val rob_complete = RegInit(VecInit(Seq.fill(p.numRobEntries)(false.B)))
    val rob_exc      = RegInit(VecInit(Seq.fill(p.numRobEntries)(false.B)))

    val rob_rf_wen     = RegInit(VecInit(Seq.fill(p.numRobEntries)(false.B)))
    val rob_is_store   = RegInit(VecInit(Seq.fill(p.numRobEntries)(false.B)))
    val rob_stale_p_rd = RegInit(VecInit(Seq.fill(p.numRobEntries)(0.U(p.pRegBits.W))))
    
    val rob_l_rd = RegInit(VecInit(Seq.fill(p.numRobEntries)(0.U(p.lRegBits.W))))
    val rob_p_rd = RegInit(VecInit(Seq.fill(p.numRobEntries)(0.U(p.pRegBits.W))))

    val ptrWidth = p.robBits + 1

    val head = RegInit(0.U(ptrWidth.W))
    val tail = RegInit(0.U(ptrWidth.W))

    val head_idx = head(ptrWidth - 2, 0)
    val tail_idx = tail(ptrWidth - 2, 0)

    val rob_is_branch = RegInit(VecInit(Seq.fill(p.numRobEntries)(false.B)))
    val rob_br_taken  = Reg(Vec(p.numRobEntries, Bool()))
    val rob_br_target = Reg(Vec(p.numRobEntries, UInt(p.xLen.W)))
    val rob_br_pc     = Reg(Vec(p.numRobEntries, UInt(p.xLen.W)))

    def wrapInc(ptr: UInt, offset: UInt): UInt = {
        val sum = ptr + offset
        val width = log2Ceil(p.numRobEntries)
        sum(width - 1 , 0)
    }

    // =========================================================
    // ROB 回滚状态机 (s_walk)
    // =========================================================
    val s_normal :: s_walk :: Nil = Enum(2)
    val state = RegInit(s_normal)

    val walk_ptr = Reg(UInt(ptrWidth.W))
    val target_ptr = Reg(UInt(ptrWidth.W))

    def restore_phase(idx: UInt, current_head: UInt): UInt = {
        val h_phase = current_head(ptrWidth - 1)
        val h_idx = current_head(ptrWidth - 2, 0)
        val phase = Mux(idx >= h_idx, h_phase, ~h_phase)
        Cat(phase, idx)
    }

    val incoming_ptr = restore_phase(io.br_res.bits.rob_idx, head)
    val incoming_age = incoming_ptr - head
    val target_age = target_ptr - head
    val is_older = incoming_age < target_age

    val is_walking = (state === s_walk)
    val walk_idx = walk_ptr(ptrWidth - 2, 0)

    when(io.br_res.valid && io.br_res.bits.mispredicted) {
        when(state === s_normal || is_older) {
            state := s_walk
            target_ptr := incoming_ptr
            walk_ptr := tail - 1.U
        }
    }

    io.rbk_active := is_walking
    io.rbk_valid := is_walking && rob_rf_wen(walk_idx) && (walk_ptr =/= target_ptr)
    io.rbk_l_rd := rob_l_rd(walk_idx)
    io.rbk_p_rd := rob_p_rd(walk_idx)
    io.rbk_stale_p_rd := rob_stale_p_rd(walk_idx)

    when(is_walking) {
        when(walk_ptr === target_ptr) {
            state := s_normal
            tail := target_ptr + 1.U
        }.otherwise{
            walk_ptr := walk_ptr - 1.U
        }
    }

    // =========================================================
    // 提前计算 Commit 数量，打通读写竞争的壁垒！
    // =========================================================
    val head_0 = head_idx
    val head_1 = wrapInc(head_idx, 1.U)

    val u0_busy     = rob_busy(head_0)
    val u0_complete = rob_complete(head_0)
    val u0_exc      = rob_exc(head_0)

    val u1_busy     = rob_busy(head_1)
    val u1_complete = rob_complete(head_1)
    val u1_exc      = rob_exc(head_1)

    val can_commit_0 = u0_busy && u0_complete 
    val can_commit_1 = can_commit_0 && !u0_exc && u1_busy && u1_complete

    val commit_count = WireInit(0.U(2.W))
    val is_flush = WireInit(false.B)

    when(is_walking) {
        commit_count := 0.U
    }.elsewhen(can_commit_0 && u0_exc) {
        commit_count := 0.U
        is_flush := true.B
    }.elsewhen(can_commit_1 && u1_exc) {
        commit_count := 0.U
        is_flush := true.B
    }.elsewhen(can_commit_1) {
        commit_count := 2.U
    }.elsewhen(can_commit_0) {
        commit_count := 1.U
    }

    io.flush_pipeline := is_flush

    // =========================================================
    // 同周期信用前推 (Early-Credit Forwarding) 的空间计算
    // =========================================================
    val count = tail - head
    
    // 【核心修复】：扣除本拍即将 Commit 腾出的空间
    val effective_count = count - commit_count 

    val is_full = (effective_count === p.numRobEntries.U)
    val is_empty = (effective_count === 0.U)
    // 根据扣减后的真实空间判断是否能进 2 条指令
    val has_space = effective_count <= (p.numRobEntries.U - 2.U)
    
    io.enq.ready := has_space && !is_walking
    val do_alloc = io.enq.valid && io.enq.ready
    val alloc_count = Mux(do_alloc, 2.U, 0.U)

    val tail_0 = tail_idx
    val tail_1 = wrapInc(tail_idx, 1.U)
    io.rob_idx_alloc(0) := tail_0
    io.rob_idx_alloc(1) := tail_1

    // 更新指针
    head := head + commit_count
    when(!is_walking) {
        tail := tail + alloc_count
    }

    // =========================================================
    // ROB 阵列更新
    // =========================================================
    val debug_rob_inst = RegInit(VecInit(Seq.fill(p.numRobEntries)(0.U(32.W))))
    val rob_pc         = RegInit(VecInit(Seq.fill(p.numRobEntries)(0.U(p.xLen.W))))
    val rob_result     = RegInit(VecInit(Seq.fill(p.numRobEntries)(0.U(p.xLen.W))))
    val rob_inst_valid = RegInit(VecInit(Seq.fill(p.numRobEntries)(false.B)))

    for(i <- 0 until p.numRobEntries){
        val i_u = i.U

        val is_alloced_0 = do_alloc && (tail_0 === i_u)
        val is_alloced_1 = do_alloc && (tail_1 === i_u)
        val is_alloc = is_alloced_0 || is_alloced_1

        val alloc_uop = Mux(is_alloced_0, io.enq.bits(0), io.enq.bits(1))

        val is_commited_0 = (commit_count >= 1.U) && (head_0 === i_u)
        val is_commited_1 = (commit_count === 2.U) && (head_1 === i_u)
        val is_this_commit = is_commited_0 || is_commited_1

        val is_rbk_clear = is_walking && (walk_ptr =/= target_ptr) && (i_u === walk_idx)

        val is_wb_0 = io.cdb(0).valid && (io.cdb(0).bits.rob_idx === i_u)
        val is_wb_1 = io.cdb(1).valid && (io.cdb(1).bits.rob_idx === i_u)
        val is_wb   = is_wb_0 || is_wb_1
        val wb_exc  = (is_wb_0 && io.cdb(0).bits.exc) || (is_wb_1 && io.cdb(1).bits.exc)
        //test
        val wb_cdb = Mux(is_wb_0, io.cdb(0).bits, io.cdb(1).bits)
        val wb_is_branch = wb_cdb.is_branch
        val wb_br_taken  = wb_cdb.br_taken
        val wb_br_target = wb_cdb.br_target
        val wb_br_pc     = wb_cdb.br_pc

        rob_busy(i) := Mux(is_alloc, true.B,
                                Mux(is_this_commit || is_rbk_clear, false.B, rob_busy(i)))

        val init_complete = !alloc_uop.valid
        rob_complete(i) := Mux(is_alloc, init_complete,
                                Mux(is_wb, true.B, rob_complete(i)))
        rob_exc(i) := Mux(is_alloc, alloc_uop.exception,
                                Mux(is_wb, rob_exc(i) || wb_exc, rob_exc(i)))
        rob_rf_wen(i) := Mux(is_alloc, alloc_uop.rf_wen && alloc_uop.valid, rob_rf_wen(i))
        rob_is_store(i) := Mux(is_alloc, alloc_uop.mem_cmd === MC_W.U && alloc_uop.valid, rob_is_store(i))
        rob_stale_p_rd(i) := Mux(is_alloc, alloc_uop.stale_p_rd, rob_stale_p_rd(i))

        rob_l_rd(i) := Mux(is_alloc, alloc_uop.l_rd, rob_l_rd(i))
        rob_p_rd(i) := Mux(is_alloc, alloc_uop.p_rd, rob_p_rd(i))

        debug_rob_inst(i) := Mux(is_alloc, alloc_uop.inst, debug_rob_inst(i))
        rob_pc(i)         := Mux(is_alloc, alloc_uop.pc, rob_pc(i))
        // 专门给 Difftest 增加空泡判断
        rob_inst_valid(i) := Mux(is_alloc, alloc_uop.valid, rob_inst_valid(i))

        val wb_data = Mux(is_wb_0, io.cdb(0).bits.data, io.cdb(1).bits.data)
        rob_result(i) := Mux(is_wb, wb_data, rob_result(i))
        //test
        rob_is_branch(i) := Mux(is_alloc, false.B,
                     Mux(is_wb && wb_is_branch, true.B, rob_is_branch(i)))
        rob_br_taken(i)  := Mux(is_wb && wb_is_branch, wb_br_taken, rob_br_taken(i))
        rob_br_target(i) := Mux(is_wb && wb_is_branch, wb_br_target, rob_br_target(i))
        rob_br_pc(i)     := Mux(is_wb && wb_is_branch, wb_br_pc, rob_br_pc(i))
    /*
        when (is_this_commit){
            printf(p"[ROB-commit] slot=$i busy=${rob_busy(i)} complete=${rob_complete(i)} pc=0x${Hexadecimal(rob_pc(i))} inst=0x${Hexadecimal(debug_rob_inst(i))}\n")
        }
        */
    }
    dontTouch(debug_rob_inst)

    // =========================================================
    // 输出引脚组装
    // =========================================================
    val cmt0_fire = commit_count >= 1.U
    io.commit_free(0).valid := cmt0_fire && rob_rf_wen(head_0) && (rob_stale_p_rd(head_0) =/= 0.U)
    io.commit_free(0).bits  := rob_stale_p_rd(head_0)
    
    // Store Commit 通知 LSU
    io.commit_store(0).valid := cmt0_fire && rob_is_store(head_0)
    io.commit_store(0).bits  := head_0

    val cmt1_fire = commit_count === 2.U
    io.commit_free(1).valid := cmt1_fire && rob_rf_wen(head_1) && (rob_stale_p_rd(head_1) =/= 0.U)
    io.commit_free(1).bits  := rob_stale_p_rd(head_1)
    
    io.commit_store(1).valid := cmt1_fire && rob_is_store(head_1)
    io.commit_store(1).bits  := head_1

    io.rob_head_idx := head_idx
    io.commit_num   := commit_count

    io.bpu_update.valid := cmt0_fire && rob_is_branch(head_0)
    io.bpu_update.bits.taken  := rob_br_taken(head_0)
    io.bpu_update.bits.target := rob_br_target(head_0)
    io.bpu_update.bits.pc     := rob_br_pc(head_0)

    // Difftest 调试总线输出
    io.debug_commit(0).valid  := cmt0_fire && rob_inst_valid(head_0)
    io.debug_commit(0).pc     := rob_pc(head_0)
    io.debug_commit(0).inst   := debug_rob_inst(head_0)
    io.debug_commit(0).l_rd   := rob_l_rd(head_0)
    io.debug_commit(0).p_rd   := rob_p_rd(head_0)
    io.debug_commit(0).rf_wen := rob_rf_wen(head_0)

    io.debug_commit(1).valid  := cmt1_fire && rob_inst_valid(head_1)
    io.debug_commit(1).pc     := rob_pc(head_1)
    io.debug_commit(1).inst   := debug_rob_inst(head_1)
    io.debug_commit(1).l_rd   := rob_l_rd(head_1)
    io.debug_commit(1).p_rd   := rob_p_rd(head_1)
    io.debug_commit(1).rf_wen := rob_rf_wen(head_1)
}