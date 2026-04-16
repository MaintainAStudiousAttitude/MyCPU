package MyCPU
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec
import MyCPU.common._  // 必须导入配置类

//class BenchmarkSpec extends AnyFlatSpec with ChiselScalatestTester {
//  behavior of "Baby R10k"
//
//  it should "run benchmark" in {
//    // === 关键点：在这里给出一个全局的参数实例 ===
//    implicit val p = CoreParams() 
//    
//    test(new TestHarness("src/test/resources/dhrystone.hex")) { dut =>
//       // ... 之前的 peek() 和 clock.step() 逻辑
//    }
//  }
//}
class BenchmarkSpec extends AnyFlatSpec with ChiselScalatestTester {
  behavior of "Baby R10k on Bare-metal Benchmark"

  it should "execute Dhrystone and calculate IPC" in {
    implicit val p = CoreParams() 
    // 假设你的 C 代码已经编译为 dhrystone.hex
    test(new TestHarness("/home/nalchr/Code/ChaoZuoGou/MyCPU/src/test/resources/dhrystone.hex"))
      .withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      
      dut.clock.setTimeout(100000) // 放大超时时间，Dhrystone 可能会跑几十万拍

      println("🚀 [Simulation Started] Running Dhrystone benchmark...")

      // 时钟步进，监听 halt 信号
      while(!dut.io.halt.peek().litToBoolean) {
        dut.clock.step(1)
      }

      // 仿真结束，采集数据
      val success  = dut.io.success.peek().litToBoolean
      val mcycle   = dut.io.ipc_mcycle.peek().litValue
      val minstret = dut.io.ipc_minstret.peek().litValue
      
      val ipc = minstret.toDouble / mcycle.toDouble

      println("==========================================")
      if (success) {
        println("✅ [Status] Program Terminated SUCCESSFULLY")
      } else {
        println("❌ [Status] Program Terminated with ERROR")
      }
      println(f"⏱️  [Cycles]   $mcycle")
      println(f"📦[Instrs]   $minstret")
      println(f"🚀 [IPC]      $ipc%.3f")
      println("==========================================")
      
      assert(success, "Benchmark failed according to tohost value.")
    }
  }
}