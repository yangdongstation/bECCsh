#!/bin/bash

# 基础扩展测试 - 验证纯Bash基础功能

echo "🔍 基础扩展测试"
echo "=================="

# 获取脚本目录
SCRIPT_DIR="${BASH_SOURCE%/*}"

# 加载扩展模块
echo "🔄 加载扩展模块..."
if source "$SCRIPT_DIR/../../core/lib/pure_bash/pure_bash_bigint_extended.sh" 2>/dev/null; then
    echo "✅ 扩展大数模块加载成功"
else
    echo "❌ 无法加载扩展大数模块"
    exit 1
fi

echo
echo "🧪 开始基础测试..."
echo

# 测试1: 大数加法
echo "1. 大数加法测试:"
echo "----------------"

test_num1="12345678901234567890"
test_num2="98765432109876543210"

echo "  测试数1: $test_num1"
echo "  测试数2: $test_num2"

result=$(purebash_bigint_add "$test_num1" "$test_num2")
if [[ -n "$result" ]]; then
    echo "  ✅ 加法结果: $result"
else
    echo "  ❌ 加法失败"
fi

echo

# 测试2: 大数乘法
echo "2. 大数乘法测试:"
echo "----------------"

result=$(purebash_bigint_multiply "$test_num1" "12345")
if [[ -n "$result" ]]; then
    echo "  ✅ 乘法结果: $result"
else
    echo "  ❌ 乘法失败"
fi

echo

# 测试3: 模运算
echo "3. 模运算测试:"
echo "--------------"

result=$(purebash_bigint_mod "$test_num1" "97")
if [[ -n "$result" ]]; then
    echo "  ✅ 模运算结果: $result"
else
    echo "  ❌ 模运算失败"
fi

echo
echo "================================"
echo "🔍 基础扩展测试完成！"
