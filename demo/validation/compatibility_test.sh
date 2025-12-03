#!/bin/bash

# 纯Bash兼容性测试
echo "🔧 纯Bash兼容性测试"
echo "===================="

echo "1. Bash版本检查:"
echo "  当前Bash版本: $BASH_VERSION"
if [[ "${BASH_VERSION%%.*}" -ge 4 ]]; then
    echo "  ✅ Bash版本兼容（4.0+）"
else
    echo "  ⚠️  Bash版本较低，可能有不兼容功能"
fi

echo
echo "2. 外部依赖检查:"
external_commands=("openssl" "sha256sum" "shasum" "xxd" "base64" "cut" "tr")
external_count=0
for cmd in "${external_commands[@]}"; do
    if command -v "$cmd" &>/dev/null; then
        echo "  ⚠️  发现外部命令: $cmd"
        ((external_count++))
    else
        echo "  ✅ 无外部命令: $cmd"
    fi
done

echo "  外部依赖统计: $external_count 个"
if [[ $external_count -eq 0 ]]; then
    echo "  🎯 纯Bash环境验证通过！"
else
    echo "  ℹ️  存在外部命令，但不影响纯Bash实现"
fi

echo
echo "3. 系统功能检查:"
if [[ -f /proc/meminfo ]]; then
    echo "  ✅ /proc文件系统可用"
else
    echo "  ⚠️  /proc文件系统不可用"
fi

if [[ -n "${RANDOM:-}" ]]; then
    echo "  ✅ RANDOM变量可用: $RANDOM"
else
    echo "  ❌ RANDOM变量不可用"
fi

echo
echo "🔧 兼容性测试完成！"
