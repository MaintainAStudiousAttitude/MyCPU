package MyCPU.be

import chisel3._
import chisel3.util._

import MyCPU.common._

class BackEndIO(implicit p: CoreParams)
extends Bundle
{
    val from_frontend = Flipped(Decoupled(Vec(p.decodeWidth, new FetchPacket)))

    val redirect_valid = Output(Bool())
    val redirect_pc = Output(UInt(p.xLen.W))
    val commit_num = Output(UInt(2.W))

    val dmem = new SimpleMemIO

    val bpu_update = Output(Valid(new BpuUpdate))

    val debug_commit      = Output(Vec(p.decodeWidth, new CommitDebug))
    val debug_commit_data = Output(Vec(p.decodeWidth, UInt(p.xLen.W)))
}   

class BackEndTOP(implicit p: CoreParams)
extends Module
with MyCPU.common.constants.ScalaOpConsts
with MyCPU.common.constants.RISCVConsts
{
    val io = IO(new BackEndIO)

    val decode = Module(new DecodeUnit)
    val rename = Module(new RenameUnit)
    val rob = Module(new Rob)
    val issue = Module(new IssueQueue)
    val regread = Module(new RegRead)
    val prf = Module(new PRF)
    val alu = Module(new ALU_Unit)
    val lsu =Module(new LSU_Unit)

  val cdb = Wire(Vec(2, Valid(new CDBIO)))
  cdb(0) := DontCare
  cdb(1) := DontCare

  // --------------------------------------------------------
  // B. 级间连线: Frontend -> Decode -> Rename
  // --------------------------------------------------------
  decode.io.enq <> io.from_frontend

  rename.io.enq.valid := decode.io.deq.valid
  decode.io.deq.ready := rename.io.enq.ready
  rename.io.enq.bits := decode.io.deq.bits

  val dispatch_ready = rob.io.enq.ready && issue.io.enq.ready

  rename.io.deq.ready := dispatch_ready
  val dispatch_fire = rename.io.deq.valid && dispatch_ready
  
  rob.io.enq.valid := dispatch_fire
  issue.io.enq.valid := dispatch_fire

  for (w <- 0 until p.decodeWidth){
    rob.io.enq.bits(w) := rename.io.deq.bits(w)

    issue.io.enq.bits(w) := rename.io.deq.bits(w)
    issue.io.enq.bits(w).rob_idx := rob.io.rob_idx_alloc(w)
  }

  regread.io.iss_alu <> issue.io.iss_alu
  regread.io.iss_lsu <> issue.io.iss_lsu 
  
  prf.io.alu_req_rs1 := regread.io.prf_alu_req_rs1
  prf.io.alu_req_rs2 := regread.io.prf_alu_req_rs2
  regread.io.prf_alu_resp_rs1 := prf.io.alu_resp_rs1
  regread.io.prf_alu_resp_rs2 := prf.io.alu_resp_rs2
  
  prf.io.lsu_req_rs1 := regread.io.prf_lsu_req_rs1
  prf.io.lsu_req_rs2 := regread.io.prf_lsu_req_rs2
  regread.io.prf_lsu_resp_rs1 := prf.io.lsu_resp_rs1
  regread.io.prf_lsu_resp_rs2 := prf.io.lsu_resp_rs2
  

  alu.io.req <> regread.io.exe_alu
  lsu.io.req <> regread.io.exe_lsu

  io.dmem.req.valid      := lsu.io.dmem.req.valid
  io.dmem.req.bits       := lsu.io.dmem.req.bits
  lsu.io.dmem.req.ready  := io.dmem.req.ready

  lsu.io.dmem.resp.valid := io.dmem.resp.valid
  lsu.io.dmem.resp.bits  := io.dmem.resp.bits

  cdb(0) := alu.io.cdb
  cdb(1) := lsu.io.cdb 

  prf.io.wb_alu_valid := cdb(0).valid
  prf.io.wb_alu_pdst  := cdb(0).bits.p_rd
  prf.io.wb_alu_data  := cdb(0).bits.data

  prf.io.wb_lsu_valid := cdb(1).valid
  prf.io.wb_lsu_pdst  := cdb(1).bits.p_rd
  prf.io.wb_lsu_data  := cdb(1).bits.data
  
  issue.io.cdb   := cdb
  regread.io.cdb := cdb
  rob.io.cdb     := cdb
  rename.io.cdb  := cdb
  
  rename.io.commit_free := rob.io.commit_free
  //lsu.io.commit_store   := rob.io.commit_store(0) || rob.io.commit_store(1)
  lsu.io.commit_store := rob.io.commit_store

  issue.io.flush := rob.io.flush_pipeline 
  //lsu change age tag queue
  lsu.io.flush_mispredict   := issue.io.flush_mispredict
  lsu.io.mispredict_rob_idx := issue.io.mispredict_rob_idx
  lsu.io.rob_head_idx       := issue.io.rob_head_idx
  lsu.io.flush              := rob.io.flush_pipeline

  io.redirect_valid := alu.io.br_redirect || rob.io.flush_pipeline
  io.redirect_pc    := Mux(alu.io.br_redirect, alu.io.br_redirect_pc, 0.U)

  rob.io.br_res := alu.io.br_res

  rename.io.rbk_active     := rob.io.rbk_active
  rename.io.rbk_valid      := rob.io.rbk_valid
  rename.io.rbk_l_rd       := rob.io.rbk_l_rd
  rename.io.rbk_p_rd       := rob.io.rbk_p_rd
  rename.io.rbk_stale_p_rd := rob.io.rbk_stale_p_rd

  issue.io.flush_mispredict := alu.io.br_res.bits.mispredicted && alu.io.br_res.valid
  issue.io.mispredict_rob_idx := alu.io.br_res.bits.rob_idx
  issue.io.rob_head_idx := rob.io.rob_head_idx

  io.bpu_update := rob.io.bpu_update

  io.commit_num := rob.io.commit_num

  //difftest 
  io.debug_commit := rob.io.debug_commit
  for (w <- 0 until p.decodeWidth) {
        // 把 ROB 要提交的物理寄存器号给 PRF
        prf.io.debug_commit_req_p_rd(w) := rob.io.debug_commit(w).p_rd
        // 把 PRF 吐出来的数据接给外部
        io.debug_commit_data(w) := prf.io.debug_commit_resp_data(w)
  }

}