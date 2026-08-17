package MyCPU.fe

import chisel3._
import chisel3.util._
import chisel3.dontTouch

import MyCPU.common._
import MyCPU.bpu


class FrontEndIO(implicit p: CoreParams)
extends Bundle
{
    val imem = new SimpleMemIO

    val fetch_packet = Decoupled(Vec(p.decodeWidth, new FetchPacket))

    val redirect_valid = Input(Bool())
    val redirect_pc    = Input(UInt(p.xLen.W))

    val bpu_update = Flipped(Valid(new BpuUpdate))


}

class FrontEnd(implicit p: CoreParams)
extends Module
with MyCPU.common.constants.ScalaOpConsts
with MyCPU.common.constants.RISCVConsts
{
    val io = IO(new FrontEndIO)

    val fq = Module(new Queue(Vec(p.fetchWidth, new FetchPacket), entries = 8))
    val bpu = Module(new BPU)

    fq.reset := reset.asBool || io.redirect_valid

    val pc_reg = RegInit("h8000_0000".U(p.xLen.W))

    val if1_ready = fq.io.enq.ready && io.imem.req.ready
    val if1_fire  = if1_ready && !io.redirect_valid

    BPU.pc_reg := pc_reg
    BPU.bpu_update := io.bpu_update
    BPU.if1_fire := if1_fire

    val pred_target = bpu.pred_target
    val pred_slot = bpu.pred_slot
    val pred_taken = bpu.pred_taken

    io.imem.req.valid     := if1_fire
    io.imem.req.bits.addr := pc_reg & (~ 7.U(p.xLen.W))
    io.imem.req.bits.cmd  := MC_R.U  // 假设你的常数里读命令叫这个
    io.imem.req.bits.size := MT_D.U     // 64-bit Word
    io.imem.req.bits.data := 0.U

    when(io.redirect_valid) {
        pc_reg := io.redirect_pc   // 优先级最高：后端纠错打断
    }.elsewhen(if1_fire && pred_taken){
        pc_reg := pred_target
    } .elsewhen(if1_fire) {
        pc_reg := (pc_reg & (~7.U(p.xLen.W))) + 8.U     // 正常顺序取指
    }

    val if2_pc_reg = RegEnable(pc_reg, if1_fire)
    val if2_valid  = RegNext(if1_fire, false.B)

    val if2_pred_taken = RegEnable(pred_taken, false.B, if1_fire)
    val if2_pred_target = RegEnable(pred_target, 0.U, if1_fire)
    val if2_pred_slot = RegEnable(pred_slot, false.B, if1_fire)

    val flush_in_flight = RegNext(io.redirect_valid, false.B) || io.redirect_valid

    val inst0 = io.imem.resp.bits.data(31, 0)
    val inst1 = io.imem.resp.bits.data(63, 32)

    //unaligned check
    val is_unaligned = if2_pc_reg(2)
    val inst0_valid = !is_unaligned

    fq.io.enq.valid := if2_valid && io.imem.resp.valid && !flush_in_flight

    val inst0_pred_taken = if2_pred_taken && (if2_pred_slot === false.B) && inst0_valid

    val inst1_valid = !inst0_pred_taken

    fq.io.enq.bits(0).pc := if2_pc_reg & (~7.U(p.xLen.W))
    fq.io.enq.bits(0).inst := inst0
    fq.io.enq.bits(0).valid := inst0_valid
    fq.io.enq.bits(0).pred_taken := inst0_pred_taken
    fq.io.enq.bits(0).pred_target := if2_pred_target

    fq.io.enq.bits(1).pc := (if2_pc_reg & (~7.U(p.xLen.W))) + 4.U
    fq.io.enq.bits(1).inst := inst1
    fq.io.enq.bits(1).valid := inst1_valid
    fq.io.enq.bits(1).pred_taken := if2_pred_taken && (if2_pred_slot === true.B) && inst1_valid
    fq.io.enq.bits(1).pred_target := if2_pred_target

    dontTouch(fq.io.enq.bits)

    io.fetch_packet.valid   := fq.io.deq.valid
  // 将 Queue 的单个元素包裹进 Vec(0) 发送给 Backend
    io.fetch_packet.bits := fq.io.deq.bits
  
  // 后端接收几条，队列就弹出几条
    fq.io.deq.ready := io.fetch_packet.ready
}   