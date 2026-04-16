package MyCPU

import chisel3._
import circt.stage.ChiselStage 
import MyCPU.common._

object Elaborate extends App {
    println("🚀 正在将 Baby R10k 编译为 SystemVerilog...")
    implicit val p = CoreParams(
    xLen = 64,
    numLRegs = 32,
    numPRegs = 64,      // 64个物理寄存器
    numRobEntries = 16, // ROB 16项
    numIssueEntries = 8,// 发射队列 8项
    fetchWidth = 2,     // 先综合单发射版本保平安
    decodeWidth = 2
  )
  ChiselStage.emitSystemVerilogFile(
    new MyCoreTop,
    firtoolOpts = Array(
      "-disable-all-randomization", // 去掉 Chisel 自动生成的随机初始化噪声代码
      "-strip-debug-info",          // 去掉多余的调试信息，让代码更干净
      "-o", "BabyR10k_Core.sv"      // 指定输出文件名
    )
  )

  println("✅ 编译完成！请在项目根目录下查看 BabyR10k_Core.sv")
}