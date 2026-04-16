.section .text.init
.global _start

_start:
    /* 1. 初始化栈指针 (将栈放在 0x80010000，即 64KB 处) */
    li sp, 0x80010000
    
    /* 2. 跳转到 C 语言的 main 函数 */
    call main
    
    /* 3. main 函数返回后，把它的返回值写给 tohost (通知硬件停机) */
    li t1, 0x80001000
    sw a0, 0(t1)   /* a0 保存了 main 的返回值 */
    
1:  j 1b           /* 死循环，等待外壳停机 */
