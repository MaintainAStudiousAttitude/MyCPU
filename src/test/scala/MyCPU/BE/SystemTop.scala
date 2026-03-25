package MyCPU

import chisel3._
import chisel3.util._

import MyCPU.common._

// ============================================================
// 1. 模拟指令内存 (Mock I-Cache)
// ============================================================
class MockIMem(program: Seq[Long])(implicit p: CoreParams) extends Module {
  val io = IO(Flipped(new SimpleMemIO))
  
  // ========================================================
  // 💡 改进：将程序用 0 (NOP/非法指令) 填充至 256 条指令 (1KB 容量)
  // 保证它是 2 的整数次幂，彻底消除 Chisel 动态索引截断问题
  // ========================================================
  val rom_size = 256
  val padded_program = program.padTo(rom_size, 0L) // 不足256个的用 0L 补齐
  val rom = VecInit(padded_program.map(_.U(32.W)))

  io.req.ready := true.B

  val req_valid = RegNext(io.req.fire, false.B)
  val req_addr  = RegNext(io.req.bits.addr)
  
  val word_idx = (req_addr - "h8000_0000".U) >> 2

  io.resp.valid := req_valid
  
  // 💡 改进：为了极致的安全，强制给 word_idx 套上掩码，防止严重越界
  // 因为 rom_size = 256，需要 8 bit 索引 (0~255)
  val safe_idx0 = word_idx(7, 0)
  val safe_idx1 = word_idx(7, 0) + 1.U
  
  // 此时不再需要繁琐的 program.length.U 判断了
  val inst0 = rom(safe_idx0)
  val inst1 = rom(safe_idx1)
  
  // 如果原始地址算出来的 index 超出了 255，强制返回 0
  val out_of_bounds = word_idx >= rom_size.U
  io.resp.bits.data := Mux(out_of_bounds, 0.U(64.W), Cat(inst1, inst0))
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

  // 在 MockDMem 的底部加上这些打印：
  
  when(io.dmem.req.fire) {
    printf(p"[MockDMem-REQ] CMD: ${io.dmem.req.bits.cmd}, ADDR: 0x${Hexadecimal(io.dmem.req.bits.addr)}, DATA: ${io.dmem.req.bits.data}\n")
  }

  when(req_valid && req_cmd === MC_W.U) {
    ram(word_idx) := req_data
    printf(p"[MockDMem-WRITE] Success! Wrote ${req_data} to slot ${word_idx}\n")
  }
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

