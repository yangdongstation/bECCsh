#!/bin/bash
# test_suite.sh - bECCsh专业测试套件
# 包含单元测试、集成测试和性能测试

set -euo pipefail

# 测试统计
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试框架函数
run_test() {
    local test_name="$1"
    local test_func="$2"
    
    ((TESTS_TOTAL++))
    echo -n "测试: $test_name ... "
    
    if $test_func > /dev/null 2>&1; then
        echo -e "${GREEN}通过${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}失败${NC}"
        ((TESTS_FAILED++))
    fi
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-断言失败}"
    
    if [ "$expected" != "$actual" ]; then
        echo "$message: 期望 '$expected', 实际 '$actual'" >&2
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local message="${2:-值不能为空}"
    
    if [ -z "$value" ]; then
        echo "$message" >&2
        return 1
    fi
}

assert_file_exists() {
    local filename="$1"
    local message="${2:-文件不存在}"
    
    if [ ! -f "$filename" ]; then
        echo "$message: $filename" >&2
        return 1
    fi
}

# 数学运算测试
test_bn_mod_add() {
    source lib/big_math.sh
    
    local result
    result=$(bn_mod_add "5" "3" "17")
    assert_equals "8" "$result" "模加法测试失败"
    
    result=$(bn_mod_add "10" "10" "17")
    assert_equals "3" "$result" "模加法溢出测试失败"
}

test_bn_mod_sub() {
    source lib/big_math.sh
    
    local result
    result=$(bn_mod_sub "10" "3" "17")
    assert_equals "7" "$result" "模减法测试失败"
    
    result=$(bn_mod_sub "3" "10" "17")
    assert_equals "10" "$result" "模减法负数测试失败"
}

test_bn_mod_mul() {
    source lib/big_math.sh
    
    local result
    result=$(bn_mod_mul "5" "3" "17")
    assert_equals "15" "$result" "模乘法测试失败"
    
    result=$(bn_mod_mul "10" "10" "17")
    assert_equals "15" "$result" "模乘法溢出测试失败"
}

test_bn_mod_inverse() {
    source lib/big_math.sh
    
    local result
    result=$(bn_mod_inverse "3" "17")
    assert_equals "6" "$result" "模逆元测试失败"
    
    # 验证逆元正确性
    local product=$(bn_mod_mul "3" "$result" "17")
    assert_equals "1" "$product" "模逆元验证失败"
}

# 椭圆曲线测试
test_point_double() {
    source lib/ec_curve.sh
    source lib/ec_point.sh
    
    # 测试点加倍
    local x3 y3
    read -r x3 y3 < <(point_double "$CURVE_GX" "$CURVE_GY")
    
    assert_not_empty "$x3" "点加倍x坐标为空"
    assert_not_empty "$y3" "点加倍y坐标为空"
}

test_point_add() {
    source lib/ec_curve.sh
    source lib/ec_point.sh
    
    # 测试点加法
    local x3 y3
    read -r x3 y3 < <(point_add "$CURVE_GX" "$CURVE_GY" "$CURVE_GX" "$CURVE_GY")
    
    assert_not_empty "$x3" "点加法x坐标为空"
    assert_not_empty "$y3" "点加法y坐标为空"
}

test_scalar_mult() {
    source lib/ec_curve.sh
    source lib/ec_point.sh
    
    # 测试标量乘法
    local rx ry
    read -r rx ry < <(scalar_mult "2" "$CURVE_GX" "$CURVE_GY")
    
    assert_not_empty "$rx" "标量乘法x坐标为空"
    assert_not_empty "$ry" "标量乘法y坐标为空"
}

# ECDSA测试
test_ecdsa_sign() {
    source lib/ec_curve.sh
    source lib/ecdsa.sh
    
    local hash="abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
    local k="123456789012345678901234567890123456789012345678901234567890"
    local d="987654321098765432109876543210987654321098765432109876543210"
    
    local signature
    signature=$(ecdsa_sign "$hash" "$k" "$d")
    
    assert_not_empty "$signature" "签名生成失败"
    assert_equals "128" "${#signature}" "签名长度不正确"
}

test_ecdsa_verify() {
    source lib/ec_curve.sh
    source lib/ecdsa.sh
    
    local hash="abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
    local k="123456789012345678901234567890123456789012345678901234567890"
    local d="987654321098765432109876543210987654321098765432109876543210"
    
    # 生成签名
    local signature
    signature=$(ecdsa_sign "$hash" "$k" "$d")
    
    # 计算公钥
    local pub_key_x pub_key_y
    read -r pub_key_x pub_key_y < <(scalar_mult "$d" "$CURVE_GX" "$CURVE_GY")
    
    # 验证签名
    if ecdsa_verify "$hash" "$signature" "$pub_key_x" "$pub_key_y"; then
        return 0
    else
        echo "签名验证失败" >&2
        return 1
    fi
}

# 熵收集测试
test_entropy_collection() {
    source lib/entropy.sh
    
    local entropy
    entropy=$(collect_entropy)
    
    assert_not_empty "$entropy" "熵收集失败"
    
    # 检查熵值范围
    if [ "$entropy" -le "0" ] || [ "$entropy" -ge "$CURVE_N" ]; then
        echo "熵值超出有效范围" >&2
        return 1
    fi
}

# 曲线参数测试
test_curve_parameters() {
    source lib/curves.sh
    
    # 测试secp256r1
    set_curve "secp256r1"
    assert_equals "secp256r1" "$CURVE_NAME" "曲线设置失败"
    assert_not_empty "$CURVE_P" "曲线素数为空"
    assert_not_empty "$CURVE_N" "曲线阶为空"
    
    # 测试secp256k1
    set_curve "secp256k1"
    assert_equals "secp256k1" "$CURVE_NAME" "secp256k1曲线设置失败"
    
    # 测试secp384r1
    set_curve "secp384r1"
    assert_equals "secp384r1" "$CURVE_NAME" "secp384r1曲线设置失败"
}

# 密钥格式测试
test_key_formats() {
    source lib/key_formats.sh
    
    local test_key="123456789012345678901234567890"
    local test_file="test_key.tmp"
    
    # 测试十六进制格式
    export_key_hex "private" "$test_key" "$test_file"
    assert_file_exists "$test_file" "十六进制密钥文件不存在"
    rm -f "$test_file"
    
    # 测试JSON格式
    export_key_info "$test_key" "111" "222" "secp256r1" "$test_file"
    assert_file_exists "$test_file" "JSON密钥文件不存在"
    rm -f "$test_file"
}

# 完整流程测试
test_full_workflow() {
    local test_file="test_message.txt"
    local test_sig="test_message.txt.sig"
    
    # 创建测试文件
    echo "这是一个测试消息，用于验证ECDSA完整流程。" > "$test_file"
    
    # 生成密钥对
    if ! ./becc.sh genkey > /dev/null 2>&1; then
        echo "密钥生成失败" >&2
        return 1
    fi
    
    # 签名文件
    if ! ./becc.sh sign "$test_file" > /dev/null 2>&1; then
        echo "签名失败" >&2
        return 1
    fi
    
    # 验证签名文件是否存在
    assert_file_exists "$test_sig" "签名文件不存在"
    
    # 验证签名
    if ! ./becc.sh verify "$test_file" "$test_sig" > /dev/null 2>&1; then
        echo "签名验证失败" >&2
        return 1
    fi
    
    # 清理
    rm -f "$test_file" "$test_sig" ecc.key.priv ecc.key.pub
}

# 性能测试
test_performance() {
    echo "性能测试（这可能需要几分钟）..."
    
    local start_time=$(date +%s)
    
    # 测试标量乘法性能
    source lib/ec_curve.sh
    source lib/ec_point.sh
    
    read -r rx ry < <(scalar_mult "12345" "$CURVE_GX" "$CURVE_GY")
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo "标量乘法耗时: ${duration}秒"
    
    # 期望在合理时间内完成（虽然仍然很慢）
    if [ "$duration" -lt 300 ]; then  # 5分钟
        return 0
    else
        echo "性能测试超时" >&2
        return 1
    fi
}

# 边界条件测试
test_edge_cases() {
    source lib/big_math.sh
    
    # 测试零值
    local result
    result=$(bn_mod_add "0" "5" "17")
    assert_equals "5" "$result" "零值加法失败"
    
    result=$(bn_mod_mul "0" "5" "17")
    assert_equals "0" "$result" "零值乘法失败"
    
    # 测试大数
    result=$(bn_mod_add "1000000" "2000000" "3000000")
    assert_equals "0" "$result" "大数加法溢出失败"
}

# 错误处理测试
test_error_handling() {
    # 测试无效输入
    local result
    result=$(bn_mod_inverse "0" "17" 2>/dev/null || echo "error")
    assert_equals "error" "$result" "零值逆元应该失败"
    
    # 测试文件不存在
    if ./becc.sh sign "nonexistent_file.txt" 2>/dev/null; then
        echo "不存在的文件应该导致失败" >&2
        return 1
    fi
}

# 运行所有测试
run_all_tests() {
    echo "========================================"
    echo "bECCsh 专业测试套件"
    echo "========================================"
    echo ""
    
    # 数学运算测试
    echo "数学运算测试:"
    run_test "模加法" test_bn_mod_add
    run_test "模减法" test_bn_mod_sub
    run_test "模乘法" test_bn_mod_mul
    run_test "模逆元" test_bn_mod_inverse
    echo ""
    
    # 椭圆曲线测试
    echo "椭圆曲线测试:"
    run_test "点加倍" test_point_double
    run_test "点加法" test_point_add
    run_test "标量乘法" test_scalar_mult
    echo ""
    
    # ECDSA测试
    echo "ECDSA测试:"
    run_test "签名生成" test_ecdsa_sign
    run_test "签名验证" test_ecdsa_verify
    echo ""
    
    # 系统测试
    echo "系统测试:"
    run_test "熵收集" test_entropy_collection
    run_test "曲线参数" test_curve_parameters
    run_test "密钥格式" test_key_formats
    echo ""
    
    # 集成测试
    echo "集成测试:"
    run_test "完整流程" test_full_workflow
    run_test "性能测试" test_performance
    echo ""
    
    # 边界测试
    echo "边界条件测试:"
    run_test "边界条件" test_edge_cases
    run_test "错误处理" test_error_handling
    echo ""
    
    # 测试结果统计
    echo "========================================"
    echo "测试结果统计:"
    echo "总测试数: $TESTS_TOTAL"
    echo -e "通过: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "失败: ${RED}$TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}所有测试通过！${NC}"
        return 0
    else
        echo -e "${RED}部分测试失败！${NC}"
        return 1
    fi
}

# 性能基准测试
run_benchmark() {
    echo "========================================"
    echo "bECCsh 性能基准测试"
    echo "========================================"
    echo ""
    
    # 测试各种操作的性能
    echo "1. 密钥生成性能测试..."
    local keygen_start=$(date +%s)
    ./becc.sh genkey > /dev/null 2>&1
    local keygen_end=$(date +%s)
    local keygen_time=$((keygen_end - keygen_start))
    echo "密钥生成耗时: ${keygen_time}秒"
    
    echo "2. 签名性能测试..."
    echo "测试数据" > test_perf.txt
    local sign_start=$(date +%s)
    ./becc.sh sign test_perf.txt > /dev/null 2>&1
    local sign_end=$(date +%s)
    local sign_time=$((sign_end - sign_start))
    echo "签名耗时: ${sign_time}秒"
    
    echo "3. 验证性能测试..."
    local verify_start=$(date +%s)
    ./becc.sh verify test_perf.txt test_perf.txt.sig > /dev/null 2>&1
    local verify_end=$(date +%s)
    local verify_time=$((verify_end - verify_start))
    echo "验证耗时: ${verify_time}秒"
    
    echo ""
    echo "性能基准结果:"
    echo "密钥生成: ${keygen_time}秒"
    echo "签名: ${sign_time}秒"
    echo "验证: ${verify_time}秒"
    echo "总计: $((keygen_time + sign_time + verify_time))秒"
    
    # 清理
    rm -f test_perf.txt test_perf.txt.sig ecc.key.priv ecc.key.pub
}

# 主函数
main() {
    local command="${1:-all}"
    
    case "$command" in
        unit)
            # 只运行单元测试
            TESTS_TOTAL=0
            TESTS_PASSED=0
            TESTS_FAILED=0
            
            echo "单元测试:"
            run_test "模加法" test_bn_mod_add
            run_test "模减法" test_bn_mod_sub
            run_test "模乘法" test_bn_mod_mul
            run_test "模逆元" test_bn_mod_inverse
            run_test "点加倍" test_point_double
            run_test "点加法" test_point_add
            run_test "标量乘法" test_scalar_mult
            run_test "签名生成" test_ecdsa_sign
            run_test "签名验证" test_ecdsa_verify
            ;;
        integration)
            # 只运行集成测试
            TESTS_TOTAL=0
            TESTS_PASSED=0
            TESTS_FAILED=0
            
            echo "集成测试:"
            run_test "完整流程" test_full_workflow
            ;;
        performance)
            # 只运行性能测试
            run_benchmark
            ;;
        all|*)
            # 运行所有测试
            run_all_tests
            ;;
    esac
}

# 入口点
main "$@"