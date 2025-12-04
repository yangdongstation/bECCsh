#!/bin/bash
# ECDSA调试比较 - 比较成功和失败的案例

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ec_math_fixed_simple.sh"
source "$SCRIPT_DIR/ecdsa_fixed_test.sh"

# 手动执行ECDSA验证步骤，与调试输出比较
debug_manual_verification() {
    local message_hash="$1"
    local r="$2"
    local s="$3"
    local pubkey_x="$4"
    local pubkey_y="$5"
    local gx="$6"
    local gy="$7"
    local a="$8"
    local p="$9"
    local n="${10}"
    
    echo "手动ECDSA验证调试"
    echo "=================="
    echo "输入参数:"
    echo "  消息哈希: $message_hash"
    echo "  签名: (r=$r, s=$s)"
    echo "  公钥: ($pubkey_x, $pubkey_y)"
    echo "  基点G: ($gx, $gy)"
    echo "  曲线参数: a=$a, p=$p, n=$n"
    echo
    
    # 确保消息哈希在有效范围内
    local original_hash="$message_hash"
    message_hash=$((message_hash % n))
    if [[ $message_hash -eq 0 ]]; then
        message_hash="1"
    fi
    echo "调整后消息哈希: $message_hash (原值: $original_hash)"
    echo
    
    echo "=== 手动计算验证 ==="
    
    # 步骤1: 计算 w = s⁻¹ mod n
    echo "步骤1: 计算 w = s⁻¹ mod n"
    local w=$(mod_inverse_simple "$s" "$n")
    echo "  w = $s⁻¹ mod $n = $w"
    
    # 验证 w × s mod n = 1
    local verify_w=$((w * s % n))
    echo "  验证: w × s mod n = $w × $s mod $n = $verify_w (应该是1)"
    echo
    
    # 步骤2: 计算 u₁ = message_hash × w mod n
    echo "步骤2: 计算 u₁ = message_hash × w mod n"
    local u1=$((message_hash * w % n))
    echo "  u₁ = $message_hash × $w mod $n = $u1"
    echo
    
    # 步骤3: 计算 u₂ = r × w mod n
    echo "步骤3: 计算 u₂ = r × w mod n"
    local u2=$((r * w % n))
    echo "  u₂ = $r × $w mod $n = $u2"
    echo
    
    # 步骤4: 计算 P₁ = u₁ × G
    echo "步骤4: 计算 P₁ = u₁ × G"
    local P1=$(curve_scalar_mult_simple "$u1" "$gx" "$gy" "$a" "$p")
    local P1_x=$(echo "$P1" | cut -d' ' -f1)
    local P1_y=$(echo "$P1" | cut -d' ' -f2)
    echo "  P₁ = $u1 × G = ($P1_x, $P1_y)"
    
    # 验证P₁在曲线上
    check_point_on_curve "$P1_x" "$P1_y" "$a" "1" "$p"
    echo
    
    # 步骤5: 计算 P₂ = u₂ × Q (Q是公钥)
    echo "步骤5: 计算 P₂ = u₂ × Q (Q是公钥)"
    local P2=$(curve_scalar_mult_simple "$u2" "$pubkey_x" "$pubkey_y" "$a" "$p")
    local P2_x=$(echo "$P2" | cut -d' ' -f1)
    local P2_y=$(echo "$P2" | cut -d' ' -f2)
    echo "  P₂ = $u2 × Q = ($P2_x, $P2_y)"
    
    # 验证P₂在曲线上
    check_point_on_curve "$P2_x" "$P2_y" "$a" "1" "$p"
    echo
    
    # 步骤6: 计算 P = P₁ + P₂
    echo "步骤6: 计算 P = P₁ + P₂"
    local P=$(curve_point_add_correct "$P1_x" "$P1_y" "$P2_x" "$P2_y" "$a" "$p")
    local px=$(echo "$P" | cut -d' ' -f1)
    local py=$(echo "$P" | cut -d' ' -f2)
    echo "  P = P₁ + P₂ = ($px, $py)"
    
    # 验证P在曲线上
    check_point_on_curve "$px" "$py" "$a" "1" "$p"
    echo
    
    # 步骤7: 计算 v = xₚ mod n
    echo "步骤7: 计算 v = xₚ mod n"
    local v=$((px % n))
    echo "  v = $px mod $n = $v"
    echo
    
    # 步骤8: 比较 v 和 r
    echo "步骤8: 比较 v 和 r"
    echo "  v = $v, r = $r"
    
    if [[ "$v" == "$r" ]]; then
        echo "✅ 签名验证成功!"
        return 0
    else
        echo "❌ 签名验证失败!"
        echo "  差异: v - r = $((v - r))"
        return 1
    fi
}

