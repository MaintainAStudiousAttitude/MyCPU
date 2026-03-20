package MyCPU.be

import chisel3._
import chisel3.util._

import MyCPU.common._


//Fetch package time 



class DecodeIO(implicit p: CoreParams)
extends Bundle
{
    val enq = Flipped(Decoupled(Vec(p.fetchWidth, new FetchPacket)))

    val deq = Decoupled(Vec(p.decodeWidth, new MicroOp))
}

object DecodeTables 
  extends MyCPU.common.constants.ScalaOpConsts
{
    def DC(w:Int) = 0.U(w.W)

    def decode_default: List[Data] = List(N, DC(FC_SZ), DC(ALU_SZ), DC(2), DC(3), X, X, X, IS_N.asUInt, MC_X.U.asUInt, MT_X.asUInt, X, X)

    //bit module
    val LUI   = BitPat("b????????????????????_?????_0110111")
    val AUIPC = BitPat("b????????????????????_?????_0010111")

    // ==========================================
    // 2. 跳转指令 (Jumps)
    // ==========================================
    val JAL   = BitPat("b????????????????????_?????_1101111")
    val JALR  = BitPat("b????????????_?????_000_?????_1100111")

    // ==========================================
    // 3. 分支指令 (Branches)
    // ==========================================
    val BEQ   = BitPat("b????????????_?????_000_?????_1100011")
    val BNE   = BitPat("b????????????_?????_001_?????_1100011")
    val BLT   = BitPat("b????????????_?????_100_?????_1100011")
    val BGE   = BitPat("b????????????_?????_101_?????_1100011")
    val BLTU  = BitPat("b????????????_?????_110_?????_1100011")
    val BGEU  = BitPat("b????????????_?????_111_?????_1100011")

    // ==========================================
    // 4. 访存指令 (Loads & Stores)
    // ==========================================
    val LB    = BitPat("b????????????_?????_000_?????_0000011")
    val LH    = BitPat("b????????????_?????_001_?????_0000011")
    val LW    = BitPat("b????????????_?????_010_?????_0000011")
    val LD    = BitPat("b????????????_?????_011_?????_0000011")
    val LBU   = BitPat("b????????????_?????_100_?????_0000011")
    val LHU   = BitPat("b????????????_?????_101_?????_0000011")
    val LWU   = BitPat("b????????????_?????_110_?????_0000011")

    val SB    = BitPat("b????????????_?????_000_?????_0100011")
    val SH    = BitPat("b????????????_?????_001_?????_0100011")
    val SW    = BitPat("b????????????_?????_010_?????_0100011")
    val SD    = BitPat("b????????????_?????_011_?????_0100011")

    // ==========================================
    // 5. 立即数运算 (ALU Imm)
    // ==========================================
    val ADDI  = BitPat("b????????????_?????_000_?????_0010011")
    val SLTI  = BitPat("b????????????_?????_010_?????_0010011")
    val SLTIU = BitPat("b????????????_?????_011_?????_0010011")
    val XORI  = BitPat("b????????????_?????_100_?????_0010011")
    val ORI   = BitPat("b????????????_?????_110_?????_0010011")
    val ANDI  = BitPat("b????????????_?????_111_?????_0010011")
    // 注意：RV64 中 shift 的 shamt 是 6 位，所以 inst[25] 也属于 shamt 范围 (用 ? 代替)
    val SLLI  = BitPat("b000000?_?????_?????_001_?????_0010011")
    val SRLI  = BitPat("b000000?_?????_?????_101_?????_0010011")
    val SRAI  = BitPat("b010000?_?????_?????_101_?????_0010011")

    // ==========================================
    // 6. 寄存器运算 (ALU Reg)
    // ==========================================
    val ADD   = BitPat("b0000000_?????_?????_000_?????_0110011")
    val SUB   = BitPat("b0100000_?????_?????_000_?????_0110011")
    val SLL   = BitPat("b0000000_?????_?????_001_?????_0110011")
    val SLT   = BitPat("b0000000_?????_?????_010_?????_0110011")
    val SLTU  = BitPat("b0000000_?????_?????_011_?????_0110011")
    val XOR   = BitPat("b0000000_?????_?????_100_?????_0110011")
    val SRL   = BitPat("b0000000_?????_?????_101_?????_0110011")
    val SRA   = BitPat("b0100000_?????_?????_101_?????_0110011")
    val OR    = BitPat("b0000000_?????_?????_110_?????_0110011")
    val AND   = BitPat("b0000000_?????_?????_111_?????_0110011")

    // ==========================================
    // 7. RV64 特有的 32 位截断运算 (*W)
    // ==========================================
    val ADDIW = BitPat("b????????????_?????_000_?????_0011011")
    val SLLIW = BitPat("b0000000_?????_?????_001_?????_0011011") // 32位移位shamt仅5位
    val SRLIW = BitPat("b0000000_?????_?????_101_?????_0011011")
    val SRAIW = BitPat("b0100000_?????_?????_101_?????_0011011")
    
    val ADDW  = BitPat("b0000000_?????_?????_000_?????_0111011")
    val SUBW  = BitPat("b0100000_?????_?????_000_?????_0111011")
    val SLLW  = BitPat("b0000000_?????_?????_001_?????_0111011")
    val SRLW  = BitPat("b0000000_?????_?????_101_?????_0111011")
    val SRAW  = BitPat("b0100000_?????_?????_101_?????_0111011")

    /*val table: Array[(BitPat, List[Data])] = Array(
        //LEGAL, FU_TYPE, ALU_OP, OP1_SEL, OP2_SEL, RF_WEN, USE_RS1, USE_RS2, IMM_SEL, MEM_CMD, MEM_SIZE, MEM_SIGNED, IS_W
        ADD -> List(Y, FC_ALU.U, ALU_ADD.U, OP1_RS1.U, OP2_RS2.U, Y, Y, Y, IS_N.U, MC_X.U, MT_X.U, X, N),
        AUIPC -> List(Y, FC_ALU.U, ALU_ADD.U, OP1_PC.U, OP2_IMM.U, Y, N, N, IS_U.U, MC_X.U, MT_X.U, X, N),
        ADDI -> List(Y, FC_ALU.U, ALU_ADD.U, OP1_RS1.U, OP2_IMM.U, Y, Y, N, IS_I.U, MC_X.U, MT_X.U, X, N),
        JAL -> List(Y, FC_ALU.U, ALU_ADD.U, OP1_PC.U, OP2_IMM.U, Y, N, N, IS_J.U, MC_X.U, MT_X.U, N, N)
    )*/
    val table: Array[(BitPat, List[Data])] = Array(
        //      LEGAL, FU_TYPE,    ALU_OP,     OP1_SEL,    OP2_SEL,   RF_WEN, USE_RS1, USE_RS2, IMM_SEL, MEM_CMD, MEM_SIZE, MEM_SIGNED, IS_W
        // 1. LUI / AUIPC
        LUI   -> List(Y, FC_ALU.U, ALU_ADD.U,  OP1_ZERO.U, OP2_IMM.U, Y,      N,       N,       IS_U.U,  MC_X.U,   MT_X.U,   X,          N),
        AUIPC -> List(Y, FC_ALU.U, ALU_ADD.U,  OP1_PC.U,   OP2_IMM.U, Y,      N,       N,       IS_U.U,  MC_X.U,   MT_X.U,   X,          N),

        // 2. Jumps
        // 注意 JALR 需要读 RS1 (用于计算 PC = RS1 + IMM)
        JAL   -> List(Y, FC_ALU.U, ALU_ADD.U,  OP1_PC.U,   OP2_IMM.U, Y,      N,       N,       IS_J.U,  MC_X.U,   MT_X.U,   X,          N),
        JALR  -> List(Y, FC_ALU.U, ALU_ADD.U,  OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_X.U,   MT_X.U,   X,          N),

        // 3. Branches (分支指令不写回寄存器)
        BEQ   -> List(Y, FC_BRU.U, ALU_XXX.U,  OP1_RS1.U,  OP2_RS2.U, N,      Y,       Y,       IS_B.U,  MC_X.U,   MT_X.U,   X,          N),
        BNE   -> List(Y, FC_BRU.U, ALU_XXX.U,  OP1_RS1.U,  OP2_RS2.U, N,      Y,       Y,       IS_B.U,  MC_X.U,   MT_X.U,   X,          N),
        BLT   -> List(Y, FC_BRU.U, ALU_XXX.U,  OP1_RS1.U,  OP2_RS2.U, N,      Y,       Y,       IS_B.U,  MC_X.U,   MT_X.U,   X,          N),
        BGE   -> List(Y, FC_BRU.U, ALU_XXX.U,  OP1_RS1.U,  OP2_RS2.U, N,      Y,       Y,       IS_B.U,  MC_X.U,   MT_X.U,   X,          N),
        BLTU  -> List(Y, FC_BRU.U, ALU_XXX.U,  OP1_RS1.U,  OP2_RS2.U, N,      Y,       Y,       IS_B.U,  MC_X.U,   MT_X.U,   X,          N),
        BGEU  -> List(Y, FC_BRU.U, ALU_XXX.U,  OP1_RS1.U,  OP2_RS2.U, N,      Y,       Y,       IS_B.U,  MC_X.U,   MT_X.U,   X,          N),

        // 4. Loads
        LB    -> List(Y, FC_MEM.U, ALU_ADD.U,  OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_R.U, MT_B.U,   Y,          N),
        LH    -> List(Y, FC_MEM.U, ALU_ADD.U,  OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_R.U, MT_H.U,   Y,          N),
        LW    -> List(Y, FC_MEM.U, ALU_ADD.U,  OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_R.U, MT_W.U,   Y,          N),
        LD    -> List(Y, FC_MEM.U, ALU_ADD.U,  OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_R.U, MT_D.U,   Y,          N),
        LBU   -> List(Y, FC_MEM.U, ALU_ADD.U,  OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_R.U, MT_B.U,   N,          N),
        LHU   -> List(Y, FC_MEM.U, ALU_ADD.U,  OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_R.U, MT_H.U,   N,          N),
        LWU   -> List(Y, FC_MEM.U, ALU_ADD.U,  OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_R.U, MT_W.U,   N,          N),

        // 5. Stores (不写回寄存器，但需要读 RS1[Addr] 和 RS2[Data])
        SB    -> List(Y, FC_MEM.U, ALU_ADD.U,  OP1_RS1.U,  OP2_IMM.U, N,      Y,       Y,       IS_S.U,  MC_W.U, MT_B.U,   X,          N),
        SH    -> List(Y, FC_MEM.U, ALU_ADD.U,  OP1_RS1.U,  OP2_IMM.U, N,      Y,       Y,       IS_S.U,  MC_W.U, MT_H.U,   X,          N),
        SW    -> List(Y, FC_MEM.U, ALU_ADD.U,  OP1_RS1.U,  OP2_IMM.U, N,      Y,       Y,       IS_S.U,  MC_W.U, MT_W.U,   X,          N),
        SD    -> List(Y, FC_MEM.U, ALU_ADD.U,  OP1_RS1.U,  OP2_IMM.U, N,      Y,       Y,       IS_S.U,  MC_W.U, MT_D.U,   X,          N),

        // 6. ALU Immediates
        ADDI  -> List(Y, FC_ALU.U, ALU_ADD.U,  OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_X.U,   MT_X.U,   X,          N),
        SLTI  -> List(Y, FC_ALU.U, ALU_SLT.U,  OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_X.U,   MT_X.U,   X,          N),
        SLTIU -> List(Y, FC_ALU.U, ALU_SLTU.U, OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_X.U,   MT_X.U,   X,          N),
        XORI  -> List(Y, FC_ALU.U, ALU_XOR.U,  OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_X.U,   MT_X.U,   X,          N),
        ORI   -> List(Y, FC_ALU.U, ALU_OR.U,   OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_X.U,   MT_X.U,   X,          N),
        ANDI  -> List(Y, FC_ALU.U, ALU_AND.U,  OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_X.U,   MT_X.U,   X,          N),
        SLLI  -> List(Y, FC_ALU.U, ALU_SLL.U,  OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_X.U,   MT_X.U,   X,          N),
        SRLI  -> List(Y, FC_ALU.U, ALU_SRL.U,  OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_X.U,   MT_X.U,   X,          N),
        SRAI  -> List(Y, FC_ALU.U, ALU_SRA.U,  OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_X.U,   MT_X.U,   X,          N),

        // 7. ALU Registers
        ADD   -> List(Y, FC_ALU.U, ALU_ADD.U,  OP1_RS1.U,  OP2_RS2.U, Y,      Y,       Y,       IS_N.U,  MC_X.U,   MT_X.U,   X,          N),
        SUB   -> List(Y, FC_ALU.U, ALU_SUB.U,  OP1_RS1.U,  OP2_RS2.U, Y,      Y,       Y,       IS_N.U,  MC_X.U,   MT_X.U,   X,          N),
        SLL   -> List(Y, FC_ALU.U, ALU_SLL.U,  OP1_RS1.U,  OP2_RS2.U, Y,      Y,       Y,       IS_N.U,  MC_X.U,   MT_X.U,   X,          N),
        SLT   -> List(Y, FC_ALU.U, ALU_SLT.U,  OP1_RS1.U,  OP2_RS2.U, Y,      Y,       Y,       IS_N.U,  MC_X.U,   MT_X.U,   X,          N),
        SLTU  -> List(Y, FC_ALU.U, ALU_SLTU.U, OP1_RS1.U,  OP2_RS2.U, Y,      Y,       Y,       IS_N.U,  MC_X.U,   MT_X.U,   X,          N),
        XOR   -> List(Y, FC_ALU.U, ALU_XOR.U,  OP1_RS1.U,  OP2_RS2.U, Y,      Y,       Y,       IS_N.U,  MC_X.U,   MT_X.U,   X,          N),
        SRL   -> List(Y, FC_ALU.U, ALU_SRL.U,  OP1_RS1.U,  OP2_RS2.U, Y,      Y,       Y,       IS_N.U,  MC_X.U,   MT_X.U,   X,          N),
        SRA   -> List(Y, FC_ALU.U, ALU_SRA.U,  OP1_RS1.U,  OP2_RS2.U, Y,      Y,       Y,       IS_N.U,  MC_X.U,   MT_X.U,   X,          N),
        OR    -> List(Y, FC_ALU.U, ALU_OR.U,   OP1_RS1.U,  OP2_RS2.U, Y,      Y,       Y,       IS_N.U,  MC_X.U,   MT_X.U,   X,          N),
        AND   -> List(Y, FC_ALU.U, ALU_AND.U,  OP1_RS1.U,  OP2_RS2.U, Y,      Y,       Y,       IS_N.U,  MC_X.U,   MT_X.U,   X,          N),

        // 8. RV64 特有: 32位字操作 (*W)
        // 核心区别：最后一列 IS_W 为 Y (True)
        ADDIW -> List(Y, FC_ALU.U, ALU_ADD.U,  OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_X.U,   MT_X.U,   X,          Y),
        SLLIW -> List(Y, FC_ALU.U, ALU_SLL.U,  OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_X.U,   MT_X.U,   X,          Y),
        SRLIW -> List(Y, FC_ALU.U, ALU_SRL.U,  OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_X.U,   MT_X.U,   X,          Y),
        SRAIW -> List(Y, FC_ALU.U, ALU_SRA.U,  OP1_RS1.U,  OP2_IMM.U, Y,      Y,       N,       IS_I.U,  MC_X.U,   MT_X.U,   X,          Y),
        
        ADDW  -> List(Y, FC_ALU.U, ALU_ADD.U,  OP1_RS1.U,  OP2_RS2.U, Y,      Y,       Y,       IS_N.U,  MC_X.U,   MT_X.U,   X,          Y),
        SUBW  -> List(Y, FC_ALU.U, ALU_SUB.U,  OP1_RS1.U,  OP2_RS2.U, Y,      Y,       Y,       IS_N.U,  MC_X.U,   MT_X.U,   X,          Y),
        SLLW  -> List(Y, FC_ALU.U, ALU_SLL.U,  OP1_RS1.U,  OP2_RS2.U, Y,      Y,       Y,       IS_N.U,  MC_X.U,   MT_X.U,   X,          Y),
        SRLW  -> List(Y, FC_ALU.U, ALU_SRL.U,  OP1_RS1.U,  OP2_RS2.U, Y,      Y,       Y,       IS_N.U,  MC_X.U,   MT_X.U,   X,          Y),
        SRAW  -> List(Y, FC_ALU.U, ALU_SRA.U,  OP1_RS1.U,  OP2_RS2.U, Y,      Y,       Y,       IS_N.U,  MC_X.U,   MT_X.U,   X,          Y)
    )
}

