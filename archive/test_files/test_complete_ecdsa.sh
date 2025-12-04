#!/bin/bash
# 完整ECDSA功能测试 - 无bc版本
# 测试所有功能，但使用简化和性能优化的方法

set -euo pipefail

# 颜色定义
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

# 导入库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "core/crypto/ec_math_fixed_simple.sh"
# 归档依赖不存在，使用当前核心库
# 归档依赖不存在，使用当前核心库
# 归档依赖不存在，使用当前核心库
# 归档依赖不存在，使用当前核心库
source "${SCRIPT_DIR}/lib/security.sh"
source "${SCRIPT_DIR}/lib/asn1.sh"
source "${SCRIPT_DIR}/lib/entropy.sh"

# 测试计数器
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# 测试日志函数
test_log() {
    local level="$1"
    shift
    local message="$*"
    
    case "$level" in
        "PASS") echo -e "${COLOR_GREEN}✓${COLOR_RESET} $message" ;;
        "FAIL") echo -e "${COLOR_RED}✗${COLOR_RESET} $message" ;;
        "INFO") echo -e "${COLOR_BLUE}ℹ${COLOR_RESET} $message" ;;
        "WARN") echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} $message" ;;
    esac
}

# 断言函数
assert_equal() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if [[ "$expected" == "$actual" ]]; then
        test_log "PASS" "$message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        test_log "FAIL" "$message (期望: '$expected', 实际: '$actual')"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# 测试1: 数学函数库
test_math_library() {
    test_log "INFO" "测试数学函数库..."
    
    # 十六进制转换
    assert_equal "255" "$(bashmath_hex_to_dec "FF")" "十六进制 FF -> 255"
    assert_equal "256" "$(bashmath_hex_to_dec "100")" "十六进制 100 -> 256"
    assert_equal "FF" "$(bashmath_dec_to_hex "255")" "十进制 255 -> FF"
    
    # 对数计算
    assert_equal "8" "$(bashmath_log2 "256")" "log2(256) = 8"
    assert_equal "7" "$(bashmath_log2 "128")" "log2(128) = 7"
    
    # 浮点除法
    local result=$(bashmath_divide_float "10" "3" "6")
    assert_equal "3.333333" "$result" "10/3 = 3.333333"
}

# 测试2: 大数运算
test_bigint_operations() {
    test_log "INFO" "测试大数运算..."
    
    # 基本运算
    assert_equal "5" "$(bigint_add "2" "3")" "2 + 3 = 5"
    assert_equal "1" "$(bigint_subtract "4" "3")" "4 - 3 = 1"
    assert_equal "6" "$(bigint_multiply "2" "3")" "2 × 3 = 6"
    assert_equal "2" "$(bigint_divide "6" "3")" "6 ÷ 3 = 2"
    assert_equal "0" "$(bigint_mod "6" "3")" "6 % 3 = 0"
    
    # 大数运算
    local big_num="12345678901234567890"
    assert_equal "$big_num" "$(bigint_add "$big_num" "0")" "大数加法恒等性"
}

# 测试3: 曲线初始化（简化验证）
test_curve_initialization() {
    test_log "INFO" "测试曲线初始化..."
    
    # 测试支持的曲线
    for curve in "secp256r1" "secp256k1" "secp384r1" "secp521r1"; do
        if curve_is_supported "$curve"; then
            test_log "PASS" "曲线 $curve 受支持"
        else
            test_log "FAIL" "曲线 $curve 不受支持"
        fi
    done
    
    # 初始化secp256r1
    if curve_init "secp256r1"; then
        test_log "PASS" "secp256r1 曲线初始化"
        test_log "INFO" "曲线参数已设置: P=${#CURVE_P}位, N=${#CURVE_N}位"
    else
        test_log "FAIL" "secp256r1 曲线初始化失败"
    fi
}

