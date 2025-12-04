#!/bin/bash
# 通用椭圆曲线算术运算
# 支持多种椭圆曲线的模运算和点运算

set -euo pipefail

# 导入保护 - 防止重复定义
if [[ -n "${ECC_ARITHMETIC_LOADED:-}" ]]; then
    return 0
fi
readonly ECC_ARITHMETIC_LOADED=1

# 导入基础数学库
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/bash_math.sh"

# 大数模运算（适用于任意大小的模数）
# 参数: value (要约简的值), modulus (模数)
# 返回: value mod modulus
mod_reduce() {
    local value="$1"
    local modulus="$2"
    
    # 输入验证
    if [[ -z "$value" ]] || [[ -z "$modulus" ]]; then
        echo "错误: mod_reduce 需要两个参数" >&2
        return 1
    fi
    
    if [[ ! "$value" =~ ^[0-9]+$ ]] || [[ ! "$modulus" =~ ^[0-9]+$ ]]; then
        echo "错误: mod_reduce 参数必须是正整数" >&2
        return 1
    fi
    
    if [[ "$modulus" -eq 0 ]]; then
        echo "错误: 模数不能为零" >&2
        return 1
    fi
    
    # 使用bc进行大数模运算
    local result
    result=$(echo "$value % $modulus" | bc)
    
    # 确保结果为非负数
    if [[ "$result" -lt 0 ]]; then
        result=$(echo "$result + $modulus" | bc)
    fi
    
    echo "$result"
}

# 大数模加法
# 参数: a, b, modulus
# 返回: (a + b) mod modulus
mod_add() {
    local a="$1"
    local b="$2"
    local modulus="$3"
    
    # 输入验证
    if [[ -z "$a" ]] || [[ -z "$b" ]] || [[ -z "$modulus" ]]; then
        echo "错误: mod_add 需要三个参数" >&2
        return 1
    fi
    
    if [[ ! "$a" =~ ^[0-9]+$ ]] || [[ ! "$b" =~ ^[0-9]+$ ]] || [[ ! "$modulus" =~ ^[0-9]+$ ]]; then
        echo "错误: mod_add 参数必须是正整数" >&2
        return 1
    fi
    
    # 计算 (a + b) mod p
    local sum=$(echo "$a + $b" | bc)
    mod_reduce "$sum" "$modulus"
}

# 大数模减法
# 参数: a, b, modulus
# 返回: (a - b) mod modulus
mod_sub() {
    local a="$1"
    local b="$2"
    local modulus="$3"
    
    # 输入验证
    if [[ -z "$a" ]] || [[ -z "$b" ]] || [[ -z "$modulus" ]]; then
        echo "错误: mod_sub 需要三个参数" >&2
        return 1
    fi
    
    if [[ ! "$a" =~ ^[0-9]+$ ]] || [[ ! "$b" =~ ^[0-9]+$ ]] || [[ ! "$modulus" =~ ^[0-9]+$ ]]; then
        echo "错误: mod_sub 参数必须是正整数" >&2
        return 1
    fi
    
    # 计算 (a - b) mod p
    local diff=$(echo "$a - $b" | bc)
    mod_reduce "$diff" "$modulus"
}

# 大数模乘法
# 参数: a, b, modulus
# 返回: (a * b) mod modulus
mod_mul() {
    local a="$1"
    local b="$2"
    local modulus="$3"
    
    # 输入验证
    if [[ -z "$a" ]] || [[ -z "$b" ]] || [[ -z "$modulus" ]]; then
        echo "错误: mod_mul 需要三个参数" >&2
        return 1
    fi
    
    if [[ ! "$a" =~ ^[0-9]+$ ]] || [[ ! "$b" =~ ^[0-9]+$ ]] || [[ ! "$modulus" =~ ^[0-9]+$ ]]; then
        echo "错误: mod_mul 参数必须是正整数" >&2
        return 1
    fi
    
    # 计算 (a * b) mod p
    local product=$(echo "$a * $b" | bc)
    mod_reduce "$product" "$modulus"
}

