#!/bin/bash
# 纯Bash数学函数库简化测试脚本

# 确保使用bash运行
if [ -z "${BASH_VERSION:-}" ]; then
    echo "错误: 请使用bash运行此脚本"
    exit 1
fi

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 导入数学函数库
source "$(dirname "$0")/lib/bash_math.sh"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}纯Bash数学函数库测试${NC}"
echo -e "${BLUE}========================================${NC}"

# 测试计数器
total_tests=0
passed_tests=0
failed_tests=0

# 测试函数
test_function() {
    local description="$1"
    local result="$2"
    local expected="$3"
    
    total_tests=$((total_tests + 1))
    
    if [[ "$result" == "$expected" ]]; then
        echo -e "${GREEN}✓${NC} $description"
        passed_tests=$((passed_tests + 1))
    else
        echo -e "${RED}✗${NC} $description"
        echo "  期望: $expected"
        echo "  实际: $result"
        failed_tests=$((failed_tests + 1))
    fi
}

echo -e "\n${BLUE}=== 测试十六进制转十进制 ===${NC}"
test_function "FF -> 255" "$(bashmath_hex_to_dec "FF")" "255"
test_function "100 -> 256" "$(bashmath_hex_to_dec "100")" "256"
test_function "A -> 10" "$(bashmath_hex_to_dec "A")" "10"
test_function "ff -> 255 (小写)" "$(bashmath_hex_to_dec "ff")" "255"
test_function "0xFF -> 255" "$(bashmath_hex_to_dec "0xFF")" "255"

echo -e "\n${BLUE}=== 测试十进制转十六进制 ===${NC}"
test_function "255 -> FF" "$(bashmath_dec_to_hex "255")" "FF"
test_function "256 -> 100" "$(bashmath_dec_to_hex "256")" "100"
test_function "10 -> A" "$(bashmath_dec_to_hex "10")" "A"

echo -e "\n${BLUE}=== 测试对数计算 ===${NC}"
test_function "log2(256) = 8" "$(bashmath_log2 "256")" "8"
test_function "log2(128) = 7" "$(bashmath_log2 "128")" "7"
test_function "log2(1024) = 10" "$(bashmath_log2 "1024")" "10"

echo -e "\n${BLUE}=== 测试浮点除法 ===${NC}"
test_function "10/3 = 3.333333" "$(bashmath_divide_float "10" "3")" "3.333333"
test_function "22/7 = 3.142857" "$(bashmath_divide_float "22" "7")" "3.142857"
test_function "5/2 = 2.5" "$(bashmath_divide_float "5" "2")" "2.5"

echo -e "\n${BLUE}=== 测试二进制转换 ===${NC}"
test_function "1010 -> 10" "$(bashmath_binary_to_dec "1010")" "10"
test_function "11111111 -> 255" "$(bashmath_binary_to_dec "11111111")" "255"
test_function "10 -> 1010" "$(bashmath_dec_to_binary "10")" "1010"
test_function "255 -> 11111111" "$(bashmath_dec_to_binary "255")" "11111111"

echo -e "\n${BLUE}=== 错误处理测试 ===${NC}"
# 测试错误情况 - 这些应该返回0
test_function "无效十六进制 GG -> 0" "$(bashmath_hex_to_dec "GG")" "0"
test_function "除数为0 -> 0" "$(bashmath_divide_float "10" "0")" "0"
test_function "无效二进制 102 -> 0" "$(bashmath_binary_to_dec "102")" "0"

echo -e "\n${BLUE}=== 大数测试 ===${NC}"
test_function "FFFF -> 65535" "$(bashmath_hex_to_dec "FFFF")" "65535"
test_function "65535 -> FFFF" "$(bashmath_dec_to_hex "65535")" "FFFF"
test_function "1111111111 -> 1023" "$(bashmath_binary_to_dec "1111111111")" "1023"
test_function "1023 -> 1111111111" "$(bashmath_dec_to_binary "1023")" "1111111111"

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}测试总结${NC}"
echo -e "${BLUE}========================================${NC}"
echo "总测试数: $total_tests"
echo -e "${GREEN}通过: $passed_tests${NC}"
echo -e "${RED}失败: $failed_tests${NC}"

if [[ $failed_tests -eq 0 ]]; then
    echo -e "\n${GREEN}所有测试通过！✓${NC}"
    exit 0
else
    echo -e "\n${RED}部分测试失败！✗${NC}"
    exit 1
fi