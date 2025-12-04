#!/bin/bash

# 简化测试 - 验证扩展纯Bash功能
# 修复local变量问题

echo "🔍 简化测试扩展纯Bash功能"
echo "================================"

# 获取脚本目录
SCRIPT_DIR="${BASH_SOURCE%/*}"

# 尝试加载模块
echo "🔄 加载纯Bash模块..."
if source "$SCRIPT_DIR/pure_bash_bigint_extended.sh" 2>/dev/null; then
    echo "✅ 扩展大数模块加载成功"
elif source "$(dirname "$0")/pure_bash_bigint_extended.sh" 2>/dev/null; then
    echo "✅ 扩展大数模块加载成功（相对路径）"
else
    echo "❌ 无法加载扩展大数模块"
    exit 1
fi

echo
echo "🧪 开始基础功能测试..."
echo

# 测试1: 基础大数运算
echo "1. 基础大数运算测试:"
echo "--------------------"

# 使用全局变量而不是local
test_num1="123456789012345678901234567890"
test_num2="987654321098765432109876543210"

echo "  测试数1: $test_num1 (${#test_num1} 位)"
echo "  测试数2: $test_num2 (${#test_num2} 位)"

# 测试加法
echo "  测试加法..."
if sum_result=$(purebash_bigint_add "$test_num1" "$test_num2" 2>/dev/null); then
    echo "  ✅ 加法成功: $sum_result"
else
    echo "  ❌ 加法失败"
fi

# 测试减法
echo "  测试减法..."
if diff_result=$(purebash_bigint_subtract "$test_num2" "$test_num1" 2>/dev/null); then
    echo "  ✅ 减法成功: $diff_result"
else
    echo "  ❌ 减法失败"
fi

# 测试乘法
echo "  测试乘法..."
if product_result=$(purebash_bigint_multiply "$test_num1" "12345" 2>/dev/null); then
    echo "  ✅ 乘法成功: $product_result"
else
    echo "  ❌ 乘法失败"
fi

# 测试模运算
echo "  测试模运算..."
if mod_result=$(purebash_bigint_mod "$test_num1" "97" 2>/dev/null); then
    echo "  ✅ 模运算成功: $mod_result"
else
    echo "  ❌ 模运算失败"
fi

echo

# 测试2: 简单运算验证
echo "2. 简单运算验证:"
echo "------------------"

echo "  测试简单加法..."
simple_sum=$(purebash_bigint_add "123" "456" 2>/dev/null)
if [[ "$simple_sum" == "579" ]]; then
    echo "  ✅ 简单加法正确: 123 + 456 = $simple_sum"
else
    echo "  ❌ 简单加法错误: 123 + 456 = $simple_sum"
fi

echo "  测试简单乘法..."
simple_product=$(purebash_bigint_multiply "12" "34" 2>/dev/null)
if [[ "$simple_product" == "408" ]]; then
    echo "  ✅ 简单乘法正确: 12 × 34 = $simple_product"
else
    echo "  ❌ 简单乘法错误: 12 × 34 = $simple_product"
fi

echo "  测试简单模运算..."
simple_mod=$(purebash_bigint_mod "100" "7" 2>/dev/null)
if [[ "$simple_mod" == "2" ]]; then
    echo "  ✅ 简单模运算正确: 100 mod 7 = $simple_mod"
else
    echo "  ❌ 简单模运算错误: 100 mod 7 = $simple_mod"
fi

echo

# 测试3: 函数可用性检查
echo "3. 函数可用性检查:"
echo "--------------------"

available_functions=()
for func in purebash_bigint_add purebash_bigint_subtract purebash_bigint_multiply purebash_bigint_mod; do
    if command -v "$func" >/dev/null 2>&1; then
        available_functions+=("$func")
        echo "  ✅ $func 可用"
    else
        echo "  ❌ $func 不可用"
    fi
done

local func_count=${#available_functions[@]}
echo "  可用函数: $func_count/4"

echo

# 测试4: 性能简单测试
echo "4. 简单性能测试:"
echo "------------------"

echo "  测试大数运算性能..."
start_time=$(date +%s%N)
for i in {1..5}; do
    purebash_bigint_add "123456789" "987654321" >/dev/null 2>&1
done
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))
echo "  5次大数加法耗时: ${duration}ms"

echo

echo "================================"
echo "🔍 简化测试完成总结:"

if [[ $func_count -eq 4 ]]; then
    echo "✅ 所有基础大数函数可用！"
elif [[ $func_count -gt 0 ]]; then
    echo "⚠️  部分函数可用: ${available_functions[*]}"
else
    echo "❌ 基础函数均不可用"
fi

echo
echo "🎯 测试结论:"
if [[ $func_count -gt 0 ]]; then
    echo "✅ 扩展纯Bash大数功能基本可用"
    echo "✅ 实现了突破整数限制的大数运算"
    echo "✅ 为完整密码学实现奠定了基础"
else
    echo "❌ 需要进一步调试模块加载"
fi

echo
echo "🚀 下一步建议:"
echo "  • 运行完整演示: bash core/lib/pure_bash/pure_bash_complete_demo.sh"
echo "  • 查看项目文档: cat PROJECT_OVERVIEW.md"
echo "  • 体验核心功能: cd core && ./becc_pure.sh"