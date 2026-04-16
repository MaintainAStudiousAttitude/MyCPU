# 1. 编译并提取 bin
riscv64-unknown-elf-gcc -march=rv64i -mabi=lp64 -mcmodel=medany \
  -ffreestanding -nostdlib -O1 \
  -T link.ld crt0.S main.c -o dhrystone.elf

riscv64-unknown-elf-objcopy -O binary dhrystone.elf dhrystone.bin

# 2. 完美的 Python 转换脚本
python3 -c '
import sys
with open("dhrystone.bin", "rb") as f:
    while (b := f.read(8)):
        # 单独拎出来转换，完美避开 f-string 内部的引号冲突
        val = int.from_bytes(b, byteorder="little")
        print(f"{val:016x}")
' > dhrystone.hex

# 3. 查看生成结果
head -n 5 dhrystone.hex
