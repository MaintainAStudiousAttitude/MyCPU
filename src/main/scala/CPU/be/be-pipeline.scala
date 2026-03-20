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
  rename.io.enq.bits  := decode.io.deq.bits // 单发射拆包

  // --------------------------------------------------------
  // C.[新增: 分支停顿] Dispatch (Rename -> Issue & ROB)
  // --------------------------------------------------------
  val branch_in_flight = RegInit(false.B)

  // 提取即将进入后端的微指令
  val rename_uop = rename.io.deq.bits
  val is_branch_inst = rename_uop.is_br || rename_uop.is_jal || rename_uop.is_jalr

  // 握手逻辑：只有 ROB、IssueQueue 都有空位，且【没有未决的分支指令】时，才允许分发！
  val dispatch_ready = rob.io.enq.ready && issue.io.enq.ready && !branch_in_flight
  
  rename.io.deq.ready := dispatch_ready
  val dispatch_fire = rename.io.deq.valid && dispatch_ready

  // 连入 ROB
  rob.io.enq.valid := dispatch_fire
  rob.io.enq.bits  := rename.io.deq.bits

  // 连入 Issue Queue
  issue.io.enq.valid := dispatch_fire
  issue.io.enq.bits  := rename.io.deq.bits
  issue.io.enq.bits.rob_idx := rob.io.rob_idx_alloc // 拼装 ROB ID

  // 状态机更新：控制闸门起落
  when (rob.io.flush_pipeline) {
    branch_in_flight := false.B // 遇到全局异常冲刷，解除锁定
  } .elsewhen (alu.io.br_resolved) {
    branch_in_flight := false.B // ALU 算完分支了，解除锁定！
  } .elsewhen (dispatch_fire && is_branch_inst) {
    branch_in_flight := true.B  // 分支指令进入了后端，拉下闸门！
  }

  // --------------------------------------------------------
  // D. Issue -> RegRead -> PRF
  // --------------------------------------------------------
  regread.io.iss_alu <> issue.io.iss_alu
  regread.io.iss_lsu <> issue.io.iss_lsu 

  // PRF 读端口连线 (ALU 2R, LSU 2R)
  prf.io.alu_req_rs1 := regread.io.prf_alu_req_rs1
  prf.io.alu_req_rs2 := regread.io.prf_alu_req_rs2
  regread.io.prf_alu_resp_rs1 := prf.io.alu_resp_rs1
  regread.io.prf_alu_resp_rs2 := prf.io.alu_resp_rs2
  
  prf.io.lsu_req_rs1 := regread.io.prf_lsu_req_rs1
  prf.io.lsu_req_rs2 := regread.io.prf_lsu_req_rs2
  regread.io.prf_lsu_resp_rs1 := prf.io.lsu_resp_rs1
  regread.io.prf_lsu_resp_rs2 := prf.io.lsu_resp_rs2

  // --------------------------------------------------------
  // E. Execute (RegRead -> ALU & LSU)
  // --------------------------------------------------------
  alu.io.req <> regread.io.exe_alu
  lsu.io.req <> regread.io.exe_lsu

  // --------------------------------------------------------
  // F. 外部内存接口 (LSU -> D-Cache/MockRAM)
  // --------------------------------------------------------
  io.dmem.req.valid      := lsu.io.dmem.req.valid
  io.dmem.req.bits       := lsu.io.dmem.req.bits
  lsu.io.dmem.req.ready  := io.dmem.req.ready

  lsu.io.dmem.resp.valid := io.dmem.resp.valid
  lsu.io.dmem.resp.bits  := io.dmem.resp.bits

  // --------------------------------------------------------
  // G. Writeback (ALU/LSU -> CDB 广播网)
  // --------------------------------------------------------
  cdb(0) := alu.io.cdb
  cdb(1) := lsu.io.cdb 

  // 广播写回 PRF
  prf.io.wb_alu_valid := cdb(0).valid
  prf.io.wb_alu_pdst  := cdb(0).bits.p_rd
  prf.io.wb_alu_data  := cdb(0).bits.data

  prf.io.wb_lsu_valid := cdb(1).valid
  prf.io.wb_lsu_pdst  := cdb(1).bits.p_rd
  prf.io.wb_lsu_data  := cdb(1).bits.data

  // 扇出到各个监控模块
  issue.io.cdb   := cdb
  regread.io.cdb := cdb
  rob.io.cdb     := cdb
  rename.io.cdb  := cdb  // 你的 Rename 现已支持 Vec(2) 的 CDB 监听

  // --------------------------------------------------------
  // H. Retire & Flush 协同机制
  // --------------------------------------------------------
  // ROB 通知 Rename 释放物理寄存器
  rename.io.commit_free := rob.io.commit_free

  // ROB 通知 LSU 真正写入外部内存 (极度关键)
  lsu.io.commit_store   := rob.io.commit_store 

  // 冲刷逻辑: 因为错误路径的指令被挡在闸门外了，IssueQueue 里现在都是安全的。
  // 所以只有在 ROB 发生真实 Exception (比如非法指令) 时，才做流水线 Flush。
  issue.io.flush := rob.io.flush_pipeline 
  
  // 纠错逻辑: 告诉前端重新取指
  io.redirect_valid := alu.io.br_redirect
  io.redirect_pc    := alu.io.br_redirect_pc
}