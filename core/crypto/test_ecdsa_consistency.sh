#!/bin/bash
# ECDSA一致性测试 - 确保相同输入产生相同输出

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ec_math_fixed_simple.sh"
source "$SCRIPT_DIR/ecdsa_final_fixed_simple.sh"

# 测试ECDSA的确定性
test_ecdsa_deterministic() {
    echo "ECDSA确定性测试"
    echo "=================="
    echo
    
    # 固定参数
    local test_p=23
    local test_a=1
    local test_b=1
    local test_gx=3
    local test_gy=10
    local test_n=29
    local private_key=7
    local message_hash=12345
    
    echo "固定参数:"
    echo "  曲线: y² = x³ + ${test_a}x + ${test_b} mod ${test_p}"
    echo "  基点G: (${test_gx}, ${test_gy})"
    echo "  阶n: ${test_n}"
    echo "  私钥: $private_key"
    echo "  消息哈希: $message_hash"
    echo
    
    # 生成密钥对（应该总是相同的）
    echo "1. 生成密钥对..."
    local keypair=$(generate_keypair "$private_key" "$test_gx" "$test_gy" "$test_a" "$test_p" "$test_n")
    local priv_key=$(echo "$keypair" | cut -d' ' -f1)
    local pub_key_x=$(echo "$keypair" | cut -d' ' -f2)
    local pub_key_y=$(echo "$keypair" | cut -d' ' -f3)
    echo "私钥: $priv_key"
    echo "公钥: ($pub_key_x, $pub_key_y)"
    echo
    
    # 为了测试一致性，我们需要固定k值
    echo "2. 手动创建签名（固定k=5）..."
    local k=5
    
    # 计算点P = kG
    local P=$(curve_scalar_mult_simple "$k" "$test_gx" "$test_gy" "$test_a" "$test_p")
    local px=$(echo "$P" | cut -d' ' -f1)
    local py=$(echo "$P" | cut -d' ' -f2)
    echo "k = $k"
    echo "P = kG = ($px, $py)"
    
    # r = xP mod n
    local r=$((px % test_n))
    echo "r = xP mod n = $px mod $test_n = $r"
    
    # 确保消息哈希在有效范围内
    message_hash=$((message_hash % test_n))
    if [[ $message_hash -eq 0 ]]; then
        message_hash="1"
    fi
    echo "消息哈希 (mod n) = $message_hash"
    
    # s = k⁻¹ * (message_hash + private_key * r) mod n
    local k_inv=$(mod_inverse_simple "$k" "$test_n")
    local s_temp=$((message_hash + private_key * r))
    local s=$(((k_inv * s_temp) % test_n))
    echo "k⁻¹ = $k_inv"
    echo "s = k⁻¹ × (message_hash + private_key × r) mod n"
    echo "s = $k_inv × ($message_hash + $private_key × $r) mod $test_n = $s"
    echo "签名: (r=$r, s=$s)"
    echo
    
    # 手动验证签名
    echo "3. 手动验证签名..."
    echo "计算 w = s⁻¹ mod n = $s⁻¹ mod $test_n"
    local w=$(mod_inverse_simple "$s" "$test_n")
    echo "w = $w"
    
    echo "计算 u₁ = message_hash × w mod n"
    local u1=$((message_hash * w % test_n))
    echo "u₁ = $message_hash × $w mod $test_n = $u1"
    
    echo "计算 u₂ = r × w mod n"
    local u2=$((r * w % test_n))
    echo "u₂ = $r × $w mod $test_n = $u2"
    
    echo "计算 P₁ = u₁ × G"
    local P1=$(curve_scalar_mult_simple "$u1" "$test_gx" "$test_gy" "$test_a" "$test_p")
    local P1_x=$(echo "$P1" | cut -d' ' -f1)
    local P1_y=$(echo "$P1" | cut -d' ' -f2)
    echo "P₁ = $u1 × G = ($P1_x, $P1_y)"
    
    echo "计算 P₂ = u₂ × Q"
    local P2=$(curve_scalar_mult_simple "$u2" "$pub_key_x" "$pub_key_y" "$test_a" "$test_p")
    local P2_x=$(echo "$P2" | cut -d' ' -f1)
    local P2_y=$(echo "$P2" | cut -d' ' -f2)
    echo "P₂ = $u2 × Q = ($P2_x, $P2_y)"
    
    echo "计算 P = P₁ + P₂"
    local P=$(curve_point_add_correct "$P1_x" "$P1_y" "$P2_x" "$P2_y" "$test_a" "$test_p")
    local px=$(echo "$P" | cut -d' ' -f1)
    local py=$(echo "$P" | cut -d' ' -f2)
    echo "P = P₁ + P₂ = ($px, $py)"
    
    echo "计算 v = xₚ mod n"
    local v=$((px % test_n))
    echo "v = $px mod $test_n = $v"
    echo
    
    echo "验证结果:"
    echo "  v = $v, r = $r"
    if [[ "$v" == "$r" ]]; then
        echo "✅ 签名验证成功!"
    else
        echo "❌ 签名验证失败!"
    fi
}

# 测试消息哈希处理
test_message_hash() {
    echo "消息哈希处理测试"
    echo "=================="
    echo
    
    local test_messages=(
        "Hello"
        "12345"
        "0"
        "999999"
    )
    
    local test_n=29
    
    for message in "${test_messages[@]}"; do
        echo "原始消息: '$message'"
        
        # 模拟消息哈希处理
        local hash_val
        if [[ "$message" =~ ^[0-9]+$ ]]; then
            hash_val=$message
        else
            # 简单的字符串到数字转换
            hash_val=0
            for ((i=0; i<${#message}; i++)); do
                local char="${message:$i:1}"
                local ord=$(printf "%d" "'$char")
                hash_val=$((hash_val + ord))
            done
        fi
        
        echo "  哈希值: $hash_val"
        
        # 确保哈希值在有效范围内
        local final_hash=$((hash_val % test_n))
        if [[ $final_hash -eq 0 ]]; then
            final_hash="1"
        fi
        
        echo "  最终哈希 (mod n, 非零): $final_hash"
        echo
    done
}

# 主函数
main() {
    test_ecdsa_deterministic
    echo
    echo
    test_message_hash
}

# 如果直接运行此脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi