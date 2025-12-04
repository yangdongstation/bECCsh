#!/bin/bash
# 最终ECDSA测试 - 统一参数确保一致性

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ec_math_fixed_simple.sh"

# 生成密钥对
generate_keypair() {
    local private_key="$1"
    local gx="$2"
    local gy="$3"
    local a="$4"
    local p="$5"
    local n="$6"
    
    # 确保私钥在有效范围内
    private_key=$((private_key % n))
    if [[ $private_key -eq 0 ]]; then
        private_key="1"
    fi
    
    # 计算公钥 Q = dG
    local pubkey=$(curve_scalar_mult_simple "$private_key" "$gx" "$gy" "$a" "$p")
    local pubkey_x=$(echo "$pubkey" | cut -d' ' -f1)
    local pubkey_y=$(echo "$pubkey" | cut -d' ' -f2)
    
    echo "$private_key $pubkey_x $pubkey_y"
}

# 固定k值的签名创建（无调试输出）
create_signature_fixed_k() {
    local message_hash="$1"
    local private_key="$2"
    local gx="$3"
    local gy="$4"
    local a="$5"
    local p="$6"
    local n="$7"
    local k="$8"  # 固定的k值
    
    # 确保消息哈希在有效范围内
    message_hash=$((message_hash % n))
    if [[ $message_hash -eq 0 ]]; then
        message_hash="1"
    fi
    
    # 计算点P = kG
    local P=$(curve_scalar_mult_simple "$k" "$gx" "$gy" "$a" "$p")
    local px=$(echo "$P" | cut -d' ' -f1)
    local py=$(echo "$P" | cut -d' ' -f2)
    
    # r = xP mod n
    local r=$((px % n))
    
    if [[ $r -le 0 || $r -ge $n ]]; then
        return 1
    fi
    
    # s = k⁻¹ * (message_hash + private_key * r) mod n
    local k_inv=$(mod_inverse_simple "$k" "$n")
    local s_temp=$((message_hash + private_key * r))
    local s=$(((k_inv * s_temp) % n))
    
    if [[ $s -eq 0 ]]; then
        return 1
    fi
    
    echo "$r $s"
}

# 验证签名
verify_signature() {
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
    
    # 检查r和s的范围
    if [[ $r -le 0 || $r -ge $n || $s -le 0 || $s -ge $n ]]; then
        return 1
    fi
    
    # 确保消息哈希在有效范围内
    message_hash=$((message_hash % n))
    if [[ $message_hash -eq 0 ]]; then
        message_hash="1"
    fi
    
    # 计算w = s⁻¹ mod n
    local w=$(mod_inverse_simple "$s" "$n")
    
    # 计算u1 = message_hash * w mod n
    local u1=$((message_hash * w % n))
    
    # 计算u2 = r * w mod n
    local u2=$((r * w % n))
    
    # 计算点P = u1G + u2Q
    local P1=$(curve_scalar_mult_simple "$u1" "$gx" "$gy" "$a" "$p")
    local P2=$(curve_scalar_mult_simple "$u2" "$pubkey_x" "$pubkey_y" "$a" "$p")
    
    local P1_x=$(echo "$P1" | cut -d' ' -f1)
    local P1_y=$(echo "$P1" | cut -d' ' -f2)
    local P2_x=$(echo "$P2" | cut -d' ' -f1)
    local P2_y=$(echo "$P2" | cut -d' ' -f2)
    
    # P = P1 + P2
    local P=$(curve_point_add_correct "$P1_x" "$P1_y" "$P2_x" "$P2_y" "$a" "$p")
    local px=$(echo "$P" | cut -d' ' -f1)
    
    # v = xP mod n
    local v=$((px % n))
    
    if [[ "$v" == "$r" ]]; then
        return 0
    else
        return 1
    fi
}

# 主测试函数
main() {
    echo "最终ECDSA测试 - 统一参数"
    echo "========================="
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
    
    echo "测试参数:"
    echo "  曲线: y² = x³ + ${test_a}x + ${test_b} mod ${test_p}"
    echo "  基点G: (${test_gx}, ${test_gy})"
    echo "  阶n: ${test_n}"
    echo "  私钥: $private_key"
    echo "  消息哈希: $message_hash"
    echo
    
    # 1. 生成密钥对
    echo "1. 生成密钥对..."
    local keypair=$(generate_keypair "$private_key" "$test_gx" "$test_gy" "$test_a" "$test_p" "$test_n")
    local priv_key=$(echo "$keypair" | cut -d' ' -f1)
    local pub_key_x=$(echo "$keypair" | cut -d' ' -f2)
    local pub_key_y=$(echo "$keypair" | cut -d' ' -f3)
    echo "私钥: $priv_key"
    echo "公钥: ($pub_key_x, $pub_key_y)"
    echo
    
    # 2. 测试不同的k值
    echo "2. 测试不同的k值..."
    local test_k_values=(1 2 3 4 5 6 7 8 9 10 15 20 25 28)
    local success_count=0
    local total_count=0
    
    for k in "${test_k_values[@]}"; do
        echo -n "  k=$k: "
        total_count=$((total_count + 1))
        
        if signature=$(create_signature_fixed_k "$message_hash" "$priv_key" "$test_gx" "$test_gy" "$test_a" "$test_p" "$test_n" "$k" 2>/dev/null); then
            local r=$(echo "$signature" | cut -d' ' -f1)
            local s=$(echo "$signature" | cut -d' ' -f2)
            
            if verify_signature "$message_hash" "$r" "$s" "$pub_key_x" "$pub_key_y" "$test_gx" "$test_gy" "$test_a" "$test_p" "$test_n"; then
                echo "✅ 成功 (r=$r, s=$s)"
                success_count=$((success_count + 1))
            else
                echo "❌ 验证失败 (r=$r, s=$s)"
            fi
        else
            echo "❌ 签名创建失败"
        fi
    done
    
    echo
    echo "测试结果: $success_count/$total_count 成功"
    
    if [[ $success_count -eq $total_count ]]; then
        echo
        echo "🎉 所有测试通过! ECDSA实现已修复!"
        return 0
    else
        echo
        echo "❌ 部分测试失败，需要进一步调试"
        return 1
    fi
}

# 如果直接运行此脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi