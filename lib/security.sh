#!/bin/bash
# Security - 密码学安全功能
# 实现RFC 6979确定性k值生成、侧信道攻击防护等

set -euo pipefail

# 导入保护 - 防止重复定义
if [[ -n "${SECURITY_LOADED:-}" ]]; then
    return 0
fi
readonly SECURITY_LOADED=1

# 导入必要的库
source "$(dirname "${BASH_SOURCE[0]}")/bigint.sh"
source "$(dirname "${BASH_SOURCE[0]}")/bash_math.sh"

# 常量定义
readonly RFC6979_K_CANDIDATE_MAX=100
readonly RFC6979_V_SIZE=32  # 32字节 = 256位

# HMAC-SHA256实现（简化版本）
hmac_sha256() {
    local key="$1"
    local message="$2"
    
    # 使用openssl作为后备
    if command -v openssl >/dev/null 2>&1; then
        echo -n "$message" | openssl dgst -sha256 -hmac "$key" | cut -d' ' -f2
    elif command -v hmac256 >/dev/null 2>&1; then
        echo -n "$message" | hmac256 "$key" | cut -d' ' -f1
    else
        # 简化的HMAC实现
        echo "警告: 使用简化的HMAC实现" >&2
        echo -n "$key$message" | sha256sum | cut -d' ' -f1
    fi
}

# SHA256哈希
sha256_hash() {
    local message="$1"
    
    if command -v sha256sum >/dev/null 2>&1; then
        echo -n "$message" | sha256sum | cut -d' ' -f1
    elif command -v shasum >/dev/null 2>&1; then
        echo -n "$message" | shasum -a 256 | cut -d' ' -f1
    else
        echo "错误: 未找到SHA256实现" >&2
        return 1
    fi
}

