package MyCPU


import chisel3._
import chisel3.util._

import MyCPU.be._
import MyCPU.fe._
import MyCPU.common._

class MyCoreIO(implicit p: CoreParams) extends Bundle {
  // 指令内存接口 (Instruction Memory Interface)
  // 用于前端 Fetch 取指
  val imem = new SimpleMemIO

  // 数据内存接口 (Data Memory Interface)
  // 用于后端 LSU 读写数据
  val dmem = new SimpleMemIO

  val commit_count = Output(UInt(4.W))
}

class MyCoreTop(implicit p: CoreParams) extends Module {
  val io = IO(new MyCoreIO)

  // --------------------------------------------------------
  // A. 实例化前端和后端
  // --------------------------------------------------------
  val frontend = Module(new FrontEnd)
  val backend  = Module(new BackEndTOP)

  // --------------------------------------------------------
  // B. 前后端数据流闭环 (The Data Path)
  // --------------------------------------------------------
  // 顺流：前端将取到的 FetchPacket 送给后端 (交接点：Decode 的输入队列)
  backend.io.from_frontend <> frontend.io.fetch_packet

  // 逆流：后端遇到预测错误或异常时，要求前端重定向 PC 并冲刷流水线
  frontend.io.redirect_valid := backend.io.redirect_valid
  frontend.io.redirect_pc    := backend.io.redirect_pc

  // --------------------------------------------------------
  // C. 连接外部接口 (External Interfaces)
  // --------------------------------------------------------
  // 前端的取指请求接出到 CoreTop 的 imem
  io.imem <> frontend.io.imem

  // 后端 LSU 的访存请求接出到 CoreTop 的 dmem
  io.dmem <> backend.io.dmem

  // --------------------------------------------------------
  // D. 辅助 Debug 探针 (可选，极力推荐)
  // --------------------------------------------------------
  // 在顶层暴露一些关键信号，方便验证时观察 CPU 整体状态
  // 例如：当前正在提交的 PC，或者是否发生了 Flush
  io.commit_count := backend.io.commit_num
  /*
  val debug_commit_pc = Output(UInt(p.xLen.W))
  debug_commit_pc := backend.io.debug_commit_pc // 假设你在 BackendTop 连出了这个信号
  */
}