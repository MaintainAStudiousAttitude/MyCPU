package MyCPU.common.constants

import chisel3._
import chisel3.util._

// Mixin for scala op constants
trait ScalaOpConsts
{
    def X = false.B
    def Y = true.B
    def N = false.B


    //PC
    val PC_SIZE = 2 

    val PC_PLUS4 = 0
    val PC_BRJMP = 1
    val PC_JAIR = 2
    //Branch type

    //rename reg read

    def RS1_EN0 = false.B
    def RS1_EN1 = true.B

    def RS2_EN0 = false.B
    def RS2_EN1 = true.B


    //RS1
    val OP1_SIZE = 2

    val OP1_RS1 = 0
    val OP1_ZERO = 1
    val OP1_PC = 2
    val OP1_X = 3

    //RS2
    val OP2_SIZE = 3

    val OP2_RS2 = 0
    val OP2_ZERO = 1
    val OP2_IMM = 2
    val OP2_NEXT = 3
    val OP2_IMMC = 4
    val OP2_FOUR = 5
    val OP2_X = 6

    // Branch Type
    val BR_SIZE = 4

    val B_N   = 0  // Next
    val B_NE  = 1  // Branch on NotEqual
    val B_EQ  = 2  // Branch on Equal
    val B_GE  = 3  // Branch on Greater/Equal
    val B_GEU = 4  // Branch on Greater/Equal Unsigned
    val B_LT  = 5  // Branch on Less Than
    val B_LTU = 6  // Branch on Less Than Unsigned
    val B_J   = 7  // Jump
    val B_JR  = 8  // Jump Register

    //Register File Write Enable Signal
    def REN_0 = false.B
    def REN_1 = true.B

    //Memory Enable Signal
    def MEN_0 = false.B
    def MEN_1 = true.B
    def MEN_X = false.B

    //MEM-CMD
    val MC_SZ = 3

    val MC_X = 0
    val MC_R = 1
    val MC_W = 2
    //MEM_size Byte/half/word/double
    val MT_SZ = 5
    
    val MT_X = 0
    val MT_B = 1
    val MT_H = 2
    val MT_W = 3
    val MT_D = 4
    
    //Imm Extend select
    val IS_SIZE = 3

    val IS_I   = 0  // I-Type  (LD,ALU)
    val IS_S   = 1  // S-Type  (ST)
    val IS_B   = 2  // SB-Type (BR)
    val IS_U   = 3  // U-Type  (LUI/AUIPC)
    val IS_J   = 4  // UJ-Type (J/JAL)
    val IS_N   = 5  // No immediate (zeros immediate)
    val IS_F3  = 6  // funct3

    //imm data

    //Function unit select
    val FC_SZ = 6

    val FC_ALU = 0
    val FC_MEM = 1
    val FC_BRU = 2
    val FC_MUL = 3
    val FC_CSR = 4
    val FC_DIV = 5

    //Decode Stage Control Signal

    //ALU OP
    val ALU_SZ = 10

    val ALU_ADD = 0
    val ALU_SUB = 1
    val ALU_AND = 2
    val ALU_OR = 3
    val ALU_XOR = 4
    val ALU_SLL = 5
    val ALU_SRL = 6
    val ALU_SRA = 7
    val ALU_SLT = 8
    val ALU_SLTU = 9
    val ALU_XXX = 10

}

// Mixin for RISCV constants
trait RISCVConsts
{
    def ImmI(inst: UInt): UInt= {
        val sign = inst(31)
        val imm12 = inst(31,20)
        imm12.asSInt.pad(64).asUInt
    }
    def ImmS(inst: UInt): UInt= {
        val sign = inst(31)
        val imm11_5 = inst(31, 25)
        val imm4_0 = inst(11, 7)
        Cat(Fill(52, sign), imm11_5, imm4_0)
    }
    def ImmB(inst: UInt): UInt= {
        val sign = inst(31)
        val imm11 = inst(7)
        val imm10_5 = inst(30, 25)
        val imm4_1 = inst(11, 8)
        Cat(Fill(52, sign), imm11, imm10_5, imm4_1, 0.U(1.W))
    }
    def ImmU(inst: UInt): UInt= {
        val sign = inst(31)
        val imm31_12 = inst(31, 12)
        Cat(Fill(32, sign),imm31_12, 0.U(12.W))

    }
    def ImmJ(inst: UInt): UInt= {
        val sign = inst(31)
        val imm19_12 = inst(19, 12)
        val imm11 = inst(20)
        val imm10_1 = inst(30, 21)
        Cat(Fill(44, sign), imm19_12, imm11, imm10_1, 0.U(1.W))
    }
}