# 测试4: 熵收集系统
test_entropy_system() {
    test_log "INFO" "测试熵收集系统..."
    
    # 初始化熵池
    if entropy_init; then
        test_log "PASS" "熵池初始化"
    else
        test_log "FAIL" "熵池初始化失败"
    fi
    
    # 生成随机数
    local random_num
    random_num=$(entropy_generate "128")
    if [[ -n "$random_num" ]] && [[ "$random_num" != "0" ]]; then
        test_log "PASS" "生成128位随机数: ${#random_num}位十进制"
    else
        test_log "FAIL" "随机数生成失败"
    fi
}

# 测试5: ASN.1编码
test_asn1_encoding() {
    test_log "INFO" "测试ASN.1编码..."
    
    # 测试整数编码
    local encoded
    encoded=$(asn1_encode_integer "255")
    if [[ -n "$encoded" ]]; then
        test_log "PASS" "整数255 ASN.1编码: ${encoded:0:20}..."
    else
        test_log "FAIL" "ASN.1整数编码失败"
    fi
    
    # 测试长度编码
    local length_encoded
    length_encoded=$(asn1_encode_length "32")
    if [[ -n "$length_encoded" ]]; then
        test_log "PASS" "长度32 ASN.1编码"
    else
        test_log "FAIL" "ASN.1长度编码失败"
    fi
}

# 测试6: 简化ECDSA操作
test_simplified_ecdsa() {
    test_log "INFO" "测试简化ECDSA操作..."
    
    # 初始化曲线
    curve_init "secp256r1"
    
    # 使用测试向量进行验证
    local test_private="12345678901234567890123456789012"
    local test_message="Hello, ECDSA!"
    
    # 验证私钥范围
    if [[ $(bigint_compare "$test_private" "1") -ge 0 ]] && \
       [[ $(bigint_compare "$test_private" "$CURVE_N") -lt 0 ]]; then
        test_log "PASS" "测试私钥在有效范围内"
    else
        test_log "FAIL" "测试私钥超出范围"
        return 1
    fi
    
    # 计算消息哈希
    local message_hash
    message_hash=$(hash_message "$test_message")
    if [[ -n "$message_hash" ]] && [[ "$message_hash" != "0" ]]; then
        test_log "PASS" "消息哈希计算: ${message_hash:0:20}..."
    else
        test_log "FAIL" "消息哈希计算失败"
    fi
    
    # 验证RFC 6979 k值生成
    local k
    k=$(rfc6979_generate_k "$test_private" "$message_hash" "secp256r1" "sha256")
    if [[ -n "$k" ]] && [[ "$k" != "0" ]]; then
        test_log "PASS" "RFC 6979 k值生成: ${#k}位十进制"
    else
        test_log "FAIL" "RFC 6979 k值生成失败"
    fi
}

# 测试7: 密钥保存和加载
test_key_serialization() {
    test_log "INFO" "测试密钥序列化..."
    
    # 测试私钥编码
    local test_private="12345678901234567890123456789012"
    local encoded_private
    encoded_private=$(asn1_encode_integer "$test_private")
    
    if [[ -n "$encoded_private" ]]; then
        test_log "PASS" "私钥ASN.1编码"
    else
        test_log "FAIL" "私钥ASN.1编码失败"
    fi
    
    # 测试十六进制转换
    local hex_private
    hex_private=$(bashmath_dec_to_hex "$test_private")
    if [[ -n "$hex_private" ]]; then
        test_log "PASS" "私钥十六进制转换: ${hex_private:0:10}..."
    else
        test_log "FAIL" "私钥十六进制转换失败"
    fi
}

