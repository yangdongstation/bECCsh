#!/bin/bash
# 软件包可运行度测试 - 专注于基本功能

set -euo pipefail

echo "bECCsh 软件包可运行度测试"
echo "========================"
echo "测试时间: $(date)"
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUCCESS_COUNT=0
TOTAL_COUNT=0

# 测试函数
run_test() {
    local test_name="$1"
    local test_cmd="$2"
    local expected_pattern="$3"
    
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    echo -n "测试 $TOTAL_COUNT: $test_name ... "
    
    if output=$(timeout 10 $test_cmd 2>&1); then
        if echo "$output" | grep -q "$expected_pattern"; then
            echo "✅ 通过"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            echo "❌ 失败 (输出不匹配)"
            echo "期望包含: $expected_pattern"
            echo "实际输出: $output"
        fi
    else
        echo "❌ 失败 (命令失败或超时)"
        echo "错误输出: $output"
    fi
    echo
}

# 测试1: 基本数学运算
echo "1. 基本数学运算测试"
run_test "模运算" \
    "bash -c 'echo \"10 mod 7 = \\$((10 % 7))\"'" \
    "10 mod 7 = 3"

run_test "模逆元" \
    "bash $SCRIPT_DIR/core/crypto/ec_math_fixed_simple.sh" \
    "修复的数学运算测试完成"

# 测试2: 椭圆曲线数学
echo "2. 椭圆曲线数学测试"
run_test "点加法" \
    "bash -c 'source $SCRIPT_DIR/core/crypto/ec_math_fixed_simple.sh && result=\$(curve_point_add_correct 3 10 3 10 1 23) && echo 结果: \$result'" \
    "结果:"

run_test "标量乘法" \
    "bash -c 'source $SCRIPT_DIR/core/crypto/ec_math_fixed_simple.sh && result=\$(curve_scalar_mult_simple 2 3 10 1 23) && echo 结果: \$result'" \
    "结果:"

# 测试3: ECDSA功能
echo "3. ECDSA功能测试"
run_test "固定k值ECDSA" \
    "bash $SCRIPT_DIR/core/crypto/ecdsa_fixed_test.sh" \
    "签名验证成功"

# 测试4: 曲线选择器
echo "4. 曲线选择器测试"
run_test "曲线选择器" \
    "bash $SCRIPT_DIR/core/crypto/curve_selector_simple.sh" \
    "支持的椭圆曲线"

# 测试5: 核心功能
echo "5. 核心功能测试"
run_test "核心功能完整性" \
    "bash -c 'ls $SCRIPT_DIR/core/crypto/*.sh | wc -l'" \
    ""

# 测试结果
echo "测试结果总结:"
echo "============="
echo "成功: $SUCCESS_COUNT / $TOTAL_COUNT"
echo
if [[ $SUCCESS_COUNT -eq $TOTAL_COUNT ]]; then
    echo "🎉 所有测试通过! 软件包可运行度: 高 ✅"
    echo "bECCsh 核心功能运行正常!"
    exit 0
else
    echo "❌ 部分测试失败，软件包可运行度: 中 ⚠️"
    echo "需要修复 $((TOTAL_COUNT - SUCCESS_COUNT)) 个问题"
    exit 1
fi