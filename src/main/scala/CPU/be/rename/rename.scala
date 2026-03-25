package MyCPU.be

import chisel3._
import chisel3.util._

import MyCPU.common._


class RenameIO(implicit p: CoreParams)
extends Bundle
{
    val enq = Flipped(Decoupled(Vec(p.decodeWidth,new MicroOp)))

    val deq = Decoupled(Vec(p.decodeWidth, new MicroOp))

    val commit_free = Flipped(Vec(p.decodeWidth, Valid(UInt(p.pRegBits.W))))

    val cdb = Flipped(Vec(2, Valid(new CDBIO))) 
}

class RenameUnit(implicit p: CoreParams)
extends Module
{
    val io = IO(new RenameIO)

    val rat = RegInit(VecInit(Seq.fill(p.numLRegs)(0.U(p.pRegBits.W))))
    
    //val free_list = Module(new Queue(UInt(p.pRegBits.W), p.numPRegs))

    val busy_table = RegInit(VecInit(Seq.fill(p.numPRegs)(false.B)))

    val is_free = RegInit(VecInit(Seq.tabulate(p.numPRegs)(i => if (i == 0) false.B else true.B)))

    val free_idx_0 = PriorityEncoder(is_free)
    val is_free_mask1 = Wire(Vec(p.numPRegs, Bool()))
    for (i <- 0 until p.numPRegs){
        is_free_mask1(i) := is_free(i) && (i.U =/= free_idx_0)
    }
    val free_idx_1 = PriorityEncoder(is_free_mask1)

    val has_1_free = is_free.asUInt.orR
    val has_2_free = is_free_mask1.asUInt.orR

    val uop0 = io.enq.bits(0)
    val uop1 = io.enq.bits(1)
    val need_alloc_0 = uop0.valid && uop0.rf_wen && (uop0.l_rd =/= 0.U)
    val need_alloc_1 = uop1.rf_wen && (uop1.l_rd =/= 0.U)

    val prd_0 = Mux(need_alloc_0, free_idx_0, 0.U)
    val prd_1 = Mux(need_alloc_1, 
                                Mux(need_alloc_0, free_idx_1, free_idx_0),
                                0.U)
    //number of p reg 
    val need_2 = need_alloc_0 && need_alloc_1
    val need_1 = need_alloc_0 ^ need_alloc_1 
    val can_alloc = Mux(need_2, has_2_free, Mux(need_1, has_1_free, true.B))

    val fire = io.enq.valid && io.deq.ready && can_alloc
    io.enq.ready := io.deq.ready && can_alloc
    io.deq.valid := io.enq.valid && can_alloc

    val prs1_0_raw = rat(uop0.l_rs1)
    val prs2_0_raw = rat(uop0.l_rs2)
    val stale_prd_0_raw = rat(uop0.l_rd)

    val prs1_1_raw = rat(uop1.l_rs1)
    val prs2_1_raw = rat(uop1.l_rs2)
    val stale_prd_1_raw = rat(uop1.l_rd)

    //RAW check
    val dep1_rs1_on_0 = need_alloc_0 && (uop1.l_rs1 === uop0.l_rd) && (uop1.l_rs1 =/= 0.U)
    val dep1_rs2_on_0 = need_alloc_0 && (uop1.l_rs2 === uop0.l_rd) && (uop1.l_rs2 =/= 0.U)
    //WAW check
    val dep1_rd_on_0 = need_alloc_0 && need_alloc_1 && (uop0.l_rd === uop1.l_rd) && (uop1.l_rd =/= 0.U)
    
    //bypass net RAW
    val prs1_1 = Mux(dep1_rs1_on_0, prd_0, prs1_1_raw)
    val prs2_1 = Mux(dep1_rs2_on_0, prd_0, prs2_1_raw)
    // WAW
    val stale_prd_1 = Mux(dep1_rd_on_0, prd_0, stale_prd_1_raw)

    val cdb0_v = io.cdb(0).valid
    val cdb0_p = io.cdb(0).bits.p_rd
    val cdb1_v = io.cdb(1).valid
    val cdb1_p = io.cdb(1).bits.p_rd

    def checkReady(prs: UInt): Bool = {
        !busy_table(prs) || (cdb0_v && cdb0_p === prs) || (cdb1_v && cdb1_p === prs)
    }

    val rdy1_0 = checkReady(prs1_0_raw)
    val rdy2_0 = checkReady(prs2_0_raw)

    val rdy1_1 = Mux(dep1_rs1_on_0, false.B, checkReady(prs1_1_raw))
    val rdy2_1 = Mux(dep1_rs2_on_0, false.B, checkReady(prs2_1_raw))

    when(fire) {
        when(need_alloc_0){
            rat(uop0.l_rd) := prd_0
        }
        when(need_alloc_1){
            rat(uop1.l_rd) := prd_1
        }
    }
    for (i <- 1 until p.numPRegs){
        val i_U = i.U

        val alloc_by_0 = fire && need_alloc_0 && (prd_0 === i.U)
        val alloc_by_1 = fire && need_alloc_1 && (prd_1 === i.U)
        val is_alloc = alloc_by_0 || alloc_by_1

        val free0 = io.commit_free(0)
        val free1 = io.commit_free(1)
        val freed_by_0 = free0.valid && (free0.bits === i.U)
        val freed_by_1 = free1.valid && (free1.bits === i.U)
        val is_freed = freed_by_0 || freed_by_1

        val is_done_cdb0 = cdb0_v && (cdb0_p === i.U)
        val is_done_cdb1 = cdb1_v && (cdb1_p === i.U)
        val is_done = is_done_cdb0 || is_done_cdb1

        is_free(i) := Mux(is_alloc, false.B,
                                    Mux(is_freed, true.B,
                                                is_free(i)))
        busy_table(i) := Mux(is_alloc, true.B,
                                        Mux(is_done, false.B,
                                                    busy_table(i)))

    }

    val out0 = WireInit(uop0)
    out0.p_rs1 := prs1_0_raw
    out0.p_rs2 := prs2_0_raw
    out0.p_rd := prd_0
    out0.stale_p_rd := stale_prd_0_raw
    out0.prs1_ready := Mux(uop0.use_rs1, rdy1_0, true.B)
    out0.prs2_ready := Mux(uop0.use_rs2, rdy2_0, true.B)

    val out1 = WireInit(uop1)
    out1.p_rs1 := prs1_1
    out1.p_rs2 := prs2_1
    out1.p_rd := prd_1
    out1.stale_p_rd := stale_prd_1
    out1.prs1_ready := Mux(uop1.use_rs1, rdy1_1, true.B)
    out1.prs2_ready := Mux(uop1.use_rs2, rdy2_1, true.B)

    io.deq.bits(0) := out0
    io.deq.bits(1) := out1


}