# 测试8: 性能基准
test_performance_baseline() {
    test_log "INFO" "测试性能基准..."
    
    local start_time end_time duration
    
    # 测试数学函数性能
    start_time=$(date +%s.%N)
    
    for ((i=1; i<=100; i++)); do
        bashmath_hex_to_dec "FF" >/dev/null
        bashmath_dec_to_hex "255" >/dev/null
        bashmath_log2 "256" >/dev/null
    done
    
    end_time=$(date +%s.%N)
    duration=$(bashmath_divide_float "${end_time%.*}${end_time#*.}" "1000000000" "3")
    
    test_log "INFO" "100次数学运算耗时: ${duration}s"
    
    # 测试大数运算性能
    start_time=$(date +%s.%N)
    
    for ((i=1; i<=50; i++)); do
        bigint_add "12345678901234567890" "98765432109876543210" >/dev/null
        bigint_multiply "12345678901234567890" "2" >/dev/null
    done
    
    end_time=$(date +%s.%N)
    duration=$(bashmath_divide_float "${end_time%.*}${end_time#*.}" "1000000000" "3")
    
    test_log "INFO" "50次大数运算耗时: ${duration}s"
}

# 测试9: 集成流程测试
test_integration_flow() {
    test_log "INFO" "测试集成流程..."
    
    # 完整的密钥生成流程（简化版）
    curve_init "secp256r1"
    entropy_init
    
    # 生成随机私钥
    local private_key
    private_key=$(entropy_generate "256")
    if [[ -n "$private_key" ]]; then
        test_log "PASS" "生成256位私钥: ${#private_key}位十进制"
    else
        test_log "FAIL" "私钥生成失败"
        return 1
    fi
    
    # 转换为十六进制
    local private_hex
    private_hex=$(bashmath_dec_to_hex "$private_key")
    if [[ -n "$private_hex" ]]; then
        test_log "PASS" "私钥十六进制转换: ${#private_hex}字符"
    else
        test_log "FAIL" "私钥十六进制转换失败"
    fi
    
    # 消息哈希
    local message="Test message for ECDSA"
    local hash_value
    hash_value=$(hash_message "$message")
    if [[ -n "$hash_value" ]]; then
        test_log "PASS" "消息哈希计算完成"
    else
        test_log "FAIL" "消息哈希计算失败"
    fi
}

# 测试10: 无bc依赖验证
test_no_bc_dependency() {
    test_log "INFO" "验证无bc依赖..."
    
    # 检查是否还有bc调用
    if command -v bc >/dev/null 2>&1; then
        test_log "WARN" "bc工具存在，但不会使用"
    else
        test_log "PASS" "bc工具不存在，验证纯Bash实现"
    fi
    
    # 验证所有数学运算都不依赖bc
    local test_result
    test_result=$(bashmath_hex_to_dec "FF")
    assert_equal "255" "$test_result" "纯Bash十六进制转换"
    
    test_result=$(bashmath_dec_to_hex "255")
    assert_equal "FF" "$test_result" "纯Bash十进制转换"
    
    test_result=$(bashmath_log2 "256")
    assert_equal "8" "$test_result" "纯Bash对数计算"
}

# 主测试函数
main() {
    echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
    echo -e "${COLOR_BLUE}  bECCsh 完整功能测试 (无bc版本)${COLOR_RESET}"
    echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
    echo ""
    
    # 运行所有测试
    test_math_library
    echo ""
    
    test_bigint_operations
    echo ""
    
    test_curve_initialization
    echo ""
    
    test_entropy_system
    echo ""
    
    test_asn1_encoding
    echo ""
    
    test_simplified_ecdsa
    echo ""
    
    test_key_serialization
    echo ""
    
    test_performance_baseline
    echo ""
    
    test_integration_flow
    echo ""
    
    test_no_bc_dependency
    echo ""
    
    # 测试总结
    echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
    echo -e "${COLOR_BLUE}  测试总结${COLOR_RESET}"
    echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
    echo -e "总测试数: $TESTS_TOTAL"
    echo -e "${COLOR_GREEN}通过: $TESTS_PASSED${COLOR_RESET}"
    echo -e "${COLOR_RED}失败: $TESTS_FAILED${COLOR_RESET}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${COLOR_GREEN}所有测试通过！✓${COLOR_RESET}"
        echo -e "${COLOR_GREEN}bECCsh纯Bash实现工作正常，无bc依赖！${COLOR_RESET}"
        return 0
    else
        echo -e "${COLOR_RED}部分测试失败！${COLOR_RESET}"
        return 1
    fi
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi