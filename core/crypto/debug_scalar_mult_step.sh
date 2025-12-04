#!/bin/bash
# 逐步调试标量乘法

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

# 逐步计算标量乘法
debug_scalar_mult_step() {
    local k="$1" gx="$2" gy="$3" a="$4" p="$5"
    
    echo "逐步计算标量乘法: $k × ($gx, $gy)"
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
        echo "  当前结果 = ($result_x, $result_y)"
        echo "  当前点 = ($current_x, $current_y)"
        
        # 检查当前点是否在曲线上
        check_point_on_curve "$current_x" "$current_y" "$a" "1" "$p"
        
        if [[ $((k % 2)) -eq 1 ]]; then
            echo "  k是奇数，结果 = 结果 + 当前"
            if [[ $result_x -ne 0 || $result_y -ne 0 ]]; then
                echo "  执行点加法: ($result_x, $result_y) + ($current_x, $current_y)"
                local result=$(curve_point_add_correct "$result_x" "$result_y" "$current_x" "$current_y" "$a" "$p")
                result_x=$(echo "$result" | cut -d' ' -f1)
                result_y=$(echo "$result" | cut -d' ' -f2)
                echo "  新结果 = ($result_x, $result_y)"
            else
                echo "  结果是无穷远点，新结果 = 当前点"
                result_x="$current_x"
                result_y="$current_y"
                echo "  新结果 = ($result_x, $result_y)"
            fi
        else
            echo "  k是偶数，跳过结果更新"
        fi
        
        # current = current + current (倍点)
        echo "  当前 = 当前 + 当前 (倍点)"
        echo "  执行倍点: ($current_x, $current_y) + ($current_x, $current_y)"
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

# 主函数
main() {
    echo "逐步标量乘法调试"
    echo "================="
    echo
    
    # 测试参数
    local test_p=23
    local test_a=1
    local test_b=1
    local test_gx=3
    local test_gy=10
    local private_key=7
    
    echo "测试曲线: y² = x³ + ${test_a}x + ${test_b} mod ${test_p}"
    echo "基点G: (${test_gx}, ${test_gy})"
    echo
    
    # 计算公钥
    echo "1. 计算公钥 Q = 7 × G:"
    debug_scalar_mult_step "$private_key" "$test_gx" "$test_gy" "$test_a" "$test_p"
    echo
    
    # 测试25 × Q
    echo "2. 计算 25 × Q:"
    local Q=$(curve_scalar_mult_simple "$private_key" "$test_gx" "$test_gy" "$test_a" "$test_p")
    local qx=$(echo "$Q" | cut -d' ' -f1)
    local qy=$(echo "$Q" | cut -d' ' -f2)
    debug_scalar_mult_step "25" "$qx" "$qy" "$test_a" "$test_p"
}

# 如果直接运行此脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi