#!/bin/bash
# bECCsh测试套件
# 全面的ECDSA实现测试，包括功能测试、安全测试和性能测试

set -euo pipefail

# 测试配置
readonly TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR="${TEST_DIR}/lib"
readonly OUTPUT_DIR="${TEST_DIR}/test_output"

# 导入数学库
source "${LIB_DIR}/bash_math.sh"

# 颜色定义
readonly COLOR_RED='\\033[0;31m'
readonly COLOR_GREEN='\\033[0;32m'
readonly COLOR_YELLOW='\\033[1;33m'
readonly COLOR_BLUE='\\033[0;34m'
readonly COLOR_RESET='\\033[0m'

# 测试结果统计
TEST_TOTAL=0
TEST_PASSED=0
TEST_FAILED=0
TEST_SKIPPED=0

# 导入库
source "${LIB_DIR}/bigint.sh"
source "${LIB_DIR}/ec_curve.sh"
source "${LIB_DIR}/ec_point.sh"
source "${LIB_DIR}/ecdsa.sh"
source "${LIB_DIR}/security.sh"
source "${LIB_DIR}/asn1.sh"
source "${LIB_DIR}/entropy.sh"

# 测试输出函数
test_log() {
    local level="$1"
    shift
    local message="$*"
    
    case "$level" in
        "INFO")
            echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $message"
            ;;
        "PASS")
            echo -e "${COLOR_GREEN}[PASS]${COLOR_RESET} $message"
            ;;
        "FAIL")
            echo -e "${COLOR_RED}[FAIL]${COLOR_RESET} $message"
            ;;
        "SKIP")
            echo -e "${COLOR_YELLOW}[SKIP]${COLOR_RESET} $message"
            ;;
    esac
}

# 测试断言
assert_equal() {
    local expected="$1"
    local actual="$2"
    local message="${3:-断言失败}"
    
    ((TEST_TOTAL++))
    
    if [[ "$expected" == "$actual" ]]; then
        ((TEST_PASSED++))
        test_log "PASS" "$message"
        return 0
    else
        ((TEST_FAILED++))
        test_log "FAIL" "$message (期望: $expected, 实际: $actual)"
        return 1
    fi
}

assert_not_equal() {
    local expected="$1"
    local actual="$2"
    local message="${3:-断言失败}"
    
    ((TEST_TOTAL++))
    
    if [[ "$expected" != "$actual" ]]; then
        ((TEST_PASSED++))
        test_log "PASS" "$message"
        return 0
    else
        ((TEST_FAILED++))
        test_log "FAIL" "$message (不应等于: $expected)"
        return 1
    fi
}

assert_true() {
    local condition="$1"
    local message="${2:-断言失败}"
    
    ((TEST_TOTAL++))
    
    if [[ $condition -eq 0 ]]; then
        ((TEST_PASSED++))
        test_log "PASS" "$message"
        return 0
    else
        ((TEST_FAILED++))
        test_log "FAIL" "$message"
        return 1
    fi
}

assert_false() {
    local condition="$1"
    local message="${2:-断言失败}"
    
    ((TEST_TOTAL++))
    
    if [[ $condition -ne 0 ]]; then
        ((TEST_PASSED++))
        test_log "PASS" "$message"
        return 0
    else
        ((TEST_FAILED++))
        test_log "FAIL" "$message"
        return 1
    fi
}

# 测试BigInt库
test_bigint() {
    test_log "INFO" "测试BigInt库..."
    
    # 基本运算测试
    local sum=$(bigint_add "123456789" "987654321")
    assert_equal "1111111110" "$sum" "大数加法"
    
    local diff=$(bigint_subtract "987654321" "123456789")
    assert_equal "864197532" "$diff" "大数减法"
    
    local product=$(bigint_multiply "12345" "67890")
    assert_equal "838102050" "$product" "大数乘法"
    
    local quotient=$(bigint_divide "987654321" "12345")
    assert_equal "80004" "$quotient" "大数除法"
    
    local remainder=$(bigint_mod "987654321" "12345")
    assert_equal "10101" "$remainder" "大数模运算"
    
    # 边界情况测试
    local zero_add=$(bigint_add "0" "12345")
    assert_equal "12345" "$zero_add" "零加法"
    
    local zero_mul=$(bigint_multiply "0" "12345")
    assert_equal "0" "$zero_mul" "零乘法"
    
    # 大数测试
    local large_num="123456789012345678901234567890"
    local large_square=$(bigint_multiply "$large_num" "$large_num")
    assert_not_equal "0" "$large_square" "大数平方"
    
    test_log "INFO" "BigInt库测试完成"
}

