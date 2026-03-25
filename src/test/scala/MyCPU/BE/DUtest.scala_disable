package MyCPU.be

import chisel3._
import chisel3.util._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

// 导入你的项目依赖 (请根据实际包名调整)
import MyCPU.be._
import MyCPU.common._
import MyCPU.common.constants.ScalaOpConsts
import MyCPU.common.constants.RISCVConsts

class DecodeUnitTest 
extends AnyFlatSpec 
with ChiselScalatestTester 
{
  private object Consts
    extends MyCPU.common.constants.ScalaOpConsts
    with MyCPU.common.constants.RISCVConsts
  import Consts._
  // 1. 定义测试参数 (单发射)
  implicit val p = CoreParams(
    xLen = 64,
    fetchWidth = 1,
    decodeWidth = 1
  )

  "DecodeUnit" should "correctly decode instructions with FetchPacket" in {
    test(new DecodeUnit).withAnnotations(Seq(WriteVcdAnnotation)) { c =>
      
      // --- 初始化 ---
      c.io.enq.valid.poke(false.B)
      c.io.deq.ready.poke(true.B) // 模拟下游(Rename)永远准备好
      c.clock.step(1)

      // ----------------------------------------------------------
      // 测试用例 1: AUIPC x1, 0x12345 (U-Type)
      // 这个指令非常关键，因为它使用了 FetchPacket 里的 PC
      // ----------------------------------------------------------
      // Machine Code: 12345097 (rd=1, imm=0x12345)
      println("Testing AUIPC x1, 0x12345 ...")
      
      // 关键：同时 Poke 指令和 PC
      val test_pc = "h8000_1000"
      c.io.enq.bits(0).pc.poke(test_pc.U)          // 注入 PC
      c.io.enq.bits(0).inst.poke("h12345097".U)  // 注入指令
      c.io.enq.valid.poke(true.B)
      
      c.clock.step(1)

      // 验证
      c.io.deq.valid.expect(true.B)
      val uop = c.io.deq.bits(0)

      // AUIPC 的逻辑是: rd = PC + (Imm << 12)
      // 所以 OP1 应该是 PC，OP2 应该是 IMM
      uop.alu_op.expect(ALU_ADD)
      uop.op1_sel.expect(OP1_PC)   // <--- 验证这里是否选中了 PC
      uop.op2_sel.expect(OP2_IMM)
      
      // 验证 PC 是否透传正确
      uop.pc.expect(test_pc.U)
      // 验证立即数 (0x12345 << 12)
      uop.imm.expect("h0000000012345000".U) 
      uop.l_rd.expect(1.U)

      println("  -> AUIPC Pass!")

      // ----------------------------------------------------------
      // 测试用例 2: ADDI x2, x1, 1 (I-Type)
      // ----------------------------------------------------------
      println("Testing ADDI x2, x1, 1 ...")
      
      c.io.enq.bits(0).pc.poke((test_pc + 4).U) // PC 前进
      c.io.enq.bits(0).inst.poke("h00108113".U) // ADDI x2, x1, 1
      c.clock.step(1)

      uop.fu_code.expect(FC_ALU)
      uop.op1_sel.expect(OP1_RS1) // 普通指令用寄存器
      uop.op2_sel.expect(OP2_IMM)
      uop.l_rd.expect(2.U)
      uop.l_rs1.expect(1.U)
      uop.imm.expect(1.U)

      println("  -> ADDI Pass!")
      
      // ----------------------------------------------------------
      // 测试用例 3: JAL x1, offset (J-Type)
      // ----------------------------------------------------------
      // 这是一个跳转指令，同样依赖 PC
      println("Testing JAL ...")
      // JAL x1, 0 (死循环) -> 0000006F
      c.io.enq.bits(0).pc.poke("h8000_2000".U)
      c.io.enq.bits(0).inst.poke("h0000006F".U)
      c.clock.step(1)

      uop.br_type.expect(B_J.U)
      // JAL 的语义是: rd = PC + 4, 跳转到 PC + Imm
      // 在 Decode/ALU 阶段，通常计算的是 rd 的值
      uop.op1_sel.expect(OP1_PC)
      uop.op2_sel.expect(OP2_IMM) // 注意：这里 OP2 可能是常数4，取决于你的常量定义
                                  // 如果你定义 OP2_SIZE (4字节)，这里要改一下
      
      uop.l_rd.expect(0.U) // Link Register

      println("  -> JAL Pass!")
    }
  }
}