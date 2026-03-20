package MyCPU.be

import chisel3._
import chisel3.util._

import MyCPU.common._

class RegReadIO(implicit p: CoreParams)
extends Bundle
{
    val iss_alu = Flipped(Decoupled(new MicroOp))
    val iss_lsu = Flipped(Decoupled(new MicroOp))

    val exe_alu = Decoupled(new FuncUnitReq)
    val exe_lsu = Decoupled(new FuncUnitReq)

    
    val prf_alu_req_rs1  = Output(UInt(p.pRegBits.W))
    val prf_alu_req_rs2  = Output(UInt(p.pRegBits.W))
    val prf_alu_resp_rs1 = Input(UInt(p.xLen.W))
    val prf_alu_resp_rs2 = Input(UInt(p.xLen.W))

    val prf_lsu_req_rs1  = Output(UInt(p.pRegBits.W))
    val prf_lsu_req_rs2  = Output(UInt(p.pRegBits.W))
    val prf_lsu_resp_rs1 = Input(UInt(p.xLen.W))
    val prf_lsu_resp_rs2 = Input(UInt(p.xLen.W))


    val cdb = Flipped(Vec(2, Valid(new CDBIO)))
}

class RegRead(implicit p: CoreParams)
extends Module
with MyCPU.common.constants.ScalaOpConsts
with MyCPU.common.constants.RISCVConsts
{
    val io = IO(new RegReadIO)
    val alu_uop = io.iss_alu.bits
    val lsu_uop = io.iss_lsu.bits

    io.prf_alu_req_rs1 := alu_uop.p_rs1
    io.prf_alu_req_rs2 := alu_uop.p_rs2
    io.prf_lsu_req_rs1 := lsu_uop.p_rs1
    io.prf_lsu_req_rs2 := lsu_uop.p_rs2


    def bypassData(prs: UInt, prf_data: UInt): UInt = {
        val match_cdb0 = io.cdb(0).valid && (io.cdb(0).bits.p_rd === prs) && (prs =/= 0.U)
        val match_cdb1 = io.cdb(1).valid && (io.cdb(1).bits.p_rd === prs) && (prs =/= 0.U)

        Mux(match_cdb0, io.cdb(0).bits.data,
          Mux(match_cdb1, io.cdb(1).bits.data,
            prf_data)) // 如果都没命中，老老实实用 PRF 的数据
    }

    
    val alu_rs1_fwd = bypassData(alu_uop.p_rs1, io.prf_alu_resp_rs1)
    val alu_rs2_fwd = bypassData(alu_uop.p_rs2, io.prf_alu_resp_rs2)
    val lsu_rs1_fwd = bypassData(lsu_uop.p_rs1, io.prf_lsu_resp_rs1)
    val lsu_rs2_fwd = bypassData(lsu_uop.p_rs2, io.prf_lsu_resp_rs2)

    val alu_req = Wire(new FuncUnitReq)
    alu_req.uop := alu_uop
    alu_req.rs1_data := alu_rs1_fwd
    alu_req.rs2_data := alu_rs2_fwd

    val lsu_req = Wire(new FuncUnitReq)
    lsu_req.uop      := lsu_uop
    lsu_req.rs1_data := lsu_rs1_fwd
    lsu_req.rs2_data := lsu_rs2_fwd

    val alu_pipe_reg = Module(new Queue(new FuncUnitReq, entries = 2))
    val lsu_pipe_reg = Module(new Queue(new FuncUnitReq, entries = 2))

    // ALU 通路连接
    alu_pipe_reg.io.enq.valid := io.iss_alu.valid
    alu_pipe_reg.io.enq.bits  := alu_req
    io.iss_alu.ready          := alu_pipe_reg.io.enq.ready
    io.exe_alu               <> alu_pipe_reg.io.deq

    // LSU 通路连接
    lsu_pipe_reg.io.enq.valid := io.iss_lsu.valid
    lsu_pipe_reg.io.enq.bits  := lsu_req
    io.iss_lsu.ready          := lsu_pipe_reg.io.enq.ready
    io.exe_lsu               <> lsu_pipe_reg.io.deq

}