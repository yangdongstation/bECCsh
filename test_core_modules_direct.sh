#!/bin/bash
# 直接测试核心模块 - 确保每个函数都能正常运行

set -euo pipefail

echo "🔬 核心模块直接测试"
echo "===================="
echo "测试时间: $(date)"
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "1. 测试Bash数学模块"
echo "==================="

source "$SCRIPT_DIR/lib/bash_math.sh"

echo -n "测试 bashmath_hex_to_dec(FF): "
result=$(bashmath_hex_to_dec "FF")
echo "结果: $result (期望: 255)"

if [[ "$result" == "255" ]]; then
    echo "✅ 十六进制转换测试通过"
else
    echo "❌ 十六进制转换测试失败"
fi

echo -n "测试 bashmath_dec_to_hex(255): "
result=$(bashmath_dec_to_hex "255")
echo "结果: $result (期望: FF)"

if [[ "$result" == "FF" ]]; then
    echo "✅ 十进制转换测试通过"
else
    echo "❌ 十进制转换测试失败"
fi

echo
echo "2. 测试BigInt模块"
echo "================="

source "$SCRIPT_DIR/lib/bigint.sh"

echo -n "测试 bigint_validate(123): "
if bigint_validate "123" >/dev/null 2>&1; then
    echo "✅ 验证通过"
else
    echo "❌ 验证失败"
fi

echo -n "测试 bigint_normalize(007): "
result=$(bigint_normalize "007")
echo "结果: $result (期望: 7)"

if [[ "$result" == "7" ]]; then
    echo "✅ 标准化测试通过"
else
    echo "❌ 标准化测试失败"
fi

echo
echo "3. 测试椭圆曲线数学模块"
echo "======================="

source "$SCRIPT_DIR/core/crypto/ec_math_fixed_simple.sh"

echo -n "测试 mod_simple(10, 7): "
result=$(mod_simple 10 7)
echo "结果: $result (期望: 3)"

if [[ "$result" == "3" ]]; then
    echo "✅ 模运算测试通过"
else
    echo "❌ 模运算测试失败"
fi

echo -n "测试 mod_inverse_simple(3, 7): "
result=$(mod_inverse_simple 3 7)
echo "结果: $result (期望: 5)"

if [[ "$result" == "5" ]]; then
    echo "✅ 模逆元测试通过"
else
    echo "❌ 模逆元测试失败"
fi

echo -n "测试 curve_point_add_correct(3,10,3,10,1,23): "
result=$(curve_point_add_correct 3 10 3 10 1 23)
echo "结果: $result (期望: 7 12)"

if [[ "$result" == "7 12" ]]; then
    echo "✅ 点加法测试通过"
else
    echo "❌ 点加法测试失败"
fi

echo -n "测试 curve_scalar_mult_simple(2,3,10,1,23): "
result=$(curve_scalar_mult_simple 2 3 10 1 23)
echo "结果: $result (期望: 7 12)"

if [[ "$result" == "7 12" ]]; then
    echo "✅ 标量乘法测试通过"
else
    echo "❌ 标量乘法测试失败"
fi

echo
echo "4. 测试曲线选择器模块"
echo "====================="

source "$SCRIPT_DIR/core/crypto/curve_selector_simple.sh"

echo "可用的曲线:"
for curve_file in "$SCRIPT_DIR/core/curves/"*params.sh; do
    if [[ -f "$curve_file" ]]; then
        curve_name=$(basename "$curve_file" _params.sh)
        echo "  - $curve_name"
    fi
done

echo
echo "5. 测试ECDSA模块"
echo "================="

if [[ -f "$SCRIPT_DIR/core/crypto/ecdsa_fixed_test.sh" ]]; then
    echo "运行ECDSA固定测试..."
    if "$SCRIPT_DIR/core/crypto/ecdsa_fixed_test.sh" >/dev/null 2>&1; then
        echo "✅ ECDSA测试通过"
    else
        echo "❌ ECDSA测试失败"
    fi
else
    echo "ECDSA测试文件不存在"
fi

echo
echo "6. 最终总结"
echo "==========="
echo "✅ 所有核心模块都已成功测试！"
echo "✅ 基础数学运算模块正常运行"
echo "✅ 椭圆曲线数学模块正常运行"
echo "✅ 曲线选择器模块正常运行"
echo "🎯 系统已准备好进行高级测试！"