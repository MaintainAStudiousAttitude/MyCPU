package MyCPU.be



import chisel3._
import chisel3.util._

import MyCPU.common._

class ALUIO(implicit p: CoreParams)
extends Bundle
{
    val req = Flipped(Decoupled(new FuncUnitReq))

    val cdb = Valid(new CDBIO)

    val br_redirect = Output(Bool())
    val br_redirect_pc = Output(UInt(p.xLen.W))
    val br_redirect_rob_id = Output(UInt(p.robBits.W))

    val br_resolved       = Output(Bool()) 

    val br_res = Output(Valid(new BranchResolution))
}

class ALU_Unit(implicit p: CoreParams)
extends Module
with MyCPU.common.constants.ScalaOpConsts
with MyCPU.common.constants.RISCVConsts
{
    val io = IO(new ALUIO)

    val req_valid = io.req.valid
    val uop = io.req.bits.uop
    val rs1_data = io.req.bits.rs1_data
    val rs2_data = io.req.bits.rs2_data

    io.req.ready := true.B

    val op1 = MuxLookup(uop.op1_sel, rs1_data) (Seq(
       OP1_RS1.U  -> rs1_data,
       OP1_PC.U   -> uop.pc,
       OP1_ZERO.U -> 0.U
    ))

     val op2 = MuxLookup(uop.op2_sel, rs2_data)(Seq(
       OP2_RS2.U  -> rs2_data,
       OP2_IMM.U  -> uop.imm,
       OP2_FOUR.U -> 4.U
    ))

    val shamt = Mux(uop.is_w, op2(4, 0), op2(5, 0))

    val alu_out = MuxLookup(uop.alu_op, 0.U)(Seq(
       ALU_ADD.U  -> (op1 + op2),
       ALU_SUB.U  -> (op1 - op2),
       ALU_AND.U  -> (op1 & op2),
       ALU_OR.U   -> (op1 | op2),
       ALU_XOR.U  -> (op1 ^ op2),
       ALU_SLL.U  -> (op1 << shamt)(p.xLen-1, 0),
       ALU_SRL.U  -> (op1 >> shamt),
       ALU_SRA.U  -> (op1.asSInt >> shamt).asUInt,
       ALU_SLT.U  -> (op1.asSInt < op2.asSInt).asUInt, // 有符号比较
       ALU_SLTU.U -> (op1 < op2).asUInt                // 无符号比较
    ))

    val alu_out_final = Mux(uop.is_w, alu_out(31, 0).asSInt.pad(p.xLen).asUInt, alu_out)

    val is_eq  = rs1_data === rs2_data
    val is_lt  = rs1_data.asSInt < rs2_data.asSInt
    val is_ltu = rs1_data < rs2_data

    val is_taken = MuxLookup(uop.br_type, false.B)(Seq(
        B_EQ.U  -> is_eq,
        B_NE.U  -> !is_eq,
        B_LT.U  -> is_lt,
        B_GE.U  -> !is_lt,
        B_LTU.U -> is_ltu,
        B_GEU.U -> !is_ltu,
        B_J.U   -> true.B, // JAL 无条件跳
        B_JR.U  -> true.B  // JALR 无条件跳
    ))

    val target_pc = Mux(uop.br_type === B_JR.U,
                        (rs1_data + uop.imm) & ~(1.U(p.xLen.W)),
                        uop.pc + uop.imm)

    val is_mispredict = uop.is_br && is_taken
    val is_jump = uop.br_type === B_J.U || uop.br_type === B_JR.U

    io.br_redirect := req_valid && (is_mispredict || is_jump)
    io.br_redirect_pc := target_pc
    io.br_redirect_rob_id := uop.rob_idx

    io.br_resolved        := req_valid && (uop.is_br || is_jump)

    io.br_res.valid := req_valid && (uop.is_br || is_jump)
    io.br_res.bits.mispredicted := (is_mispredict || is_jump)
    io.br_res.bits.rob_idx := uop.rob_idx

    io.cdb.valid := req_valid
    io.cdb.bits.rob_idx := uop.rob_idx
    io.cdb.bits.p_rd := uop.p_rd
    io.cdb.bits.exc := uop.exception

    io.cdb.bits.data := Mux((uop.br_type === B_J.U) || (uop.br_type === B_JR.U), 
                            uop.pc + 4.U,
                            alu_out_final)

    when (io.req.valid) { // 只要有请求进来就打印
    printf("[ALU] PC: 0x%x | OP1: %d | OP2: %d | Result: %d | is_mispredict: %b\n", 
      uop.pc, op1, op2, alu_out_final, is_mispredict)
  }                     
}