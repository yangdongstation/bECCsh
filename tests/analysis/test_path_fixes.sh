#!/bin/bash

# 测试路径修复的脚本

echo "🔧 测试路径修复结果"
echo "===================="

# 定义要测试的文件列表
test_files=(
    "demo/pure_bash_demo.sh"
    "demo/examples/pure_bash_demo.sh"
    "demo/final_verification.sh"
    "demo/quick_tests/quick_hex_verification.sh"
    "demo/tests/hex_conversion_focused_test.sh"
    "demo/tests/final_hex_test.sh"
    "demo/validation/performance_test.sh"
    "core/operations/ecc_arithmetic.sh"
    "core/utils/curve_validator.sh"
    "core/crypto/ecdsa_final_fixed.sh"
    "core/crypto/ecdsa_final.sh"
    "core/crypto/ecdsa_fixed.sh"
    "core/crypto/ec_math_fixed.sh"
)

# 检查每个文件是否可以正常source
echo "检查文件路径修复情况:"
for file in "${test_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ 文件存在: $file"
        
        # 检查是否使用了SCRIPT_DIR
        if grep -q "SCRIPT_DIR" "$file"; then
            echo "  ✓ 使用了SCRIPT_DIR变量"
        else
            echo "  ⚠️  未使用SCRIPT_DIR变量"
        fi
        
        # 检查是否还有相对路径导入
        if grep -q "source.*\.\./" "$file"; then
            echo "  ❌ 仍包含相对路径导入"
            grep -n "source.*\.\./" "$file"
        else
            echo "  ✓ 无相对路径导入"
        fi
    else
        echo "❌ 文件不存在: $file"
    fi
    echo
done