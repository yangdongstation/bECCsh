#!/bin/bash
# 简化的椭圆曲线数学运算修复版本

set -euo pipefail

# 导入基础数学库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/bash_math.sh"
source "${SCRIPT_DIR}/../../lib/bigint.sh"

# 简单的模运算函数
mod_simple() {
    local a="$1"
    local m="$2"
    
    # 处理负数
    if [[ "$a" =~ ^- ]]; then
        local pos_a="${a#-}"
        local mod_pos=$((pos_a % m))
        echo $((m - mod_pos))
    else
        echo $((a % m))
    fi
}

# 简单的模逆元函数 (扩展欧几里得算法)
mod_inverse_simple() {
    local a="$1"
    local m="$2"
    
    # 确保a是正数且在模范围内
    a=$(mod_simple "$a" "$m")
    
    # 扩展欧几里得算法
    local t=0
    local new_t=1
    local r="$m"
    local new_r="$a"
    
    while [[ "$new_r" -ne 0 ]]; do
        local quotient=$((r / new_r))
        
        # 交换t和new_t
        local temp_t="$t"
        t="$new_t"
        new_t=$((temp_t - quotient * new_t))
        
        # 交换r和new_r
        local temp_r="$r"
        r="$new_r"
        new_r=$((temp_r - quotient * new_r))
    done
    
    if [[ "$r" -gt 1 ]]; then
        echo "0"  # 逆元不存在
        return 1
    fi
    
    if [[ "$t" -lt 0 ]]; then
        t=$((t + m))
    fi
    
    echo "$t"
}

# 修复的椭圆曲线点加法
curve_point_add_correct() {
    local x1="$1" y1="$2" x2="$3" y2="$4" a="$5" p="$6"
    
    # 处理无穷远点情况
    if [[ "$x1" == "0" && "$y1" == "0" ]]; then
        echo "$x2 $y2"
        return 0
    fi
    
    if [[ "$x2" == "0" && "$y2" == "0" ]]; then
        echo "$x1 $y1"
        return 0
    fi
    
    # 检查是否是同一个点
    if [[ "$x1" == "$x2" ]]; then
        if [[ "$y1" == "$y2" ]]; then
            # 点加倍
            if [[ "$y1" == "0" ]]; then
                echo "0 0"  # 无穷远点
                return 0
            fi
            
            # λ = (3x₁² + a) / (2y₁) mod p
            local x1_squared=$((x1 * x1))
            local numerator=$((3 * x1_squared + a))
            local denominator=$((2 * y1))
            
            local inv_denominator=$(mod_inverse_simple "$denominator" "$p")
            if [[ "$inv_denominator" == "0" ]]; then
                echo "0 0"
                return 1
            fi
            
            local lambda=$((numerator * inv_denominator % p))
            
        else
            # 互为相反数
            echo "0 0"  # 无穷远点
            return 0
        fi
    else
        # 点加法: λ = (y₂ - y₁) / (x₂ - x₁) mod p
        local numerator=$((y2 - y1))
        local denominator=$((x2 - x1))
        
        # 处理负数
        if [[ "$numerator" -lt 0 ]]; then
            numerator=$((numerator + p))
        fi
        if [[ "$denominator" -lt 0 ]]; then
            denominator=$((denominator + p))
        fi
        
        local inv_denominator=$(mod_inverse_simple "$denominator" "$p")
        if [[ "$inv_denominator" == "0" ]]; then
            echo "0 0"
            return 1
        fi
        
        local lambda=$((numerator * inv_denominator % p))
    fi
    
    # x₃ = λ² - x₁ - x₂ mod p
    local lambda_squared=$((lambda * lambda))
    local x3=$((lambda_squared - x1 - x2))
    x3=$(mod_simple "$x3" "$p")
    
    # y₃ = λ(x₁ - x₃) - y₁ mod p
    local y3=$((lambda * (x1 - x3) - y1))
    y3=$(mod_simple "$y3" "$p")
    
    echo "$x3 $y3"
}

# 简化的标量乘法
curve_scalar_mult_simple() {
    local k="$1" x="$2" y="$3" a="$4" p="$5"
    
    # 处理k=0的情况
    if [[ "$k" == "0" ]]; then
        echo "0 0"
        return 0
    fi
    
    # 处理k=1的情况
    if [[ "$k" == "1" ]]; then
        echo "$x $y"
        return 0
    fi
    
    # 使用二进制展开算法
    local result_x="0"
    local result_y="0"
    local temp_x="$x"
    local temp_y="$y"
    
    local n="$k"
    while [[ "$n" -gt 0 ]]; do
        if [[ $((n & 1)) -eq 1 ]]; then
            # result = result + temp
            if [[ "$result_x" == "0" && "$result_y" == "0" ]]; then
                result_x="$temp_x"
                result_y="$temp_y"
            else
                local add_result=$(curve_point_add_correct "$result_x" "$result_y" "$temp_x" "$temp_y" "$a" "$p")
                result_x=$(echo "$add_result" | cut -d' ' -f1)
                result_y=$(echo "$add_result" | cut -d' ' -f2)
            fi
        fi
        
        # temp = temp + temp (点加倍)
        if [[ "$n" -gt 1 ]]; then
            local double_result=$(curve_point_add_correct "$temp_x" "$temp_y" "$temp_x" "$temp_y" "$a" "$p")
            temp_x=$(echo "$double_result" | cut -d' ' -f1)
            temp_y=$(echo "$double_result" | cut -d' ' -f2)
        fi
        
        n=$((n >> 1))
    done
    
    echo "$result_x $result_y"
}

# 导出函数
export -f mod_simple mod_inverse_simple curve_point_add_correct curve_scalar_mult_simple

# 如果直接运行此脚本，进行简单测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== 椭圆曲线数学运算简单测试 ==="
    
    echo "测试 mod_simple(10, 7): $(mod_simple 10 7) (期望: 3)"
    echo "测试 mod_inverse_simple(3, 7): $(mod_inverse_simple 3 7) (期望: 5)"
    echo "测试 curve_point_add_correct(3,10,3,10,1,23): $(curve_point_add_correct 3 10 3 10 1 23) (期望: 7 12)"
    echo "测试 curve_scalar_mult_simple(2,3,10,1,23): $(curve_scalar_mult_simple 2 3 10 1 23) (期望: 7 12)"
    
    echo "✅ 椭圆曲线数学运算测试完成"
fi