#!/bin/bash
# 纯Bash数学函数库完整测试脚本
# 包含用户要求的所有测试用例

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
echo -e "${BLUE}纯Bash数学函数库完整验证测试${NC}"
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
        return 0
    else
        echo -e "${RED}✗${NC} $description"
        echo "  期望: $expected"
        echo "  实际: $result"
        failed_tests=$((failed_tests + 1))
        return 1
    fi
}

echo -e "\n${YELLOW}=== 1. 十六进制转十进制测试 ===${NC}"
echo "测试用例: FF->255, 100->256, A->10"
test_function "FF -> 255" "$(bashmath_hex_to_dec "FF")" "255"
test_function "100 -> 256" "$(bashmath_hex_to_dec "100")" "256"
test_function "A -> 10" "$(bashmath_hex_to_dec "A")" "10"

echo -e "\n${YELLOW}=== 2. 十进制转十六进制测试 ===${NC}"
echo "测试用例: 255->FF, 256->100, 10->A"
test_function "255 -> FF" "$(bashmath_dec_to_hex "255")" "FF"
test_function "256 -> 100" "$(bashmath_dec_to_hex "256")" "100"
test_function "10 -> A" "$(bashmath_dec_to_hex "10")" "A"

echo -e "\n${YELLOW}=== 3. 对数计算测试 ===${NC}"
echo "测试用例: log2(256)=8, log2(128)=7"
test_function "log2(256) = 8" "$(bashmath_log2 "256")" "8"
test_function "log2(128) = 7" "$(bashmath_log2 "128")" "7"

echo -e "\n${YELLOW}=== 4. 浮点除法测试 ===${NC}"
echo "测试用例: 10/3=3.333333, 22/7=3.142857"
test_function "10/3 = 3.333333" "$(bashmath_divide_float "10" "3")" "3.333333"
test_function "22/7 = 3.142857" "$(bashmath_divide_float "22" "7")" "3.142857"

echo -e "\n${YELLOW}=== 5. 二进制转换测试 ===${NC}"
echo "测试用例: 1010->10, 11111111->255, 10->1010, 255->11111111"
test_function "1010 -> 10" "$(bashmath_binary_to_dec "1010")" "10"
test_function "11111111 -> 255" "$(bashmath_binary_to_dec "11111111")" "255"
test_function "10 -> 1010" "$(bashmath_dec_to_binary "10")" "1010"
test_function "255 -> 11111111" "$(bashmath_dec_to_binary "255")" "11111111"

echo -e "\n${YELLOW}=== 6. 大数运算测试 ===${NC}"
# 大数十六进制转换
test_function "FFFFFFFF -> 4294967295" "$(bashmath_hex_to_dec "FFFFFFFF")" "4294967295"
test_function "100000000 -> 4294967296" "$(bashmath_hex_to_dec "100000000")" "4294967296"
test_function "4294967295 -> FFFFFFFF" "$(bashmath_dec_to_hex "4294967295")" "FFFFFFFF"

# 大数二进制转换
test_function "11111111111111111111 -> 1048575" "$(bashmath_binary_to_dec "11111111111111111111")" "1048575"
test_function "1048575 -> 11111111111111111111" "$(bashmath_dec_to_binary "1048575")" "11111111111111111111"

# 大数对数
test_function "log2(4294967296) = 32" "$(bashmath_log2 "4294967296")" "32"
test_function "log2(1048576) = 20" "$(bashmath_log2 "1048576")" "20"

# 大数浮点除法
test_function "1000000/7 = 142857.142857" "$(bashmath_divide_float "1000000" "7")" "142857.142857"

echo -e "\n${YELLOW}=== 7. 边界情况测试 ===${NC}"
# 零值测试
test_function "0 -> 0 (十六进制转十进制)" "$(bashmath_hex_to_dec "0")" "0"
test_function "0 -> 0 (十进制转十六进制)" "$(bashmath_dec_to_hex "0")" "0"
test_function "0 -> 0 (二进制转十进制)" "$(bashmath_binary_to_dec "0")" "0"
test_function "0 -> 0 (十进制转二进制)" "$(bashmath_dec_to_binary "0")" "0"
test_function "log2(1) = 0" "$(bashmath_log2 "1")" "0"

# 单位测试
test_function "1 -> 1 (十六进制转十进制)" "$(bashmath_hex_to_dec "1")" "1"
test_function "1 -> 1 (十进制转十六进制)" "$(bashmath_dec_to_hex "1")" "1"
test_function "1 -> 1 (二进制转十进制)" "$(bashmath_binary_to_dec "1")" "1"
test_function "1 -> 1 (十进制转二进制)" "$(bashmath_dec_to_binary "1")" "1"

echo -e "\n${YELLOW}=== 8. 错误处理测试 ===${NC}"
# 无效输入应该返回0
test_function "无效十六进制 GG -> 0" "$(bashmath_hex_to_dec "GG")" "0"
test_function "无效十进制 abc -> 0" "$(bashmath_dec_to_hex "abc")" "0"
test_function "无效二进制 123 -> 0" "$(bashmath_binary_to_dec "123")" "0"
test_function "无效十进制 xyz -> 0" "$(bashmath_dec_to_binary "xyz")" "0"
test_function "除数为0 -> 0" "$(bashmath_divide_float "10" "0")" "0"
test_function "log2(0) -> 0" "$(bashmath_log2 "0")" "0"

echo -e "\n${YELLOW}=== 9. 格式变化测试 ===${NC}"
# 大小写变化
test_function "ff -> 255 (小写)" "$(bashmath_hex_to_dec "ff")" "255"
test_function "Ff -> 255 (混合大小写)" "$(bashmath_hex_to_dec "Ff")" "255"
test_function "0xFF -> 255 (带0x前缀)" "$(bashmath_hex_to_dec "0xFF")" "255"
test_function "0Xff -> 255 (带0X前缀)" "$(bashmath_hex_to_dec "0Xff")" "255"

# 不同精度浮点除法
test_function "10/3 (精度2) = 3.33" "$(bashmath_divide_float "10" "3" "2")" "3.33"
test_function "10/3 (精度8) = 3.33333333" "$(bashmath_divide_float "10" "3" "8")" "3.33333333"

echo -e "\n${YELLOW}=== 10. 综合循环测试 ===${NC}"
# 测试完整的转换循环
original_hex="ABCDEF"
dec_from_hex=$(bashmath_hex_to_dec "$original_hex")
bin_from_dec=$(bashmath_dec_to_binary "$dec_from_hex")
dec_from_bin=$(bashmath_binary_to_dec "$bin_from_dec")
hex_from_dec=$(bashmath_dec_to_hex "$dec_from_bin")

test_function "完整循环: ABCDEF->->->->ABCDEF" "$hex_from_dec" "$original_hex"

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}测试总结${NC}"
echo -e "${BLUE}========================================${NC}"
echo "总测试数: $total_tests"
echo -e "${GREEN}通过: $passed_tests${NC}"
echo -e "${RED}失败: $failed_tests${NC}"

if [[ $failed_tests -eq 0 ]]; then
    echo -e "\n${GREEN}所有测试通过！纯Bash数学函数库工作正常！✓${NC}"
    echo -e "${GREEN}函数库可以在没有bc的情况下正常工作！${NC}"
    exit 0
else
    echo -e "\n${RED}部分测试失败！✗${NC}"
    exit 1
fi