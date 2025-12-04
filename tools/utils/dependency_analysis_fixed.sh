#!/bin/bash

# 分析依赖关系的脚本
cd /home/donz/bECCsh

echo "=== 主要lib目录依赖关系分析 ==="
echo

for file in lib/*.sh; do
    echo "📄 $(basename "$file"):"
    grep -n "source.*""$(dirname "${BASH_SOURCE[0]}")" "$file" 2>/dev/null | while read line; do
        echo "  🔗 $line"
    done
    echo
done

echo "=== core/lib/pure_bash目录依赖关系分析 ==="
echo

for file in core/lib/pure_bash/*.sh; do
    echo "📄 $(basename "$file"):"
    grep -n "source.*""$(dirname "${BASH_SOURCE[0]}")" "$file" 2>/dev/null | while read line; do
        echo "  🔗 $line"
    done
    echo
done

echo "=== 检查循环依赖 ==="
echo

# 检查是否有A->B 和 B->A的循环依赖
echo "检查主lib目录循环依赖..."
grep -l "source.*bigint" lib/bash_math.sh lib/ec_curve.sh 2>/dev/null || echo "无循环依赖"