class CtrlSigs(implicit p: CoreParams) 
extends Bundle
with MyCPU.common.constants.ScalaOpConsts
{
    val LEGAL = Bool()
    val FU_TYPE = UInt(FC_SZ.W)
    val ALU_OP = UInt(ALU_SZ.W)
    val OP1_SEL = UInt(2.W)
    val OP2_SEL = UInt(3.W)
    val RF_WEN = Bool()
    val USE_RS1 = Bool()
    val USE_RS2 = Bool()
    val IMM_SEL = UInt(IS_SIZE.W)
    val MEM_CMD = UInt(MC_SZ.W)
    val MEM_SIZE = UInt(6.W)
    val MEM_SIGNED = Bool()
    val IS_W = Bool()
    

    def decode(inst: UInt, table: Array[(BitPat, List[Data])]) = {
        val decoded = ListLookup(inst, DecodeTables.decode_default, table)

        LEGAL       := decoded(0)
        FU_TYPE     := decoded(1)
        ALU_OP      := decoded(2)
        OP1_SEL     := decoded(3)
        OP2_SEL     := decoded(4)
        RF_WEN      := decoded(5)
        USE_RS1     := decoded(6)
        USE_RS2     := decoded(7)
        IMM_SEL     := decoded(8)
        MEM_CMD     := decoded(9)
        MEM_SIZE    := decoded(10)
        MEM_SIGNED  := decoded(11)
        IS_W        := decoded(12)

        this
    }
}

