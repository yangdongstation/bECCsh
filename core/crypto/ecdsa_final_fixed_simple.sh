#!/bin/bash
# 最终修复版ECDSA实现 - 简化版本
# 使用纯Bash数学运算，专注于功能正确性

set -euo pipefail

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 导入修复的数学运算
source "$SCRIPT_DIR/ec_math_fixed_simple.sh"

# 日志函数
log_info() {
    echo "[INFO] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

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

# ECDSA签名
create_signature() {
    local message_hash="$1"
    local private_key="$2"
    local gx="$3"
    local gy="$4"
    local a="$5"
    local p="$6"
    local n="$7"
    
    log_info "创建签名 - 消息哈希: $message_hash, 私钥: $private_key"
    
    # 确保消息哈希在有效范围内
    message_hash=$((message_hash % n))
    if [[ $message_hash -eq 0 ]]; then
        message_hash="1"
    fi
    
    # 生成随机数k，确保r有效
    local k r px py
    local max_attempts=10
    local attempts=0
    
    while [[ $attempts -lt $max_attempts ]]; do
        k=$((RANDOM % (n - 1) + 1))
        
        # 计算点P = kG
        local P=$(curve_scalar_mult_simple "$k" "$gx" "$gy" "$a" "$p")
        px=$(echo "$P" | cut -d' ' -f1)
        py=$(echo "$P" | cut -d' ' -f2)
        
        # r = xP mod n
        r=$((px % n))
        
        # 确保r在有效范围内
        if [[ $r -gt 0 && $r -lt $n ]]; then
            break
        fi
        
        attempts=$((attempts + 1))
        log_info "尝试 $attempts: r = $r 无效，重新生成k"
    done
    
    if [[ $attempts -ge $max_attempts ]]; then
        log_error "无法在 $max_attempts 次尝试内生成有效的r"
        return 1
    fi
    
    # s = k⁻¹ * (message_hash + private_key * r) mod n
    local k_inv=$(mod_inverse_simple "$k" "$n")
    local s_temp=$((message_hash + private_key * r))
    local s=$(( (k_inv * s_temp) % n ))
    
    if [[ $s -eq 0 ]]; then
        log_error "s = 0, 需要重新生成k"
        return 1
    fi
    
    log_info "签名创建成功 - r: $r, s: $s"
    echo "$r $s"
}

# ECDSA签名验证
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
    
    log_info "验证签名 - 消息哈希: $message_hash, r: $r, s: $s"
    
    # 检查r和s的范围
    if [[ $r -le 0 || $r -ge $n || $s -le 0 || $s -ge $n ]]; then
        log_error "r或s超出有效范围"
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
    
    log_info "验证计算 - v: $v, r: $r"
    
    if [[ "$v" == "$r" ]]; then
        log_info "✅ 签名验证成功!"
        return 0
    else
        log_info "❌ 签名验证失败!"
        return 1
    fi
}

# 主测试函数
main() {
    echo "最终修复版ECDSA测试 - 简化版本"
    echo "===================================="
    echo
    
    # 使用小参数进行测试
    echo "使用小参数进行功能测试..."
    echo
    
    # 小参数椭圆曲线
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
    
    # 2. 创建签名
    echo "2. 创建签名..."
    echo "测试消息: $message"
    echo "消息哈希: $message_hash"
    
    if signature=$(create_signature "$message_hash" "$priv_key" "$test_gx" "$test_gy" "$test_a" "$test_p" "$test_n"); then
        local r=$(echo "$signature" | cut -d' ' -f1)
        local s=$(echo "$signature" | cut -d' ' -f2)
        echo "签名: (r=$r, s=$s)"
        echo
        
        # 3. 验证签名
        echo "3. 验证签名..."
        if verify_signature "$message_hash" "$r" "$s" "$pub_key_x" "$pub_key_y" "$test_gx" "$test_gy" "$test_a" "$test_p" "$test_n"; then
            echo "✅ ECDSA测试成功完成!"
        else
            echo "❌ 签名验证失败"
            exit 1
        fi
    else
        echo "❌ 签名创建失败"
        exit 1
    fi
    
    echo
    echo "====================================="
    echo "🎉 所有测试通过!"
    echo "====================================="
}

# 如果直接运行此脚本，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi