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
  val commit_store = Input(Vec(2, Valid(UInt(p.robBits.W))))
  
  // [NEW] 接收幽灵抹杀信号
  val flush_mispredict   = Input(Bool())
  val mispredict_rob_idx = Input(UInt(p.robBits.W))
  val rob_head_idx       = Input(UInt(p.robBits.W))
  val flush              = Input(Bool())

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
  val rs1_data = io.req.bits.rs1_data
  val rs2_data = io.req.bits.rs2_data

  val effective_addr = rs1_data + uop.imm

  val store_data_b = Fill(8, rs2_data(7, 0))
  val store_data_h = Fill(4, rs2_data(15, 0))
  val store_data_w = Fill(2, rs2_data(31, 0))
  
  val store_data_aligned = MuxLookup(uop.mem_size, rs2_data)(Seq(
    MT_B.U -> store_data_b, MT_H.U -> store_data_h, MT_W.U -> store_data_w
  ))

  // =========================================================
  // 1. Speculative Store Array (推测写缓冲，受 ROB 保护)
  // =========================================================
  val sb_addr = Reg(Vec(p.numRobEntries, UInt(p.xLen.W)))
  val sb_data = Reg(Vec(p.numRobEntries, UInt(p.xLen.W)))
  val sb_size = Reg(Vec(p.numRobEntries, UInt(2.W)))
  val sb_valid = RegInit(VecInit(Seq.fill(p.numRobEntries)(false.B)))

  def isYounger(my_idx: UInt, target_idx: UInt, head: UInt): Bool = {
    (my_idx - head) > (target_idx - head)
  }

  val is_store = uop.mem_cmd === MC_W.U
  val is_load  = uop.mem_cmd === MC_R.U

  // 1.1 Store 执行：直接写入对应 rob_idx 的槽位
  when(io.req.fire && is_store) {
    sb_addr(uop.rob_idx) := effective_addr
    sb_data(uop.rob_idx) := store_data_aligned
    sb_size(uop.rob_idx) := uop.mem_size
    sb_valid(uop.rob_idx) := true.B
  }

  // 1.2 幽灵抹杀：直接清除年轻的推测条目！
  when(io.flush) {
    sb_valid.foreach(_ := false.B)
  } .elsewhen(io.flush_mispredict) {
    for(i <- 0 until p.numRobEntries) {
      when(isYounger(i.U, io.mispredict_rob_idx, io.rob_head_idx)) {
        sb_valid(i) := false.B
      }
    }
  }

  // =========================================================
  // 2. Committed Store Queue (真实写内存队列)
  // =========================================================
  // 采用环形数组处理一拍内可能 Commit 两个 Store 的情况
  val c_sq = Reg(Vec(p.numRobEntries, new StoreBufferEntry))
  val c_sq_val = RegInit(VecInit(Seq.fill(p.numRobEntries)(false.B)))
  val c_sq_head = RegInit(0.U(p.robBits.W))
  val c_sq_tail = RegInit(0.U(p.robBits.W))

  val c0_valid = io.commit_store(0).valid
  val c1_valid = io.commit_store(1).valid
  val c0_idx   = io.commit_store(0).bits
  val c1_idx   = io.commit_store(1).bits

  val t0 = c_sq_tail
  val t1 = c_sq_tail + 1.U

  when(c0_valid) {
    c_sq(t0).addr := sb_addr(c0_idx)
    c_sq(t0).data := sb_data(c0_idx)
    c_sq(t0).size := sb_size(c0_idx)
    c_sq_val(t0)  := true.B
    sb_valid(c0_idx) := false.B // 推测态转为确态
  }
  when(c1_valid) {
    val t_idx = Mux(c0_valid, t1, t0)
    c_sq(t_idx).addr := sb_addr(c1_idx)
    c_sq(t_idx).data := sb_data(c1_idx)
    c_sq(t_idx).size := sb_size(c1_idx)
    c_sq_val(t_idx)  := true.B
    sb_valid(c1_idx) := false.B
  }
  c_sq_tail := c_sq_tail + c0_valid.asUInt + c1_valid.asUInt

  val sq_not_empty = c_sq_val(c_sq_head)
  val sq_head_entry = c_sq(c_sq_head)

  // =========================================================
  // 3. Load 状态机与内存仲裁
  // =========================================================
  val s_IDLE :: s_WAIT_MEM :: Nil = Enum(2)
  val state = RegInit(s_IDLE)
  val load_uop_reg = Reg(new MicroOp)
  val load_addr_reg = Reg(UInt(p.xLen.W))

  val do_store_req = sq_not_empty
  // 仅当所有的确态、推测态 Store 均为空时，Load 才能发起 (极简安全机制)
  val do_load_req  = io.req.valid && is_load && !sq_not_empty && (sb_valid.asUInt === 0.U) && (state === s_IDLE)

  // 【神级优化】：由于 Store 现在按 rob_idx 入座，绝对不会发生冲突阻塞！
  io.req.ready := (state === s_IDLE) && Mux(is_store, true.B, do_load_req)

  when (io.req.fire && is_load) {
    state := s_WAIT_MEM
    load_uop_reg := uop
    load_addr_reg := effective_addr
  } .elsewhen (state === s_WAIT_MEM && io.dmem.resp.valid) {
    state := s_IDLE
  }

  io.dmem.req.valid     := do_load_req || do_store_req
  io.dmem.req.bits.addr := Mux(do_load_req, effective_addr, sq_head_entry.addr)
  io.dmem.req.bits.data := sq_head_entry.data
  io.dmem.req.bits.cmd  := Mux(do_load_req, MC_R.U, MC_W.U)
  io.dmem.req.bits.size := Mux(do_load_req, uop.mem_size, sq_head_entry.size)

  when(io.dmem.req.fire && do_store_req) {
    c_sq_val(c_sq_head) := false.B
    c_sq_head := c_sq_head + 1.U
  }

  // =========================================================
  // 4. Load 数据格式化与 CDB 广播
  // =========================================================
  val raw_mem_data = io.dmem.resp.bits.data
  val shift_amount = (load_addr_reg(2, 0) * 8.U)(5, 0)
  val shifted_data = raw_mem_data >> shift_amount

  val load_data_final = MuxLookup(load_uop_reg.mem_size, raw_mem_data)(Seq(
    MT_B.U -> Mux(load_uop_reg.mem_signed, shifted_data(7, 0).asSInt.pad(p.xLen).asUInt, shifted_data(7, 0).zext.asUInt),
    MT_H.U -> Mux(load_uop_reg.mem_signed, shifted_data(15, 0).asSInt.pad(p.xLen).asUInt, shifted_data(15, 0).zext.asUInt),
    MT_W.U -> Mux(load_uop_reg.mem_signed, shifted_data(31, 0).asSInt.pad(p.xLen).asUInt, shifted_data(31, 0).zext.asUInt)
  ))

  io.cdb.valid := false.B
  io.cdb.bits.rob_idx := 0.U
  io.cdb.bits.p_rd    := 0.U
  io.cdb.bits.data    := 0.U
  io.cdb.bits.exc     := false.B
  //test
  io.cdb.bits.is_branch := false.B
  io.cdb.bits.br_taken  := false.B
  io.cdb.bits.br_target := 0.U
  io.cdb.bits.br_pc     := 0.U

  when (io.req.fire && is_store) {
    io.cdb.valid        := true.B
    io.cdb.bits.rob_idx := uop.rob_idx
    io.cdb.bits.p_rd    := 0.U 
    io.cdb.bits.exc     := uop.exception
  } .elsewhen (state === s_WAIT_MEM && io.dmem.resp.valid) {
    io.cdb.valid        := true.B
    io.cdb.bits.rob_idx := load_uop_reg.rob_idx
    io.cdb.bits.p_rd    := load_uop_reg.p_rd
    io.cdb.bits.data    := load_data_final
    io.cdb.bits.exc     := load_uop_reg.exception
  }
  
}