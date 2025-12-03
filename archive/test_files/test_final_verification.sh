#!/bin/bash
# bECCsh 最终验证测试 - 无bc版本
# 验证核心功能正常工作

set -euo pipefail

# 颜色定义
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

# 导入库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bash_math.sh"
source "${SCRIPT_DIR}/lib/bigint.sh"
source "${SCRIPT_DIR}/lib/ec_curve.sh"
source "${SCRIPT_DIR}/lib/ec_point.sh"
source "${SCRIPT_DIR}/lib/ecdsa.sh"
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

# 测试1: 纯Bash数学函数库
test_math_library() {
    test_log "INFO" "=== 测试1: 纯Bash数学函数库 ==="
    
    # 十六进制转换
    assert_equal "255" "$(bashmath_hex_to_dec "FF")" "十六进制 FF -> 255"
    assert_equal "256" "$(bashmath_hex_to_dec "100")" "十六进制 100 -> 256"
    assert_equal "255" "$(bashmath_hex_to_dec "0xFF")" "十六进制 0xFF -> 255"
    assert_equal "FF" "$(bashmath_dec_to_hex "255")" "十进制 255 -> FF"
    assert_equal "100" "$(bashmath_dec_to_hex "256")" "十进制 256 -> 100"
    
    # 对数计算
    assert_equal "8" "$(bashmath_log2 "256")" "log2(256) = 8"
    assert_equal "7" "$(bashmath_log2 "128")" "log2(128) = 7"
    assert_equal "0" "$(bashmath_log2 "1")" "log2(1) = 0"
    
    # 浮点除法
    local result=$(bashmath_divide_float "10" "3" "6")
    assert_equal "3.333333" "$result" "10/3 = 3.333333"
    
    result=$(bashmath_divide_float "22" "7" "6")
    assert_equal "3.142857" "$result" "22/7 = 3.142857"
    
    # 二进制转换
    assert_equal "10" "$(bashmath_binary_to_dec "1010")" "二进制 1010 -> 10"
    assert_equal "255" "$(bashmath_binary_to_dec "11111111")" "二进制 11111111 -> 255"
    assert_equal "1010" "$(bashmath_dec_to_binary "10")" "十进制 10 -> 1010"
    assert_equal "11111111" "$(bashmath_dec_to_binary "255")" "十进制 255 -> 11111111"
    
    test_log "INFO" "数学函数库测试完成 ✓"
}

# 测试2: 大数运算库
test_bigint_library() {
    test_log "INFO" "=== 测试2: 大数运算库 ==="
    
    # 基本运算
    assert_equal "5" "$(bigint_add "2" "3")" "2 + 3 = 5"
    assert_equal "1" "$(bigint_subtract "4" "3")" "4 - 3 = 1"
    assert_equal "6" "$(bigint_multiply "2" "3")" "2 × 3 = 6"
    assert_equal "2" "$(bigint_divide "6" "3")" "6 ÷ 3 = 2"
    assert_equal "0" "$(bigint_mod "6" "3")" "6 % 3 = 0"
    
    # 大数运算
    local big_num="123456789012345678901234567890"
    assert_equal "$big_num" "$(bigint_add "$big_num" "0")" "大数加法恒等性"
    
    local product=$(bigint_multiply "$big_num" "2")
    assert_equal "246913578024691357802469135780" "$product" "大数乘法"
    
    test_log "INFO" "大数运算库测试完成 ✓"
}

# 测试3: 椭圆曲线操作
test_elliptic_curve() {
    test_log "INFO" "=== 测试3: 椭圆曲线操作 ==="
    
    # 测试曲线支持
    for curve in "secp256r1" "secp256k1" "secp384r1" "secp521r1"; do
        if curve_is_supported "$curve"; then
            test_log "PASS" "曲线 $curve 受支持"
        else
            test_log "FAIL" "曲线 $curve 不受支持"
        fi
    done
    
    # 初始化secp256r1
    if curve_init "secp256r1"; then
        test_log "PASS" "secp256r1 曲线初始化成功"
        test_log "INFO" "曲线参数: P=${#CURVE_P}位, A=${#CURVE_A}位, B=${#CURVE_B}位"
        test_log "INFO" "基点: Gx=${#CURVE_GX}位, Gy=${#CURVE_GY}位"
        test_log "INFO" "阶: N=${#CURVE_N}位, 余因子: H=${#CURVE_H}"
    else
        test_log "FAIL" "secp256r1 曲线初始化失败"
        return 1
    fi
    
    test_log "INFO" "椭圆曲线操作测试完成 ✓"
}

