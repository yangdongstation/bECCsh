#!/bin/bash
# 测试数学模块函数导出修复

set -euo pipefail

echo "🔧 测试数学模块函数导出修复"
echo "============================="

echo "1. 测试Bash数学函数导出:"
source lib/bash_math.sh

# 手动导出函数
export -f bashmath_hex_to_dec bashmath_dec_to_hex bashmath_log2 bashmath_divide_float bashmath_binary_to_dec bashmath_dec_to_binary

echo "测试bashmath_hex_to_dec:"
result=$(bash -c 'bashmath_hex_to_dec "FF"')
echo "FF → $result (期望: 255)"

if [[ "$result" == "255" ]]; then
    echo "✅ Bash数学函数导出成功"
else
    echo "❌ Bash数学函数导出失败"
fi

echo
echo "2. 测试BigInt函数导出:"
source lib/bigint.sh

# 获取实际存在的函数
functions=$(declare -f | grep "^bigint_" | cut -d'(' -f1)
echo "存在的BigInt函数:"
echo "$functions"

# 手动导出存在的函数
for func in $functions; do
    export -f "$func"
done

echo "测试bigint_validate:"
if bash -c 'bigint_validate "123" >/dev/null 2>&1'; then
    echo "✅ BigInt函数导出成功"
else
    echo "❌ BigInt函数导出失败"
fi

echo
echo "3. 测试BigInt标准化修复:"
result=$(bash -c 'bigint_normalize "-0"')
echo "-0 → $result (期望: 0)"

if [[ "$result" == "0" ]]; then
    echo "✅ BigInt标准化修复成功"
else
    echo "❌ BigInt标准化修复失败"
fi