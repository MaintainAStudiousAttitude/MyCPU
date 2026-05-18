package MyCPU.common

import chisel3._
import chisel3.util._

case class CoreParams(
  xLen: Int = 64,
  numLRegs: Int = 32,
  numPRegs: Int = 64,
  numRobEntries: Int = 8,
  numIssueEntries: Int = 4,
  hasFPU: Boolean = false,
  fetchWidth: Int = 2,
  decodeWidth: Int = 2
) {
  // --- 辅助方法 (Helpers) ---
  // 这些方法可以帮助你在其他模块中快速计算位宽，避免到处写 log2Ceil

  def xBytes: Int = xLen / 8
  
  // 物理寄存器索引的位宽 (例如 64个寄存器 -> 6 bits)
  def pRegBits: Int = log2Ceil(numPRegs)
  
  // 逻辑寄存器索引的位宽 (通常 5 bits)
  def lRegBits: Int = log2Ceil(numLRegs)
  
  // ROB 索引位宽
  def robBits: Int = log2Ceil(numRobEntries)
  
  // 检查是否是 RV64
  def is64Bit: Boolean = xLen == 64

  def GetRd(inst: UInt): UInt = inst(11, 7)

  def GetRs1(inst: UInt): UInt = inst(19, 15)

  def GetRs2(inst: UInt): UInt = inst(24, 20)
}