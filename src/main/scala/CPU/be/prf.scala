package MyCPU.be

import chisel3._
import chisel3.util._

import MyCPU.common._

class PRFIO(implicit p: CoreParams)
extends Bundle
{
    val alu_req_rs1  = Input(UInt(p.pRegBits.W))
    val alu_req_rs2  = Input(UInt(p.pRegBits.W))
    val alu_resp_rs1 = Output(UInt(p.xLen.W))
    val alu_resp_rs2 = Output(UInt(p.xLen.W))

    // --- 给 LSU 管线用的读端口 (2个) ---
    val lsu_req_rs1  = Input(UInt(p.pRegBits.W))
    val lsu_req_rs2  = Input(UInt(p.pRegBits.W))
    val lsu_resp_rs1 = Output(UInt(p.xLen.W))
    val lsu_resp_rs2 = Output(UInt(p.xLen.W))

    // --- 写回端口 (CDB 传回来的数据写进去) ---
    val wb_alu_valid = Input(Bool())
    val wb_alu_pdst  = Input(UInt(p.pRegBits.W))
    val wb_alu_data  = Input(UInt(p.xLen.W))

    val wb_lsu_valid = Input(Bool())
    val wb_lsu_pdst  = Input(UInt(p.pRegBits.W))
    val wb_lsu_data  = Input(UInt(p.xLen.W))
}

class PRF(implicit p: CoreParams) extends Module {
  val io = IO(new PRFIO)

  // 物理寄存器堆实体 (64 个 64-bit 寄存器)
  // 在 FPGA 上，如果端口太多，这会被综合成分布式 RAM (LUTRAM)
  val regfile = RegInit(VecInit(Seq.fill(p.numPRegs)(0.U(p.xLen.W))))

  // 1. 读逻辑 (组合逻辑直出，注意 p0 永远读出 0)
  io.alu_resp_rs1 := Mux(io.alu_req_rs1 === 0.U, 0.U, regfile(io.alu_req_rs1))
  io.alu_resp_rs2 := Mux(io.alu_req_rs2 === 0.U, 0.U, regfile(io.alu_req_rs2))
  
  io.lsu_resp_rs1 := Mux(io.lsu_req_rs1 === 0.U, 0.U, regfile(io.lsu_req_rs1))
  io.lsu_resp_rs2 := Mux(io.lsu_req_rs2 === 0.U, 0.U, regfile(io.lsu_req_rs2))

  // 2. 写逻辑 (同步写入)
  // p0 是硬件 0，绝不允许被写入
  when(io.wb_alu_valid && io.wb_alu_pdst =/= 0.U) {
    regfile(io.wb_alu_pdst) := io.wb_alu_data
  }
  
  // 假设 ALU 和 LSU 不会在同一周期写同一个寄存器 (OoO 逻辑保证了物理寄存器只会写一次)
  when(io.wb_lsu_valid && io.wb_lsu_pdst =/= 0.U) {
    regfile(io.wb_lsu_pdst) := io.wb_lsu_data
  }

  
}