# 检查点是否在曲线上
check_point_on_curve() {
    local x="$1" y="$2" a="$3" b="$4" p="$5"
    
    # 计算 y² mod p
    local y_sq=$((y * y % p))
    
    # 计算 x³ + ax + b mod p
    local x_cub=$((x * x * x % p))
    local ax=$((a * x % p))
    local rhs=$(((x_cub + ax + b) % p))
    
    echo "  点 ($x, $y) 检查: y² = $y_sq, x³ + ax + b = $rhs"
    
    if [[ $y_sq -eq $rhs ]]; then
        echo "  ✅ 点在曲线上"
        return 0
    else
        echo "  ❌ 点不在曲线上 (y² ≠ x³ + ax + b)"
        return 1
    fi
}

# 主函数
main() {
    echo "ECDSA调试比较测试"
    echo "=================="
    echo
    
    # 测试参数
    local test_p=23
    local test_a=1
    local test_b=1
    local test_gx=3
    local test_gy=10
    local test_n=29
    local private_key=7
    local message_hash=12345
    
    echo "测试曲线: y² = x³ + ${test_a}x + ${test_b} mod ${test_p}"
    echo "基点G: (${test_gx}, ${test_gy})"
    echo "阶n: ${test_n}"
    echo "私钥: $private_key"
    echo "消息哈希: $message_hash"
    echo
    
    # 生成密钥对
    echo "生成密钥对..."
    source "$SCRIPT_DIR/ecdsa_final_fixed_simple.sh"  # 导入ECDSA函数
    local keypair=$(generate_keypair "$private_key" "$test_gx" "$test_gy" "$test_a" "$test_p" "$test_n")
    local priv_key=$(echo "$keypair" | cut -d' ' -f1)
    local pub_key_x=$(echo "$keypair" | cut -d' ' -f2)
    local pub_key_y=$(echo "$keypair" | cut -d' ' -f3)
    echo "私钥: $priv_key"
    echo "公钥: ($pub_key_x, $pub_key_y)"
    echo
    
    # 测试1: 使用固定k=5（已知成功的案例）
    echo "=== 测试1: 使用固定k=5 ==="
    local fixed_k=5
    local signature1=$(create_signature_fixed_k "$message_hash" "$priv_key" "$test_gx" "$test_gy" "$test_a" "$test_p" "$test_n" "$fixed_k")
    local r1=$(echo "$signature1" | cut -d' ' -f1)
    local s1=$(echo "$signature1" | cut -d' ' -f2)
    echo "签名: (r=$r1, s=$s1)"
    echo
    
    debug_manual_verification "$message_hash" "$r1" "$s1" "$pub_key_x" "$pub_key_y" "$test_gx" "$test_gy" "$test_a" "$test_p" "$test_n"
    echo
    
    # 测试2: 使用固定k=18（来自失败案例）
    echo "=== 测试2: 使用固定k=18 ==="
    local fixed_k2=18
    local signature2=$(create_signature_fixed_k "$message_hash" "$priv_key" "$test_gx" "$test_gy" "$test_a" "$test_p" "$test_n" "$fixed_k2")
    local r2=$(echo "$signature2" | cut -d' ' -f1)
    local s2=$(echo "$signature2" | cut -d' ' -f2)
    echo "签名: (r=$r2, s=$s2)"
    echo
    
    debug_manual_verification "$message_hash" "$r2" "$s2" "$pub_key_x" "$pub_key_y" "$test_gx" "$test_gy" "$test_a" "$test_p" "$test_n"
}

# 如果直接运行此脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi