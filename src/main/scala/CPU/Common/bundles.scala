package MyCPU.common

import chisel3._
import chisel3.util._

import MyCPU.common._

class FetchPacket(implicit p:CoreParams)
extends Bundle
{
    val inst = UInt(32.W)
    val pc = UInt(p.xLen.W)
    val valid = Bool() // to deal with unaligned branch target

    //bp
    val pred_taken = Bool()
    val pred_target = UInt(p.xLen.W)
}

class BpuUpdate(implicit p: CoreParams)
extends Bundle
{
  val pc = UInt(p.xLen.W)
  val target = UInt(p.xLen.W)
  val taken = Bool()
  val br_type = UInt(p.br_type_w.W)
  val is_mispredict = Bool()

}
//ai ren qv ni men ying le
class CommitDebug(implicit p: CoreParams)
extends Bundle
{
  val valid = Bool()
  val pc     = UInt(p.xLen.W)
  val inst   = UInt(32.W)
  val l_rd   = UInt(5.W)
  val p_rd   = UInt(p.pRegBits.W)
  val rf_wen = Bool()
}

class CDBIO(implicit p: CoreParams)
extends Bundle
with MyCPU.common.constants.ScalaOpConsts
{
    val rob_idx = UInt(p.robBits.W)
    val p_rd = UInt(p.pRegBits.W)
    val data = UInt(p.xLen.W)
    val exc = Bool()

    //test
    val is_branch = Bool()
    val br_taken  = Bool()
    val br_target = UInt(p.xLen.W)
    val br_pc     = UInt(p.xLen.W)
    val br_type   = UInt(p.br_type_w.W)
}

class FuncUnitReq(implicit p: CoreParams)
extends Bundle
{
    val uop = new MicroOp
    val rs1_data = UInt(p.xLen.W)
    val rs2_data = UInt(p.xLen.W)
}

class BranchResolution(implicit p: CoreParams)
extends Bundle
{
    
    val mispredicted = Bool()
    val rob_idx = UInt(p.robBits.W)

}

class MemReq(implicit p: CoreParams) 
extends Bundle
with MyCPU.common.constants.ScalaOpConsts {
  val addr  = UInt(p.xLen.W)
  val data  = UInt(p.xLen.W) // Store用的数据
  val cmd   = UInt(MC_SZ.W)  // M_XRD (读) 或 M_XWR (写)
  val size  = UInt(2.W)      // MT_B, MT_H, MT_W, MT_D
}

// 访存响应
class MemResp(implicit p: CoreParams) extends Bundle {
  val data  = UInt(p.xLen.W) // Load返回的数据
}

// 内存总线接口
class SimpleMemIO(implicit p: CoreParams) extends Bundle {
  val req  = Decoupled(new MemReq)
  val resp = Flipped(Valid(new MemResp)) // 假设内存返回总是有效的(无乱序返回)
}