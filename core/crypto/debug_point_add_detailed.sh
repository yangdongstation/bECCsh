#!/bin/bash
# 详细调试点加法

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ec_math_fixed_simple.sh"

# 检查点是否在曲线上
check_point_on_curve() {
    local x="$1" y="$2" a="$3" b="$4" p="$5"
    
    # 计算 y² mod p
    local y_sq=$((y * y % p))
    
    # 计算 x³ + ax + b mod p
    local x_cub=$((x * x * x % p))
    local ax=$((a * x % p))
    local rhs=$(((x_cub + ax + b) % p))
    
    echo "点 ($x, $y): y² = $y_sq, x³ + ax + b = $rhs"
    
    if [[ $y_sq -eq $rhs ]]; then
        echo "✅ 点在曲线上"
        return 0
    else
        echo "❌ 点不在曲线上"
        return 1
    fi
}

# 详细调试点加法
debug_point_add_detailed() {
    local x1="$1" y1="$2" x2="$3" y2="$4" a="$5" p="$6"
    
    echo "详细调试点加法"
    echo "================"
    echo "计算: ($x1, $y1) + ($x2, $y2)"
    echo "曲线: y² = x³ + ${a}x + 1 mod $p"
    echo
    
    # 验证输入点
    echo "验证输入点:"
    check_point_on_curve "$x1" "$y1" "$a" "1" "$p"
    check_point_on_curve "$x2" "$y2" "$a" "1" "$p"
    echo
    
    # 处理无穷远点
    if [[ "$x1" == "0" && "$y1" == "0" ]]; then
        echo "P1是无穷远点，结果 = P2 = ($x2, $y2)"
        return 0
    fi
    if [[ "$x2" == "0" && "$y2" == "0" ]]; then
        echo "P2是无穷远点，结果 = P1 = ($x1, $y1)"
        return 0
    fi
    
    # 计算斜率
    local lambda
    if [[ "$x1" == "$x2" ]]; then
        if [[ "$y1" == "$y2" ]]; then
            echo "倍点运算 (P1 = P2)"
            # 倍点运算: λ = (3x² + a) / (2y) mod p
            local three_x1_sq=$((3 * x1 * x1))
            local numerator=$((three_x1_sq + a))
            local two_y1=$((2 * y1))
            
            echo "3x₁² + a = 3×$x1² + $a = $three_x1_sq + $a = $numerator"
            echo "2y₁ = 2×$y1 = $two_y1"
            
            # 确保分子为正
            while [[ $numerator -lt 0 ]]; do
                numerator=$((numerator + p))
            done
            
            # 确保分母为正
            while [[ $two_y1 -lt 0 ]]; do
                two_y1=$((two_y1 + p))
            done
            
            echo "分子 mod p = $numerator"
            echo "分母 mod p = $two_y1"
            
            # 检查分母是否为0
            if [[ $two_y1 -eq 0 ]]; then
                echo "❌ 分母为0，无法计算逆元"
                return 1
            fi
            
            # 计算模逆元
            local two_y1_inv=$(mod_inverse_simple "$two_y1" "$p")
            echo "分母的逆元 = $two_y1_inv"
            
            lambda=$(((numerator * two_y1_inv) % p))
            echo "λ = (分子 × 分母的逆元) mod p = ($numerator × $two_y1_inv) mod $p = $lambda"
        else
            echo "P1和P2x坐标相同但y不同，结果为无穷远点"
            echo "结果: (0, 0)"
            return 0
        fi
    else
        echo "一般点加法 (P1 ≠ P2)"
        # 一般点加法: λ = (y₂ - y₁) / (x₂ - x₁) mod p
        local numerator=$((y2 - y1))
        local denominator=$((x2 - x1))
        
        echo "y₂ - y₁ = $y2 - $y1 = $numerator"
        echo "x₂ - x₁ = $x2 - $x1 = $denominator"
        
        # 确保分子为正
        while [[ $numerator -lt 0 ]]; do
            numerator=$((numerator + p))
        done
        
        # 确保分母为正
        while [[ $denominator -lt 0 ]]; do
            denominator=$((denominator + p))
        done
        
        echo "分子 mod p = $numerator"
        echo "分母 mod p = $denominator"
        
        # 检查分母是否为0
        if [[ $denominator -eq 0 ]]; then
            echo "❌ 分母为0，无法计算逆元"
            return 1
        fi
        
        # 计算模逆元
        local denom_inv=$(mod_inverse_simple "$denominator" "$p")
        echo "分母的逆元 = $denom_inv"
        
        lambda=$(((numerator * denom_inv) % p))
        echo "λ = (分子 × 分母的逆元) mod p = ($numerator × $denom_inv) mod $p = $lambda"
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
    
    echo "x₃ = (λ² - x₁ - x₂) mod p = ($lambda² - $x1 - $x2) mod $p = $x3"
    echo "y₃ = (λ(x₁ - x₃) - y₁) mod p = ($lambda($x1 - $x3) - $y1) mod $p = $y3"
    echo
    
    local result_point="($x3, $y3)"
    echo "结果点: $result_point"
    
    # 验证结果点在曲线上
    check_point_on_curve "$x3" "$y3" "$a" "1" "$p"
    
    echo "$x3 $y3"
}

# 主函数
main() {
    echo "详细点加法调试"
    echo "=============="
    echo
    
    # 测试参数
    local test_p=23
    local test_a=1
    local test_b=1
    
    echo "测试曲线: y² = x³ + ${test_a}x + ${test_b} mod ${test_p}"
    echo
    
    # 测试 (4, 0) + (4, 0)
    echo "测试1: (4, 0) + (4, 0) - 倍点运算"
    debug_point_add_detailed "4" "0" "4" "0" "$test_a" "$test_p"
    echo
    
    # 测试 (11, 3) + (4, 0)
    echo "测试2: (11, 3) + (4, 0) - 一般点加法"
    debug_point_add_detailed "11" "3" "4" "0" "$test_a" "$test_p"
    echo
    
    # 测试 (11, 20) + (12, 8)
    echo "测试3: (11, 20) + (12, 8) - ECDSA验证中的点加法"
    debug_point_add_detailed "11" "20" "12" "8" "$test_a" "$test_p"
}

# 如果直接运行此脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi