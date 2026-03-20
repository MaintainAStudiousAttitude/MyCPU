package MyCPU.be

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec
import MyCPU.common._

class RobUnitTest 
extends AnyFlatSpec 
with ChiselScalatestTester
with MyCPU.common.constants.ScalaOpConsts
with MyCPU.common.constants.RISCVConsts
{
  
  implicit val p = CoreParams(xLen = 64, numPRegs = 64, numRobEntries = 4)

  // 绝对严密的重置函数，杀死所有 X 态
  def resetInputs(c: Rob): Unit = {
    c.io.enq.valid.poke(false.B)
    c.io.enq.bits.inst.poke(0.U)
    c.io.enq.bits.pc.poke(0.U)
    c.io.enq.bits.fu_code.poke(0.U)
    c.io.enq.bits.alu_op.poke(0.U)
    c.io.enq.bits.op1_sel.poke(0.U)
    c.io.enq.bits.op2_sel.poke(0.U)
    c.io.enq.bits.imm.poke(0.U)
    c.io.enq.bits.mem_cmd.poke(0.U)
    c.io.enq.bits.mem_size.poke(0.U)
    c.io.enq.bits.mem_signed.poke(false.B)
    c.io.enq.bits.l_rd.poke(0.U)
    c.io.enq.bits.l_rs1.poke(0.U)
    c.io.enq.bits.l_rs2.poke(0.U)
    c.io.enq.bits.rf_wen.poke(false.B)
    c.io.enq.bits.use_rs1.poke(false.B)
    c.io.enq.bits.use_rs2.poke(false.B)
    c.io.enq.bits.p_rd.poke(0.U)
    c.io.enq.bits.p_rs1.poke(0.U)
    c.io.enq.bits.p_rs2.poke(0.U)
    c.io.enq.bits.stale_p_rd.poke(0.U)
    c.io.enq.bits.rob_idx.poke(0.U)
    c.io.enq.bits.exception.poke(false.B)
    c.io.enq.bits.exc_cause.poke(0.U)

    c.io.cdb(0).valid.poke(false.B)
    c.io.cdb(0).bits.rob_idx.poke(0.U)
    c.io.cdb(0).bits.p_rd.poke(0.U)
    c.io.cdb(0).bits.data.poke(0.U)
    c.io.cdb(0).bits.exc.poke(false.B)

    c.io.cdb(1).valid.poke(false.B)
    c.io.cdb(1).bits.rob_idx.poke(0.U)
    c.io.cdb(1).bits.p_rd.poke(0.U)
    c.io.cdb(1).bits.data.poke(0.U)
    c.io.cdb(1).bits.exc.poke(false.B)
  }

  "RobUnit" should "handle out-of-order completion and in-order commit" in {
    test(new Rob).withAnnotations(Seq(WriteVcdAnnotation)) { c =>
      resetInputs(c)
      c.clock.step(1)

      // ==========================================================
      // Phase 1: 顺序入队 (Dispatch A and B)
      // ==========================================================
      println("[Phase 1] Dispatching A...")
      c.io.enq.valid.poke(true.B)
      c.io.enq.bits.rf_wen.poke(true.B)
      c.io.enq.bits.stale_p_rd.poke(10.U)
      c.io.rob_idx_alloc.expect(0.U)
      c.clock.step(1) // A 进入 index 0

      println("[Phase 1] Dispatching B...")
      c.io.enq.valid.poke(true.B)
      c.io.enq.bits.rf_wen.poke(true.B)
      c.io.enq.bits.stale_p_rd.poke(11.U)
      c.io.rob_idx_alloc.expect(1.U)
      c.clock.step(1) // B 进入 index 1
      
      resetInputs(c) // 停止入队
      c.clock.step(1) // 稳一拍

      // ==========================================================
      // Phase 2: 乱序写回 (B 优先完成)
      // ==========================================================
      println("[Phase 2] Out-of-Order WB: B completes first...")
      c.io.cdb(0).valid.poke(true.B)
      c.io.cdb(0).bits.rob_idx.poke(1.U) // B的ID是1
      c.clock.step(1)
      c.io.cdb(0).valid.poke(false.B)
      
      // 验证: A没完成，B不能Commit
      c.io.commit_free.valid.expect(false.B)
      println("  -> Pass: B is waiting for A.")

      // ==========================================================
      // Phase 3: 顺序提交 (A 完成，随后 B 也自动提交)
      // ==========================================================
      println("[Phase 3] In-Order Commit: A completes...")
      c.io.cdb(1).valid.poke(true.B)
      c.io.cdb(1).bits.rob_idx.poke(0.U) // A的ID是0
      c.clock.step(1)
      c.io.cdb(1).valid.poke(false.B) // 立刻拉低，防止干扰

      // 此时 A 成为 Head，且已完成，必须触发 Commit！
      println("  -> Checking A's Commit...")
      c.io.commit_free.valid.expect(true.B)
      c.io.commit_free.bits.expect(10.U)
      
      // 推进时钟，让 A 真正退役，B 成为新的 Head
      c.clock.step(1)

      // 此时 B 已经在等待了，它应该立刻触发 Commit！
      println("  -> Checking B's Auto-Commit...")
      c.io.commit_free.valid.expect(true.B)
      c.io.commit_free.bits.expect(11.U)
      
      c.clock.step(1) // B 退役
      
      // 验证全空
      c.io.commit_free.valid.expect(false.B)

      // ==========================================================
      // Phase 4: 异常冲刷测试
      // ==========================================================
      println("[Phase 4] Exception Flush...")
      c.io.enq.valid.poke(true.B)
      c.io.enq.bits.rf_wen.poke(true.B)
      c.io.enq.bits.stale_p_rd.poke(12.U)
      c.clock.step(1) // C 进入 index 2
      resetInputs(c)

      // 制造异常写回
      c.io.cdb(0).valid.poke(true.B)
      c.io.cdb(0).bits.rob_idx.poke(2.U)
      c.io.cdb(0).bits.exc.poke(true.B)
      c.clock.step(1)
      c.io.cdb(0).valid.poke(false.B)

      c.io.flush_pipeline.expect(true.B)
      c.io.commit_free.valid.expect(false.B)
      println("  -> Pass: Exception flushed pipeline.")

      println("🚀 All ROB Tests Passed!")
    }
  }
}