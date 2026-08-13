package MyCPU

import chisel3._
import circt.stage.ChiselStage 
import MyCPU.common._
import scala.sys.process._  // 加这一行

object Elaborate extends App {
    println("🚀 正在将 Baby R10k 编译为 SystemVerilog...")
    implicit val p = CoreParams(
    xLen = 64,
    numLRegs = 32,
    numPRegs = 64,      
    numRobEntries = 16, 
    numIssueEntries = 8,
    fetchWidth = 2,     
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
  val sv2vResult = "sv2v BabyR10k_Core.sv -w BabyR10k_Core.v".!

  if (sv2vResult == 0) {
    // 删除中间 .sv 文件，只保留 .v
    "rm BabyR10k_Core.sv".!
    println("✅ 转换完成！请在项目根目录下查看 BabyR10k_Core.v")
  } else {
    println("❌ sv2v 转换失败，请确认已安装 sv2v：")
    println("   sudo apt install sv2v")
    println("   中间文件 BabyR10k_Core.sv 已保留")
  }
}