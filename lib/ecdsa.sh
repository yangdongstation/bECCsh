#!/bin/bash
# ECDSA - 椭圆曲线数字签名算法
# 实现完整的ECDSA签名和验证功能

set -euo pipefail

# 导入保护 - 防止重复定义
if [[ -n "${ECDSA_LOADED:-}" ]]; then
    return 0
fi
readonly ECDSA_LOADED=1

# 导入数学库
source "$(dirname "${BASH_SOURCE[0]}")/bash_math.sh"

# 导入必要的库
source "$(dirname "${BASH_SOURCE[0]}")/bigint.sh"
source "$(dirname "${BASH_SOURCE[0]}")/ec_curve.sh"
source "$(dirname "${BASH_SOURCE[0]}")/ec_point.sh"
source "$(dirname "${BASH_SOURCE[0]}")/security.sh"

# ECDSA全局变量
ECDSA_SIGNATURE_R=""
ECDSA_SIGNATURE_S=""

# ECDSA错误处理
ecdsa_error() {
    echo "ECDSA错误: $*" >&2
    return 1
}

# 生成ECDSA私钥
ecdsa_generate_private_key() {
    local max_attempts=10
    local attempts=0
    
    while [[ $attempts -lt $max_attempts ]]; do
        # 生成随机私钥
        local private_key=$(bigint_random "256")
        
        # 确保私钥在有效范围内 [1, n-1]
        private_key=$(bigint_mod "$private_key" $(bigint_subtract "$CURVE_N" "1"))
        private_key=$(bigint_add "$private_key" "1")
        
        # 验证私钥有效性
        if [[ $(bigint_compare "$private_key" "1") -ge 0 && \
              $(bigint_compare "$private_key" $(bigint_subtract "$CURVE_N" "1")) -le 0 ]]; then
            echo "$private_key"
            return 0
        fi
        
        ((attempts++))
    done
    
    ecdsa_error "无法生成有效的私钥"
    return 1
}

# 从私钥计算公钥
ecdsa_get_public_key() {
    local private_key="$1"
    
    if [[ -z "$CURVE_GX" || -z "$CURVE_GY" || -z "$CURVE_P" ]]; then
        ecdsa_error "曲线参数未初始化"
        return 1
    fi
    
    # 验证私钥
    if [[ $(bigint_compare "$private_key" "1") -lt 0 || \
          $(bigint_compare "$private_key" $(bigint_subtract "$CURVE_N" "1")) -gt 0 ]]; then
        ecdsa_error "私钥超出有效范围"
        return 1
    fi
    
    # 计算公钥 Q = dG
    local public_key=$(ec_point_multiply "$private_key" "$CURVE_GX" "$CURVE_GY")
    if [[ $? -ne 0 ]]; then
        ecdsa_error "公钥计算失败"
        return 1
    fi
    
    echo "$public_key"
}

# 计算消息的哈希值
hash_message() {
    local message="$1"
    local hash_alg="${2:-sha256}"
    
    case "$hash_alg" in
        "sha256")
            if command -v sha256sum >/dev/null 2>&1; then
                echo -n "$message" | sha256sum | cut -d' ' -f1
            elif command -v shasum >/dev/null 2>&1; then
                echo -n "$message" | shasum -a 256 | cut -d' ' -f1
            else
                # 备用哈希实现
                ecdsa_error "未找到sha256sum或shasum命令"
                return 1
            fi
            ;;
        "sha384")
            if command -v sha384sum >/dev/null 2>&1; then
                echo -n "$message" | sha384sum | cut -d' ' -f1
            elif command -v shasum >/dev/null 2>&1; then
                echo -n "$message" | shasum -a 384 | cut -d' ' -f1
            else
                ecdsa_error "未找到sha384sum或shasum命令"
                return 1
            fi
            ;;
        "sha512")
            if command -v sha512sum >/dev/null 2>&1; then
                echo -n "$message" | sha512sum | cut -d' ' -f1
            elif command -v shasum >/dev/null 2>&1; then
                echo -n "$message" | shasum -a 512 | cut -d' ' -f1
            else
                ecdsa_error "未找到sha512sum或shasum命令"
                return 1
            fi
            ;;
        *)
            ecdsa_error "不支持的哈希算法: $hash_alg"
            return 1
            ;;
    esac
}

# 将十六进制哈希转换为整数
hash_to_int() {
    local hash_hex="$1"
    
    # 移除可能的空格和换行符
    hash_hex=$(echo "$hash_hex" | tr -d '[:space:]')
    
    # 转换为小写
    hash_hex=${hash_hex,,}
    
    # 转换为十进制
    local hash_int=$(bashmath_hex_to_dec "$hash_hex" || echo "0")
    
    # 确保哈希值小于曲线阶n
    hash_int=$(bigint_mod "$hash_int" "$CURVE_N")
    
    echo "$hash_int"
}

# ECDSA签名
ecdsa_sign() {
    local private_key="$1"
    local message_hash="$2"
    local curve_name="${3:-secp256r1}"
    local hash_alg="${4:-sha256}"
    
    # 初始化曲线
    if ! curve_init "$curve_name"; then
        ecdsa_error "曲线初始化失败"
        return 1
    fi
    
    # 验证私钥
    if [[ $(bigint_compare "$private_key" "1") -lt 0 || \
          $(bigint_compare "$private_key" $(bigint_subtract "$CURVE_N" "1")) -gt 0 ]]; then
        ecdsa_error "私钥超出有效范围"
        return 1
    fi
    
    # 处理消息哈希
    local hash_int
    if [[ ${#message_hash} -eq 64 && $message_hash =~ ^[0-9a-fA-F]+$ ]]; then
        # 已经是十六进制哈希
        hash_int=$(hash_to_int "$message_hash")
    else
        # 需要重新计算哈希
        hash_int=$(hash_to_int $(hash_message "$message_hash" "$hash_alg"))
    fi
    
    local max_attempts=10
    local attempts=0
    
    while [[ $attempts -lt $max_attempts ]]; do
        # 生成随机k或使用RFC 6979确定性k
        local k
        if ! k=$(rfc6979_generate_k "$private_key" "$hash_int" "$curve_name" "$hash_alg"); then
            # 备用：生成随机k
            k=$(bigint_random "256")
            k=$(bigint_mod "$k" $(bigint_subtract "$CURVE_N" "1"))
            k=$(bigint_add "$k" "1")
        fi
        
        # 验证k
        if [[ $(bigint_compare "$k" "1") -lt 0 || \
              $(bigint_compare "$k" $(bigint_subtract "$CURVE_N" "1")) -gt 0 ]]; then
            ((attempts++))
            continue
        fi
        
        # 计算点 (x1, y1) = kG
        local point_kg=$(ec_point_multiply "$k" "$CURVE_GX" "$CURVE_GY")
        local x1=$(echo "$point_kg" | cut -d' ' -f1)
        local y1=$(echo "$point_kg" | cut -d' ' -f2)
        
        # 计算 r = x1 mod n
        local r=$(bigint_mod "$x1" "$CURVE_N")
        
        # 如果r=0，重新生成k
        if [[ "$r" == "0" ]]; then
            ((attempts++))
            continue
        fi
        
        # 计算 s = k^(-1) * (hash + private_key * r) mod n
        local k_inv=$(bigint_mod_inverse "$k" "$CURVE_N")
        if [[ $? -ne 0 ]]; then
            ((attempts++))
            continue
        fi
        
        local temp1=$(bigint_multiply "$private_key" "$r")
        local temp2=$(bigint_add "$hash_int" "$temp1")
        local s=$(bigint_mod $(bigint_multiply "$k_inv" "$temp2") "$CURVE_N")
        
        # 如果s=0，重新生成k
        if [[ "$s" == "0" ]]; then
            ((attempts++))
            continue
        fi
        
        # 确保s在较低范围内（BIP 62规则）
        local half_n=$(bigint_divide "$CURVE_N" "2")
        if [[ $(bigint_compare "$s" "$half_n") -gt 0 ]]; then
            s=$(bigint_subtract "$CURVE_N" "$s")
        fi
        
        # 设置全局变量
        ECDSA_SIGNATURE_R="$r"
        ECDSA_SIGNATURE_S="$s"
        
        return 0
        
        ((attempts++))
    done
    
    ecdsa_error "签名生成失败"
    return 1
}

# ECDSA验证
ecdsa_verify() {
    local public_key_x="$1"
    local public_key_y="$2"
    local message_hash="$3"
    local r="$4"
    local s="$5"
    local curve_name="${6:-secp256r1}"
    local hash_alg="${7:-sha256}"
    
    # 初始化曲线
    if ! curve_init "$curve_name"; then
        ecdsa_error "曲线初始化失败"
        return 1
    fi
    
    # 验证签名参数
    if [[ $(bigint_compare "$r" "1") -lt 0 || \
          $(bigint_compare "$r" $(bigint_subtract "$CURVE_N" "1")) -gt 0 || \
          $(bigint_compare "$s" "1") -lt 0 || \
          $(bigint_compare "$s" $(bigint_subtract "$CURVE_N" "1")) -gt 0 ]]; then
        ecdsa_error "签名参数超出有效范围"
        return 1
    fi
    
    # 验证公钥点是否在曲线上
    if ! ec_point_is_on_curve "$public_key_x" "$public_key_y"; then
        ecdsa_error "公钥点不在曲线上"
        return 1
    fi
    
    # 处理消息哈希
    local hash_int
    if [[ ${#message_hash} -eq 64 && $message_hash =~ ^[0-9a-fA-F]+$ ]]; then
        # 已经是十六进制哈希
        hash_int=$(hash_to_int "$message_hash")
    else
        # 需要重新计算哈希
        hash_int=$(hash_to_int $(hash_message "$message_hash" "$hash_alg"))
    fi
    
    # 计算 w = s^(-1) mod n
    local w=$(bigint_mod_inverse "$s" "$CURVE_N")
    if [[ $? -ne 0 ]]; then
        ecdsa_error "无法计算s的模逆元"
        return 1
    fi
    
    # 计算 u1 = hash * w mod n
    local u1=$(bigint_mod $(bigint_multiply "$hash_int" "$w") "$CURVE_N")
    
    # 计算 u2 = r * w mod n
    local u2=$(bigint_mod $(bigint_multiply "$r" "$w") "$CURVE_N")
    
    # 计算点 (x1, y1) = u1*G + u2*Q
    local point_u1g=$(ec_point_multiply "$u1" "$CURVE_GX" "$CURVE_GY")
    local point_u2q=$(ec_point_multiply "$u2" "$public_key_x" "$public_key_y")
    
    local u1g_x=$(echo "$point_u1g" | cut -d' ' -f1)
    local u1g_y=$(echo "$point_u1g" | cut -d' ' -f2)
    local u2q_x=$(echo "$point_u2q" | cut -d' ' -f1)
    local u2q_y=$(echo "$point_u2q" | cut -d' ' -f2)
    
    local sum_point=$(ec_point_add "$u1g_x" "$u1g_y" "$u2q_x" "$u2q_y")
    local x1=$(echo "$sum_point" | cut -d' ' -f1)
    local y1=$(echo "$sum_point" | cut -d' ' -f2)
    
    # 计算 v = x1 mod n
    local v=$(bigint_mod "$x1" "$CURVE_N")
    
    # 验证 v == r
    if [[ "$v" == "$r" ]]; then
        return 0
    else
        return 1
    fi
}

# ECDSA签名验证（简化接口）
ecdsa_verify_simple() {
    local public_key_str="$1"  # 格式: "x y"
    local message_hash="$2"
    local r="$3"
    local s="$4"
    local curve_name="${5:-secp256r1}"
    local hash_alg="${6:-sha256}"
    
    local public_key_x=$(echo "$public_key_str" | cut -d' ' -f1)
    local public_key_y=$(echo "$public_key_str" | cut -d' ' -f2)
    
    ecdsa_verify "$public_key_x" "$public_key_y" "$message_hash" "$r" "$s" "$curve_name" "$hash_alg"
}

# 保存私钥到文件
save_private_key() {
    local private_key="$1"
    local filename="$2"
    
    # PEM格式
    cat > "$filename" << EOF
-----BEGIN EC PRIVATE KEY-----
$private_key
-----END EC PRIVATE KEY-----
EOF
    
    chmod 600 "$filename"
}

# 保存公钥到文件
save_public_key() {
    local public_key_str="$1"
    local filename="$2"
    
    local public_key_x=$(echo "$public_key_str" | cut -d' ' -f1)
    local public_key_y=$(echo "$public_key_str" | cut -d' ' -f2)
    
    # PEM格式
    cat > "$filename" << EOF
-----BEGIN EC PUBLIC KEY-----
$public_key_x $public_key_y
-----END EC PUBLIC KEY-----
EOF
    
    chmod 644 "$filename"
}

# 从文件加载私钥
load_private_key() {
    local filename="$1"
    
    if [[ ! -f "$filename" ]]; then
        ecdsa_error "私钥文件不存在: $filename"
        return 1
    fi
    
    # 提取私钥
    local private_key=$(grep -v "^-" "$filename" | tr -d '[:space:]')
    
    if [[ -z "$private_key" ]]; then
        ecdsa_error "无法从文件读取私钥"
        return 1
    fi
    
    echo "$private_key"
}

# 从文件加载公钥
load_public_key() {
    local filename="$1"
    
    if [[ ! -f "$filename" ]]; then
        ecdsa_error "公钥文件不存在: $filename"
        return 1
    fi
    
    # 提取公钥
    local public_key=$(grep -v "^-" "$filename" | tr -d '[:space:]')
    
    if [[ -z "$public_key" ]]; then
        ecdsa_error "无法从文件读取公钥"
        return 1
    fi
    
    echo "$public_key"
}

# 测试ECDSA实现
ecdsa_test() {
    echo "测试ECDSA实现..."
    
    # 初始化曲线
    local curve_name="secp256r1"
    if ! curve_init "$curve_name"; then
        echo "错误: 无法初始化曲线 $curve_name"
        return 1
    fi
    
    echo "使用曲线: $curve_name"
    
    # 生成密钥对
    echo -e "\n生成密钥对..."
    local private_key=$(ecdsa_generate_private_key)
    local public_key_str=$(ecdsa_get_public_key "$private_key")
    local public_key_x=$(echo "$public_key_str" | cut -d' ' -f1)
    local public_key_y=$(echo "$public_key_str" | cut -d' ' -f2)
    
    echo "私钥: $private_key"
    echo "公钥: ($public_key_x, $public_key_y)"
    
    # 测试消息
    local test_message="Hello, ECDSA!"
    echo -e "\n测试消息: $test_message"
    
    # 计算哈希
    local message_hash=$(hash_message "$test_message")
    echo "消息哈希: $message_hash"
    
    # 签名
    echo -e "\n生成签名..."
    if ecdsa_sign "$private_key" "$message_hash" "$curve_name"; then
        echo "✓ 签名生成成功"
        echo "r = $ECDSA_SIGNATURE_R"
        echo "s = $ECDSA_SIGNATURE_S"
    else
        echo "✗ 签名生成失败"
        return 1
    fi
    
    # 验证签名
    echo -e "\n验证签名..."
    if ecdsa_verify "$public_key_x" "$public_key_y" "$message_hash" "$ECDSA_SIGNATURE_R" "$ECDSA_SIGNATURE_S" "$curve_name"; then
        echo "✓ 签名验证通过"
    else
        echo "✗ 签名验证失败"
        return 1
    fi
    
    # 测试错误情况
    echo -e "\n测试错误情况..."
    
    # 修改消息
    local wrong_message="Hello, Wrong Message!"
    local wrong_hash=$(hash_message "$wrong_message")
    
    if ecdsa_verify "$public_key_x" "$public_key_y" "$wrong_hash" "$ECDSA_SIGNATURE_R" "$ECDSA_SIGNATURE_S" "$curve_name"; then
        echo "✗ 错误: 错误消息的签名验证通过"
    else
        echo "✓ 错误消息的正确拒绝"
    fi
    
    # 修改签名
    local wrong_r=$(bigint_add "$ECDSA_SIGNATURE_R" "1")
    
    if ecdsa_verify "$public_key_x" "$public_key_y" "$message_hash" "$wrong_r" "$ECDSA_SIGNATURE_S" "$curve_name"; then
        echo "✗ 错误: 错误签名的验证通过"
    else
        echo "✓ 错误签名的正确拒绝"
    fi
    
    echo -e "\nECDSA测试完成"
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ecdsa_test
fi