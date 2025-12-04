#!/bin/bash
# 验证ECDSA数学运算

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ec_math_fixed_simple.sh"

# 验证给定点是否在曲线上
check_point_on_curve() {
    local x="$1" y="$2" a="$3" b="$4" p="$5"
    
    # 计算 y² mod p
    local y_sq=$((y * y % p))
    
    # 计算 x³ + ax + b mod p
    local x_cub=$((x * x * x % p))
    local ax=$((a * x % p))
    local rhs=$(((x_cub + ax + b) % p))
    
    echo "点 ($x, $y) 检查:"
    echo "  y² mod p = $y_sq"
    echo "  x³ + ax + b mod p = $x_cub + $ax + $b mod $p = $rhs"
    
    if [[ $y_sq -eq $rhs ]]; then
        echo "  ✅ 点在曲线上"
        return 0
    else
        echo "  ❌ 点不在曲线上"
        return 1
    fi
}

# 验证标量乘法
verify_scalar_mult() {
    local expected_x="$1" expected_y="$2" k="$3" gx="$4" gy="$5" a="$6" p="$7"
    
    echo "验证标量乘法: $k × ($gx, $gy)"
    echo "期望结果: ($expected_x, $expected_y)"
    
    local result=$(curve_scalar_mult_simple "$k" "$gx" "$gy" "$a" "$p")
    local result_x=$(echo "$result" | cut -d' ' -f1)
    local result_y=$(echo "$result" | cut -d' ' -f2)
    
    echo "实际结果: ($result_x, $result_y)"
    
    if [[ "$result_x" == "$expected_x" && "$result_y" == "$expected_y" ]]; then
        echo "✅ 标量乘法正确"
        return 0
    else
        echo "❌ 标量乘法错误"
        return 1
    fi
}

# 验证点加法
verify_point_add() {
    local expected_x="$1" expected_y="$2" x1="$3" y1="$4" x2="$5" y2="$6" a="$7" p="$8"
    
    echo "验证点加法: ($x1, $y1) + ($x2, $y2)"
    echo "期望结果: ($expected_x, $expected_y)"
    
    local result=$(curve_point_add_correct "$x1" "$y1" "$x2" "$y2" "$a" "$p")
    local result_x=$(echo "$result" | cut -d' ' -f1)
    local result_y=$(echo "$result" | cut -d' ' -f2)
    
    echo "实际结果: ($result_x, $result_y)"
    
    if [[ "$result_x" == "$expected_x" && "$result_y" == "$expected_y" ]]; then
        echo "✅ 点加法正确"
        return 0
    else
        echo "❌ 点加法错误"
        return 1
    fi
}

# 主验证函数
main() {
    echo "ECDSA数学运算验证"
    echo "=================="
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
    
    # 验证基点G在曲线上
    echo "1. 验证基点G在曲线上:"
    check_point_on_curve "$test_gx" "$test_gy" "$test_a" "$test_b" "$test_p"
    echo
    
    # 验证已知点的标量乘法
    echo "2. 验证标量乘法:"
    echo "   根据之前的调试，我们知道:"
    echo "   2 × G = (7, 12)"
    echo "   4 × G = (17, 3)"
    echo "   7 × G = (11, 3)"
    echo
    
    verify_scalar_mult "7" "12" "2" "$test_gx" "$test_gy" "$test_a" "$test_p"
    echo
    verify_scalar_mult "17" "3" "4" "$test_gx" "$test_gy" "$test_a" "$test_p"
    echo
    verify_scalar_mult "11" "3" "7" "$test_gx" "$test_gy" "$test_a" "$test_p"
    echo
    
    # 验证点加法
    echo "3. 验证点加法:"
    echo "   测试: (17, 3) + (15, 8) = ?"
    verify_point_add "3" "8" "17" "3" "15" "8" "$test_a" "$test_p"
    echo
    
    # 验证ECDSA验证步骤中的关键点
    echo "4. 验证ECDSA验证中的关键点:"
    echo "   从之前的调试测试，我们知道:"
    echo "   u₁ = 21, P₁ = 21 × G = (11, 20)"
    echo "   u₂ = 15, P₂ = 15 × Q = (11, 20)"
    echo "   Q = 7 × G = (11, 3)"
    echo
    
    verify_scalar_mult "11" "20" "21" "$test_gx" "$test_gy" "$test_a" "$test_p"
    echo
    verify_scalar_mult "11" "20" "15" "11" "3" "$test_a" "$test_p"
    echo
    
    echo "5. 验证最终点加法:"
    echo "   P = P₁ + P₂ = (11, 20) + (11, 3) = 无穷远点"
    verify_point_add "0" "0" "11" "20" "11" "3" "$test_a" "$test_p"
    echo
    
    # 验证模逆元
    echo "6. 验证模逆元:"
    echo "   12 × 17 mod 29 = $((12 * 17 % 29)) (应该是1)"
    echo "   5 × 6 mod 29 = $((5 * 6 % 29)) (应该是1)"
    echo
}

# 如果直接运行此脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi