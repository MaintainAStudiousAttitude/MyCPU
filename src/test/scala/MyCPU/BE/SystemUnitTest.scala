package MyCPU

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec
import MyCPU.common._

class SystemUnitTest extends AnyFlatSpec with ChiselScalatestTester {
  
  implicit val p = CoreParams(
    xLen = 64, 
    numLRegs = 32, 
    numPRegs = 64, 
    numRobEntries = 16, // 小 ROB 方便观测
    numIssueEntries = 8,
    fetchWidth = 2, 
    decodeWidth = 2
  )

  // 我们手工汇编的那个“循环计数并存内存”的程序
  /**
   * ======================================================================
   * 测试程序：斐波那契数列生成器 (C 语言等效代码)
   * ======================================================================
   * long long* ptr = (long long*) 0x10000;
   * ptr[0] = 0;
   * ptr[1] = 1;
   * long long i = 2;
   * long long max = 10;
   * long long* curr_ptr = ptr + 2;
   * 
   * loop:
   *   if (i == max) goto end;
   *   *curr_ptr = *(curr_ptr - 1) + *(curr_ptr - 2);
   *   i++;
   *   curr_ptr++;
   *   goto loop;
   * end:
   *   while(1);
   * ======================================================================
   */
  val fibonacciProgram = Seq(
   0x000101b7L, // [0] 00: LUI  x3, 0x10       -> x3 = 0x10000 (Base Addr)
    0x00000213L, //[1] 04: ADDI x4, x0, 0      -> x4 = 0
    0x00100293L, // [2] 08: ADDI x5, x0, 1      -> x5 = 1
    0x0041b023L, // [3] 0C: SD   x4, 0(x3)      -> mem[0] = 0
    0x0051b423L, // [4] 10: SD   x5, 8(x3)      -> mem[1] = 1
    0x00200313L, // [5] 14: ADDI x6, x0, 2      -> x6 = 2 (计数器 i)
    0x00a00393L, // [6] 18: ADDI x7, x0, 10     -> x7 = 10 (上限 max)
    0x01018413L, // [7] 1C: ADDI x8, x3, 16     -> x8 = 0x10010 (当前指针 ptr)

    // 循环体 (Loop)  <-- PC = 0x8000_0020
    0x02730063L, //[8] 20: BEQ  x6, x7, +32    -> 如果 i==10, 跳出循环 (跳到 40: End)
    0xff843483L, // [9] 24: LD   x9, -8(x8)     -> x9 = mem[i-1]
    0xff043503L, // [A] 28: LD   x10, -16(x8)   -> x10 = mem[i-2]
    0x00a485b3L, // [B] 2C: ADD  x11, x9, x10   -> x11 = x9 + x10
    0x00b43023L, // [C] 30: SD   x11, 0(x8)     -> mem[i] = x11
    0x00130313L, // [D] 34: ADDI x6, x6, 1      -> i++
    0x00840413L, // [E] 38: ADDI x8, x8, 8      -> ptr += 8
    
    // ✅ 修复的行：JAL x0, -28 (跳回 0x8000_0020)
    0xfe5ff06fL,    // [F] 3C: JAL  x0, -28 

    // 结束 (End)    <-- PC = 0x8000_0040
    0x0000006fL  // [10] 40: JAL  x0, 0          -> 死循环停机
  )

  "MyCoreTop" should "execute Fibonacci program and handle out-of-order memory updates" in {
    // 设置超时周期长一点，因为乱序核分支预测失败的冲刷惩罚比较大
    test(new SystemTop(fibonacciProgram)).withAnnotations(Seq(WriteVcdAnnotation)) { c =>
      
      println("==========================================================")
      println("🚀 System Booting: Baby R10k Out-of-Order Core")
      println("==========================================================")
      
      // 斐波那契生成 10 个数，循环 8 次，加上 Flush 惩罚，大概需要 300 个周期
      var timeout = 500
      var pc_val = 0L
      
      // 监控死循环指令 (0x0000006f)，如果执行到了说明程序正常结束
      // 注意：我们在测试台无法直接读内部 PC，所以在外层固定步进 300 拍
      println("Executing instructions... Please wait...")
      c.clock.step(300)

      println("\n==========================================================")
      println("📊 Execution Finished. Inspecting D-Cache Memory:")
      println("==========================================================")
      
      // 预期的斐波那契数列 (前 10 项)
      val expected_fib = Seq(0, 1, 1, 2, 3, 5, 8, 13, 21, 34)
      
      var all_passed = true

      for (i <- 0 until 10) {
        // 读取 MockDMem 中导出的内部数组
        val mem_val = c.io.debug_mem(i).peek().litValue
        val expected = expected_fib(i)
        
        val status = if (mem_val == expected) "✅ PASS" else "❌ FAIL"
        if (mem_val != expected) all_passed = false

        println(f"  Mem[0x1000${i * 8}%02X] = $mem_val%4d  (Expected: $expected%4d) $status")
        
        // 硬件断言
        c.io.debug_mem(i).expect(expected.U)
      }

      if (all_passed) {
        println("\n🎉🎉🎉 INCREDIBLE! YOUR OUT-OF-ORDER CPU IS FULLY ALIVE! 🎉🎉🎉")
        println("It successfully executed branches, memory loads/stores, and data forwarding!")
      } else {
        println("\n⚠️ Something went wrong. Check the VCD waveform for Deadlocks or Flush issues.")
      }
    }
  }
}