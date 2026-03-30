# Baby R10k — RV64I 双发射乱序超标量处理器

基于 Chisel/Scala 独立实现的 RISC-V 64位双发射乱序超标量处理器核，微架构参考 MIPS R10000 与 Berkeley BOOM 设计。

---

## 项目概述

本项目从零开始独立设计并实现了一款面向 FPGA（PYNQ-Z2，xc7z020）的乱序超标量处理器原型。核心目标是完整实现乱序执行的三个根基机制：**显式寄存器重命名、数据驱动的动态调度、精确异常与顺序提交**。

---

## 核心微架构特性

### 寄存器重命名（Register Renaming）
- 基于 RAT（寄存器别名表）+ Bit-Vector FreeList 实现显式物理寄存器重命名
- 通过定制旁路网络解决双发射组内 RAW/WAW 冒险，支持 0 周期级联重命名
- 采用 stale_p_rd 机制在 Commit 阶段精确回收物理寄存器

### 动态乱序发射（Out-of-Order Issue）
- 基于双路 CDB（公共数据总线）的动态唤醒网络，支持背靠背执行
- ALU 与 LSU 独立发射队列，双路并行仲裁器，最大化执行单元利用率
- 入队时检查 CDB 广播状态，避免操作数就绪指令入队死锁

### 精确异常与顺序提交（Precise Exception）
- 双路 Commit 的 ROB（重排序缓冲区），强制顺序提交保证精确异常语义
- 支持分支跳转与异常两类 Flush，分别在 ALU 执行阶段与 ROB Commit 阶段触发
- ROB Walk 机制逐条回滚 RAT 状态与 FreeList，精确恢复架构状态

### 访存子系统（Memory Subsystem）
- 读写分离访存管线，Store Buffer 机制保证乱序执行下内存写入的顺序一致性
- 以 TileLink 总线 ACK 信号驱动 Store 出队，确保写回完成后才释放资源
- 采用保守 Load 策略，Store Buffer 非空时阻止 Load 发射，规避内存地址别名消解的硬件开销

---

## 技术栈

| 类别 | 工具 |
|---|---|
| 硬件描述语言 | Chisel/Scala |
| 仿真框架 | Verilator + ChiselTest |
| 构建系统 | Mill |
| 综合布线 | Vivado 2024.1 |
| 目标器件 | Xilinx xc7z020（PYNQ-Z2） |
| 指令集架构 | RISC-V RV64I |

---

## FPGA 综合结果

目标器件：**Xilinx xc7z020clg400-1**

| 指标 | 数值 |
|---|---|
| 时钟频率 | **67 MHz** |
| Slice LUT 占用 | 11866 / 53200（**22.3%**） |
| Slice 占用 | 4611 / 13300（**34.7%**） |
| Slice Register 占用 | 5820 / 106400（**5.47%**） |
| Block RAM | 0%（全部使用 Distributed RAM） |

### 时序分析

| 指标 | 数值 |
|---|---|
| 时钟约束 | 15ns（67MHz） |
| WNS | 0.175ns（时序收敛） |
| 关键路径总延迟 | 14.457ns |
| 逻辑延迟 | 2.199ns（15.2%） |
| 布线延迟 | 12.258ns（**84.8%**） |

### 关键路径分析

关键路径位于 **Rename-to-Dispatch 跨模块组合逻辑链**，从前端取指队列出队指针出发，经过 Decode、RAT 查找、FreeList 判断，到达 Issue Queue 槽位写入，跨越三个主要模块。

主要瓶颈：`slot_uop_valid` 信号扇出达 **137**，单条网线布线延迟 2.690ns，占整条路径的 18.6%。

**优化方向**：
- 在 Rename 与 Dispatch 之间插入流水线寄存器，切断跨模块组合逻辑链
- 对高扇出信号进行寄存器复制
- 将寄存器文件迁移至 Block RAM，释放 Distributed RAM 资源

---

## 已知局限性

- 指令集：当前实现 RV64I，尚未支持 M 扩展（硬件乘除法器）和 C 扩展
- 无 Cache：直接访问片上 BRAM，访存延迟固定
- 无特权架构：尚未实现 CSR 和 M/U 模式切换，不能运行操作系统
- 无分支预测器：采用保守顺序取指策略，跳转确认后触发 Flush
- 验证：通过汇编程序和单模块单元测试验证基本正确性，尚未接入 DiffTest 和标准测试集

---

## 下一步计划

- 补全 RISC-V 特权架构（CSR、M/U 模式切换）
- 接入 DiffTest 框架与 riscv-tests 标准测试集
- 实现 ICache/DCache
- 实现 BTB + GShare 分支预测器
- 对关键路径进行流水线切割，目标主频 100MHz+

---

## 参考资料

- MIPS R10000 微架构论文：*The MIPS R10000 Superscalar Microprocessor*
- Berkeley BOOM：[https://github.com/riscv-boom/riscv-boom](https://github.com/riscv-boom/riscv-boom)
- RISC-V ISA 规范：[https://riscv.org/specifications/](https://riscv.org/specifications/)
