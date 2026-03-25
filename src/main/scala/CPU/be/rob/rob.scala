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

    val ptrWidth = p.robBits + 1

    val head = RegInit(0.U((ptrWidth).W))
    val tail = RegInit(0.U((ptrWidth).W))


    val head_idx = head(ptrWidth - 2, 0)
    val tail_idx = tail(ptrWidth - 2, 0)

    val count = tail - head
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

    val is_full = (count === p.numRobEntries.U)
    val is_empty = (count === 0.U)
    val has_space = count <= (p.numRobEntries.U - 2.U)
    //val has_space = count <= (p.numRobEntries.U - 2.U)
    io.enq.ready := has_space

    val do_alloc = io.enq.valid && has_space
    //ganged mode 2/0 there still have one mode called parties mode 
    val alloc_count = Mux(do_alloc, 2.U, 0.U)

    val tail_0 = tail_idx
    val tail_1 = wrapInc(tail_idx, 1.U)
    io.rob_idx_alloc(0) := tail_0
    io.rob_idx_alloc(1) := tail_1

    val head_0 = head_idx
    val head_1 = wrapInc(head_idx, 1.U)

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

    head  := head + commit_count
    tail  := tail + alloc_count
    //count := count + alloc_count - commit_count

    //debug
    val debug_rob_inst = RegInit(VecInit(Seq.fill(p.numRobEntries)(0.U(32.W))))

    for(i <- 0 until p.numRobEntries){
        val i_u = i.U

        val is_alloc_0 = do_alloc && (tail_0 === i_u)
        val is_alloc_1 = do_alloc && (tail_1 === i_u)
        val is_alloc = is_alloc_0 || is_alloc_1

        val alloc_uop = Mux(is_alloc_0, io.enq.bits(0), io.enq.bits(1))

        val is_commit_0 = (commit_count >= 1.U) && (head_0 === i_u)
        val is_commit_1 = (commit_count === 2.U) && (head_1 === i_u)
        val is_this_commit = is_commit_0 || is_commit_1

        val is_wb_0 = io.cdb(0).valid && (io.cdb(0).bits.rob_idx === i_u)
        val is_wb_1 = io.cdb(1).valid && (io.cdb(1).bits.rob_idx === i_u)
        val is_wb   = is_wb_0 || is_wb_1
        val wb_exc  = (is_wb_0 && io.cdb(0).bits.exc) || (is_wb_1 && io.cdb(1).bits.exc)

        rob_busy(i) := Mux(is_alloc, true.B,
                                    Mux(is_this_commit, false.B, rob_busy(i)))

        //care about this
        val init_complete = !alloc_uop.valid
        rob_complete(i) := Mux(is_alloc, init_complete, 
                                        Mux(is_wb, true.B, rob_complete(i)))
        rob_exc(i) := Mux(is_alloc, alloc_uop.exception, 
                                    Mux(is_wb, rob_exc(i) || wb_exc, rob_exc(i)))
        rob_rf_wen(i) := Mux(is_alloc, alloc_uop.rf_wen && alloc_uop.valid, rob_rf_wen(i))
        rob_is_store(i) := Mux(is_alloc, alloc_uop.mem_cmd === MC_W.U && alloc_uop.valid, rob_is_store(i))
        rob_stale_p_rd(i) := Mux(is_alloc, alloc_uop.stale_p_rd, rob_stale_p_rd(i))

        debug_rob_inst(i) := Mux(is_alloc, alloc_uop.inst, debug_rob_inst(i))

        when (rob_busy(i)) {
            printf(p"ROB[$i] contains inst: 0x${Hexadecimal(debug_rob_inst(i))}\n")
        }
    }

    val cmt0_fire = commit_count >= 1.U
    io.commit_free(0).valid := cmt0_fire && rob_rf_wen(head_0) && (rob_stale_p_rd(head_0) =/= 0.U)
    io.commit_free(0).bits := rob_stale_p_rd(head_0)
    io.commit_store(0) := cmt0_fire && rob_is_store(head_0)

    val cmt1_fire = commit_count === 2.U
    io.commit_free(1).valid := cmt1_fire && rob_rf_wen(head_1) && (rob_stale_p_rd(head_1) =/= 0.U)
    io.commit_free(1).bits := rob_stale_p_rd(head_1)
    io.commit_store(1) := cmt1_fire && rob_is_store(head_1)

    val h0 = head_0
when(can_commit_0) {
  printf("[ROB-CMT0] Trying to Commit idx %d. is_store: %b, complete: %b\n", h0, rob_is_store(h0), rob_complete(h0))
}

}   