package MyCPU.be

import chisel3._
import chisel3.util._

import MyCPU.common._

class LsuIO(implicit p: CoreParams) extends Bundle {
  // 1. 执行请求 (来自 RegRead)
  val req = Flipped(Decoupled(new FuncUnitReq))
  
  // 2. 结果广播 (写回 CDB 1)
  val cdb = Valid(new CDBIO)

  // 3. 外部内存接口 (连向 D-Cache)
  val dmem = new SimpleMemIO

  // 4. 来自 ROB 的 Commit 信号 (通知 SB 真正写内存)
  val commit_store = Input(Bool())
}

class StoreBufferEntry(implicit p: CoreParams) 
extends Bundle {
  val addr = UInt(p.xLen.W)
  val data = UInt(p.xLen.W)
  val size = UInt(2.W)
}

class LSU_Unit(implicit p: CoreParams) 
extends Module
with MyCPU.common.constants.ScalaOpConsts
with MyCPU.common.constants.RISCVConsts
{
  val io = IO(new LsuIO)

  val uop      = io.req.bits.uop
  val rs1_data = io.req.bits.rs1_data // Base Address
  val rs2_data = io.req.bits.rs2_data // Store Data

  // =========================================================
  // 1. AGU (地址生成) 与 数据对齐
  // =========================================================
  val effective_addr = rs1_data + uop.imm

  // Store 数据预处理：根据 Size 将数据复制对齐 (例如 SB 指令将低8位复制到整个64位)
  // 方便 Cache 控制器根据 byte mask 直接抓取
  val store_data_b = Fill(8, rs2_data(7, 0))
  val store_data_h = Fill(4, rs2_data(15, 0))
  val store_data_w = Fill(2, rs2_data(31, 0))
  
  val store_data_aligned = MuxLookup(uop.mem_size, rs2_data)(Seq(
    MT_B.U -> store_data_b,
    MT_H.U -> store_data_h,
    MT_W.U -> store_data_w
  ))

  // =========================================================
  // 2. Store Buffer (SB) 逻辑
  // =========================================================
  // 使用 Queue 作为 Store Buffer (假设深度为 4)
  val store_buffer = Module(new Queue(new StoreBufferEntry, entries = 4))
  val sb_empty = !store_buffer.io.deq.valid

  val is_store = uop.mem_cmd === MC_W.U
  val is_load  = uop.mem_cmd === MC_R.U

  // SB 入队逻辑 (在执行阶段)
  store_buffer.io.enq.valid := io.req.fire && is_store
  store_buffer.io.enq.bits.addr := effective_addr
  store_buffer.io.enq.bits.data := store_data_aligned
  store_buffer.io.enq.bits.size := uop.mem_size

  // SB 出队/写内存逻辑 (在 Commit 阶段)
  // 当 ROB 通知 commit_store 且 内存 Ready 时，将 SB 队首发给内存
  val sb_head = store_buffer.io.deq.bits
  store_buffer.io.deq.ready := io.commit_store && io.dmem.req.ready


  //debug

   when(store_buffer.io.enq.fire || store_buffer.io.deq.fire || store_buffer.io.count > 0.U) {
    printf(p"[SB-STATUS] 📦 当前 SB 元素个数: ${store_buffer.io.count}/4 | 满: ${!store_buffer.io.enq.ready} | 空: ${!store_buffer.io.deq.valid}\n")
  }

  // 2. 监控“幽灵指令”的潜入 (Push / Enqueue)
  when(store_buffer.io.enq.fire) {
    printf(p"  ---> [SB-PUSH] 🔴 收到 Store 暂存请求! 入队地址: 0x${Hexadecimal(store_buffer.io.enq.bits.addr)}, 数据: ${store_buffer.io.enq.bits.data}\n")
  }

  // 3. 监控真实的内存写入 (Pop / Dequeue)
  when(store_buffer.io.deq.fire) {
    printf(p"  <--- [SB-POP]  🟢 ROB 允许提交! 正在写入物理内存! 出队地址: 0x${Hexadecimal(store_buffer.io.deq.bits.addr)}\n")
  }

  // =========================================================
  // 3. Load 状态机
  // =========================================================
  val s_IDLE :: s_WAIT_MEM :: Nil = Enum(2)
  val state = RegInit(s_IDLE)

  // 锁存 Load 的目标寄存器和 ID，等待内存返回时使用
  val load_uop_reg = Reg(new MicroOp)
  val load_addr_reg = Reg(UInt(p.xLen.W))

  // 接收请求条件：
  // 1. 状态机空闲
  // 2. 如果是 Store，SB 必须有空位
  // 3. 【极简安全策略】如果是 Load，必须等 SB 完全清空！防止读到旧数据！
  val load_can_issue = is_load && sb_empty
  io.req.ready := (state === s_IDLE) && 
                  Mux(is_store, store_buffer.io.enq.ready, load_can_issue)

  when (io.req.fire && is_load) {
    state := s_WAIT_MEM
    load_uop_reg := uop
    load_addr_reg := effective_addr
  } .elsewhen (state === s_WAIT_MEM && io.dmem.resp.valid) {
    state := s_IDLE
  }

  // =========================================================
  // 4. 外部内存接口控制 (D-Mem Arbiter)
  // =========================================================
  // 内存请求优先服务 Load (在执行阶段)，其次服务 Store (在 Commit 阶段)
  // 注意：因为 Load 只有在 SB empty 时才执行，所以其实 Load 和 Store 不会同时发起请求！
  
  val do_load_req  = io.req.valid && is_load && sb_empty && (state === s_IDLE)
  val do_store_req = store_buffer.io.deq.valid && io.commit_store

  io.dmem.req.valid     := do_load_req || do_store_req
  io.dmem.req.bits.addr := Mux(do_load_req, effective_addr, sb_head.addr)
  io.dmem.req.bits.data := sb_head.data // Load 请求忽略此字段
  io.dmem.req.bits.cmd  := Mux(do_load_req, MC_R.U, MC_W.U)
  io.dmem.req.bits.size := Mux(do_load_req, uop.mem_size, sb_head.size)

  // =========================================================
  // 5. Load 数据后处理 (符号扩展)
  // =========================================================
  val raw_mem_data = io.dmem.resp.bits.data
  
  // 根据地址的低两位进行移位提取 (假设是小端序)
  val shift_amount = (load_addr_reg(2, 0) * 8.U)(5, 0)
  val shifted_data = raw_mem_data >> shift_amount

  val b_data = shifted_data(7, 0)
  val h_data = shifted_data(15, 0)
  val w_data = shifted_data(31, 0)

  // 根据 signed 标志决定扩展方式 (asSInt.pad)
  val load_data_final = MuxLookup(load_uop_reg.mem_size, raw_mem_data)(Seq(
    MT_B.U -> Mux(load_uop_reg.mem_signed, b_data.asSInt.pad(p.xLen).asUInt, b_data.zext.asUInt),
    MT_H.U -> Mux(load_uop_reg.mem_signed, h_data.asSInt.pad(p.xLen).asUInt, h_data.zext.asUInt),
    MT_W.U -> Mux(load_uop_reg.mem_signed, w_data.asSInt.pad(p.xLen).asUInt, w_data.zext.asUInt)
  ))

  // =========================================================
  // 6. CDB 广播逻辑
  // =========================================================
  io.cdb.valid := false.B
  io.cdb.bits.rob_idx := 0.U
  io.cdb.bits.p_rd    := 0.U
  io.cdb.bits.data    := 0.U
  io.cdb.bits.exc     := false.B

  when (io.req.fire && is_store) {
    // Store 瞬间完成 (进 SB 就算执行完)
    io.cdb.valid        := true.B
    io.cdb.bits.rob_idx := uop.rob_idx
    io.cdb.bits.p_rd    := 0.U // Store 不写寄存器
    io.cdb.bits.exc     := uop.exception
  } .elsewhen (state === s_WAIT_MEM && io.dmem.resp.valid) {
    // Load 等到内存返回数据才完成
    io.cdb.valid        := true.B
    io.cdb.bits.rob_idx := load_uop_reg.rob_idx
    io.cdb.bits.p_rd    := load_uop_reg.p_rd
    io.cdb.bits.data    := load_data_final
    io.cdb.bits.exc     := load_uop_reg.exception
  }
  
}