package MyCPU.common

import chisel3._
import chisel3.util._

import MyCPU.common.CoreParams

class MicroOp(implicit p: CoreParams)
extends Bundle
with MyCPU.common.constants.ScalaOpConsts
with MyCPU.common.constants.RISCVConsts
{
    // flow info
    val valid = Bool()
    val pc = UInt(p.xLen.W)
    val inst = UInt(32.W)

    //decode info
    val fu_code = UInt(FC_SZ.W)
    val alu_op = UInt(ALU_SZ.W)

    val op1_sel = UInt(2.W)
    val op2_sel = UInt(3.W)

    val imm = UInt(p.xLen.W)
    val imm_sel = UInt(3.W)

    val is_w = Bool()

    val mem_cmd = UInt(MC_SZ.W)
    val mem_size = UInt(2.W) 
    val mem_signed = Bool()

    val br_type = UInt(4.W)
    //def is_br = br_type.isOneOf(B_NE, B_EQ, B_GE, B_GEU, B_LT, B_LTU)
    def is_br = Seq(B_NE, B_EQ, B_GE, B_GEU, B_LT, B_LTU).map(br_type === _.U).reduce(_ || _)
    def is_jal = br_type === B_J.U
    def is_jalr = br_type === B_JR.U


    //reg info
    val l_rd = UInt(5.W)
    val l_rs1 = UInt(5.W)
    val l_rs2 = UInt(5.W)

    //reg value
    val rf_wen = Bool()
    val use_rs1 = Bool()
    val use_rs2 = Bool()

    //Rename
    val p_rd = UInt(log2Ceil(p.numPRegs).W)
    val p_rs1 = UInt(log2Ceil(p.numPRegs).W)
    val p_rs2 = UInt(log2Ceil(p.numPRegs).W)
    //rename reg ready
    val prs1_ready = Bool()
    val prs2_ready = Bool()
    
    //stale phy reg
    val stale_p_rd = UInt(log2Ceil(p.numPRegs).W)

    //scheduler info 
    //rob
    val rob_idx = UInt(log2Ceil(p.numRobEntries).W)

    //exception
    val exception = Bool()
    val exc_cause = UInt(p.xLen.W)
}