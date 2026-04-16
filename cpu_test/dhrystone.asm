
dhrystone.elf:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_start>:
    80000000:	00008137          	lui	sp,0x8
    80000004:	0011011b          	addiw	sp,sp,1 # 8001 <_start-0x7fff7fff>
    80000008:	01011113          	slli	sp,sp,0x10
    8000000c:	018000ef          	jal	80000024 <main>
    80000010:	00080337          	lui	t1,0x80
    80000014:	0013031b          	addiw	t1,t1,1 # 80001 <_start-0x7ff7ffff>
    80000018:	00c31313          	slli	t1,t1,0xc
    8000001c:	00a32023          	sw	a0,0(t1)
    80000020:	0000006f          	j	80000020 <_start+0x20>

0000000080000024 <main>:
    80000024:	00100513          	li	a0,1
    80000028:	00008067          	ret
