#!/bin/bash
# 修复的椭圆曲线数学运算 - 简化版本
# 专注于功能正确性，不在乎性能

set -euo pipefail

# 简化的模运算
mod_simple() {
    local a="$1"
    local m="$2"
    echo $((a % m))
}

# 简化的模逆元
mod_inverse_simple() {
    local a="$1"
    local m="$2"
    
    # 扩展欧几里得算法简化版
    local t=0 newt=1
    local r=$m newr=$a
    
    while [[ $newr -ne 0 ]]; do
        local quotient=$((r / newr))
        local temp=$newr
        newr=$((r - quotient * newr))
        r=$temp
        
        temp=$newt
        newt=$((t - quotient * newt))
        t=$temp
    done
    
    if [[ $t -lt 0 ]]; then
        t=$((t + m))
    fi
    
    echo $t
}

# 正确的椭圆曲线点加法
curve_point_add_correct() {
    local x1="$1" y1="$2" x2="$3" y2="$4" a="$5" p="$6"
    
    # 处理无穷远点
    if [[ "$x1" == "0" && "$y1" == "0" ]]; then
        echo "$x2 $y2"
        return 0
    fi
    if [[ "$x2" == "0" && "$y2" == "0" ]]; then
        echo "$x1 $y1"
        return 0
    fi
    
    # 计算斜率
    local lambda
    if [[ "$x1" == "$x2" ]]; then
        if [[ "$y1" == "$y2" ]]; then
            # 倍点运算: λ = (3x² + a) / (2y) mod p
            local three_x1_sq=$((3 * x1 * x1))
            local numerator=$((three_x1_sq + a))
            local two_y1=$((2 * y1))
            
            # 确保分子为正
            while [[ $numerator -lt 0 ]]; do
                numerator=$((numerator + p))
            done
            
            # 确保分母为正
            while [[ $two_y1 -lt 0 ]]; do
                two_y1=$((two_y1 + p))
            done
            
            # 检查分母是否为0 (特殊情况: y=0)
            if [[ $two_y1 -eq 0 ]]; then
                # 当y=0时，倍点运算结果为无穷远点
                echo "0 0"
                return 0
            fi
            
            # 计算模逆元
            local two_y1_inv=$(mod_inverse_simple "$two_y1" "$p")
            lambda=$(((numerator * two_y1_inv) % p))
        else
            echo "0 0"  # 无穷远点
            return 0
        fi
    else
        # 一般点加法: λ = (y₂ - y₁) / (x₂ - x₁) mod p
        local numerator=$((y2 - y1))
        local denominator=$((x2 - x1))
        
        # 确保分子为正
        while [[ $numerator -lt 0 ]]; do
            numerator=$((numerator + p))
        done
        
        # 确保分母为正
        while [[ $denominator -lt 0 ]]; do
            denominator=$((denominator + p))
        done
        
        # 检查分母是否为0
        if [[ $denominator -eq 0 ]]; then
            # 当x坐标相同但y不同时，结果为无穷远点
            echo "0 0"
            return 0
        fi
        
        # 计算模逆元
        local denom_inv=$(mod_inverse_simple "$denominator" "$p")
        lambda=$(((numerator * denom_inv) % p))
    fi
    
    # 计算结果点
    local x3=$(((lambda * lambda - x1 - x2) % p))
    if [[ $x3 -lt 0 ]]; then
        x3=$((x3 + p))
    fi
    
    local y3=$(((lambda * (x1 - x3) - y1) % p))
    if [[ $y3 -lt 0 ]]; then
        y3=$((y3 + p))
    fi
    
    echo "$x3 $y3"
}

# 简化的标量乘法
curve_scalar_mult_simple() {
    local k="$1" gx="$2" gy="$3" a="$4" p="$5"
    
    local result_x="0"
    local result_y="0"
    local current_x="$gx"
    local current_y="$gy"
    
    while [[ $k -gt 0 ]]; do
        if [[ $((k % 2)) -eq 1 ]]; then
            # result = result + current
            if [[ $result_x -ne 0 || $result_y -ne 0 ]]; then
                local result=$(curve_point_add_correct "$result_x" "$result_y" "$current_x" "$current_y" "$a" "$p")
                result_x=$(echo "$result" | cut -d' ' -f1)
                result_y=$(echo "$result" | cut -d' ' -f2)
            else
                result_x="$current_x"
                result_y="$current_y"
            fi
        fi
        
        # current = current + current (倍点)
        local current=$(curve_point_add_correct "$current_x" "$current_y" "$current_x" "$current_y" "$a" "$p")
        current_x=$(echo "$current" | cut -d' ' -f1)
        current_y=$(echo "$current" | cut -d' ' -f2)
        
        k=$((k / 2))
    done
    
    echo "$result_x $result_y"
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "修复的椭圆曲线数学运算测试"
    echo "==================================="
    
    # 测试基本运算
    echo "测试模运算:"
    echo "10 mod 7 = $(mod_simple 10 7)"
    echo "15 mod 6 = $(mod_simple 15 6)"
    
    # 测试模逆元
    echo "测试模逆元:"
    echo "3⁻¹ mod 7 = $(mod_inverse_simple 3 7)"
    echo "5⁻¹ mod 11 = $(mod_inverse_simple 5 11)"
    
    # 测试点加法
    echo "测试点加法:"
    test_result=$(curve_point_add_correct "3" "4" "1" "2" "1" "7")
    echo "(3,4) + (1,2) on y² = x³ + x + 1 mod 7 = $test_result"
    
    echo "==================================="
    echo "✅ 修复的数学运算测试完成"
fi