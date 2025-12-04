#!/bin/bash

# 验证路径修复的脚本

echo "🔧 验证路径修复结果"
echo "===================="

# 测试导入功能
echo "1. 测试demo/pure_bash_demo.sh导入:"
cd /home/donz/bECCsh/demo
if bash -n pure_bash_demo.sh; then
    echo "✅ 语法检查通过"
else
    echo "❌ 语法检查失败"
fi

echo
echo "2. 测试demo/examples/pure_bash_demo.sh导入:"
cd /home/donz/bECCsh/demo/examples
if bash -n pure_bash_demo.sh; then
    echo "✅ 语法检查通过"
else
    echo "❌ 语法检查失败"
fi

echo
echo "3. 测试core/operations/ecc_arithmetic.sh导入:"
cd /home/donz/bECCsh/core/operations
if bash -n ecc_arithmetic.sh; then
    echo "✅ 语法检查通过"
else
    echo "❌ 语法检查失败"
fi

echo
echo "4. 测试demo/comparison/openssl_comparison_test.sh导入:"
cd /home/donz/bECCsh/demo/comparison
if bash -n openssl_comparison_test.sh; then
    echo "✅ 语法检查通过"
else
    echo "❌ 语法检查失败"
fi

echo
echo "5. 测试实际导入功能:"
cd /home/donz/bECCsh
if bash -c 'source demo/pure_bash_demo.sh && echo "导入成功"' 2>/dev/null; then
    echo "✅ demo/pure_bash_demo.sh可以正常source"
else
    echo "❌ demo/pure_bash_demo.sh导入失败"
fi

echo
echo "验证完成!"