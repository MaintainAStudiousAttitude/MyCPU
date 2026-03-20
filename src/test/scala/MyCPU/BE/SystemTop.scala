package MyCPU

import chisel3._
import chisel3.util._

import MyCPU.common._

// ============================================================
// 1. 模拟指令内存 (Mock I-Cache)
// ============================================================
class MockIMem(program: Seq[Long])(implicit p: CoreParams) extends Module {
  val io = IO(Flipped(new SimpleMemIO))
  
  // 将传入的程序转换为硬件 ROM
  val rom = VecInit(program.map(_.U(32.W)))

  io.req.ready := true.B

  // 模拟 1 周期延迟的 SRAM
  val req_valid = RegNext(io.req.fire, false.B)
  val req_addr  = RegNext(io.req.bits.addr)
  
  // 假设基地址是 0x8000_0000，每条指令 4 字节
  // 算出数组索引
  val word_idx = (req_addr - "h8000_0000".U) >> 2

  io.resp.valid := req_valid
  
  val inst0 = Mux(word_idx < program.length.U, rom(word_idx), 0.U(32.W))
  // 注意数组越界保护
  val inst1 = Mux((word_idx + 1.U) < program.length.U, rom(word_idx + 1.U), 0.U(32.W))
  // 防止越界读取导致报错
  io.resp.bits.data := Cat(inst1, inst0)
}

// ============================================================
// 2. 模拟数据内存 (Mock D-Cache)
// ============================================================
class MockDMem(implicit p: CoreParams) 
extends Module
with MyCPU.common.constants.ScalaOpConsts
with MyCPU.common.constants.RISCVConsts
{
  val io = IO(new Bundle {
    val dmem = Flipped(new SimpleMemIO)
    val debug_mem = Output(Vec(16, UInt(64.W))) // 导出给 Testbench 检查结果
  })

  // 定义一块小小的 RAM，16 个 64-bit 槽位 (总共 128 字节)
  val ram = RegInit(VecInit(Seq.fill(16)(0.U(64.W))))
  io.debug_mem := ram

  io.dmem.req.ready := true.B

  val req_valid = RegNext(io.dmem.req.fire, false.B)
  val req_cmd   = RegNext(io.dmem.req.bits.cmd)
  val req_addr  = RegNext(io.dmem.req.bits.addr)
  val req_data  = RegNext(io.dmem.req.bits.data)

  // 映射地址 (截取低位，并按照 8 字节对齐)
  // 比如 0x10000 -> 槽 0; 0x10008 -> 槽 1
  val word_idx = req_addr(6, 3) 

  // 写操作 (MEN_XWR 为你在 Consts 里定义的写常量)
  when(req_valid && req_cmd === MC_W.U) {
    ram(word_idx) := req_data
  }

  // 读操作
  io.dmem.resp.valid := req_valid && req_cmd === MC_R.U
  io.dmem.resp.bits.data := ram(word_idx)
}

// ============================================================
// 3. 系统总成 (System Top)
// ============================================================
class SystemTop(program: Seq[Long])(implicit p: CoreParams) 
extends Module
{
  val io = IO(new Bundle {
    val debug_mem = Output(Vec(16, UInt(64.W)))
  })

  // 实例化 Core 和 双路假内存
  val core = Module(new MyCoreTop)
  val imem = Module(new MockIMem(program))
  val dmem = Module(new MockDMem)

  // 连线
  core.io.imem <> imem.io
  core.io.dmem <> dmem.io.dmem
  
  // 导出内存状态给测试脚本
  io.debug_mem := dmem.io.debug_mem
}

