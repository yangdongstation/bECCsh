#!/bin/bash
# 纯Bash数学函数库完整测试脚本
# 测试所有数学函数的正确性和边界情况

# 确保使用bash运行
if [ -z "${BASH_VERSION:-}" ]; then
    echo "错误: 请使用bash运行此脚本"
    exit 1
fi

set -euo pipefail

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# 测试结果统计
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# 导入数学函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bash_math.sh"

# 测试辅助函数
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    ((TESTS_TOTAL++))
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name"
        echo -e "  期望: $expected"
        echo -e "  实际: $actual"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_error() {
    local test_output="$1"
    local test_name="$2"
    
    ((TESTS_TOTAL++))
    
    if [[ "$test_output" == "0" ]]; then
        echo -e "${GREEN}✓${NC} $test_name (错误处理正确)"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $test_name (应该返回错误)"
        echo -e "  输出: $test_output"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 测试十六进制转十进制
test_hex_to_dec() {
    echo -e "\n${BLUE}=== 测试十六进制转十进制 ===${NC}"
    
    # 基本测试
    assert_equals "255" "$(bashmath_hex_to_dec "FF")" "FF -> 255"
    assert_equals "256" "$(bashmath_hex_to_dec "100")" "100 -> 256"
    assert_equals "10" "$(bashmath_hex_to_dec "A")" "A -> 10"
    assert_equals "0" "$(bashmath_hex_to_dec "0")" "0 -> 0"
    
    # 大小写测试
    assert_equals "255" "$(bashmath_hex_to_dec "ff")" "ff -> 255 (小写)"
    assert_equals "255" "$(bashmath_hex_to_dec "Ff")" "Ff -> 255 (混合大小写)"
    
    # 带0x前缀测试
    assert_equals "255" "$(bashmath_hex_to_dec "0xFF")" "0xFF -> 255"
    assert_equals "256" "$(bashmath_hex_to_dec "0x100")" "0x100 -> 256"
    
    # 大数测试
    assert_equals "65535" "$(bashmath_hex_to_dec "FFFF")" "FFFF -> 65535"
    assert_equals "1048576" "$(bashmath_hex_to_dec "100000")" "100000 -> 1048576"
    
    # 错误处理测试
    assert_error "$(bashmath_hex_to_dec "GG")" "无效十六进制 GG"
    assert_error "$(bashmath_hex_to_dec "XYZ")" "无效十六进制 XYZ"
    assert_error "$(bashmath_hex_to_dec "")" "空字符串"
    assert_error "$(bashmath_hex_to_dec "12G")" "部分无效 12G"
}

# 测试十进制转十六进制
test_dec_to_hex() {
    echo -e "\n${BLUE}=== 测试十进制转十六进制 ===${NC}"
    
    # 基本测试
    assert_equals "FF" "$(bashmath_dec_to_hex "255")" "255 -> FF"
    assert_equals "100" "$(bashmath_dec_to_hex "256")" "256 -> 100"
    assert_equals "A" "$(bashmath_dec_to_hex "10")" "10 -> A"
    assert_equals "0" "$(bashmath_dec_to_hex "0")" "0 -> 0"
    
    # 大数测试
    assert_equals "FFFF" "$(bashmath_dec_to_hex "65535")" "65535 -> FFFF"
    assert_equals "100000" "$(bashmath_dec_to_hex "1048576")" "1048576 -> 100000"
    
    # 边界测试
    assert_equals "1" "$(bashmath_dec_to_hex "1")" "1 -> 1"
    assert_equals "F" "$(bashmath_dec_to_hex "15")" "15 -> F"
    
    # 错误处理测试
    assert_error "$(bashmath_dec_to_hex "-1")" "负数 -1"
    assert_error "$(bashmath_dec_to_hex "abc")" "非数字 abc"
    assert_error "$(bashmath_dec_to_hex "")" "空字符串"
    assert_error "$(bashmath_dec_to_hex "12.5")" "小数 12.5"
}

# 测试对数计算
test_log2() {
    echo -e "\n${BLUE}=== 测试对数计算 ===${NC}"
    
    # 基本测试
    assert_equals "8" "$(bashmath_log2 "256")" "log2(256) = 8"
    assert_equals "7" "$(bashmath_log2 "128")" "log2(128) = 7"
    assert_equals "0" "$(bashmath_log2 "1")" "log2(1) = 0"
    assert_equals "1" "$(bashmath_log2 "2")" "log2(2) = 1"
    assert_equals "2" "$(bashmath_log2 "4")" "log2(4) = 2"
    assert_equals "10" "$(bashmath_log2 "1024")" "log2(1024) = 10"
    
    # 大数测试
    assert_equals "20" "$(bashmath_log2 "1048576")" "log2(1048576) = 20"
    
    # 错误处理测试
    assert_error "$(bashmath_log2 "0")" "log2(0) 应该错误"
    assert_error "$(bashmath_log2 "-1")" "log2(-1) 应该错误"
    assert_error "$(bashmath_log2 "abc")" "log2(abc) 应该错误"
}

# 测试浮点除法
test_divide_float() {
    echo -e "\n${BLUE}=== 测试浮点除法 ===${NC}"
    
    # 基本测试
    assert_equals "3.333333" "$(bashmath_divide_float "10" "3")" "10/3 = 3.333333"
    assert_equals "3.142857" "$(bashmath_divide_float "22" "7")" "22/7 = 3.142857"
    assert_equals "2.5" "$(bashmath_divide_float "5" "2")" "5/2 = 2.5"
    assert_equals "4" "$(bashmath_divide_float "8" "2")" "8/2 = 4"
    
    # 不同精度测试
    assert_equals "3.33" "$(bashmath_divide_float "10" "3" "2")" "10/3 (精度2) = 3.33"
    assert_equals "3.33333333" "$(bashmath_divide_float "10" "3" "8")" "10/3 (精度8) = 3.33333333"
    
    # 大数测试
    assert_equals "333333.333333" "$(bashmath_divide_float "1000000" "3")" "1000000/3 = 333333.333333"
    
    # 错误处理测试
    assert_error "$(bashmath_divide_float "10" "0")" "除数为0"
    assert_error "$(bashmath_divide_float "abc" "3")" "无效被除数"
    assert_error "$(bashmath_divide_float "10" "xyz")" "无效除数"
}

# 测试二进制转十进制
test_binary_to_dec() {
    echo -e "\n${BLUE}=== 测试二进制转十进制 ===${NC}"
    
    # 基本测试
    assert_equals "10" "$(bashmath_binary_to_dec "1010")" "1010 -> 10"
    assert_equals "255" "$(bashmath_binary_to_dec "11111111")" "11111111 -> 255"
    assert_equals "0" "$(bashmath_binary_to_dec "0")" "0 -> 0"
    assert_equals "1" "$(bashmath_binary_to_dec "1")" "1 -> 1"
    
    # 边界测试
    assert_equals "15" "$(bashmath_binary_to_dec "1111")" "1111 -> 15"
    assert_equals "16" "$(bashmath_binary_to_dec "10000")" "10000 -> 16"
    
    # 大数测试
    assert_equals "1023" "$(bashmath_binary_to_dec "1111111111")" "1111111111 -> 1023"
    
    # 错误处理测试
    assert_error "$(bashmath_binary_to_dec "102")" "无效二进制 102"
    assert_error "$(bashmath_binary_to_dec "abc")" "无效二进制 abc"
    assert_error "$(bashmath_binary_to_dec "")" "空字符串"
}

# 测试十进制转二进制
test_dec_to_binary() {
    echo -e "\n${BLUE}=== 测试十进制转二进制 ===${NC}"
    
    # 基本测试
    assert_equals "1010" "$(bashmath_dec_to_binary "10")" "10 -> 1010"
    assert_equals "11111111" "$(bashmath_dec_to_binary "255")" "255 -> 11111111"
    assert_equals "0" "$(bashmath_dec_to_binary "0")" "0 -> 0"
    assert_equals "1" "$(bashmath_dec_to_binary "1")" "1 -> 1"
    
    # 边界测试
    assert_equals "10" "$(bashmath_dec_to_binary "2")" "2 -> 10"
    assert_equals "11" "$(bashmath_dec_to_binary "3")" "3 -> 11"
    assert_equals "100" "$(bashmath_dec_to_binary "4")" "4 -> 100"
    
    # 大数测试
    assert_equals "1111111111" "$(bashmath_dec_to_binary "1023")" "1023 -> 1111111111"
    
    # 错误处理测试
    assert_error "$(bashmath_dec_to_binary "-1")" "负数 -1"
    assert_error "$(bashmath_dec_to_binary "abc")" "非数字 abc"
    assert_error "$(bashmath_dec_to_binary "")" "空字符串"
    assert_error "$(bashmath_dec_to_binary "12.5")" "小数 12.5"
}

# 综合测试
test_comprehensive() {
    echo -e "\n${BLUE}=== 综合测试 ===${NC}"
    
    # 组合测试：十六进制 -> 十进制 -> 二进制 -> 十进制 -> 十六进制
    local hex="FF"
    local dec1=$(bashmath_hex_to_dec "$hex")
    local bin=$(bashmath_dec_to_binary "$dec1")
    local dec2=$(bashmath_binary_to_dec "$bin")
    local hex2=$(bashmath_dec_to_hex "$dec2")
    
    assert_equals "$hex" "$hex2" "完整转换循环: FF->255->11111111->255->FF"
    
    # 大数运算测试
    local big_hex="10000"
    local big_dec=$(bashmath_hex_to_dec "$big_hex")
    local big_bin=$(bashmath_dec_to_binary "$big_dec")
    local big_log=$(bashmath_log2 "$big_dec")
    
    assert_equals "65536" "$big_dec" "大数十六进制转换: 10000 -> 65536"
    assert_equals "16" "$big_log" "大数对数: log2(65536) = 16"
    
    # 浮点精度测试
    local div_result=$(bashmath_divide_float "1" "3" "10")
    assert_equals "0.3333333333" "$div_result" "高精度除法: 1/3 (10位精度)"
}

# 性能测试
test_performance() {
    echo -e "\n${BLUE}=== 性能测试 ===${NC}"
    
    local start_time=$(date +%s.%N)
    local iterations=1000
    
    for ((i=0; i<iterations; i++)); do
        bashmath_hex_to_dec "FFFF" >/dev/null
        bashmath_dec_to_hex "65535" >/dev/null
        bashmath_log2 "1024" >/dev/null
        bashmath_divide_float "100" "7" >/dev/null
        bashmath_binary_to_dec "11111111" >/dev/null
        bashmath_dec_to_binary "255" >/dev/null
    done
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "1")
    local rate=$(echo "scale=2; $iterations * 6 / $duration" | bc -l 2>/dev/null || echo "unknown")
    
    echo -e "${YELLOW}性能统计:${NC}"
    echo -e "  运行 ${iterations} 次循环"
    echo -e "  总时间: ${duration} 秒"
    echo -e "  每秒操作: ${rate} 次"
}

# 主测试函数
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}纯Bash数学函数库完整测试${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    # 运行所有测试
    test_hex_to_dec
    test_dec_to_hex
    test_log2
    test_divide_float
    test_binary_to_dec
    test_dec_to_binary
    test_comprehensive
    
    # 性能测试（可选）
    if [[ "${1:-}" == "--performance" ]]; then
        test_performance
    fi
    
    # 测试总结
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}测试总结${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "总测试数: $TESTS_TOTAL"
    echo -e "${GREEN}通过: $TESTS_PASSED${NC}"
    echo -e "${RED}失败: $TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}所有测试通过！✓${NC}"
        exit 0
    else
        echo -e "\n${RED}部分测试失败！✗${NC}"
        exit 1
    fi
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi