int main() {
    int a = 0;
    int b = 1;
    int c = 0;
    
    // 计算斐波那契数列第 20 项
    for (int i = 0; i < 20; i++) {
        c = a + b;
        a = b;
        b = c;
    }
    
    // 验证结果是否正确: fib(20) = 10946
    if (c == 10946) {
        return 1; // 1 表示成功，将写入 tohost
    } else {
        return 2; // 非 1 表示失败 (算错了)
    }
}