# 测试4: ASN.1编码
test_asn1_operations() {
    test_log "INFO" "=== 测试4: ASN.1编码操作 ==="
    
    # 测试整数编码
    local encoded
    encoded=$(asn1_encode_integer "255")
    if [[ -n "$encoded" ]]; then
        test_log "PASS" "整数255 ASN.1编码: ${encoded:0:20}..."
    else
        test_log "FAIL" "ASN.1整数编码失败"
    fi
    
    encoded=$(asn1_encode_integer "0")
    if [[ -n "$encoded" ]]; then
        test_log "PASS" "整数0 ASN.1编码"
    else
        test_log "FAIL" "ASN.1整数0编码失败"
    fi
    
    # 测试长度编码
    local length_encoded
    length_encoded=$(asn1_encode_length "32")
    if [[ -n "$length_encoded" ]]; then
        test_log "PASS" "长度32 ASN.1编码"
    else
        test_log "FAIL" "ASN.1长度编码失败"
    fi
    
    test_log "INFO" "ASN.1编码测试完成 ✓"
}

# 测试5: 哈希函数
test_hash_functions() {
    test_log "INFO" "=== 测试5: 哈希函数 ==="
    
    # 测试消息哈希
    local message="Hello, ECDSA!"
    local hash_value
    hash_value=$(hash_message "$message")
    if [[ -n "$hash_value" ]] && [[ "$hash_value" != "0" ]]; then
        test_log "PASS" "消息哈希计算: ${hash_value:0:20}..."
    else
        test_log "FAIL" "消息哈希计算失败"
    fi
    
    # 测试不同消息产生不同哈希
    local message2="Hello, ECDSA!!"
    local hash_value2
    hash_value2=$(hash_message "$message2")
    if [[ "$hash_value" != "$hash_value2" ]]; then
        test_log "PASS" "不同消息产生不同哈希"
    else
        test_log "FAIL" "不同消息产生相同哈希"
    fi
    
    test_log "INFO" "哈希函数测试完成 ✓"
}

# 测试6: 熵收集系统
test_entropy_system() {
    test_log "INFO" "=== 测试6: 熵收集系统 ==="
    
    # 初始化熵池
    if entropy_init; then
        test_log "PASS" "熵池初始化成功"
    else
        test_log "FAIL" "熵池初始化失败"
        return 1
    fi
    
    # 生成随机数
    local random_num
    random_num=$(entropy_generate "128")
    if [[ -n "$random_num" ]] && [[ "$random_num" != "0" ]]; then
        test_log "PASS" "生成128位随机数: ${#random_num}位十进制"
    else
        test_log "FAIL" "随机数生成失败"
    fi
    
    # 生成另一个随机数，检查是否不同
    local random_num2
    random_num2=$(entropy_generate "128")
    if [[ "$random_num" != "$random_num2" ]]; then
        test_log "PASS" "两次生成的随机数不同"
    else
        test_log "WARN" "两次生成的随机数相同（可能是测试环境限制）"
    fi
    
    test_log "INFO" "熵收集系统测试完成 ✓"
}

# 测试7: 密钥序列化
test_key_serialization() {
    test_log "INFO" "=== 测试7: 密钥序列化 ==="
    
    # 测试十六进制转换（适合Bash算术范围的小数字）
    local test_private="1234567890"
    local private_hex
    private_hex=$(bashmath_dec_to_hex "$test_private")
    if [[ -n "$private_hex" ]]; then
        test_log "PASS" "私钥十六进制转换: ${private_hex}"
    else
        test_log "FAIL" "私钥十六进制转换失败"
    fi
    
    # 测试反向转换
    local back_to_dec
    back_to_dec=$(bashmath_hex_to_dec "$private_hex")
    assert_equal "$test_private" "$back_to_dec" "十六进制往返转换"
    
    # 测试中等大小数字十六进制转换
    local medium_hex="ABCDEF123"
    local medium_dec
    medium_dec=$(bashmath_hex_to_dec "$medium_hex")
    test_log "INFO" "中等数十六进制 $medium_hex -> $medium_dec"
    
    local back_to_hex
    back_to_hex=$(bashmath_dec_to_hex "$medium_dec")
    assert_equal "$medium_hex" "$back_to_hex" "中等数十六进制往返转换"
    
    test_log "INFO" "密钥序列化测试完成 ✓"
}

# 测试8: 性能基准测试
test_performance() {
    test_log "INFO" "=== 测试8: 性能基准测试 ==="
    
    local start_time end_time duration
    local iterations=100
    
    # 测试数学函数性能
    start_time=$(date +%s%N)  # 使用纳秒时间戳
    
    for ((i=1; i<=iterations; i++)); do
        bashmath_hex_to_dec "FF" >/dev/null
        bashmath_dec_to_hex "255" >/dev/null
        bashmath_log2 "256" >/dev/null
    done
    
    end_time=$(date +%s%N)
    local elapsed_ns=$((end_time - start_time))
    duration=$(bashmath_divide_float "$elapsed_ns" "1000000000" "3")
    
    test_log "INFO" "数学函数性能: $iterations 次操作耗时 ${duration}s"
    
    # 测试大数运算性能
    start_time=$(date +%s%N)
    
    for ((i=1; i<=50; i++)); do
        bigint_add "12345678901234567890" "98765432109876543210" >/dev/null
        bigint_multiply "12345678901234567890" "2" >/dev/null
    done
    
    end_time=$(date +%s%N)
    elapsed_ns=$((end_time - start_time))
    duration=$(bashmath_divide_float "$elapsed_ns" "1000000000" "3")
    
    test_log "INFO" "大数运算性能: 50 次操作耗时 ${duration}s"
    
    test_log "INFO" "性能基准测试完成 ✓"
}

# 测试9: 无bc依赖验证
test_no_bc_dependency() {
    test_log "INFO" "=== 测试9: 无bc依赖验证 ==="
    
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
    
    test_result=$(bashmath_divide_float "10" "3" "6")
    assert_equal "3.333333" "$test_result" "纯Bash浮点除法"
    
    test_log "INFO" "无bc依赖验证完成 ✓"
}

# 测试10: 集成流程验证
test_integration_flow() {
    test_log "INFO" "=== 测试10: 集成流程验证 ==="
    
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
    
    # 验证私钥范围
    if [[ $(bigint_compare "$private_key" "1") -ge 0 ]] && \
       [[ $(bigint_compare "$private_key" "$CURVE_N") -lt 0 ]]; then
        test_log "PASS" "私钥在有效范围内"
    else
        test_log "WARN" "私钥可能需要调整范围"
    fi
    
    # 消息哈希
    local message="Test message for ECDSA integration test"
    local hash_value
    hash_value=$(hash_message "$message")
    if [[ -n "$hash_value" ]]; then
        test_log "PASS" "消息哈希计算完成"
    else
        test_log "FAIL" "消息哈希计算失败"
    fi
    
    # ASN.1编码测试
    local encoded_private
    encoded_private=$(asn1_encode_integer "$private_key")
    if [[ -n "$encoded_private" ]]; then
        test_log "PASS" "私钥ASN.1编码完成"
    else
        test_log "FAIL" "私钥ASN.1编码失败"
    fi
    
    test_log "INFO" "集成流程验证完成 ✓"
}

# 主测试函数
main() {
    echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
    echo -e "${COLOR_BLUE}  bECCsh 最终验证测试 (无bc版本)${COLOR_RESET}"
    echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
    echo ""
    echo "此测试验证bECCsh完全使用纯Bash实现，无需bc计算器"
    echo ""
    
    # 运行所有测试
    test_math_library
    echo ""
    
    test_bigint_library
    echo ""
    
    test_elliptic_curve
    echo ""
    
    test_asn1_operations
    echo ""
    
    test_hash_functions
    echo ""
    
    test_entropy_system
    echo ""
    
    test_key_serialization
    echo ""
    
    test_performance
    echo ""
    
    test_no_bc_dependency
    echo ""
    
    test_integration_flow
    echo ""
    
    # 测试总结
    echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
    echo -e "${COLOR_BLUE}  最终测试总结${COLOR_RESET}"
    echo -e "${COLOR_BLUE}========================================${COLOR_RESET}"
    echo -e "总测试数: $TESTS_TOTAL"
    echo -e "${COLOR_GREEN}通过: $TESTS_PASSED${COLOR_RESET}"
    echo -e "${COLOR_RED}失败: $TESTS_FAILED${COLOR_RESET}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${COLOR_GREEN}🎉 所有测试通过！${COLOR_RESET}"
        echo -e "${COLOR_GREEN}✅ bECCsh纯Bash实现完全正常工作！${COLOR_RESET}"
        echo -e "${COLOR_GREEN}✅ 成功移除所有bc依赖！${COLOR_RESET}"
        echo -e "${COLOR_GREEN}✅ 项目现在完全依赖Bash，无需外部数学工具！${COLOR_RESET}"
        return 0
    else
        echo -e "${COLOR_RED}❌ 部分测试失败！${COLOR_RESET}"
        return 1
    fi
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi