#!/bin/bash
# 调试椭圆曲线数学运算

set -euo pipefail

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ec_math_fixed_simple.sh"

# 调试函数
debug_point_add() {
    local x1="$1" y1="$2" x2="$3" y2="$4" a="$5" p="$6"
    
    echo "调试点加法:"
    echo "P1 = ($x1, $y1)"
    echo "P2 = ($x2, $y2)"
    echo "a = $a, p = $p"
    echo
    
    # 处理无穷远点
    if [[ "$x1" == "0" && "$y1" == "0" ]]; then
        echo "P1是无穷远点，结果 = P2"
        echo "结果: ($x2, $y2)"
        return 0
    fi
    if [[ "$x2" == "0" && "$y2" == "0" ]]; then
        echo "P2是无穷远点，结果 = P1"
        echo "结果: ($x1, $y1)"
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
    echo "结果: ($x3, $y3)"
}

# 调试标量乘法
debug_scalar_mult() {
    local k="$1" gx="$2" gy="$3" a="$4" p="$5"
    
    echo "调试标量乘法: $k × ($gx, $gy)"
    echo "k = $k, G = ($gx, $gy), a = $a, p = $p"
    echo
    
    local result_x="0"
    local result_y="0"
    local current_x="$gx"
    local current_y="$gy"
    local step=1
    
    echo "开始计算，初始结果 = (0, 0), 当前 = G = ($current_x, $current_y)"
    echo
    
    while [[ $k -gt 0 ]]; do
        echo "步骤 $step: k = $k"
        
        if [[ $((k % 2)) -eq 1 ]]; then
            echo "  k是奇数，结果 = 结果 + 当前"
            if [[ $result_x -ne 0 || $result_y -ne 0 ]]; then
                echo "  当前结果 = ($result_x, $result_y)"
                echo "  当前点 = ($current_x, $current_y)"
                local result=$(curve_point_add_correct "$result_x" "$result_y" "$current_x" "$current_y" "$a" "$p")
                result_x=$(echo "$result" | cut -d' ' -f1)
                result_y=$(echo "$result" | cut -d' ' -f2)
                echo "  新结果 = ($result_x, $result_y)"
            else
                result_x="$current_x"
                result_y="$current_y"
                echo "  结果是无穷远点，新结果 = ($result_x, $result_y)"
            fi
        fi
        
        # current = current + current (倍点)
        echo "  当前 = 当前 + 当前 (倍点)"
        local current=$(curve_point_add_correct "$current_x" "$current_y" "$current_x" "$current_y" "$a" "$p")
        current_x=$(echo "$current" | cut -d' ' -f1)
        current_y=$(echo "$current" | cut -d' ' -f2)
        echo "  新当前 = ($current_x, $current_y)"
        
        k=$((k / 2))
        step=$((step + 1))
        echo
    done
    
    echo "最终结果: ($result_x, $result_y)"
}

# 主调试函数
main() {
    echo "椭圆曲线数学运算调试"
    echo "===================="
    echo
    
    # 测试参数
    local test_p=23
    local test_a=1
    local test_b=1
    local test_gx=3
    local test_gy=10
    local test_n=29
    
    echo "测试曲线: y² = x³ + ${test_a}x + ${test_b} mod ${test_p}"
    echo "基点G: (${test_gx}, ${test_gy})"
    echo "阶n: ${test_n}"
    echo
    
    # 测试点加法
    echo "1. 测试点加法: G + G (倍点)"
    debug_point_add "$test_gx" "$test_gy" "$test_gx" "$test_gy" "$test_a" "$test_p"
    echo
    
    # 测试标量乘法
    echo "2. 测试标量乘法: 2 × G"
    debug_scalar_mult "2" "$test_gx" "$test_gy" "$test_a" "$test_p"
    echo
    
    echo "3. 测试标量乘法: 7 × G (私钥7的公钥)"
    debug_scalar_mult "7" "$test_gx" "$test_gy" "$test_a" "$test_p"
}

# 如果直接运行此脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi