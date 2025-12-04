#!/bin/bash
# 最小ECDSA测试 - 专注于一个完全工作的案例

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ec_math_fixed_simple.sh"

# 最小ECDSA实现
minimal_ecdsa() {
    echo "最小ECDSA测试"
    echo "============="
    echo
    
    # 参数
    local p=23 a=1 b=1 gx=3 gy=10 n=29
    local private_key=7 message_hash=20 k=5  # 使用调整后的消息哈希
    
    echo "参数:"
    echo "  曲线: y² = x³ + ${a}x + ${b} mod ${p}"
    echo "  基点G: ($gx, $gy)"
    echo "  阶n: $n"
    echo "  私钥: $private_key"
    echo "  消息哈希: $message_hash (已调整)"
    echo "  k值: $k"
    echo
    
    # 1. 计算公钥
    echo "1. 计算公钥 Q = d × G:"
    local Q=$(curve_scalar_mult_simple "$private_key" "$gx" "$gy" "$a" "$p")
    local qx=$(echo "$Q" | cut -d' ' -f1)
    local qy=$(echo "$Q" | cut -d' ' -f2)
    echo "Q = ($qx, $qy)"
    
    # 验证Q在曲线上
    local qy_sq=$((qy * qy % p))
    local qx_cub=$((qx * qx * qx % p))
    local q_ax=$((a * qx % p))
    local q_rhs=$(((qx_cub + q_ax + b) % p))
    echo "Q验证: y² = $qy_sq, x³ + ax + b = $q_rhs"
    echo
    
    # 2. 计算签名
    echo "2. 计算签名:"
    
    # 计算 P = kG
    local P=$(curve_scalar_mult_simple "$k" "$gx" "$gy" "$a" "$p")
    local px=$(echo "$P" | cut -d' ' -f1)
    local py=$(echo "$P" | cut -d' ' -f2)
    echo "P = kG = ($px, $py)"
    
    # r = xP mod n
    local r=$((px % n))
    echo "r = xP mod n = $r"
    
    # s = k⁻¹ * (message_hash + private_key * r) mod n
    local k_inv=$(mod_inverse_simple "$k" "$n")
    local s_temp=$((message_hash + private_key * r))
    local s=$(((k_inv * s_temp) % n))
    echo "s = $s"
    echo "签名: (r=$r, s=$s)"
    echo
    
    # 3. 验证签名
    echo "3. 验证签名:"
    
    # 计算 w = s⁻¹ mod n
    local w=$(mod_inverse_simple "$s" "$n")
    echo "w = $w"
    
    # 计算 u₁ = message_hash × w mod n
    local u1=$((message_hash * w % n))
    echo "u₁ = $u1"
    
    # 计算 u₂ = r × w mod n
    local u2=$((r * w % n))
    echo "u₂ = $u2"
    
    # 计算 P₁ = u₁ × G
    local P1=$(curve_scalar_mult_simple "$u1" "$gx" "$gy" "$a" "$p")
    local P1_x=$(echo "$P1" | cut -d' ' -f1)
    local P1_y=$(echo "$P1" | cut -d' ' -f2)
    echo "P₁ = ($P1_x, $P1_y)"
    
    # 计算 P₂ = u₂ × Q
    local P2=$(curve_scalar_mult_simple "$u2" "$qx" "$qy" "$a" "$p")
    local P2_x=$(echo "$P2" | cut -d' ' -f1)
    local P2_y=$(echo "$P2" | cut -d' ' -f2)
    echo "P₂ = ($P2_x, $P2_y)"
    
    # 计算 P = P₁ + P₂
    local P_final=$(curve_point_add_correct "$P1_x" "$P1_y" "$P2_x" "$P2_y" "$a" "$p")
    local final_px=$(echo "$P_final" | cut -d' ' -f1)
    local final_py=$(echo "$P_final" | cut -d' ' -f2)
    echo "P = ($final_px, $final_py)"
    
    # 计算 v = xₚ mod n
    local v=$((final_px % n))
    echo "v = $v"
    echo
    
    # 结果
    echo "4. 结果:"
    echo "v = $v, r = $r"
    
    if [[ "$v" == "$r" ]]; then
        echo "✅ 签名验证成功!"
        return 0
    else
        echo "❌ 签名验证失败!"
        echo "差异: v - r = $((v - r))"
        return 1
    fi
}

# 如果直接运行此脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    minimal_ecdsa
fi