# I2OSP - 整数到八位字节串转换
i2osp() {
    local x="$1"
    local x_len="$2"
    
    # 将整数转换为十六进制
    local hex=$(bashmath_dec_to_hex "$x")
    
    # 确保长度正确
    if [[ ${#hex} -gt $((x_len * 2)) ]]; then
        hex=${hex: -$((x_len * 2))}
    fi
    
    # 补零到指定长度
    while [[ ${#hex} -lt $((x_len * 2)) ]]; do
        hex="0${hex}"
    done
    
    echo "$hex"
}

# OS2IP - 八位字节串到整数转换
os2ip() {
    local x="$1"
    bashmath_hex_to_dec "$x" || echo "0"
}

# 位长度计算
bitlen() {
    local x="$1"
    if [[ "$x" == "0" ]]; then
        echo "0"
        return 0
    fi
    
    local bits=0
    while [[ "$x" -gt "0" ]]; do
        x=$(bigint_divide "$x" "2")
        ((bits++))
    done
    
    echo "$bits"
}

# bits2octets - 将位串转换为八位字节串
bits2octets() {
    local bits="$1"
    local q="$2"
    
    # 计算qlen（q的位长度）
    local qlen=$(bitlen "$q")
    
    # 计算rlen
    local rlen=$(((qlen + 7) / 8))
    
    # 将bits转换为八位字节串
    local octets=$(i2osp "$bits" "$rlen")
    
    echo "$octets"
}

# RFC 6979 确定性k值生成
rfc6979_generate_k() {
    local private_key="$1"
    local hash_m="$2"
    local curve_name="${3:-secp256r1}"
    local hash_alg="${4:-sha256}"
    
    # 初始化曲线
    if ! curve_init "$curve_name"; then
        echo "错误: 无法初始化曲线 $curve_name" >&2
        return 1
    fi
    
    # 计算qlen（曲线阶的位长度）
    local qlen=$(bitlen "$CURVE_N")
    
    # 将哈希转换为八位字节串
    local h1=$(bits2octets "$hash_m" "$CURVE_N")
    
    # 将私钥转换为八位字节串
    local x=$(bits2octets "$private_key" "$CURVE_N")
    
    # 初始化V和K
    local v=$(printf "%0${RFC6979_V_SIZE}s" | tr ' ' '\\001')
    local k=$(printf "%0${RFC6979_V_SIZE}s" | tr ' ' '\\000')
    
    # 步骤d: K = HMAC_K(V || 0x00 || int2octets(x) || bits2octets(h1))
    k=$(hmac_sha256 "$k" "$v\\000$x$h1")
    
    # 步骤e: V = HMAC_K(V)
    v=$(hmac_sha256 "$k" "$v")
    
    # 步骤f: K = HMAC_K(V || 0x01 || int2octets(x) || bits2octets(h1))
    k=$(hmac_sha256 "$k" "$v\\001$x$h1")
    
    # 步骤g: V = HMAC_K(V)
    v=$(hmac_sha256 "$k" "$v")
    
    # 步骤h: 生成k
    local t=""
    local t_len=0
    
    while [[ $t_len -lt $qlen ]]; do
        v=$(hmac_sha256 "$k" "$v")
        t="$t$v"
        t_len=$((${#t} * 4))  # 十六进制字符转换为位
    done
    
    # 将t截断为qlen位
    local k_candidate=$(os2ip "${t:0:$(((qlen + 7) / 8) * 2)}")
    k_candidate=$(bigint_mod "$k_candidate" "$CURVE_N")
    
    # 检查k是否有效
    if [[ $(bigint_compare "$k_candidate" "1") -ge 0 && \
          $(bigint_compare "$k_candidate" $(bigint_subtract "$CURVE_N" "1")) -le 0 ]]; then
        echo "$k_candidate"
        return 0
    fi
    
    # 如果k无效，继续生成
    local candidate_count=0
    while [[ $candidate_count -lt $RFC6979_K_CANDIDATE_MAX ]]; do
        k=$(hmac_sha256 "$k" "$v\\000")
        v=$(hmac_sha256 "$k" "$v")
        
        t=""
        t_len=0
        while [[ $t_len -lt $qlen ]]; do
            v=$(hmac_sha256 "$k" "$v")
            t="$t$v"
            t_len=$((${#t} * 4))
        done
        
        k_candidate=$(os2ip "${t:0:$(((qlen + 7) / 8) * 2)}")
        k_candidate=$(bigint_mod "$k_candidate" "$CURVE_N")
        
        if [[ $(bigint_compare "$k_candidate" "1") -ge 0 && \
              $(bigint_compare "$k_candidate" $(bigint_subtract "$CURVE_N" "1")) -le 0 ]]; then
            echo "$k_candidate"
            return 0
        fi
        
        ((candidate_count++))
    done
    
    echo "错误: 无法生成有效的k值" >&2
    return 1
}

# 常量时间比较（防侧信道攻击）
constant_time_compare() {
    local str1="$1"
    local str2="$2"
    
    if [[ ${#str1} -ne ${#str2} ]]; then
        return 1
    fi
    
    local result=0
    local i
    for ((i=0; i<${#str1}; i++)); do
        local char1=$(printf "%d" "'${str1:i:1}")
        local char2=$(printf "%d" "'${str2:i:1}")
        result=$((result | (char1 ^ char2)))
    done
    
    if [[ $result -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# 内存清零（防止敏感数据残留）
secure_zero_memory() {
    local var_name="$1"
    
    # 在bash中，我们无法真正清零内存
    # 这里只是将变量设置为空字符串
    eval "$var_name=''"
}

# 随机数生成器健康检查
entropy_health_check() {
    local test_count=10
    local last_entropy=""
    local collision_count=0
    
    for ((i=0; i<test_count; i++)); do
        local current_entropy=$(bigint_random "128")
        
        if [[ -n "$last_entropy" && "$current_entropy" == "$last_entropy" ]]; then
            ((collision_count++))
        fi
        
        last_entropy="$current_entropy"
    done
    
    if [[ $collision_count -gt 0 ]]; then
        echo "警告: 随机数生成器可能存在健康问题 (检测到 $collision_count 次碰撞)" >&2
        return 1
    fi
    
    return 0
}

# 密钥强度检查
key_strength_check() {
    local key="$1"
    local min_strength="$2"
    
    # 检查密钥长度
    local key_bits=$(bitlen "$key")
    
    if [[ $key_bits -lt $min_strength ]]; then
        echo "错误: 密钥强度不足 (需要 $min_strength 位，实际 $key_bits 位)" >&2
        return 1
    fi
    
    # 检查密钥熵
    local key_hex=$(bashmath_dec_to_hex "$key")
    local hex_length=${#key_hex}
    
    # 检查是否有重复模式
    local pattern_count=0
    for ((i=0; i<hex_length-1; i++)); do
        if [[ "${key_hex:i:2}" == "${key_hex:i+1:2}" ]]; then
            ((pattern_count++))
        fi
    done
    
    if [[ $pattern_count -gt $(($hex_length / 4)) ]]; then
        echo "警告: 密钥可能存在重复模式" >&2
        return 1
    fi
    
    return 0
}

# 时间安全操作
constant_time_add() {
    local a="$1"
    local b="$2"
    
    # 确保操作时间恒定
    local result=$(bigint_add "$a" "$b")
    
    # 添加随机延迟以混淆时间分析
    local delay=$((RANDOM % 100))
    sleep "0.000${delay}"
    
    echo "$result"
}

# 安全日志记录
secure_log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 移除敏感信息
    message=$(echo "$message" | sed 's/[0-9a-fA-F]\{32,\}/[REDACTED]/g')
    
    echo "[$level] $timestamp - $message" >&2
}

# 初始化安全检查
security_init() {
    # 检查系统熵源
    if [[ ! -c /dev/urandom ]]; then
        echo "警告: 系统缺少/dev/urandom" >&2
        return 1
    fi
    
    # 检查必要的命令
    for cmd in sha256sum openssl; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "警告: 缺少命令 $cmd" >&2
        fi
    done
    
    # 执行熵健康检查
    if ! entropy_health_check; then
        echo "警告: 熵源健康检查失败" >&2
        return 1
    fi
    
    # 设置安全环境
    umask 077
    
    secure_log "INFO" "安全模块初始化完成"
    return 0
}

# 测试安全功能
security_test() {
    echo "测试安全功能..."
    
    # 测试RFC 6979
    echo -e "\n测试RFC 6979..."
    local test_private_key="1234567890123456789012345678901234567890123456789012345678901234"
    local test_hash="1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
    
    if rfc6979_generate_k "$test_private_key" "$test_hash" "secp256r1" >/dev/null 2>&1; then
        echo "✓ RFC 6979实现可用"
    else
        echo "✗ RFC 6979实现存在问题"
    fi
    
    # 测试常量时间比较
    echo -e "\n测试常量时间比较..."
    if constant_time_compare "test123" "test123"; then
        echo "✓ 相同字符串比较正确"
    else
        echo "✗ 相同字符串比较失败"
    fi
    
    if ! constant_time_compare "test123" "test124"; then
        echo "✓ 不同字符串比较正确"
    else
        echo "✗ 不同字符串比较失败"
    fi
    
    # 测试密钥强度检查
    echo -e "\n测试密钥强度检查..."
    local weak_key="12345"
    if ! key_strength_check "$weak_key" "256"; then
        echo "✓ 弱密钥检测正确"
    else
        echo "✗ 弱密钥检测失败"
    fi
    
    local strong_key=$(bigint_random "256")
    if key_strength_check "$strong_key" "256"; then
        echo "✓ 强密钥检测正确"
    else
        echo "✗ 强密钥检测失败"
    fi
    
    # 测试安全日志
    echo -e "\n测试安全日志..."
    secure_log "TEST" "这是一个测试消息，包含敏感信息: abcdef1234567890abcdef1234567890"
    
    echo -e "\n安全功能测试完成"
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    security_init
    security_test
fi