# 测试椭圆曲线
test_ec_curve() {
    test_log "INFO" "测试椭圆曲线..."
    
    # 测试支持的曲线
    for curve in "secp256r1" "secp256k1" "secp384r1"; do
        test_log "INFO" "测试曲线: $curve"
        
        # 初始化曲线
        assert_true $(curve_init "$curve") "曲线初始化 $curve"
        
        # 验证曲线参数
        assert_true $(curve_validate_params) "曲线参数验证 $curve"
        
        # 检查基点
        assert_true $(ec_point_is_on_curve "$CURVE_GX" "$CURVE_GY") "基点验证 $curve"
        
        # 检查安全级别
        local security_level=$(curve_security_level)
        assert_not_equal "0" "$security_level" "安全级别 $curve"
    done
    
    test_log "INFO" "椭圆曲线测试完成"
}

# 测试点运算
test_ec_point() {
    test_log "INFO" "测试椭圆曲线点运算..."
    
    # 初始化曲线
    curve_init "secp256r1"
    
    # 测试点倍
    local double_point=$(ec_point_double "$CURVE_GX" "$CURVE_GY")
    local double_x=$(echo "$double_point" | cut -d' ' -f1)
    local double_y=$(echo "$double_point" | cut -d' ' -f2)
    
    assert_true $(ec_point_is_on_curve "$double_x" "$double_y") "点倍结果在曲线上"
    
    # 测试点乘法
    local triple_point=$(ec_point_multiply "3" "$CURVE_GX" "$CURVE_GY")
    local triple_x=$(echo "$triple_point" | cut -d' ' -f1)
    local triple_y=$(echo "$triple_point" | cut -d' ' -f2)
    
    assert_true $(ec_point_is_on_curve "$triple_x" "$triple_y") "点乘结果在曲线上"
    
    # 测试点加法
    local sum_point=$(ec_point_add "$CURVE_GX" "$CURVE_GY" "$double_x" "$double_y")
    local sum_x=$(echo "$sum_point" | cut -d' ' -f1)
    local sum_y=$(echo "$sum_point" | cut -d' ' -f2)
    
    assert_equal "$triple_x" "$sum_x" "点加法x坐标"
    assert_equal "$triple_y" "$sum_y" "点加法y坐标"
    
    # 测试无穷远点
    local inf_point=$(ec_point_add "$CURVE_GX" "$CURVE_GY" "$CURVE_GX" "$(bigint_subtract "0" "$CURVE_GY")")
    assert_equal "0 0" "$inf_point" "无穷远点"
    
    test_log "INFO" "椭圆曲线点运算测试完成"
}

# 测试ECDSA
test_ecdsa() {
    test_log "INFO" "测试ECDSA..."
    
    # 测试不同曲线
    for curve in "secp256r1" "secp256k1"; do
        test_log "INFO" "测试ECDSA曲线: $curve"
        
        # 初始化曲线
        curve_init "$curve"
        
        # 生成密钥对
        local private_key=$(ecdsa_generate_private_key)
        assert_not_equal "" "$private_key" "私钥生成 $curve"
        
        local public_key_str=$(ecdsa_get_public_key "$private_key")
        assert_not_equal "" "$public_key_str" "公钥生成 $curve"
        
        local public_key_x=$(echo "$public_key_str" | cut -d' ' -f1)
        local public_key_y=$(echo "$public_key_str" | cut -d' ' -f2)
        
        # 测试消息
        local test_message="Hello, ECDSA on $curve!"
        local message_hash=$(hash_message "$test_message")
        
        # 签名
        assert_true $(ecdsa_sign "$private_key" "$message_hash" "$curve") "签名生成 $curve"
        local r="$ECDSA_SIGNATURE_R"
        local s="$ECDSA_SIGNATURE_S"
        
        assert_not_equal "" "$r" "签名r值 $curve"
        assert_not_equal "" "$s" "签名s值 $curve"
        
        # 验证签名
        assert_true $(ecdsa_verify "$public_key_x" "$public_key_y" "$message_hash" "$r" "$s" "$curve") "签名验证 $curve"
        
        # 测试错误情况
        local wrong_message="Wrong message"
        local wrong_hash=$(hash_message "$wrong_message")
        assert_false $(ecdsa_verify "$public_key_x" "$public_key_y" "$wrong_hash" "$r" "$s" "$curve") "错误消息拒绝 $curve"
        
        # 测试错误签名
        local wrong_r=$(bigint_add "$r" "1")
        assert_false $(ecdsa_verify "$public_key_x" "$public_key_y" "$message_hash" "$wrong_r" "$s" "$curve") "错误签名拒绝 $curve"
    done
    
    test_log "INFO" "ECDSA测试完成"
}

# 测试安全功能
test_security() {
    test_log "INFO" "测试安全功能..."
    
    # 初始化安全模块
    assert_true $(security_init) "安全模块初始化"
    
    # 测试RFC 6979
    local test_private_key="1234567890123456789012345678901234567890123456789012345678901234"
    local test_hash="1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
    local k1=$(rfc6979_generate_k "$test_private_key" "$test_hash" "secp256r1")
    local k2=$(rfc6979_generate_k "$test_private_key" "$test_hash" "secp256r1")
    
    assert_equal "$k1" "$k2" "RFC 6979确定性k值"
    
    # 测试不同哈希的k值不同
    local test_hash2="fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321"
    local k3=$(rfc6979_generate_k "$test_private_key" "$test_hash2" "secp256r1")
    assert_not_equal "$k1" "$k3" "不同哈希的k值不同"
    
    # 测试常量时间比较
    assert_true $(constant_time_compare "test123" "test123") "相同字符串常量时间比较"
    assert_false $(constant_time_compare "test123" "test124") "不同字符串常量时间比较"
    
    # 测试密钥强度检查
    local weak_key="12345"
    assert_false $(key_strength_check "$weak_key" "256") "弱密钥检测"
    
    local strong_key=$(bigint_random "256")
    assert_true $(key_strength_check "$strong_key" "256") "强密钥检测"
    
    test_log "INFO" "安全功能测试完成"
}

# 测试ASN.1编码
test_asn1() {
    test_log "INFO" "测试ASN.1编码..."
    
    # 测试ECDSA签名编码
    local test_r="1234567890123456789012345678901234567890123456789012345678901234"
    local test_s="567890123456789012345678901234567890123456789012345678901234567890"
    
    local signature_b64=$(encode_ecdsa_signature "$test_r" "$test_s")
    assert_not_equal "" "$signature_b64" "ECDSA签名编码"
    
    # 测试解码
    local decoded_r decoded_s
    decode_ecdsa_signature "$signature_b64" decoded_r decoded_s
    
    assert_equal "$test_r" "$decoded_r" "ECDSA签名r解码"
    assert_equal "$test_s" "$decoded_s" "ECDSA签名s解码"
    
    # 测试PEM格式
    local pem_private=$(encode_private_key_pem "$test_r" "secp256r1")
    assert_not_equal "" "$pem_private" "私钥PEM编码"
    
    local pem_public=$(encode_public_key_pem "$test_r" "$test_s" "secp256r1")
    assert_not_equal "" "$pem_public" "公钥PEM编码"
    
    test_log "INFO" "ASN.1编码测试完成"
}

# 测试熵收集
test_entropy() {
    test_log "INFO" "测试熵收集系统..."
    
    # 初始化熵系统
    assert_true $(entropy_init) "熵系统初始化"
    
    # 测试各熵源
    for source in 1 2 3 4 5 6 7 8; do
        case $source in
            1) local entropy_data=$(entropy_source_timestamp) ;;
            2) local entropy_data=$(entropy_source_system) ;;
            3) local entropy_data=$(entropy_source_process) ;;
            4) local entropy_data=$(entropy_source_network) ;;
            5) local entropy_data=$(entropy_source_disk) ;;
            6) local entropy_data=$(entropy_source_user) ;;
            7) local entropy_data=$(entropy_source_hardware) ;;
            8) local entropy_data=$(entropy_source_system_random) ;;
        esac
        
        local quality=$(entropy_calculate_quality "$entropy_data")
        test_log "INFO" "熵源$source 质量: $quality%"
        
        if [[ $quality -lt 50 ]]; then
            test_log "WARN" "熵源$source 质量较低"
        fi
    done
    
    # 测试随机数生成
    for bits in 128 256 512; do
        local random_num=$(entropy_generate_random "$bits")
        assert_not_equal "" "$random_num" "生成 $bits 位随机数"
        
        # 检查位数
        local bit_count=$(bashmath_log2 "$random_num")
        if [[ $bit_count -le $bits && $bit_count -gt $(($bits - 32)) ]]; then
            test_log "PASS" "随机数位数量正确: $bit_count/$bits"
        else
            test_log "FAIL" "随机数位数量异常: $bit_count/$bits"
        fi
    done
    
    test_log "INFO" "熵收集系统测试完成"
}

# 性能测试
performance_test() {
    test_log "INFO" "性能测试..."
    
    # 初始化曲线
    curve_init "secp256r1"
    
    local iterations=100
    local start_time=$(date +%s.%N)
    
    for ((i=1; i<=iterations; i++)); do
        # 生成密钥对
        local private_key=$(ecdsa_generate_private_key)
        local public_key_str=$(ecdsa_get_public_key "$private_key")
        
        # 签名
        local message="Performance test $i"
        local message_hash=$(hash_message "$message")
        ecdsa_sign "$private_key" "$message_hash" "secp256r1"
        
        # 验证
        local public_key_x=$(echo "$public_key_str" | cut -d' ' -f1)
        local public_key_y=$(echo "$public_key_str" | cut -d' ' -f2)
        ecdsa_verify "$public_key_x" "$public_key_y" "$message_hash" "$ECDSA_SIGNATURE_R" "$ECDSA_SIGNATURE_S" "secp256r1"
    done
    
    local end_time=$(date +%s.%N)
    # 计算持续时间（纳秒转秒）
    local start_sec=${start_time%.*}
    local start_nsec=${start_time#*.}
    local end_sec=${end_time%.*}
    local end_nsec=${end_time#*.}
    
    local total_nsec=$(( (end_sec - start_sec) * 1000000000 + (end_nsec - start_nsec) ))
    local duration=$(bashmath_divide_float "$total_nsec" "1000000000" 6)
    local ops_per_second=$(bashmath_divide_float "$iterations" "$duration" 6)
    
    test_log "INFO" "性能测试结果:"
    test_log "INFO" "  操作次数: $iterations"
    test_log "INFO" "  总时间: ${duration}s"
    test_log "INFO" "  操作/秒: $ops_per_second"
    
    # 性能要求检查（比较操作/秒 > 0.1）
    local threshold_check=$(echo "$ops_per_second" | awk '{if($1 > 0.1) print 1; else print 0}')
    if [[ "$threshold_check" == "1" ]]; then
        test_log "PASS" "性能满足基本要求"
    else
        test_log "FAIL" "性能过低"
    fi
}

# 兼容性测试
compatibility_test() {
    test_log "INFO" "兼容性测试..."
    
    # 测试不同bash版本兼容性
    if [[ ${BASH_VERSION%%.*} -lt 4 ]]; then
        test_log "WARN" "Bash版本过低，某些功能可能受限"
    fi
    
    # 测试命令可用性
    local required_commands=("sha256sum" "bc" "xxd" "base64")
    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            test_log "PASS" "命令可用: $cmd"
        else
            test_log "WARN" "命令不可用: $cmd"
        fi
    done
    
    # 测试文件系统权限
    if [[ -w "/tmp" ]]; then
        test_log "PASS" "临时目录可写"
    else
        test_log "FAIL" "临时目录不可写"
    fi
    
    test_log "INFO" "兼容性测试完成"
}

# 安全测试
security_test() {
    test_log "INFO" "安全测试..."
    
    # 测试私钥保护
    curve_init "secp256r1"
    local private_key=$(ecdsa_generate_private_key)
    
    # 私钥不应出现在环境变量中
    if env | grep -q "$private_key"; then
        test_log "FAIL" "私钥泄露到环境变量"
    else
        test_log "PASS" "私钥未泄露"
    fi
    
    # 测试内存保护（有限的检查）
    if command -v ps >/dev/null 2>&1; then
        local process_info=$(ps -p $$ -o args=)
        if [[ ${#private_key} -gt 10 && "$process_info" =~ $private_key ]]; then
            test_log "WARN" "私钥可能出现在进程列表中"
        else
            test_log "PASS" "私钥未出现在进程列表"
        fi
    fi
    
    # 测试随机数质量
    local random_nums=""
    for ((i=0; i<100; i++)); do
        random_nums="${random_nums}$(bigint_random "128")"
    done
    
    # 检查重复
    local unique_count=$(echo "$random_nums" | tr ' ' '\\n' | sort -u | wc -l)
    if [[ $unique_count -gt 90 ]]; then
        test_log "PASS" "随机数质量良好 ($unique_count/100 唯一)"
    else
        test_log "FAIL" "随机数质量差 ($unique_count/100 唯一)"
    fi
    
    test_log "INFO" "安全测试完成"
}

# 主测试函数
run_tests() {
    local test_curve="${1:-secp256r1}"
    local verbose="${2:-0}"
    
    test_log "INFO" "开始bECCsh测试套件"
    test_log "INFO" "测试曲线: $test_curve"
    test_log "INFO" "开始时间: $(date)"
    
    # 创建输出目录
    mkdir -p "$OUTPUT_DIR"
    
    # 运行各项测试
    test_bigint
    test_ec_curve
    test_ec_point
    test_ecdsa
    test_security
    test_asn1
    test_entropy
    
    # 可选测试
    performance_test
    compatibility_test
    security_test
    
    # 显示测试结果
    echo -e "\\n${COLOR_BLUE}===============================${COLOR_RESET}"
    echo -e "${COLOR_BLUE}测试结果汇总${COLOR_RESET}"
    echo -e "${COLOR_BLUE}===============================${COLOR_RESET}"
    echo -e "总测试数: $TEST_TOTAL"
    echo -e "通过: ${COLOR_GREEN}$TEST_PASSED${COLOR_RESET}"
    echo -e "失败: ${COLOR_RED}$TEST_FAILED${COLOR_RESET}"
    echo -e "跳过: ${COLOR_YELLOW}$TEST_SKIPPED${COLOR_RESET}"
    echo -e "通过率: $(bashmath_divide_float "$((TEST_PASSED * 100))" "$TEST_TOTAL" 2)%"
    echo -e "${COLOR_BLUE}===============================${COLOR_RESET}"
    
    # 保存测试结果
    cat > "$OUTPUT_DIR/test_results.txt" << EOF
bECCsh测试报告
==============
开始时间: $(date)
测试曲线: $test_curve

测试结果:
- 总测试数: $TEST_TOTAL
- 通过: $TEST_PASSED
- 失败: $TEST_FAILED
- 跳过: $TEST_SKIPPED
- 通过率: $(bashmath_divide_float "$((TEST_PASSED * 100))" "$TEST_TOTAL" 2)%

系统信息:
- Bash版本: $BASH_VERSION
- 操作系统: $(uname -a)
- 主机名: $(hostname)
- 日期: $(date)
EOF
    
    # 返回测试结果
    if [[ $TEST_FAILED -eq 0 ]]; then
        test_log "INFO" "所有测试通过!"
        return 0
    else
        test_log "FAIL" "部分测试失败"
        return 1
    fi
}

# 显示使用帮助
show_help() {
    cat << EOF
bECCsh测试套件

使用方法: $0 [选项]

选项:
    -c, --curve CURVE     选择测试曲线 (secp256r1, secp256k1, secp384r1)
    -v, --verbose         详细输出
    -h, --help            显示帮助
    --performance         只运行性能测试
    --security            只运行安全测试
    --compatibility       只运行兼容性测试

示例:
    $0 -c secp256r1 -v
    $0 --performance
    $0 --security

EOF
}

# 主函数
main() {
    local test_curve="secp256r1"
    local verbose=0
    local test_mode="all"
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--curve)
                test_curve="$2"
                shift 2
                ;;
            -v|--verbose)
                verbose=1
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            --performance)
                test_mode="performance"
                shift
                ;;
            --security)
                test_mode="security"
                shift
                ;;
            --compatibility)
                test_mode="compatibility"
                shift
                ;;
            *)
                echo "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 根据测试模式运行
    case "$test_mode" in
        "performance")
            performance_test
            ;;
        "security")
            security_test
            ;;
        "compatibility")
            compatibility_test
            ;;
        *)
            run_tests "$test_curve" "$verbose"
            ;;
    esac
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi