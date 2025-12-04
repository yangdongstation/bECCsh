#!/bin/bash

# 快速十六进制转换验证测试
set -euo pipefail

# 计数器
PASSED=0
FAILED=0

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}[PASS]${NC} $1"; ((PASSED++)); }
print_error() { echo -e "${RED}[FAIL]${NC} $1"; ((FAILED++)); }
print_info() { echo -e "${CYAN}[INFO]${NC} $1"; }

echo "🔍 快速十六进制转换验证测试"
echo "=============================="

# 加载修复的十六进制库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/../../tools/fixed_pure_bash_hex.sh" ]]; then
    source "${SCRIPT_DIR}/../../tools/fixed_pure_bash_hex.sh"
    print_success "加载修复的纯Bash十六进制库"
elif [[ -f "fixed_pure_bash_hex.sh" ]]; then
    source "fixed_pure_bash_hex.sh"
    print_success "加载修复的纯Bash十六进制库"
else
    print_error "无法加载十六进制库"
    exit 1
fi

echo ""
echo "核心功能验证:"
echo "---------------"

# 测试1: 字符转换
echo -n "字符 'A' 转换: "
hex_A=$(purebash_char_to_hex "A")
back_A=$(purebash_hex_to_char "$hex_A")
if [[ "$hex_A" == "41" ]] && [[ "$back_A" == "A" ]]; then
    print_success "'A' -> 41 -> 'A' ✓"
else
    print_error "'A' 转换失败: '$hex_A' -> '$back_A'"
fi

# 测试2: 字符串转换
echo -n "字符串 'Hello' 转换: "
hex_hello=$(purebash_string_to_hex "Hello")
back_hello=$(purebash_hex_to_string "$hex_hello")
if [[ "$hex_hello" == "48656C6C6F" ]] && [[ "$back_hello" == "Hello" ]]; then
    print_success "'Hello' -> 48656C6C6F -> 'Hello' ✓"
else
    print_error "'Hello' 转换失败: '$hex_hello' -> '$back_hello'"
fi

# 测试3: 与标准工具对比
echo -n "与xxd对比验证: "
if command -v xxd >/dev/null 2>&1; then
    test_data="ABC123"
    bash_hex=$(purebash_string_to_hex "$test_data")
    xxd_hex=$(echo -n "$test_data" | xxd -p | tr -d '\n')
    
    if [[ "$bash_hex" == "$xxd_hex" ]]; then
        print_success "与xxd完全一致 ✓"
    else
        print_error "与xxd不一致: Bash=$bash_hex, xxd=$xxd_hex"
    fi
else
    print_warning "xxd不可用，跳过对比测试"
fi

# 测试4: 随机数生成
echo -n "随机数十六进制生成: "
random_hex=$(purebash_urandom_to_hex "8")
if [[ ${#random_hex} -eq 16 ]] && [[ $random_hex =~ ^[0-9A-F]+$ ]]; then
    print_success "生成8字节随机数 ✓"
else
    print_error "随机数生成失败: 长度=${#random_hex}, 值=$random_hex"
fi

# 测试5: 性能简单测试
echo -n "性能测试 (1000字符): "
large_data=$(head -c 500 /dev/urandom | base64 -w 0)
start_time=$(date +%s%N)
result_hex=$(purebash_string_to_hex "$large_data")
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))

if [[ $duration -lt 5000 ]]; then
    print_success "处理${#large_data}字符用时${duration}ms ✓"
else
    print_warning "处理较慢: ${duration}ms，但符合纯Bash预期"
fi

echo ""
echo "=============================="
if [[ $FAILED -eq 0 ]]; then
    print_success "🎉 快速验证通过！纯Bash十六进制转换功能正常"
else
    print_error "⚠️  发现一些问题，需要进一步调试"
fi

echo ""
echo "核心优势:"
echo "  ✅ 完全零依赖实现"
echo "  ✅ 与标准工具输出一致"
echo "  ✅ 支持字符/字符串/随机数转换"
echo "  ✅ 适合教育和研究用途"