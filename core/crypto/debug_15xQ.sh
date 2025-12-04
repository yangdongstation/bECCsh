#!/bin/bash
# 调试 15 × Q 计算

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

# 逐步计算 15 × Q
debug_15xQ() {
    local qx="$1" qy="$2" a="$3" p="$4"
    
    echo "逐步计算 15 × ($qx, $qy)"
    echo "Q = ($qx, $qy), a = $a, p = $p"
    echo
    
    # 15 = 8 + 4 + 2 + 1 = 2³ + 2² + 2¹ + 2⁰
    echo "15 = 8 + 4 + 2 + 1 = 2³ + 2² + 2¹ + 2⁰"
    echo
    
    local result_x="0"
    local result_y="0"
    local current_x="$qx"
    local current_y="$qy"
    
    echo "初始: 结果 = (0, 0), 当前 = Q = ($current_x, $current_y)"
    echo
    
    # 15的二进制: 1111
    local bits=(1 1 1 1)  # 从最低位到最高位
    local multipliers=(1 2 4 8)  # 对应的乘数
    
    for i in {0..3}; do
        local bit="${bits[$i]}"
        local multiplier="${multipliers[$i]}"
        
        echo "步骤 $((i+1)): 处理 2^$i = $multiplier"
        echo "  当前位: $bit, 乘数: $multiplier"
        echo "  当前结果 = ($result_x, $result_y)"
        echo "  当前点 = ($current_x, $current_y)"
        
        if [[ $bit -eq 1 ]]; then
            echo "  位为1，结果 = 结果 + 当前"
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
            echo "  位为0，跳过结果更新"
        fi
        
        # 准备下一个幂次
        if [[ $i -lt 3 ]]; then
            echo "  准备下一个幂次: 当前 = 当前 + 当前 (倍点)"
            if [[ $current_y -eq 0 ]]; then
                echo "  ⚠️  当前点y=0，倍点结果为无穷远点"
                current_x="0"
                current_y="0"
            else
                local current=$(curve_point_add_correct "$current_x" "$current_y" "$current_x" "$current_y" "$a" "$p")
                current_x=$(echo "$current" | cut -d' ' -f1)
                current_y=$(echo "$current" | cut -d' ' -f2)
            fi
            echo "  新当前 = ($current_x, $current_y)"
        fi
        
        echo
    done
    
    echo "最终结果: ($result_x, $result_y)"
    echo
    
    # 验证结果
    check_point_on_curve "$result_x" "$result_y" "$a" "1" "$p"
}

# 验证期望结果
verify_expected() {
    local expected_x="$1" expected_y="$2" actual_x="$3" actual_y="$4"
    
    echo "验证结果:"
    echo "期望: ($expected_x, $expected_y)"
    echo "实际: ($actual_x, $actual_y)"
    
    if [[ "$expected_x" == "$actual_x" && "$expected_y" == "$actual_y" ]]; then
        echo "✅ 结果正确"
        return 0
    else
        echo "❌ 结果错误"
        return 1
    fi
}

# 主函数
main() {
    echo "调试 15 × Q 计算"
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
    
    # 计算公钥 Q = 7G
    echo "1. 计算公钥 Q = 7 × G:"
    local Q=$(curve_scalar_mult_simple "$private_key" "$test_gx" "$test_gy" "$test_a" "$test_p")
    local qx=$(echo "$Q" | cut -d' ' -f1)
    local qy=$(echo "$Q" | cut -d' ' -f2)
    echo "Q = ($qx, $qy)"
    echo
    
    # 验证Q在曲线上
    echo "2. 验证Q在曲线上:"
    check_point_on_curve "$qx" "$qy" "$test_a" "$test_b" "$test_p"
    echo
    
    # 逐步计算 15 × Q
    echo "3. 逐步计算 15 × Q:"
    local result=$(debug_15xQ "$qx" "$qy" "$test_a" "$test_p")
    local result_x=$(echo "$result" | cut -d' ' -f1)
    local result_y=$(echo "$result" | cut -d' ' -f2)
    echo
    
    # 验证期望结果
    echo "4. 验证期望结果:"
    verify_expected "12" "8" "$result_x" "$result_y"
    echo
    
    # 对比直接计算
    echo "5. 对比直接计算:"
    local direct=$(curve_scalar_mult_simple "15" "$qx" "$qy" "$test_a" "$test_p")
    local direct_x=$(echo "$direct" | cut -d' ' -f1)
    local direct_y=$(echo "$direct" | cut -d' ' -f2)
    echo "直接计算 15 × Q = ($direct_x, $direct_y)"
    verify_expected "12" "8" "$direct_x" "$direct_y"
}

# 如果直接运行此脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi