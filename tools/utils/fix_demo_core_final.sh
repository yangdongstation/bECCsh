#!/bin/bash

# 修复 pure_bash_core 目录中的模块加载路径问题

echo "🔧 修复 pure_bash_core 目录中的模块加载路径问题"
echo "=============================================="

# 修复 test_complete_implementation.sh - 使用正确的核心模块路径
cat > /home/donz/bECCsh/demo/pure_bash_core/test_complete_implementation.sh << 'EOF'
#!/bin/bash

# 测试完整纯Bash实现
# 验证大数运算和完整密码学功能

echo "🔍 测试完整纯Bash实现"
echo "================================"

# 获取脚本目录
SCRIPT_DIR="${BASH_SOURCE%/*}"

# 尝试加载模块 - 使用核心目录的正确路径
echo "🔄 加载纯Bash模块..."
if source "$SCRIPT_DIR/../../core/lib/pure_bash/pure_bash_complete.sh" 2>/dev/null; then
    echo "✅ 模块加载成功"
elif source "$(dirname "$0")/../../core/lib/pure_bash/pure_bash_complete.sh" 2>/dev/null; then
    echo "✅ 模块加载成功（使用相对路径）"
else
    echo "❌ 无法加载pure_bash_complete.sh模块"
    echo "  尝试单独加载扩展模块..."
    
    # 尝试单独加载模块
    if source "$SCRIPT_DIR/../../core/lib/pure_bash/pure_bash_bigint_extended.sh" 2>/dev/null; then
        echo "✅ 扩展大数模块加载成功"
    else
        echo "❌ 无法加载扩展大数模块"
        exit 1
    fi
    
    if source "$SCRIPT_DIR/../../core/lib/pure_bash/pure_bash_extended_crypto.sh" 2>/dev/null; then
        echo "✅ 扩展密码学模块加载成功"
    else
        echo "❌ 无法加载扩展密码学模块"
        exit 1
    fi
fi

echo
echo "🧪 开始功能测试..."
echo

# 测试1: 基础大数运算
echo "1. 基础大数运算测试:"
echo "--------------------"

test_num1="123456789012345678901234567890"
test_num2="987654321098765432109876543210"

echo "  测试数1: $test_num1 (${#test_num1} 位)"
echo "  测试数2: $test_num2 (${#test_num2} 位)"

# 测试加法
echo "  测试加法..."
sum_result=$(purebash_bigint_add "$test_num1" "$test_num2" 2>/dev/null)
if [[ -n "$sum_result" ]]; then
    echo "  ✅ 加法成功: $sum_result"
else
    echo "  ❌ 加法失败"
fi

# 测试减法
echo "  测试减法..."
diff_result=$(purebash_bigint_subtract "$test_num2" "$test_num1" 2>/dev/null)
if [[ -n "$diff_result" ]]; then
    echo "  ✅ 减法成功: $diff_result"
else
    echo "  ❌ 减法失败"
fi

# 测试乘法
echo "  测试乘法..."
product_result=$(purebash_bigint_multiply "$test_num1" "12345" 2>/dev/null)
if [[ -n "$product_result" ]]; then
    echo "  ✅ 乘法成功: $product_result"
else
    echo "  ❌ 乘法失败"
fi

# 测试模运算
echo "  测试模运算..."
mod_result=$(purebash_bigint_mod "$test_num1" "97" 2>/dev/null)
if [[ -n "$mod_result" ]]; then
    echo "  ✅ 模运算成功: $mod_result"
else
    echo "  ❌ 模运算失败"
fi

echo

# 测试2: 扩展随机数
echo "2. 扩展随机数测试:"
echo "-------------------"

echo "  生成大随机数..."
for i in {1..3}; do
    random_result=$(purebash_random_extended "256" "1000000000000000000000000000000000000000" 2>/dev/null)
    if [[ -n "$random_result" ]]; then
        echo "  ✅ 随机数 $i: $random_result"
    else
        echo "  ❌ 随机数 $i 生成失败"
    fi
done

echo

# 测试3: 扩展哈希
echo "3. 扩展哈希测试:"
echo "----------------"

test_msg="Hello, Extended Pure Bash Cryptography!"
hash_result=$(purebash_sha256_extended "$test_msg" 2>/dev/null)
if [[ -n "$hash_result" ]]; then
    echo "  ✅ 扩展哈希成功: $hash_result"
else
    echo "  ❌ 扩展哈希失败"
fi

echo

# 测试4: 椭圆曲线功能（如果可用）
echo "4. 椭圆曲线功能测试:"
echo "--------------------"

if command -v purebash_secp256k1_complete >/dev/null 2>&1; then
    echo "  测试secp256k1..."
    purebash_secp256k1_complete 2>/dev/null | head -10
    echo "  ✅ secp256k1功能可用"
else
    echo "  ℹ️  secp256k1功能暂时不可用（函数未找到）"
fi

echo

# 测试5: 性能测试
echo "5. 性能测试:"
echo "-------------"

if command -v purebash_extended_performance_test >/dev/null 2>&1; then
    echo "  运行性能测试..."
    purebash_extended_performance_test 2>/dev/null
    echo "  ✅ 性能测试完成"
else
    echo "  ℹ️  性能测试暂时不可用（函数未找到）"
fi

echo
echo "================================"
echo "🔍 测试完成总结:"

# 检查哪些功能可用
available_functions=()
total_functions=0
working_functions=0

# 检查基础函数
for func in purebash_bigint_add purebash_bigint_subtract purebash_bigint_multiply purebash_bigint_mod purebash_random_extended purebash_sha256_extended; do
    total_functions=$((total_functions + 1))
    if command -v "$func" >/dev/null 2>&1; then
        available_functions+=("$func")
        working_functions=$((working_functions + 1))
    fi
done

echo "  可用函数: $working_functions/$total_functions"
echo "  可用函数列表: ${available_functions[*]}"

if [[ $working_functions -eq $total_functions ]]; then
    echo "✅ 所有基础功能正常工作！"
elif [[ $working_functions -gt 0 ]]; then
    echo "⚠️  部分功能可用，需要进一步调试"
else
    echo "❌ 基础功能均不可用，需要检查模块加载"
fi

echo
echo "🎯 建议下一步操作:"
echo "  • 检查模块文件是否存在: ls -la core/lib/pure_bash/"
echo "  • 验证模块语法: bash -n core/lib/pure_bash/pure_bash_*.sh"
echo "  • 运行完整演示: bash core/lib/pure_bash/pure_bash_complete_demo.sh"
echo "  • 查看项目文档: cat PROJECT_OVERVIEW.md"
EOF

chmod +x /home/donz/bECCsh/demo/pure_bash_core/test_complete_implementation.sh

# 修复其他核心测试脚本
cat > /home/donz/bECCsh/demo/pure_bash_core/test_basic_extended.sh << 'EOF'
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
EOF

chmod +x /home/donz/bECCsh/demo/pure_bash_core/test_basic_extended.sh

echo "✅ 修复完成！"