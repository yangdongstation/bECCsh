#!/bin/bash
# 简单调试 15 × Q 计算

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ec_math_fixed_simple.sh"

# 主函数
main() {
    echo "简单调试 15 × Q 计算"
    echo "====================="
    echo
    
    # 测试参数
    local test_p=23
    local test_a=1
    local test_gx=3
    local test_gy=10
    local private_key=7
    
    # 计算公钥 Q = 7G
    echo "计算公钥 Q = 7 × G:"
    local Q=$(curve_scalar_mult_simple "$private_key" "$test_gx" "$test_gy" "$test_a" "$test_p")
    local qx=$(echo "$Q" | cut -d' ' -f1)
    local qy=$(echo "$Q" | cut -d' ' -f2)
    echo "Q = ($qx, $qy)"
    echo
    
    # 直接计算 15 × Q
    echo "直接计算 15 × Q:"
    local result=$(curve_scalar_mult_simple "15" "$qx" "$qy" "$test_a" "$test_p")
    local result_x=$(echo "$result" | cut -d' ' -f1)
    local result_y=$(echo "$result" | cut -d' ' -f2)
    echo "15 × Q = ($result_x, $result_y)"
    echo
    
    # 验证期望结果 (12, 8)
    echo "验证期望结果 (12, 8):"
    if [[ "$result_x" == "12" && "$result_y" == "8" ]]; then
        echo "✅ 结果正确"
    else
        echo "❌ 结果错误"
        echo "期望: (12, 8)"
        echo "实际: ($result_x, $result_y)"
    fi
    
    # 检查 (12, 8) 是否在曲线上
    echo
    echo "检查 (12, 8) 是否在曲线上:"
    local y_sq=$((8 * 8 % 23))
    local x_cub=$((12 * 12 * 12 % 23))
    local ax=$((1 * 12 % 23))
    local rhs=$(((x_cub + ax + 1) % 23))
    echo "y² = $y_sq, x³ + ax + b = $x_cub + $ax + 1 = $rhs"
    
    if [[ $y_sq -eq $rhs ]]; then
        echo "✅ (12, 8) 在曲线上"
    else
        echo "❌ (12, 8) 不在曲线上"
    fi
    
    # 检查 (11, 20) 是否在曲线上
    echo
    echo "检查 (11, 20) 是否在曲线上:"
    local y_sq2=$((20 * 20 % 23))
    local x_cub2=$((11 * 11 * 11 % 23))
    local ax2=$((1 * 11 % 23))
    local rhs2=$(((x_cub2 + ax2 + 1) % 23))
    echo "y² = $y_sq2, x³ + ax + b = $x_cub2 + $ax2 + 1 = $rhs2"
    
    if [[ $y_sq2 -eq $rhs2 ]]; then
        echo "✅ (11, 20) 在曲线上"
    else
        echo "❌ (11, 20) 不在曲线上"
    fi
}

# 如果直接运行此脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi