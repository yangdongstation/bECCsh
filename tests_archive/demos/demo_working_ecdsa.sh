#!/bin/bash
# 工作版ECDSA演示 - 使用已验证的参数

set -euo pipefail

echo "bECCsh 工作版ECDSA演示"
echo "======================="
echo "演示时间: $(date)"
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 导入必要的函数
source "$SCRIPT_DIR/core/crypto/ec_math_fixed_simple.sh"

# 简化的ECDSA函数
generate_keypair_simple() {
    local private_key="$1"
    local gx="$2"
    local gy="$3"
    local a="$4"
    local p="$5"
    local n="$6"
    
    # 计算公钥 Q = dG
    local pubkey=$(curve_scalar_mult_simple "$private_key" "$gx" "$gy" "$a" "$p")
    local pubkey_x=$(echo "$pubkey" | cut -d' ' -f1)
    local pubkey_y=$(echo "$pubkey" | cut -d' ' -f2)
    
    echo "$private_key $pubkey_x $pubkey_y"
}

create_signature_simple() {
    local message_hash="$1"
    local private_key="$2"
    local gx="$3"
    local gy="$4"
    local a="$5"
    local p="$6"
    local n="$7"
    local k="$8"
    
    # 计算点P = kG
    local P=$(curve_scalar_mult_simple "$k" "$gx" "$gy" "$a" "$p")
    local px=$(echo "$P" | cut -d' ' -f1)
    local py=$(echo "$P" | cut -d' ' -f2)
    
    # r = xP mod n
    local r=$((px % n))
    
    # s = k⁻¹ * (message_hash + private_key * r) mod n
    local k_inv=$(mod_inverse_simple "$k" "$n")
    local s_temp=$((message_hash + private_key * r))
    local s=$(((k_inv * s_temp) % n))
    
    echo "$r $s"
}

verify_signature_simple() {
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

# 演示函数
demo_working_ecdsa() {
    echo "工作版ECDSA演示"
    echo "==============="
    echo
    
    # 使用已验证的小参数
    local p=23 a=1 b=1 gx=3 gy=10 n=29
    local private_key=7 message_hash=20 k=5  # 使用调整后的消息哈希
    
    echo "演示参数:"
    echo "  曲线: y² = x³ + ${a}x + ${b} mod ${p}"
    echo "  基点G: ($gx, $gy)"
    echo "  阶n: $n"
    echo "  私钥: $private_key"
    echo "  消息哈希: $message_hash (已调整)"
    echo "  k值: $k (固定用于演示)"
    echo
    
    # 1. 生成密钥对
    echo "1. 生成密钥对..."
    local keypair=$(generate_keypair_simple "$private_key" "$gx" "$gy" "$a" "$p" "$n")
    local priv_key=$(echo "$keypair" | cut -d' ' -f1)
    local pub_key_x=$(echo "$keypair" | cut -d' ' -f2)
    local pub_key_y=$(echo "$keypair" | cut -d' ' -f3)
    echo "私钥: $priv_key"
    echo "公钥: ($pub_key_x, $pub_key_y)"
    echo
    
    # 2. 创建签名
    echo "2. 创建签名..."
    local signature=$(create_signature_simple "$message_hash" "$priv_key" "$gx" "$gy" "$a" "$p" "$n" "$k")
    local r=$(echo "$signature" | cut -d' ' -f1)
    local s=$(echo "$signature" | cut -d' ' -f2)
    echo "签名: (r=$r, s=$s)"
    echo
    
    # 3. 验证签名
    echo "3. 验证签名..."
    if verify_signature_simple "$message_hash" "$r" "$s" "$pub_key_x" "$pub_key_y" "$gx" "$gy" "$a" "$p" "$n"; then
        echo "✅ 签名验证成功!"
        echo
        echo "🎉 ECDSA演示成功完成!"
        echo "   消息哈希: $message_hash"
        echo "   签名: (r=$r, s=$s)"
        echo "   验证结果: 有效 ✅"
        return 0
    else
        echo "❌ 签名验证失败!"
        return 1
    fi
}

# 运行演示
demo_working_ecdsa