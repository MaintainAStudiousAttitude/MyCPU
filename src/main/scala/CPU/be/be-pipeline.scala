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

    val dmem = new SimpleMemIO
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
  val dec_uop0 = decode.io.deq.bits(0)
  val dec_uop1 = decode.io.deq.bits(1)

  val is_branch_0 = dec_uop0.valid && (dec_uop0.is_br || dec_uop0.is_jal || dec_uop0.is_jalr)

  val safe_uop1 = WireInit(dec_uop1)

  when (is_branch_0) {
    safe_uop1.valid      := false.B // 标记为无效，Issue Queue 会忽略它，ROB 会让它瞬间 Complete
    safe_uop1.rf_wen     := false.B // 极其关键：阻止 Rename 消耗 FreeList 分配物理寄存器！
    safe_uop1.l_rd       := 0.U     // 双重保险：目标寄存器置零
    safe_uop1.l_rs1      := 0.U
    safe_uop1.l_rs2      := 0.U
    safe_uop1.mem_cmd    := 0.U     // 阻止 LSU 误将其当作 Store 塞入 Store Buffer
    safe_uop1.exception  := false.B // 确保它不会触发假异常
  }
  rename.io.enq.bits(0) := dec_uop0
  rename.io.enq.bits(1) := safe_uop1// 单发射拆包

  // --------------------------------------------------------
  // C.[新增: 分支停顿] Dispatch (Rename -> Issue & ROB)
  // --------------------------------------------------------
  val branch_in_flight = RegInit(false.B)

  // 提取即将进入后端的微指令
  val ren_uop0 = rename.io.deq.bits(0)
  val ren_uop1 = rename.io.deq.bits(1)

  val has_branch_0 = ren_uop0.valid && (ren_uop0.is_br || ren_uop0.is_jal || ren_uop0.is_jalr)
  val has_branch_1 = ren_uop1.valid && (ren_uop1.is_br || ren_uop1.is_jal || ren_uop1.is_jalr)
  val has_branch = has_branch_0 || has_branch_1

  val dispatch_ready = rob.io.enq.ready && issue.io.enq.ready && !branch_in_flight

  rename.io.deq.ready := dispatch_ready
  val dispatch_fire = rename.io.deq.valid && dispatch_ready
  
  rob.io.enq.valid := dispatch_fire
  issue.io.enq.valid := dispatch_fire

  for (w <- 0 until p.decodeWidth){
    rob.io.enq.bits(w) := rename.io.deq.bits(w)

    issue.io.enq.bits(w) := rename.io.deq.bits(w)
    issue.io.enq.bits(w).rob_idx := rob.io.rob_idx_alloc(w)
  }

  when (rob.io.flush_pipeline) {
    branch_in_flight := false.B // 遇到全局异常冲刷，解除锁定
  } .elsewhen (alu.io.br_resolved) {
    branch_in_flight := false.B // ALU 算完分支了，解除锁定！
  } .elsewhen (dispatch_fire && has_branch) {
    branch_in_flight := true.B  // 分支指令进入了后端，拉下闸门！
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
  lsu.io.commit_store   := rob.io.commit_store(0) || rob.io.commit_store(1)

  issue.io.flush := rob.io.flush_pipeline 

  io.redirect_valid := alu.io.br_redirect || rob.io.flush_pipeline
  io.redirect_pc    := Mux(alu.io.br_redirect, alu.io.br_redirect_pc, 0.U)

}