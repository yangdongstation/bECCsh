#!/bin/bash
# 调试k=5成功案例的详细信息

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ec_math_fixed_simple.sh"

# 手动验证ECDSA步骤
manual_verify_k5() {
    echo "手动验证k=5的ECDSA步骤"
    echo "======================="
    echo
    
    # 参数
    local test_p=23
    local test_a=1
    local test_b=1
    local test_gx=3
    local test_gy=10
    local test_n=29
    local private_key=7
    local message_hash=12345
    local k=5
    
    echo "参数:"
    echo "  曲线: y² = x³ + ${test_a}x + ${test_b} mod ${test_p}"
    echo "  基点G: (${test_gx}, ${test_gy})"
    echo "  阶n: ${test_n}"
    echo "  私钥: $private_key"
    echo "  消息哈希: $message_hash"
    echo "  k值: $k"
    echo
    
    # 计算公钥
    echo "1. 计算公钥 Q = d × G:"
    local Q=$(curve_scalar_mult_simple "$private_key" "$test_gx" "$test_gy" "$test_a" "$test_p")
    local qx=$(echo "$Q" | cut -d' ' -f1)
    local qy=$(echo "$Q" | cut -d' ' -f2)
    echo "Q = ($qx, $qy)"
    echo
    
    # 计算签名
    echo "2. 计算签名:"
    
    # 消息哈希处理
    message_hash=$((message_hash % test_n))
    if [[ $message_hash -eq 0 ]]; then
        message_hash="1"
    fi
    echo "调整后消息哈希: $message_hash"
    
    # 计算 P = kG
    local P=$(curve_scalar_mult_simple "$k" "$test_gx" "$test_gy" "$test_a" "$test_p")
    local px=$(echo "$P" | cut -d' ' -f1)
    local py=$(echo "$P" | cut -d' ' -f2)
    echo "P = kG = ($px, $py)"
    
    # r = xP mod n
    local r=$((px % test_n))
    echo "r = xP mod n = $px mod $test_n = $r"
    
    # s = k⁻¹ * (message_hash + private_key * r) mod n
    local k_inv=$(mod_inverse_simple "$k" "$test_n")
    local s_temp=$((message_hash + private_key * r))
    local s=$(((k_inv * s_temp) % test_n))
    echo "k⁻¹ = $k_inv"
    echo "s = k⁻¹ × (message_hash + private_key × r) mod n"
    echo "s = $k_inv × ($message_hash + $private_key × $r) mod $test_n = $s"
    echo "签名: (r=$r, s=$s)"
    echo
    
    # 验证签名
    echo "3. 验证签名:"
    
    # 计算 w = s⁻¹ mod n
    local w=$(mod_inverse_simple "$s" "$test_n")
    echo "w = s⁻¹ mod n = $s⁻¹ mod $test_n = $w"
    
    # 计算 u₁ = message_hash × w mod n
    local u1=$((message_hash * w % test_n))
    echo "u₁ = message_hash × w mod n = $message_hash × $w mod $test_n = $u1"
    
    # 计算 u₂ = r × w mod n
    local u2=$((r * w % test_n))
    echo "u₂ = r × w mod n = $r × $w mod $test_n = $u2"
    
    # 计算 P₁ = u₁ × G
    local P1=$(curve_scalar_mult_simple "$u1" "$test_gx" "$test_gy" "$test_a" "$test_p")
    local P1_x=$(echo "$P1" | cut -d' ' -f1)
    local P1_y=$(echo "$P1" | cut -d' ' -f2)
    echo "P₁ = u₁ × G = ($P1_x, $P1_y)"
    
    # 计算 P₂ = u₂ × Q
    local P2=$(curve_scalar_mult_simple "$u2" "$qx" "$qy" "$test_a" "$test_p")
    local P2_x=$(echo "$P2" | cut -d' ' -f1)
    local P2_y=$(echo "$P2" | cut -d' ' -f2)
    echo "P₂ = u₂ × Q = ($P2_x, $P2_y)"
    
    # 计算 P = P₁ + P₂
    local P=$(curve_point_add_correct "$P1_x" "$P1_y" "$P2_x" "$P2_y" "$test_a" "$test_p")
    local final_px=$(echo "$P" | cut -d' ' -f1)
    local final_py=$(echo "$P" | cut -d' ' -f2)
    echo "P = P₁ + P₂ = ($final_px, $final_py)"
    
    # 计算 v = xₚ mod n
    local v=$((final_px % test_n))
    echo "v = xₚ mod n = $final_px mod $test_n = $v"
    echo
    
    # 比较
    echo "4. 比较 v 和 r:"
    echo "v = $v, r = $r"
    
    if [[ "$v" == "$r" ]]; then
        echo "✅ 签名验证成功!"
        return 0
    else
        echo "❌ 签名验证失败!"
        return 1
    fi
}

# 主函数
main() {
    echo "调试k=5成功案例"
    echo "==============="
    echo
    
    manual_verify_k5
}

# 如果直接运行此脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi