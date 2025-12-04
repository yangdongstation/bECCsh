#!/bin/bash
# 调试公钥计算

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

# 主调试函数
main() {
    echo "公钥计算调试"
    echo "============"
    echo
    
    # 测试参数
    local test_p=23
    local test_a=1
    local test_b=1
    local test_gx=3
    local test_gy=10
    local test_n=29
    local private_key=7
    
    echo "测试曲线: y² = x³ + ${test_a}x + ${test_b} mod ${test_p}"
    echo "基点G: (${test_gx}, ${test_gy})"
    echo "阶n: ${test_n}"
    echo "私钥: $private_key"
    echo
    
    echo "1. 验证基点G:"
    check_point_on_curve "$test_gx" "$test_gy" "$test_a" "$test_b" "$test_p"
    echo
    
    echo "2. 计算公钥 Q = d × G:"
    echo "   d = $private_key, G = ($test_gx, $test_gy)"
    local Q=$(curve_scalar_mult_simple "$private_key" "$test_gx" "$test_gy" "$test_a" "$test_p")
    local qx=$(echo "$Q" | cut -d' ' -f1)
    local qy=$(echo "$Q" | cut -d' ' -f2)
    echo "   Q = ($qx, $qy)"
    echo
    
    echo "3. 验证公钥Q在曲线上:"
    check_point_on_curve "$qx" "$qy" "$test_a" "$test_b" "$test_p"
    echo
    
    echo "4. 测试标量乘法 25 × Q:"
    echo "   Q = ($qx, $qy)"
    local P2=$(curve_scalar_mult_simple "25" "$qx" "$qy" "$test_a" "$test_p")
    local p2x=$(echo "$P2" | cut -d' ' -f1)
    local p2y=$(echo "$P2" | cut -d' ' -f2)
    echo "   25 × Q = ($p2x, $p2y)"
    echo
    
    echo "5. 验证 25 × Q 在曲线上:"
    check_point_on_curve "$p2x" "$p2y" "$test_a" "$test_b" "$test_p"
    echo
    
    echo "6. 测试其他标量乘法:"
    for k in 1 2 3 4 5 10 15 20 25 28; do
        echo "   $k × G:"
        local P=$(curve_scalar_mult_simple "$k" "$test_gx" "$test_gy" "$test_a" "$test_p")
        local px=$(echo "$P" | cut -d' ' -f1)
        local py=$(echo "$P" | cut -d' ' -f2)
        check_point_on_curve "$px" "$py" "$test_a" "$test_b" "$test_p"
    done
}

# 如果直接运行此脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi