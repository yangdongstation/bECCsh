#!/bin/bash
# test_professional.sh - 专业测试套件
# 测试bECCsh Professional的所有功能

set -euo pipefail

# 测试配置
readonly TEST_ITERATIONS=10
readonly TEST_TIMEOUT=30
readonly TEST_CURVE="secp256r1"

# 测试统计
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 测试框架
run_test() {
    local test_name="$1"
    local test_func="$2"
    
    ((TESTS_TOTAL++))
    echo -n "测试: $test_name ... "
    
    # 设置超时监控
    local timeout_info=$(start_timeout_monitor "$TEST_TIMEOUT" "$test_name")
    
    if $test_func > /dev/null 2>&1; then
        echo -e "${GREEN}通过${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}失败${NC}"
        ((TESTS_FAILED++))
    fi
    
    # 取消超时监控
    cancel_timeout_monitor "$timeout_info"
}

# 断言函数
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-断言失败}"
    
    if [[ "$expected" != "$actual" ]]; then
        echo "$message: 期望 '$expected', 实际 '$actual'" >&2
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local message="${2:-值不能为空}"
    
    if [[ -z "$value" ]]; then
        echo "$message" >&2
        return 1
    fi
}

assert_file_exists() {
    local filename="$1"
    local message="${2:-文件不存在}"
    
    if [[ ! -f "$filename" ]]; then
        echo "$message: $filename" >&2
        return 1
    fi
}

# 测试大数运算
test_bigint_operations() {
    source lib/bigint.sh
    
    # 测试加法
    local sum=$(bigint_add "123" "456")
    assert_equals "579" "$sum" "大数加法失败"
    
    # 测试减法
    local diff=$(bigint_sub "579" "123")
    assert_equals "456" "$diff" "大数减法失败"
    
    # 测试乘法
    local product=$(bigint_mul "12" "34")
    assert_equals "408" "$product" "大数乘法失败"
    
    # 测试模运算
    local mod=$(bigint_mod "100" "17")
    assert_equals "15" "$mod" "大数模运算失败"
    
    # 测试逆元
    local inv=$(bigint_inverse "3" "17")
    assert_equals "6" "$inv" "大数逆元失败"
}

# 测试椭圆曲线运算
test_elliptic_curve_operations() {
    source lib/ec_math.sh
    
    # 设置测试曲线
    set_curve_parameters "$TEST_CURVE"
    
    # 测试点加倍
    local x3 y3
    read -r x3 y3 < <(point_double_professional "$CURVE_GX" "$CURVE_GY")
    assert_not_empty "$x3" "点加倍x坐标为空"
    assert_not_empty "$y3" "点加倍y坐标为空"
    
    # 测试点加法
    read -r x3 y3 < <(point_add_professional "$CURVE_GX" "$CURVE_GY" "$CURVE_GX" "$CURVE_GY")
    assert_not_empty "$x3" "点加法x坐标为空"
    assert_not_empty "$y3" "点加法y坐标为空"
    
    # 测试标量乘法
    local rx ry
    read -r rx ry < <(scalar_mult_professional "2" "$CURVE_GX" "$CURVE_GY")
    assert_not_empty "$rx" "标量乘法x坐标为空"
    assert_not_empty "$ry" "标量乘法y坐标为空"
}

# 测试ECDSA
test_ecdsa() {
    source lib/ecdsa_prof.sh
    
    # 设置测试曲线
    set_curve_parameters "$TEST_CURVE"
    
    local test_hash="abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
    local test_private="123456789012345678901234567890123456789012345678901234567890"
    local test_k="987654321098765432109876543210987654321098765432109876543210"
    
    # 生成签名
    local signature
    signature=$(ecdsa_sign_professional "$test_hash" "$test_k" "$test_private")
    assert_not_empty "$signature" "签名生成失败"
    assert_equals "128" "${#signature}" "签名长度不正确"
    
    # 计算公钥
    local public_key_x public_key_y
    read -r public_key_x public_key_y < <(scalar_mult_professional "$test_private" "$CURVE_GX" "$CURVE_GY")
    
    # 验证签名
    if ecdsa_verify_professional "$test_hash" "$signature" "$public_key_x" "$public_key_y"; then
        return 0
    else
        echo "签名验证失败" >&2
        return 1
    fi
}

# 测试密钥管理
test_key_management() {
    source lib/keymgmt.sh
    
    # 生成密钥对
    local key_data
    read -r key_data < <(generate_key_pair "$TEST_CURVE" "test_key")
    assert_not_empty "$key_data" "密钥生成失败"
    
    local key_id=$(echo "$key_data" | cut -d' ' -f1)
    
    # 验证密钥完整性
    if ! verify_key_integrity "$key_id"; then
        echo "密钥完整性验证失败" >&2
        return 1
    fi
    
    # 加载密钥
    local loaded_data
    read -r loaded_data < <(load_key_pair "$key_id")
    assert_not_empty "$loaded_data" "密钥加载失败"
    
    # 导出PEM
    export_key_pem "$key_id" "test_key.pem"
    assert_file_exists "test_key.pem" "PEM文件未生成"
    
    # 清理
    rm -f "test_key.pem"
}

# 测试错误处理
test_error_handling() {
    source lib/error_handling.sh
    
    # 测试参数验证
    if validate_parameters "test1" "test2" ""; then
        echo "空参数应该验证失败" >&2
        return 1
    fi
    
    # 测试文件验证
    if validate_file "nonexistent_file.txt"; then
        echo "不存在的文件应该验证失败" >&2
        return 1
    fi
    
    # 测试范围验证
    if validate_range "100" "0" "50"; then
        echo "超出范围的值应该验证失败" >&2
        return 1
    fi
}

# 测试安全功能
test_security_features() {
    source lib/security.sh
    
    # 测试高质量随机数生成
    local private_key
    private_key=$(generate_high_entropy_private_key)
    assert_not_empty "$private_key" "高质量随机数生成失败"
    
    # 测试确定性k值生成
    local test_hash="abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
    local test_private="123456789012345678901234567890123456789012345678901234567890"
    local k1 k2
    k1=$(generate_deterministic_k "$test_hash" "$test_private" "$CURVE_N")
    k2=$(generate_deterministic_k "$test_hash" "$test_private" "$CURVE_N")
    assert_equals "$k1" "$k2" "确定性k值生成不一致"
}

# 测试ASN.1编码
test_asn1() {
    source lib/asn1.sh
    
    # 测试整数编码
    local int_encoded=$(encode_integer "12345")
    local int_decoded
    read -r int_value int_pos <<< $(decode_integer "$int_encoded" "0")
    assert_equals "12345" "$int_value" "ASN.1整数编码/解码失败"
}

# 测试曲线参数
test_curve_parameters() {
    source lib/curves_prof.sh
    
    # 测试secp256r1
    if ! set_curve_parameters "secp256r1"; then
        echo "secp256r1参数设置失败" >&2
        return 1
    fi
    
    if ! validate_curve_parameters_prof; then
        echo "secp256r1参数验证失败" >&2
        return 1
    fi
    
    # 测试secp256k1
    if ! set_curve_parameters "secp256k1"; then
        echo "secp256k1参数设置失败" >&2
        return 1
    fi
    
    # 测试secp384r1
    if ! set_curve_parameters "secp384r1"; then
        echo "secp384r1参数设置失败" >&2
        return 1
    fi
}

# 测试完整工作流
test_complete_workflow() {
    # 创建测试文件
    echo "这是一个测试消息，用于验证ECDSA完整流程。" > test_workflow.txt
    echo "此文件包含一些示例文本，将被签名。" >> test_workflow.txt
    
    # 生成密钥对
    local key_data
    read -r key_data < <(generate_key_pair "$TEST_CURVE" "workflow_test")
    
    if [[ $? -ne 0 ]]; then
        echo "密钥生成失败" >&2
        return 1
    fi
    
    local key_id=$(echo "$key_data" | cut -d' ' -f1)
    
    # 签名文件
    if ! ./becc_professional.sh -c "$TEST_CURVE" sign test_workflow.txt; then
        echo "签名失败" >&2
        return 1
    fi
    
    # 验证签名文件是否存在
    if [[ ! -f "test_workflow.txt.sig" ]]; then
        echo "签名文件未生成" >&2
        return 1
    fi
    
    # 验证签名
    if ! ./becc_professional.sh -c "$TEST_CURVE" verify test_workflow.txt test_workflow.txt.sig; then
        echo "签名验证失败" >&2
        return 1
    fi
    
    # 清理
    rm -f test_workflow.txt test_workflow.txt.sig
    
    return 0
}

# 测试性能
test_performance() {
    log_professional INFO "性能测试..."
    
    # 测试大数运算性能
    local start_time=$(date +%s)
    local result
    for i in {1..100}; do
        result=$(bigint_mul "123456789" "987654321")
    done
    local end_time=$(date +%s)
    local bigint_time=$((end_time - start_time))
    
    # 测试ECDSA性能
    start_time=$(date +%s)
    for i in {1..10}; do
        local test_hash=$(printf "%064x" $RANDOM)
        local test_private=$(generate_high_entropy_private_key)
        local test_k=$(generate_deterministic_k "$test_hash" "$test_private" "$CURVE_N")
        local signature=$(ecdsa_sign_professional "$test_hash" "$test_k" "$test_private")
    done
    end_time=$(date +%s)
    local ecdsa_time=$((end_time - start_time))
    
    echo "性能测试结果:"
    echo "  大数运算(100次): ${bigint_time}s"
    echo "  ECDSA签名(10次): ${ecdsa_time}s"
}

# 测试边界条件
test_boundary_conditions() {
    source lib/bigint.sh
    
    # 测试零值处理
    local zero_add=$(bigint_add "0" "5")
    assert_equals "5" "$zero_add" "零值加法失败"
    
    # 测试大数处理
    local big_num="999999999999999999999999999999999999999999999999999999999999"
    local big_result=$(bigint_add "$big_num" "1")
    assert_not_empty "$big_result" "大数处理失败"
    
    # 测试边界值
    local max_test="999999999999999999999999999999999999999999999999999999999999"
    local mod_result=$(bigint_mod "$max_test" "17")
    assert_not_empty "$mod_result" "边界值模运算失败"
}

# 测试错误恢复
test_error_recovery() {
    # 测试文件错误恢复
    if validate_file "nonexistent.txt"; then
        echo "不存在的文件验证应该失败" >&2
        return 1
    fi
    
    # 测试密钥错误恢复
    if validate_key "invalid_key!@#"; then
        echo "无效密钥应该验证失败" >&2
        return 1
    fi
    
    return 0
}

# 测试内存使用
test_memory_usage() {
    local memory_before=$(ps -o rss= -p $$ 2>/dev/null | xargs)
    
    # 执行一些内存密集型操作
    for i in {1..100}; do
        local big_num=$(bigint_pow "2" "100")
        local result=$(bigint_mul "$big_num" "$big_num")
    done
    
    local memory_after=$(ps -o rss= -p $$ 2>/dev/null | xargs)
    local memory_diff=$((memory_after - memory_before))
    
    if [[ $memory_diff -gt 102400 ]]; then  # 100MB限制
        echo "内存使用增长过多: ${memory_diff}KB" >&2
        return 1
    fi
    
    return 0
}

# 运行所有专业测试
run_all_professional_tests() {
    echo "========================================"
    echo "bECCsh Professional 专业测试套件"
    echo "========================================"
    echo ""
    
    # 初始化所有模块
    init_bigint
    init_curves_prof
    init_ec_math
    init_ecdsa_prof
    init_security
    init_asn1
    init_error_handling
    init_keymgmt
    
    # 基础功能测试
    echo "基础功能测试:"
    run_test "大数运算" test_bigint_operations
    run_test "椭圆曲线运算" test_elliptic_curve_operations
    run_test "ECDSA" test_ecdsa
    run_test "密钥管理" test_key_management
    run_test "ASN.1编码" test_asn1
    echo ""
    
    # 安全功能测试
    echo "安全功能测试:"
    run_test "安全功能" test_security_features
    run_test "错误处理" test_error_handling
    echo ""
    
    # 曲线参数测试
    echo "曲线参数测试:"
    run_test "曲线参数" test_curve_parameters
    echo ""
    
    # 集成测试
    echo "集成测试:"
    run_test "完整工作流" test_complete_workflow
    echo ""
    
    # 边界条件测试
    echo "边界条件测试:"
    run_test "边界条件" test_boundary_conditions
    run_test "错误恢复" test_error_recovery
    echo ""
    
    # 性能和安全测试
    echo "性能和安全测试:"
    run_test "内存使用" test_memory_usage
    echo ""
    
    # 显示结果
    echo "========================================"
    echo "专业测试完成"
    echo "总测试数: $TESTS_TOTAL"
    echo -e "通过: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "失败: ${RED}$TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}所有专业测试通过！${NC}"
        return 0
    else
        echo -e "${RED}部分专业测试失败！${NC}"
        return 1
    fi
}

# 性能基准测试
run_performance_benchmark() {
    echo "========================================"
    echo "bECCsh Professional 性能基准测试"
    echo "========================================"
    echo ""
    
    # 初始化
    init_bigint
    init_curves_prof
    init_ec_math
    init_ecdsa_prof
    init_security
    
    # 运行性能测试
    test_performance
    
    echo "========================================"
}

# 安全测试
run_security_tests() {
    echo "========================================"
    echo "bECCsh Professional 安全测试"
    echo "========================================"
    echo ""
    
    # 初始化
    init_security
    init_error_handling
    
    # 运行安全相关测试
    run_test "安全功能" test_security_features
    run_test "错误处理" test_error_handling
    run_test "边界条件" test_boundary_conditions
    run_test "错误恢复" test_error_recovery
    
    echo "========================================"
    echo "安全测试完成"
    echo "========================================"
}

# 主函数
main() {
    local command="${1:-all}"
    
    case "$command" in
        all)
            run_all_professional_tests
            ;;
        performance)
            run_performance_benchmark
            ;;
        security)
            run_security_tests
            ;;
        unit)
            echo "运行单元测试..."
            # 运行特定单元测试
            ;;
        integration)
            echo "运行集成测试..."
            # 运行特定集成测试
            ;;
        *)
            echo "用法: $0 [all|performance|security|unit|integration]"
            echo "  all         - 运行所有测试"
            echo "  performance - 运行性能基准测试"
            echo "  security    - 运行安全测试"
            echo "  unit        - 运行单元测试"
            echo "  integration - 运行集成测试"
            ;;
    esac
}

# 入口点
main "$@"