# 大数模平方
# 参数: a, modulus
# 返回: (a^2) mod modulus
mod_square() {
    local a="$1"
    local modulus="$2"
    
    # 输入验证
    if [[ -z "$a" ]] || [[ -z "$modulus" ]]; then
        echo "错误: mod_square 需要两个参数" >&2
        return 1
    fi
    
    mod_mul "$a" "$a" "$modulus"
}

# 大数模幂运算（使用二进制指数算法）
# 参数: base, exponent, modulus
# 返回: (base^exponent) mod modulus
mod_pow() {
    local base="$1"
    local exponent="$2"
    local modulus="$3"
    
    # 输入验证
    if [[ -z "$base" ]] || [[ -z "$exponent" ]] || [[ -z "$modulus" ]]; then
        echo "错误: mod_pow 需要三个参数" >&2
        return 1
    fi
    
    if [[ ! "$base" =~ ^[0-9]+$ ]] || [[ ! "$exponent" =~ ^[0-9]+$ ]] || [[ ! "$modulus" =~ ^[0-9]+$ ]]; then
        echo "错误: mod_pow 参数必须是正整数" >&2
        return 1
    fi
    
    if [[ "$modulus" -eq 1 ]]; then
        echo "0"
        return 0
    fi
    
    # 使用bc的内置幂模运算（如果可用）
    # 否则使用二进制指数算法
    local result
    if command -v bc >/dev/null 2>&1 && echo "scale=0; $base^$exponent % $modulus" | bc >/dev/null 2>&1; then
        result=$(echo "scale=0; $base^$exponent % $modulus" | bc)
    else
        # 二进制指数算法实现
        result=1
        base=$(mod_reduce "$base" "$modulus")
        
        while [[ "$exponent" -gt 0 ]]; do
            if [[ $((exponent % 2)) -eq 1 ]]; then
                result=$(mod_mul "$result" "$base" "$modulus")
            fi
            base=$(mod_square "$base" "$modulus")
            exponent=$((exponent / 2))
        done
    fi
    
    echo "$result"
}

# 大数模逆运算（使用扩展欧几里得算法）
# 参数: a, modulus
# 返回: a^(-1) mod modulus
mod_inverse() {
    local a="$1"
    local modulus="$2"
    
    # 输入验证
    if [[ -z "$a" ]] || [[ -z "$modulus" ]]; then
        echo "错误: mod_inverse 需要两个参数" >&2
        return 1
    fi
    
    if [[ ! "$a" =~ ^[0-9]+$ ]] || [[ ! "$modulus" =~ ^[0-9]+$ ]]; then
        echo "错误: mod_inverse 参数必须是正整数" >&2
        return 1
    fi
    
    if [[ "$modulus" -lt 2 ]]; then
        echo "错误: 模数必须大于1" >&2
        return 1
    fi
    
    # 确保a在模数范围内
    a=$(mod_reduce "$a" "$modulus")
    
    if [[ "$a" -eq 0 ]]; then
        echo "错误: 零元素没有模逆元" >&2
        return 1
    fi
    
    # 扩展欧几里得算法
    local t=0
    local new_t=1
    local r="$modulus"
    local new_r="$a"
    
    while [[ "$new_r" -ne 0 ]]; do
        local quotient=$((r / new_r))
        
        # 交换t和new_t
        local temp_t="$t"
        t="$new_t"
        new_t=$(echo "$temp_t - $quotient * $new_t" | bc)
        
        # 交换r和new_r
        local temp_r="$r"
        r="$new_r"
        new_r=$(echo "$temp_r - $quotient * $new_r" | bc)
    done
    
    if [[ "$r" -gt 1 ]]; then
        echo "错误: $a 在模 $modulus 下没有逆元" >&2
        return 1
    fi
    
    if [[ "$t" -lt 0 ]]; then
        t=$(echo "$t + $modulus" | bc)
    fi
    
    echo "$t"
}

# 大数模除法
# 参数: a, b, modulus
# 返回: (a / b) mod modulus = (a * b^(-1)) mod modulus
mod_div() {
    local a="$1"
    local b="$2"
    local modulus="$3"
    
    # 输入验证
    if [[ -z "$a" ]] || [[ -z "$b" ]] || [[ -z "$modulus" ]]; then
        echo "错误: mod_div 需要三个参数" >&2
        return 1
    fi
    
    if [[ ! "$a" =~ ^[0-9]+$ ]] || [[ ! "$b" =~ ^[0-9]+$ ]] || [[ ! "$modulus" =~ ^[0-9]+$ ]]; then
        echo "错误: mod_div 参数必须是正整数" >&2
        return 1
    fi
    
    # 计算b的模逆元
    local b_inv
    b_inv=$(mod_inverse "$b" "$modulus")
    if [[ $? -ne 0 ]] || [[ -z "$b_inv" ]]; then
        return 1
    fi
    
    # 计算 (a * b^(-1)) mod modulus
    mod_mul "$a" "$b_inv" "$modulus"
}

# 验证模运算结果
validate_mod_operation() {
    local operation="$1"
    local expected="$2"
    local actual="$3"
    
    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo "错误: $operation 验证失败" >&2
        echo "期望值: $expected" >&2
        echo "实际值: $actual" >&2
        return 1
    fi
}

# 运行模运算基本测试
test_mod_arithmetic() {
    echo "测试模运算函数..."
    
    local test_passed=0
    local test_failed=0
    
    # 测试模约简
    local result
    result=$(mod_reduce "17" "5")
    if [[ "$result" == "2" ]]; then
        ((test_passed++))
    else
        ((test_failed++))
        echo "mod_reduce(17, 5) 失败: 期望 2, 得到 $result"
    fi
    
    # 测试模加法
    result=$(mod_add "3" "4" "5")
    if [[ "$result" == "2" ]]; then
        ((test_passed++))
    else
        ((test_failed++))
        echo "mod_add(3, 4, 5) 失败: 期望 2, 得到 $result"
    fi
    
    # 测试模减法
    result=$(mod_sub "3" "4" "5")
    if [[ "$result" == "4" ]]; then
        ((test_passed++))
    else
        ((test_failed++))
        echo "mod_sub(3, 4, 5) 失败: 期望 4, 得到 $result"
    fi
    
    # 测试模乘法
    result=$(mod_mul "3" "4" "5")
    if [[ "$result" == "2" ]]; then
        ((test_passed++))
    else
        ((test_failed++))
        echo "mod_mul(3, 4, 5) 失败: 期望 2, 得到 $result"
    fi
    
    # 测试模平方
    result=$(mod_square "3" "5")
    if [[ "$result" == "4" ]]; then
        ((test_passed++))
    else
        ((test_failed++))
        echo "mod_square(3, 5) 失败: 期望 4, 得到 $result"
    fi
    
    # 测试模幂运算
    result=$(mod_pow "2" "3" "5")
    if [[ "$result" == "3" ]]; then
        ((test_passed++))
    else
        ((test_failed++))
        echo "mod_pow(2, 3, 5) 失败: 期望 3, 得到 $result"
    fi
    
    # 测试模逆运算
    result=$(mod_inverse "3" "5")
    if [[ "$result" == "2" ]]; then
        ((test_passed++))
    else
        ((test_failed++))
        echo "mod_inverse(3, 5) 失败: 期望 2, 得到 $result"
    fi
    
    # 测试模除法
    result=$(mod_div "4" "3" "5")
    if [[ "$result" == "3" ]]; then
        ((test_passed++))
    else
        ((test_failed++))
        echo "mod_div(4, 3, 5) 失败: 期望 3, 得到 $result"
    fi
    
    echo "模运算测试完成: 通过 $test_passed, 失败 $test_failed"
    
    if [[ $test_failed -gt 0 ]]; then
        return 1
    fi
    
    return 0
}