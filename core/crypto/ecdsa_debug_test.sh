#!/bin/bash
# ECDSA调试测试 - 详细输出验证过程

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ec_math_fixed_simple.sh"
source "$SCRIPT_DIR/ecdsa_final_fixed_simple.sh"

log_info() {
    echo "[INFO] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

# 调试版签名验证
debug_verify_signature() {
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
    
    echo "=== ECDSA签名验证调试 ==="
    echo "输入参数:"
    echo "  消息哈希: $message_hash"
    echo "  签名: (r=$r, s=$s)"
    echo "  公钥: ($pubkey_x, $pubkey_y)"
    echo "  基点G: ($gx, $gy)"
    echo "  曲线参数: a=$a, p=$p, n=$n"
    echo
    
    # 检查r和s的范围
    if [[ $r -le 0 || $r -ge $n || $s -le 0 || $s -ge $n ]]; then
        echo "❌ r或s超出有效范围"
        return 1
    fi
    
    # 确保消息哈希在有效范围内
    message_hash=$((message_hash % n))
    if [[ $message_hash -eq 0 ]]; then
        message_hash="1"
    fi
    
    echo "步骤1: 计算 w = s⁻¹ mod n"
    local w=$(mod_inverse_simple "$s" "$n")
    echo "  s = $s, n = $n"
    echo "  w = s⁻¹ mod n = $w"
    echo
    
    echo "步骤2: 计算 u₁ = message_hash × w mod n"
    local u1=$((message_hash * w % n))
    echo "  message_hash = $message_hash"
    echo "  u₁ = $message_hash × $w mod $n = $u1"
    echo
    
    echo "步骤3: 计算 u₂ = r × w mod n"
    local u2=$((r * w % n))
    echo "  r = $r"
    echo "  u₂ = $r × $w mod $n = $u2"
    echo
    
    echo "步骤4: 计算 P₁ = u₁ × G"
    local P1=$(curve_scalar_mult_simple "$u1" "$gx" "$gy" "$a" "$p")
    local P1_x=$(echo "$P1" | cut -d' ' -f1)
    local P1_y=$(echo "$P1" | cut -d' ' -f2)
    echo "  u₁ = $u1, G = ($gx, $gy)"
    echo "  P₁ = u₁ × G = ($P1_x, $P1_y)"
    echo
    
    echo "步骤5: 计算 P₂ = u₂ × Q (Q是公钥)"
    local P2=$(curve_scalar_mult_simple "$u2" "$pubkey_x" "$pubkey_y" "$a" "$p")
    local P2_x=$(echo "$P2" | cut -d' ' -f1)
    local P2_y=$(echo "$P2" | cut -d' ' -f2)
    echo "  u₂ = $u2, Q = ($pubkey_x, $pubkey_y)"
    echo "  P₂ = u₂ × Q = ($P2_x, $P2_y)"
    echo
    
    echo "步骤6: 计算 P = P₁ + P₂"
    local P=$(curve_point_add_correct "$P1_x" "$P1_y" "$P2_x" "$P2_y" "$a" "$p")
    local px=$(echo "$P" | cut -d' ' -f1)
    local py=$(echo "$P" | cut -d' ' -f2)
    echo "  P₁ = ($P1_x, $P1_y), P₂ = ($P2_x, $P2_y)"
    echo "  P = P₁ + P₂ = ($px, $py)"
    echo
    
    echo "步骤7: 计算 v = xₚ mod n"
    local v=$((px % n))
    echo "  xₚ = $px, n = $n"
    echo "  v = $px mod $n = $v"
    echo
    
    echo "步骤8: 比较 v 和 r"
    echo "  v = $v, r = $r"
    
    if [[ "$v" == "$r" ]]; then
        echo "✅ 签名验证成功! v = r"
        return 0
    else
        echo "❌ 签名验证失败! v ≠ r"
        return 1
    fi
}

# 主调试函数
main() {
    echo "ECDSA签名验证调试测试"
    echo "===================="
    echo
    
    # 测试参数
    local test_p=23
    local test_a=1
    local test_b=1
    local test_gx=3
    local test_gy=10
    local test_n=29
    local private_key=7
    local message="Hello, ECDSA!"
    local message_hash=12345
    
    echo "测试曲线: y² = x³ + ${test_a}x + ${test_b} mod ${test_p}"
    echo "基点G: (${test_gx}, ${test_gy})"
    echo "阶n: ${test_n}"
    echo "私钥: $private_key"
    echo "消息: $message"
    echo "消息哈希: $message_hash"
    echo
    
    # 生成密钥对
    echo "=== 生成密钥对 ==="
    local keypair=$(generate_keypair "$private_key" "$test_gx" "$test_gy" "$test_a" "$test_p" "$test_n")
    local priv_key=$(echo "$keypair" | cut -d' ' -f1)
    local pub_key_x=$(echo "$keypair" | cut -d' ' -f2)
    local pub_key_y=$(echo "$keypair" | cut -d' ' -f3)
    echo "私钥: $priv_key"
    echo "公钥: ($pub_key_x, $pub_key_y)"
    echo
    
    # 创建签名
    echo "=== 创建签名 ==="
    if signature=$(create_signature "$message_hash" "$priv_key" "$test_gx" "$test_gy" "$test_a" "$test_p" "$test_n"); then
        local r=$(echo "$signature" | cut -d' ' -f1)
        local s=$(echo "$signature" | cut -d' ' -f2)
        echo "签名: (r=$r, s=$s)"
        echo
        
        # 调试签名验证
        debug_verify_signature "$message_hash" "$r" "$s" "$pub_key_x" "$pub_key_y" "$test_gx" "$test_gy" "$test_a" "$test_p" "$test_n"
    else
        echo "❌ 签名创建失败"
        exit 1
    fi
}

# 如果直接运行此脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi