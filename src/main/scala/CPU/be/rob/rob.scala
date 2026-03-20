package MyCPU.be

import chisel3._
import chisel3.util._

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

    val commit_store = Vec(p.decodeWidth, Output(Bool()))

}

class RobEntry(implicit p: CoreParams)
extends Bundle
{
    val busy = Bool()   //entry valid
    val complete = Bool()   //unit complete
    val exception = Bool() //exception
    val uop = new MicroOp //microOp

}

class Rob(implicit p: CoreParams)
extends Module
with MyCPU.common.constants.ScalaOpConsts
with MyCPU.common.constants.RISCVConsts
{
    val io = IO(new RobIO)

    val rob_busy     = RegInit(VecInit(Seq.fill(p.numRobEntries)(false.B)))
    val rob_complete = RegInit(VecInit(Seq.fill(p.numRobEntries)(false.B)))
    val rob_exc      = RegInit(VecInit(Seq.fill(p.numRobEntries)(false.B)))

    val rob_rf_wen     = RegInit(VecInit(Seq.fill(p.numRobEntries)(false.B)))
    val rob_is_store   = RegInit(VecInit(Seq.fill(p.numRobEntries)(false.B)))
    val rob_stale_p_rd = RegInit(VecInit(Seq.fill(p.numRobEntries)(0.U(p.pRegBits.W))))
    
    val rob_mem_cmd    = Reg(Vec(p.numRobEntries, UInt(MC_SZ.W)))

    val head = RegInit(0.U(p.robBits.W))
    val tail = RegInit(0.U(p.robBits.W))
    val count = RegInit(0.U(p.robBits.W))
    /*
    def wrapInc(ptr: UInt): UInt = {
        val sum = ptr + offset
        Mux(sum >= p.numRobEntries.U, sum - p.numRobEntries, sum)
    }*/
    def wrapInc(ptr: UInt, offset: UInt): UInt = {
        val sum = ptr + offset
        val width = log2Ceil(p.numRobEntries)
        sum(width - 1 , 0)
    }
    val has_space = count <= (p.numRobEntries.U - 2.U)
    io.enq.ready := has_space

    val do_alloc = io.enq.valid && has_space
    //ganged mode 2/0 there still have one mode called parties mode 
    val alloc_count = Mux(do_alloc, 2.U, 0.U)

    val tail_0 = tail
    val tail_1 = wrapInc(tail, 1.U)
    io.rob_idx_alloc(0) := tail_0
    io.rob_idx_alloc(1) := tail_1

    val head_0 = head
    val head_1 = wrapInc(head, 1.U)

    val u0_busy = rob_busy(head_0)
    val u0_complete = rob_complete(head_0)
    val u0_exc = rob_exc(head_0)

    val u1_busy = rob_busy(head_1)
    val u1_complete = rob_complete(head_1)
    val u1_exc = rob_exc(head_1)

    val can_commit_0 = u0_busy && u0_complete 
    val can_commit_1 = can_commit_0 && !u0_exc && u1_busy && u1_complete

    val commit_count = WireInit(0.U(2.W))
    val is_flush = WireInit(false.B)

    when(can_commit_0 && u0_exc)
    {
        commit_count := 0.U
        is_flush := true.B
    }.elsewhen(can_commit_1 && u1_exc)
    {
        commit_count := 0.U
        is_flush := true.B
    }.elsewhen(can_commit_1)
    {
        commit_count := 2.U
    }.elsewhen(can_commit_0)
    {
        commit_count := 1.U
    }

    io.flush_pipeline := is_flush

    head  := wrapInc(head, commit_count)
    tail  := wrapInc(tail, alloc_count)
    count := count + alloc_count - commit_count

    for(i <- 0 until p.numRobEntries){
        val i_u = i.U

        val is_alloc_0 = do_alloc && (tail_0 === i_u)
        val is_alloc_1 = do_alloc && (tail_1 === i_u)
        val is_alloc = is_alloc_0 || is_alloc_1

        val alloc_uop = Mux(is_alloc_0, io.enq.bits(0), io.enq.bits(1))

        val is_commit_0 = (commit_count >= 1.U) && (head_0 === i_u)
        val is_commit_1 = (commit_count === 2.U) && (head_1 === i_u)
        val is_commit = is_commit_0 || is_commit_1

        val is_wb_0 = io.cdb(0).valid && (io.cdb(0).bits.rob_idx === i_u)
        val is_wb_1 = io.cdb(1).valid && (io.cdb(1).bits.rob_idx === i_u)
        val is_wb   = is_wb_0 || is_wb_1
        val wb_exc  = (is_wb_0 && io.cdb(0).bits.exc) || (is_wb_1 && io.cdb(1).bits.exc)

        rob_busy(i) := Mux(is_alloc, true.B,
                                    Mux(is_commit, false.B, rob_busy(i)))

        //care about this
        val init_complete = !alloc_uop.valid
        rob_complete(i) := Mux(is_alloc, init_complete, 
                                        Mux(is_commit, true.B, rob_complete(i)))
        rob_exc(i) := Mux(is_alloc, alloc_uop.exception, 
                                    Mux(is_wb, rob_exc(i) || wb_exc, rob_exc(i)))
        rob_rf_wen(i) := Mux(is_alloc, alloc_uop.rf_wen && alloc_uop.valid, rob_rf_wen(i))
        rob_is_store(i) := Mux(is_alloc, alloc_uop.mem_cmd === MC_W.U && alloc_uop.valid, rob_is_store(i))
        rob_stale_p_rd := Mux(is_alloc, alloc_uop.stale_p_rd, rob_stale_p_rd(i))
    }

    val cmt0_fire = commit_count >= 1.U
    io.commit_free(0).valid := cmt0_fire && rob_rf_wen(head_0) && (rob_stale_p_rd(head_0) =/= 0.U)
    io.commit_free(0).bits := rob_stale_p_rd(head_0)
    io.commit_store(0) := cmt0_fire && rob_is_store(head_0)

    val cmt1_fire = commit_count === 2.U
    io.commit_free(1).valid := cmt1_fire && rob_rf_wen(head_1) && (rob_stale_p_rd(head_1) =/= 0.U)
    io.commit_free(1).bits := rob_stale_p_rd(head_1)
    io.commit_store(1) := cmt1_fire && rob_is_store(head_1)

    /*
    val maybe_full = RegInit(false.B)
    val ptr_match = head === tail
    val is_empty = ptr_match && !maybe_full
    val is_full = ptr_match && maybe_full
 
    def wrapInc(ptr: UInt): UInt = Mux(ptr === (p.numRobEntries - 1).U, 0.U, ptr + 1.U)

    io.enq.ready := !is_full
    io.rob_idx_alloc := tail
    val do_alloc = io.enq.fire
    
    val head_busy = rob_busy(head)
    val head_complete = rob_complete(head)
    val head_exc = rob_exc(head)

    val can_commit = !is_empty && head_busy && head_complete
    val has_exception = can_commit && head_exc
    val do_commit   = can_commit && !has_exception

    val next_tail = Mux(do_alloc, wrapInc(tail), tail)
    val next_head = Mux(do_commit, wrapInc(head), head)
    val next_maybe_full = Mux(do_alloc =/= do_commit, do_alloc, maybe_full)

    tail := next_tail
    head := next_head
    maybe_full := next_maybe_full

    for(i <- 0 until p.numRobEntries){
        //have some questions
        val is_this_alloc  = do_alloc && (tail === i.U)
        val is_this_commit = do_commit && (head === i.U)

        val is_this_wb0 = io.cdb(0).valid && (io.cdb(0).bits.rob_idx === i.U)
        val is_this_wb1 = io.cdb(1).valid && (io.cdb(1).bits.rob_idx === i.U)
        val is_this_wb  = is_this_wb0 || is_this_wb1

        val wb_exc = (is_this_wb0 && io.cdb(0).bits.exc) || (is_this_wb1 && io.cdb(1).bits.exc)

        rob_busy(i) := Mux(is_this_alloc, true.B,
                            Mux(is_this_commit, false.B,
                                rob_busy(i)))

        rob_complete(i) := Mux(is_this_alloc, false.B,
                       Mux(is_this_wb, true.B,
                       rob_complete(i)))

        rob_exc(i) := Mux(is_this_alloc, io.enq.bits.exception,
                        Mux(is_this_wb, rob_exc(i) || wb_exc,
                            rob_exc(i)))
        rob_rf_wen(i)     := Mux(is_this_alloc, io.enq.bits.rf_wen, rob_rf_wen(i))
        rob_stale_p_rd(i) := Mux(is_this_alloc, io.enq.bits.stale_p_rd, rob_stale_p_rd(i))

        rob_mem_cmd(i) := Mux(is_this_alloc, io.enq.bits.mem_cmd, rob_mem_cmd(i))
    }

    io.flush_pipeline := has_exception

    val will_free_preg = do_commit && rob_rf_wen(head) && (rob_stale_p_rd(head) =/= 0.U)
  
    io.commit_free.valid := will_free_preg
    io.commit_free.bits  := Mux(will_free_preg, rob_stale_p_rd(head), 0.U)


    val is_committing_store = do_commit && (rob_mem_cmd(head) === MC_W.U)

    io.commit_store := is_committing_store
    */
}   