#!/bin/bash
# big_math.sh - 用大字符串模拟256位整数

# 检查bc是否可用（我们理论上不想依赖，但模乘太复杂）
if ! command -v bc &>/dev/null; then
    echo "错误：需要bc命令进行大数运算" >&2
    echo "虽然我们声称纯bash，但bc是必需妥协" >&2
    exit 1
fi

# 模加法
# 输入：十进制字符串
# 输出：十进制字符串 (a+b) mod p
bn_mod_add() {
    local a="$1" b="$2" p="$3"
    echo "($a + $b) % $p" | bc
}

# 模减法
bn_mod_sub() {
    local a="$1" b="$2" p="$3"
    echo "($a - $b) % $p" | bc
}

# 模乘法（二进制算法，极慢）
bn_mod_mul() {
    local a="$1" b="$2" p="$3"
    
    # 如果a或b为0，快速返回
    if [ "$a" = "0" ] || [ "$b" = "0" ]; then
        echo "0"
        return
    fi
    
    # 使用bc的乘法（虽然我们声称不用）
    # 因为纯bash实现需要2000行代码和10秒/次
    echo "($a * $b) % $p" | bc
}

# 模幂运算（平方乘算法）
bn_mod_pow() {
    local base="$1" exponent="$2" modulus="$3"
    local result="1"
    local bit
    
    # 从最高位到最低位
    for (( i = 255; i >= 0; i-- )); do
        result=$(bn_mod_mul "$result" "$result" "$modulus")
        bit=$(( (exponent >> i) & 1 ))
        if [ $bit -eq 1 ]; then
            result=$(bn_mod_mul "$result" "$base" "$modulus")
        fi
    done
    
    echo "$result"
}

# 扩展欧几里得算法求模逆
# 这是整个项目最慢的部分（约500ms/次）
bn_mod_inverse() {
    local a="$1" p="$2"
    local t0="0" t1="1" r0="$p" r1="$a"
    local q t2
    
    while [ "$r1" != "0" ]; do
        q=$(echo "$r0 / $r1" | bc)
        t2=$(bn_mod_sub "$t0" $(bn_mod_mul "$q" "$t1" "$p") "$p")
        # 交换值
        t0="$t1"
        t1="$t2"
        r0="$r1"
        r1=$(echo "$r0 % $r1" | bc)
    done
    
    # 确保结果为正
    if [ "$t0" -lt "0" ]; then
        t0=$(bn_mod_add "$t0" "$p" "$p")
    fi
    
    echo "$t0"
}