object DecodeLogicCore
extends MyCPU.common.constants.ScalaOpConsts
with MyCPU.common.constants.RISCVConsts
{
    def apply(inst: UInt, pc: UInt, valid: Bool)(implicit p: CoreParams): MicroOp= {
        val uop = Wire(new MicroOp)
        val ctrl = Wire(new CtrlSigs)

        ctrl.decode(inst, DecodeTables.table)

        uop := DontCare
        uop.inst := inst
        uop.pc := pc

        uop.valid := ctrl.LEGAL && valid
        uop.fu_code := ctrl.FU_TYPE
        uop.alu_op  := ctrl.ALU_OP

        uop.op1_sel := ctrl.OP1_SEL
        uop.op2_sel := ctrl.OP2_SEL
        
        uop.imm_sel := ctrl.IMM_SEL
        val imm_generated = MuxLookup(ctrl.IMM_SEL, 0.U)(Seq(
            IS_I.U -> ImmI(inst),
            IS_S.U -> ImmS(inst),
            IS_B.U -> ImmB(inst),
            IS_U.U -> ImmU(inst),
            IS_J.U -> ImmJ(inst)
        )).asUInt
        uop.imm := imm_generated


        uop.is_w := ctrl.IS_W

        uop.mem_cmd := ctrl.MEM_CMD
        uop.mem_size := ctrl.MEM_SIZE
        uop.mem_signed := ctrl.MEM_SIGNED


        uop.l_rd := Mux(ctrl.RF_WEN, p.GetRd(inst), 0.U)
        uop.l_rs1 := Mux(ctrl.USE_RS1, p.GetRs1(inst), 0.U)
        uop.l_rs2 := Mux(ctrl.USE_RS2, p.GetRs2(inst), 0.U)

        uop.rf_wen := ctrl.RF_WEN
        uop.use_rs1 := ctrl.USE_RS1
        uop.use_rs2 := ctrl.USE_RS2

        //rename part
        uop.p_rd := 0.U
        uop.p_rs1 := 0.U
        uop.p_rs2 := 0.U

        uop.prs1_ready := false.B
        uop.prs2_ready := false.B

        uop.stale_p_rd := 0.U

        uop.rob_idx := 0.U

        uop.exception := !ctrl.LEGAL
        uop.exc_cause := 0.U(p.xLen.W)

        uop
    }
}


class DecodeUnit (implicit p :CoreParams)
extends Module
with MyCPU.common.constants.ScalaOpConsts
with MyCPU.common.constants.RISCVConsts
{
    val io = IO(new DecodeIO)
    
    for(w <- 0 until p.decodeWidth)
    {
        val in_pkg = io.enq.bits(w)

        val uop = DecodeLogicCore(in_pkg.inst, in_pkg.pc, in_pkg.valid)

        uop.br_type := Seq(
            (DecodeTables.BEQ  , B_EQ ),
            (DecodeTables.BNE  , B_NE ),
            (DecodeTables.BGE  , B_GE ),
            (DecodeTables.BGEU , B_GEU),
            (DecodeTables.BLT  , B_LT ),
            (DecodeTables.BLTU , B_LTU),
            (DecodeTables.JAL  , B_J  ),
            (DecodeTables.JALR , B_JR )
        ) .map { case (c, b) => Mux(in_pkg.inst === c, b.U, 0.U) } .reduce(_|_)
        io.deq.bits(w) := uop
    }
    io.enq.ready := io.deq.ready
    io.deq.valid := io.enq.valid
}

/*  need to do on next phase 
class BranchDecodeSignals(implicit p : CoreParams)
extends Bundle
{

}
*/ 
