#!/bin/bash
# 修复的ECDSA实现
# 专注于解决签名功能问题

set -euo pipefail

# 脚本目录 (避免重复定义)
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# 导入修复的数学函数
LOCAL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${LOCAL_SCRIPT_DIR}/ec_math_fixed.sh" 2>/dev/null || {
    echo "错误: 无法加载修复的数学函数 (路径: ${LOCAL_SCRIPT_DIR}/ec_math_fixed.sh)" >&2
    exit 1
}

# 简化的确定性k值生成 - 修复版本
generate_deterministic_k_fixed() {
    local private_key="$1"
    local message_hash="$2"
    local curve_order="$3"
    
    # 使用消息哈希和私钥生成确定性k值
    local hmac_input="${private_key}${message_hash}"
    local k_seed=$(echo -n "$hmac_input" | sha256sum | cut -d' ' -f1)
    
    # 转换为整数并确保在有效范围内
    if command -v python3 >/dev/null 2>&1; then
        local k=$(python3 -c "
import hashlib
seed = '$k_seed'
n = int('$curve_order')

# 生成确定性随机数
k = int(seed, 16)
k = (k % (n - 1)) + 1
print(k)
")
    elif command -v python >/dev/null 2>&1; then
        local k=$(python -c "
import hashlib
seed = '$k_seed'
n = int('$curve_order')

# 生成确定性随机数
k = int(seed, 16)
k = (k % (n - 1)) + 1
print(k)
")
    else
        # 回退到简单方法
        local k=$(echo "$k_seed" | head -c 16)
        k=$((16#$k % (${curve_order} - 1) + 1))
    fi
    
    # 确保k在有效范围内 [1, n-1]
    if [[ $(bigint_compare "$k" "1") -le 0 ]]; then
        k="1"
    elif [[ $(bigint_compare "$k" $(bigint_subtract "$curve_order" "1")) -gt 0 ]]; then
        k=$(bigint_subtract "$curve_order" "1")
    fi
    
    echo "$k"
}

# 修复的ECDSA签名
generate_ecdsa_signature() {
    local private_key="$1"
    local message_hash="$2"
    local curve_name="$3"
    
    echo "DEBUG: 开始生成签名 - 曲线: $curve_name" >&2
    echo "DEBUG: 私钥: ${private_key:0:10}..." >&2
    echo "DEBUG: 消息哈希: ${message_hash:0:10}..." >&2
    
    # 获取曲线参数
    local p a b gx gy n
    case "$curve_name" in
        "secp256k1")
            source "${SCRIPT_DIR}/../curves/secp256k1_params.sh" 2>/dev/null || {
                echo "错误: 无法加载SECP256K1参数" >&2
                return 1
            }
            local params=$(get_secp256k1_params)
            ;;
        "secp256r1")
            source "${SCRIPT_DIR}/../curves/secp256r1_params.sh" 2>/dev/null || {
                echo "错误: 无法加载SECP256R1参数" >&2
                return 1
            }
            local params=$(get_secp256r1_params)
            ;;
        *)
            echo "错误: 不支持的曲线 $curve_name" >&2
            return 1
            ;;
    esac
    
    # 解析参数
    p=$(echo "$params" | cut -d' ' -f1)
    a=$(echo "$params" | cut -d' ' -f2)
    b=$(echo "$params" | cut -d' ' -f3)
    gx=$(echo "$params" | cut -d' ' -f4)
    gy=$(echo "$params" | cut -d' ' -f5)
    n=$(echo "$params" | cut -d' ' -f6)
    
    echo "DEBUG: 曲线参数 - p: ${p:0:20}..., n: ${n:0:20}..." >&2
    
    # 验证私钥范围
    if [[ $(bigint_compare "$private_key" "1") -lt 0 || \
          $(bigint_compare "$private_key" $(bigint_subtract "$n" "1")) -gt 0 ]]; then
        echo "错误: 私钥超出有效范围 [1, n-1]" >&2
        return 1
    fi
    
    # 生成确定性k值
    local k=$(generate_deterministic_k_fixed "$private_key" "$message_hash" "$n")
    echo "DEBUG: 生成的k值: ${k:0:20}..." >&2
    
    if [[ $(bigint_compare "$k" "1") -le 0 ]]; then
        k="1"
    fi
    
    # 计算 k × G
    echo "DEBUG: 计算 k × G..." >&2
    local k_point=$(ec_scalar_mult "$k" "$gx" "$gy" "$a" "$p")
    local rx=$(echo "$k_point" | cut -d' ' -f1)
    local ry=$(echo "$k_point" | cut -d' ' -f2)
    
    echo "DEBUG: k×G = ($rx, $ry)" >&2
    
    # 计算 r = rx mod n
    local r=$(bigint_mod "$rx" "$n")
    echo "DEBUG: r = $r" >&2
    
    if [[ "$r" == "0" ]]; then
        echo "错误: r = 0，签名失败" >&2
        return 1
    fi
    
    # 计算 s = k⁻¹(hash + private_key × r) mod n
    echo "DEBUG: 计算 s..." >&2
    local k_inv=$(mod_inverse "$k" "$n")
    if [[ "$k_inv" == "0" ]]; then
        echo "错误: 无法计算k的逆元" >&2
        return 1
    fi
    
    echo "DEBUG: k⁻¹ = $k_inv" >&2
    
    # 计算 private_key × r mod n
    local dr=$(bigint_mod "$(bigint_multiply "$private_key" "$r")" "$n")
    echo "DEBUG: private_key × r mod n = $dr" >&2
    
    # 计算 hash + dr mod n
    local hash_dr=$(bigint_mod "$(bigint_add "$message_hash" "$dr")" "$n")
    echo "DEBUG: hash + dr mod n = $hash_dr" >&2
    
    # 计算 s = k⁻¹ × (hash + dr) mod n
    local s=$(bigint_mod "$(bigint_multiply "$k_inv" "$hash_dr")" "$n")
    echo "DEBUG: s = $s" >&2
    
    if [[ "$s" == "0" ]]; then
        echo "错误: s = 0，签名失败" >&2
        return 1
    fi
    
    # 返回签名
    echo "$r $s"
}

# 修复的ECDSA验证
verify_ecdsa_signature_fixed() {
    local public_key_x="$1"
    local public_key_y="$2"
    local message_hash="$3"
    local r="$4"
    local s="$5"
    local curve_name="$6"
    
    echo "DEBUG: 开始验证签名 - 曲线: $curve_name" >&2
    echo "DEBUG: 公钥: ($public_key_x, $public_key_y)" >&2
    echo "DEBUG: 消息哈希: ${message_hash:0:20}..." >&2
    echo "DEBUG: 签名: (r=$r, s=$s)" >&2
    
    # 获取曲线参数
    local p a b gx gy n
    case "$curve_name" in
        "secp256k1")
            source "${SCRIPT_DIR}/../curves/secp256k1_params.sh" 2>/dev/null || {
                echo "错误: 无法加载SECP256K1参数" >&2
                return 1
            }
            local params=$(get_secp256k1_params)
            ;;
        "secp256r1")
            source "${SCRIPT_DIR}/../curves/secp256r1_params.sh" 2>/dev/null || {
                echo "错误: 无法加载SECP256R1参数" >&2
                return 1
            }
            local params=$(get_secp256r1_params)
            ;;
        *)
            echo "错误: 不支持的曲线 $curve_name" >&2
            return 1
            ;;
    esac
    
    # 解析参数
    p=$(echo "$params" | cut -d' ' -f1)
    a=$(echo "$params" | cut -d' ' -f2)
    b=$(echo "$params" | cut -d' ' -f3)
    gx=$(echo "$params" | cut -d' ' -f4)
    gy=$(echo "$params" | cut -d' ' -f5)
    n=$(echo "$params" | cut -d' ' -f6)
    
    echo "DEBUG: 验证r和s的范围..." >&2
    
    # 验证r和s的范围 [1, n-1]
    if [[ $(bigint_compare "$r" "1") -lt 0 || \
          $(bigint_compare "$r" $(bigint_subtract "$n" "1")) -gt 0 ]]; then
        echo "DEBUG: r超出范围" >&2
        return 1
    fi
    
    if [[ $(bigint_compare "$s" "1") -lt 0 || \
          $(bigint_compare "$s" $(bigint_subtract "$n" "1")) -gt 0 ]]; then
        echo "DEBUG: s超出范围" >&2
        return 1
    fi
    
    echo "DEBUG: 计算s⁻¹..." >&2
    
    # 计算 s⁻¹
    local s_inv=$(mod_inverse "$s" "$n")
    if [[ "$s_inv" == "0" ]]; then
        echo "DEBUG: 无法计算s的逆元" >&2
        return 1
    fi
    
    echo "DEBUG: s⁻¹ = $s_inv" >&2
    
    # 计算 u₁ = hash × s⁻¹ mod n
    echo "DEBUG: 计算u₁ = hash × s⁻¹ mod n..." >&2
    local u1=$(bigint_mod "$(bigint_multiply "$message_hash" "$s_inv")" "$n")
    echo "DEBUG: u₁ = $u1" >&2
    
    # 计算 u₂ = r × s⁻¹ mod n
    echo "DEBUG: 计算u₂ = r × s⁻¹ mod n..." >&2
    local u2=$(bigint_mod "$(bigint_multiply "$r" "$s_inv")" "$n")
    echo "DEBUG: u₂ = $u2" >&2
    
    # 计算 P = u₁ × G + u₂ × Q
    echo "DEBUG: 计算P = u₁ × G + u₂ × Q..." >&2
    local u1_point=$(ec_scalar_mult "$u1" "$gx" "$gy" "$a" "$p")
    local u2_point=$(ec_scalar_mult "$u2" "$public_key_x" "$public_key_y" "$a" "$p")
    
    local u1x=$(echo "$u1_point" | cut -d' ' -f1)
    local u1y=$(echo "$u1_point" | cut -d' ' -f2)
    local u2x=$(echo "$u2_point" | cut -d' ' -f1)
    local u2y=$(echo "$u2_point" | cut -d' ' -f2)
    
    echo "DEBUG: u₁×G = ($u1x, $u1y)" >&2
    echo "DEBUG: u₂×Q = ($u2x, $u2y)" >&2
    
    local sum_point=$(ec_point_add "$u1x" "$u1y" "$u2x" "$u2y" "$a" "$p")
    local sum_x=$(echo "$sum_point" | cut -d' ' -f1)
    local sum_y=$(echo "$sum_point" | cut -d' ' -f2)
    
    echo "DEBUG: P = ($sum_x, $sum_y)" >&2
    
    # 验证 v = sum_x mod n == r
    echo "DEBUG: 计算v = sum_x mod n..." >&2
    local v=$(bigint_mod "$sum_x" "$n")
    echo "DEBUG: v = $v, r = $r" >&2
    
    if [[ "$v" == "$r" ]]; then
        echo "DEBUG: 签名验证通过!" >&2
        return 0  # 验证通过
    else
        echo "DEBUG: 签名验证失败: v ≠ r" >&2
        return 1  # 验证失败
    fi
}

# 测试函数
test_fixed_ecdsa() {
    echo "测试修复的ECDSA实现"
    echo "========================"
    
    # 使用小参数测试
    local test_curve="secp256k1"
    local test_message="Hello, ECDSA!"
    local test_hash=$(echo -n "$test_message" | sha256sum | cut -d' ' -f1)
    test_hash=$((16#$test_hash))  # 转换为十进制
    
    echo "测试消息: $test_message"
    echo "消息哈希: $test_hash"
    echo "测试曲线: $test_curve"
    echo ""
    
    # 生成测试密钥对（使用简单私钥）
    local private_key="1234567890123456789012345678901234567890123456789012345678901234"
    
    echo "测试私钥: $private_key"
    echo ""
    
    # 生成签名
    echo "生成签名..."
    local signature=$(generate_ecdsa_signature "$private_key" "$test_hash" "$test_curve")
    
    if [[ $? -eq 0 ]]; then
        local r=$(echo "$signature" | cut -d' ' -f1)
        local s=$(echo "$signature" | cut -d' ' -f2)
        echo "签名生成成功!"
        echo "r = $r"
        echo "s = $s"
        echo ""
        
        # 计算公钥（简化版本）
        echo "计算公钥..."
        
        # 获取曲线参数
        local params
        case "$test_curve" in
            "secp256k1")
                source "${SCRIPT_DIR}/../curves/secp256k1_params.sh"
                params=$(get_secp256k1_params)
                ;;
            "secp256r1")
                source "${SCRIPT_DIR}/../curves/secp256r1_params.sh"
                params=$(get_secp256r1_params)
                ;;
        esac
        
        local gx=$(echo "$params" | cut -d' ' -f4)
        local gy=$(echo "$params" | cut -d' ' -f5)
        local a=$(echo "$params" | cut -d' ' -f2)
        local p=$(echo "$params" | cut -d' ' -f1)
        
        local pub_point=$(ec_scalar_mult "$private_key" "$gx" "$gy" "$a" "$p")
        local pub_x=$(echo "$pub_point" | cut -d' ' -f1)
        local pub_y=$(echo "$pub_point" | cut -d' ' -f2)
        
        echo "公钥: ($pub_x, $pub_y)"
        echo ""
        
        # 验证签名
        echo "验证签名..."
        if verify_ecdsa_signature_fixed "$pub_x" "$pub_y" "$test_hash" "$r" "$s" "$test_curve"; then
            echo "✅ 签名验证成功!"
        else
            echo "❌ 签名验证失败!"
        fi
    else
        echo "❌ 签名生成失败!"
    fi
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_fixed_ecdsa
fi

# 导出函数以便其他脚本使用
export -f generate_deterministic_k_fixed generate_ecdsa_signature verify_ecdsa_signature_fixed