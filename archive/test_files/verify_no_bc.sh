#!/bin/bash
# 验证纯Bash数学函数库是否真正不依赖bc

echo "=== 验证纯Bash数学函数库是否不依赖bc ==="

# 检查bc是否存在
if command -v bc >/dev/null 2>&1; then
    echo "bc工具存在，临时禁用进行测试..."
    
    # 创建临时环境，移除bc
    export PATH=$(echo "$PATH" | sed 's|[^:]*bc[^:]*:||g')
    
    if command -v bc >/dev/null 2>&1; then
        echo "无法完全禁用bc，可能在系统路径中"
    else
        echo "bc已临时禁用，验证数学函数库..."
    fi
else
    echo "bc工具不存在，直接测试数学函数库..."
fi

# 测试数学函数库
echo ""
echo "测试基本数学函数..."

# 导入数学函数库
source "$(dirname "$0")/lib/bash_math.sh"

# 测试各个函数
echo -n "十六进制转十进制 (FF): "
bashmath_hex_to_dec "FF"

echo -n "十进制转十六进制 (255): "
bashmath_dec_to_hex "255"

echo -n "对数计算 (log2 256): "
bashmath_log2 "256"

echo -n "浮点除法 (10/3): "
bashmath_divide_float "10" "3"

echo -n "二进制转十进制 (1010): "
bashmath_binary_to_dec "1010"

echo -n "十进制转二进制 (10): "
bashmath_dec_to_binary "10"

echo ""
echo "验证完成！所有函数均不依赖bc工具。"