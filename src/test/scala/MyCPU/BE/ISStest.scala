package MyCPU.be

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

import MyCPU.common._

class IssueQueueTest 
extends AnyFlatSpec 
with ChiselScalatestTester
with MyCPU.common.constants.ScalaOpConsts
with MyCPU.common.constants.RISCVConsts
{

  // 定义测试参数：4 个发射槽位足以验证逻辑
  implicit val p = CoreParams(xLen = 64, numPRegs = 64, numIssueEntries = 4)

  // 极其严密的输入重置，彻底防止 X 态污染 Mux 树
  def resetInputs(c: IssueQueue): Unit = {
    c.io.enq.valid.poke(false.B)
    
    // 清空 MicroOp 所有无关字段
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
    c.io.enq.bits.br_type.poke(0.U)
    
    // IQ 专用就绪状态初始化
    c.io.enq.bits.prs1_ready.poke(false.B)
    c.io.enq.bits.prs2_ready.poke(false.B)

    // 清空两条 CDB
    c.io.cdb(0).valid.poke(false.B)
    c.io.cdb(0).bits.p_rd.poke(0.U)
    c.io.cdb(0).bits.rob_idx.poke(0.U)
    c.io.cdb(0).bits.data.poke(0.U)
    c.io.cdb(0).bits.exc.poke(false.B)

    c.io.cdb(1).valid.poke(false.B)
    c.io.cdb(1).bits.p_rd.poke(0.U)
    c.io.cdb(1).bits.rob_idx.poke(0.U)
    c.io.cdb(1).bits.data.poke(0.U)
    c.io.cdb(1).bits.exc.poke(false.B)

    c.io.flush.poke(false.B)
    
    // 模拟下游执行单元(ALU/LSU)永远畅通
    c.io.iss_alu.ready.poke(true.B)
    c.io.iss_lsu.ready.poke(true.B)
  }

  "IssueQueue" should "dispatch, wakeup, and dual-issue correctly" in {
    test(new IssueQueue).withAnnotations(Seq(WriteVcdAnnotation)) { c =>
      resetInputs(c)
      c.clock.step(1)

      // ==========================================================
      // Phase 1: 立即发射 (Ready on arrival)
      // 如果操作数已经算好(prs1_ready=true)，指令进队后下一拍就能发射
      // ==========================================================
      println("[Phase 1] Dispatching ALU instruction (Ready)")
      c.io.enq.valid.poke(true.B)
      c.io.enq.bits.fu_code.poke(FC_ALU)
      c.io.enq.bits.p_rd.poke(10.U) // 给个特征标签方便验证
      c.io.enq.bits.use_rs1.poke(true.B)
      c.io.enq.bits.prs1_ready.poke(true.B) // 操作数已在 PRF 里了
      
      c.clock.step(1)
      resetInputs(c) // 停止进队

      println("  -> Checking immediate issue")
      c.io.iss_alu.valid.expect(true.B)
      c.io.iss_alu.bits.p_rd.expect(10.U)
      
      c.clock.step(1) // 推进时钟，完成发射出队
      c.io.iss_alu.valid.expect(false.B) // 确认槽位已清空

      // ==========================================================
      // Phase 2: CDB 唤醒与乱序发射 (Wakeup Logic)
      // ==========================================================
      println("[Phase 2] Dispatching dependent instruction (Waiting for p5)")
      c.io.enq.valid.poke(true.B)
      c.io.enq.bits.fu_code.poke(FC_ALU)
      c.io.enq.bits.p_rd.poke(11.U)
      c.io.enq.bits.use_rs1.poke(true.B)
      c.io.enq.bits.p_rs1.poke(5.U)          // 声明自己依赖 p5 寄存器
      c.io.enq.bits.prs1_ready.poke(false.B) // p5 还没算完!
      
      c.clock.step(1)
      resetInputs(c)

      // 因为 p5 没好，所以肯定不能发射
      c.io.iss_alu.valid.expect(false.B) 
      println("  -> Pass: Instruction is waiting.")
      c.clock.step(1)

      // 模拟前一条指令刚好算完，通过 CDB 广播 p5
      println("  -> Broadcasting p5 on CDB 0")
      c.io.cdb(0).valid.poke(true.B)
      c.io.cdb(0).bits.p_rd.poke(5.U)
      
      // 【高能时刻】：在同一周期，由于我们设计的旁路唤醒网络，iss_alu 会立刻变高！
      c.io.iss_alu.valid.expect(true.B)
      c.io.iss_alu.bits.p_rd.expect(11.U)
      
      c.clock.step(1)
      resetInputs(c)
      c.io.iss_alu.valid.expect(false.B)

      // ==========================================================
      // Phase 3: 双路并发发射 (Dual Issue)
      // 测试能否在同一个周期内，让 ALU 和 LSU 各拉走一条指令
      // ==========================================================
      println("[Phase 3] Testing Dual Issue (ALU + LSU)")
      
      // 故意拉低 ready，把两条指令“憋”在队列里
      c.io.iss_alu.ready.poke(false.B)
      c.io.iss_lsu.ready.poke(false.B)

      // 进队一条 ALU 指令 (就绪)
      c.io.enq.valid.poke(true.B)
      c.io.enq.bits.fu_code.poke(FC_ALU)
      c.io.enq.bits.p_rd.poke(12.U)
      c.io.enq.bits.prs1_ready.poke(true.B)
      c.io.enq.bits.prs2_ready.poke(true.B)
      c.clock.step(1)

      // 进队一条 LSU 指令 (就绪)
      c.io.enq.valid.poke(true.B)
      c.io.enq.bits.fu_code.poke(FC_MEM) // 注意这是 MEM 编码
      c.io.enq.bits.p_rd.poke(13.U)
      c.io.enq.bits.prs1_ready.poke(true.B)
      c.io.enq.bits.prs2_ready.poke(true.B)
      c.clock.step(1)
      resetInputs(c)

      // 恢复下游通畅
      c.io.iss_alu.ready.poke(true.B)
      c.io.iss_lsu.ready.poke(true.B)

         println(s"\n==========================================")
      println(s"🔍 DUAL ISSUE DIAGNOSTICS REPORT")
      println(s"==========================================")
      println(s"[1] Slot Status:")
      println(s"    Slot 0: Valid=${c.io.dbg_slot0_valid.peek().litToBoolean}, Ready=${c.io.dbg_slot0_ready.peek().litToBoolean}, FU=${c.io.dbg_slot0_fu.peek().litValue}")
      println(s"    Slot 1: Valid=${c.io.dbg_slot1_valid.peek().litToBoolean}, Ready=${c.io.dbg_slot1_ready.peek().litToBoolean}, FU=${c.io.dbg_slot1_fu.peek().litValue}")
      
      println(s"\n[2] Type Classification:")
      println(s"    Slot 0 is ALU? = ${c.io.dbg_slot0_is_alu.peek().litToBoolean}")
      println(s"    Slot 0 is LSU? = ${c.io.dbg_slot0_is_lsu.peek().litToBoolean}  <-- 如果这是true，你条件写错了")
      println(s"    Slot 1 is ALU? = ${c.io.dbg_slot1_is_alu.peek().litToBoolean}")
      println(s"    Slot 1 is LSU? = ${c.io.dbg_slot1_is_lsu.peek().litToBoolean}")
      
      println(s"\n[3] Arbiter Requests (The Inputs to PriorityEncoder):")
      println(s"    ALU Reqs:[Slot0: ${c.io.dbg_alu_req_0.peek().litToBoolean}, Slot1: ${c.io.dbg_alu_req_1.peek().litToBoolean}]")
      println(s"    LSU Reqs:[Slot0: ${c.io.dbg_lsu_req_0.peek().litToBoolean}, Slot1: ${c.io.dbg_lsu_req_1.peek().litToBoolean}]  <-- 如果Slot0是true，你连错线了")
      
      println(s"\n[4] Arbiter Outputs:")
      println(s"    ALU Picked Index: ${c.io.dbg_sel_alu_idx.peek().litValue} (Can Issue: ${c.io.dbg_can_iss_alu.peek().litToBoolean})")
      println(s"    LSU Picked Index: ${c.io.dbg_sel_lsu_idx.peek().litValue} (Can Issue: ${c.io.dbg_can_iss_lsu.peek().litToBoolean})")
      println(s"==========================================\n")
      // 验证两条流水线同时开工！
      println("  -> Checking simultaneous issue...")
      c.io.iss_alu.valid.expect(true.B)
      c.io.iss_alu.bits.p_rd.expect(12.U)
      
      c.io.iss_lsu.valid.expect(true.B)
      c.io.iss_lsu.bits.p_rd.expect(13.U)

      c.clock.step(1)

      // ==========================================================
      // Phase 4: 流水线冲刷 (Pipeline Flush)
      // 分支预测失败时，队列里未发射的废弃指令必须瞬间清零
      // ==========================================================
      println("[Phase 4] Testing Pipeline Flush")
      
      // 塞入指令并让它等 p8
      c.io.enq.valid.poke(true.B)
      c.io.enq.bits.fu_code.poke(FC_ALU)
      c.io.enq.bits.p_rd.poke(14.U)
      c.io.enq.bits.use_rs1.poke(true.B)
      c.io.enq.bits.p_rs1.poke(8.U) 
      c.io.enq.bits.prs1_ready.poke(false.B)
      c.clock.step(1)
      resetInputs(c)

      // 触发全流水线冲刷
      c.io.flush.poke(true.B)
      c.clock.step(1)
      resetInputs(c)

      // 模拟迟来的 CDB 唤醒了 p8 
      // 验证这不会让刚才被冲刷的指令“诈尸”
      c.io.cdb(0).valid.poke(true.B)
      c.io.cdb(0).bits.p_rd.poke(8.U) 
      
      c.io.iss_alu.valid.expect(false.B)
      println("  -> Pass: Ignored wakeup after flush.")

      println("🚀 All Issue Queue Tests Passed!")
    }
  }
}