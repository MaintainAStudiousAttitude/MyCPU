package MyCPU

import chisel3._
import chisel3.util._
import chisel3.util.experimental.loadMemoryFromFileInline

import MyCPU.common._

class TestHarness(hexPath: String = "test.hex")(implicit p: CoreParams)
extends Module
with MyCPU.common.constants.ScalaOpConsts {
  val io = IO(new Bundle {
    val halt          = Output(Bool())
    val success       = Output(Bool())
    val ipc_mcycle    = Output(UInt(64.W))
    val ipc_minstret  = Output(UInt(64.W))
    // 调试用：暴露 tohost 写入的数据，便于 testbench 打印
    val tohost_data   = Output(UInt(64.W))
  })

  val core = Module(new MyCoreTop)

  // ==========================================
  // halt 反馈信号，提前声明，用于门控前端
  // ==========================================
  val halt_reg    = RegInit(false.B)
  val success_reg = RegInit(false.B)
  val tohost_data_reg = RegInit(0.U(64.W))

  // ==========================================
  // 1. 模拟主存 - 1MB 容量 (128K x 64bit)
  // ==========================================
  val sim_mem = Mem(131072, UInt(64.W))

  if (hexPath.nonEmpty) {
    loadMemoryFromFileInline(sim_mem, hexPath)
  }

  // ------------------------------------------
  // 地址解码辅助：显式校验地址是否落在合法范围
  // 合法范围: [0x80000000, 0x80100000)  —— 1MB
  // ------------------------------------------
  def isValidMemAddr(addr: UInt): Bool = {
    addr(63, 20) === "h000000000800".U  // 高 44 位必须是 0x0000_0000_0800
  }

  // --- 前端取指 ---
  val if_req = core.io.imem.req
  // halt 后停止接收新的取指请求，流水线自然排空
  core.io.imem.req.ready := !halt_reg

  val if_word_addr = if_req.bits.addr(19, 3)
  val if_fire      = if_req.valid && core.io.imem.req.ready

  // 异步读 + 1 拍 RegNext 模拟 SyncReadMem 延迟
  core.io.imem.resp.bits.data := RegNext(sim_mem.read(if_word_addr))
  core.io.imem.resp.valid     := RegNext(if_fire && !halt_reg)

  // --- 后端访存 ---
  val lsu_req = core.io.dmem.req
  core.io.dmem.req.ready := !halt_reg

  val lsu_word_addr = lsu_req.bits.addr(19, 3)
  val is_write      = (lsu_req.bits.cmd === MC_W.U)
  val lsu_fire      = lsu_req.valid && core.io.dmem.req.ready

  // 1. 根据访存大小生成基础掩码
  val base_mask = WireDefault(0.U(8.W))
  switch(lsu_req.bits.size) {
    is(MT_B.U) { base_mask := "b00000001".U }
    is(MT_H.U) { base_mask := "b00000011".U }
    is(MT_W.U) { base_mask := "b00001111".U }
    is(MT_D.U) { base_mask := "b11111111".U }
  }

  // 2. 根据地址低 3 位移位
  val offset     = lsu_req.bits.addr(2, 0)
  val wmask_8bit = (base_mask << offset)(7, 0)

  // 3. 展开成 64-bit 字节掩码
  val mask_64bit = Wire(Vec(8, UInt(8.W)))
  for (i <- 0 until 8) {
    mask_64bit(i) := Fill(8, wmask_8bit(i))
  }
  val full_mask = mask_64bit.asUInt

  // 4. Read-Modify-Write
  val lsu_rd_data = sim_mem.read(lsu_word_addr)
  val wdata_64    = lsu_req.bits.data
  val final_wdata = (wdata_64 & full_mask) | (lsu_rd_data & (~full_mask))

  when(lsu_fire && is_write) {
    sim_mem.write(lsu_word_addr, final_wdata)
  }

  // 读数据打一拍
  core.io.dmem.resp.bits.data := RegNext(lsu_rd_data)
  core.io.dmem.resp.valid     := RegNext(lsu_fire && !is_write)

  // ==========================================
  // 2. 性能探针
  //    mcycle: 从复位开始到 halt 前的周期数
  //    minstret: 真实提交指令数 (需要 core 暴露 commit_count)
  // ==========================================
  val mcycle   = RegInit(0.U(64.W))
  val minstret = RegInit(0.U(64.W))

  // 只在未 halt 时累加，halt 后冻结，保证最终读数反映"程序运行期间"
  when(!halt_reg) {
    mcycle := mcycle + 1.U
    minstret := minstret + core.io.commit_count
  }

  // TODO: 把 core 的真实提交计数接进来
  // 占位方案：若 core.io 尚未暴露，则保留每周期 +1 以便流程跑通，
  // 但需要在 core 端增补 commit_count 后替换此处。
  //
  // 期望形式：
  //   val commit_count = core.io.commit_count   // UInt(log2Up(W+1).W), W = issue/retire 宽度
  //   when(!halt_reg) { minstret := minstret + commit_count }
  //
  // 当前临时占位：

  io.ipc_mcycle   := mcycle
  io.ipc_minstret := minstret

  // ==========================================
  // 3. tohost 监听 (终止仿真)
  // ==========================================
  val TOHOST_ADDR       = "h80001000".U(64.W)
  val is_writing_tohost = lsu_fire && is_write && (lsu_req.bits.addr === TOHOST_ADDR)

  when(is_writing_tohost && !halt_reg) {
    val effective = Mux1H(Seq(
    (lsu_req.bits.size === MT_B.U) -> final_wdata(7, 0),
    (lsu_req.bits.size === MT_H.U) -> final_wdata(15, 0),
    (lsu_req.bits.size === MT_W.U) -> final_wdata(31, 0),
    (lsu_req.bits.size === MT_D.U) -> final_wdata
  ))
  halt_reg := true.B
  success_reg := (effective === 1.U)
  tohost_data_reg := effective
    //halt_reg        := true.B
    //// RISC-V 测试约定：tohost 的 bit[0] 为 1 且高位为 0 表示 pass
    //// 若用户程序直接写 1 表示成功，其他非零值为失败码
    //success_reg     := (lsu_req.bits.data === 1.U)
    //tohost_data_reg := lsu_req.bits.data
  }

  io.halt        := halt_reg
  io.success     := success_reg
  io.tohost_data := tohost_data_reg

  // ==========================================
  // 4. 非法地址访问断言 (可选，辅助调试)
  // ==========================================
  when(lsu_fire && !isValidMemAddr(lsu_req.bits.addr) && lsu_req.bits.addr =/= TOHOST_ADDR) {
    printf(p"[TestHarness] WARN: LSU access to out-of-range addr 0x${Hexadecimal(lsu_req.bits.addr)}\n")
  }
  when(if_fire && !isValidMemAddr(if_req.bits.addr)) {
    printf(p"[TestHarness] WARN: IF fetch from out-of-range addr 0x${Hexadecimal(if_req.bits.addr)}\n")
  }

  when(if_fire) {
    printf(p"[IF] addr=0x${Hexadecimal(if_req.bits.addr)}\n")
  }
  when(RegNext(if_fire)) {
    printf(p"[IF-DATA] data=0x${Hexadecimal(core.io.imem.resp.bits.data)}\n") 
  }


}
