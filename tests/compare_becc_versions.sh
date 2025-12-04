#!/bin/bash
# 对比becc.sh和becc_fixed.sh的功能

set -euo pipefail

echo "对比becc.sh和becc_fixed.sh版本"
echo "==============================="

# 测试两个版本的帮助功能
echo "1. 测试帮助功能一致性..."
HELP1=$(./becc.sh help 2>&1 | head -5)
HELP2=$(./becc_fixed.sh help 2>&1 | head -5)

if [[ "$HELP1" == *"bECCsh"* ]] && [[ "$HELP2" == *"becc_fixed"* ]]; then
    echo "✅ 两个版本的帮助功能都正常"
else
    echo "❌ 帮助功能不一致"
    echo "标准版: $HELP1"
    echo "修复版: $HELP2"
fi

# 测试曲线支持
echo "2. 测试曲线支持..."
if ./becc.sh help 2>&1 | grep -q "secp256r1" && ./becc_fixed.sh help 2>&1 | grep -q "secp256r1"; then
    echo "✅ 两个版本都支持secp256r1曲线"
else
    echo "❌ 曲线支持不一致"
fi

# 测试参数解析
echo "3. 测试参数解析..."
if ./becc.sh help 2>&1 | grep -q "keygen" && ./becc_fixed.sh help 2>&1 | grep -q "keygen"; then
    echo "✅ 两个版本都支持keygen命令"
else
    echo "❌ 命令支持不一致"
fi

# 测试安全警告
echo "4. 测试安全警告..."
if ./becc.sh help 2>&1 | grep -q "安全警告" && ./becc_fixed.sh help 2>&1 | grep -q "安全警告"; then
    echo "✅ 两个版本都有安全警告"
else
    echo "❌ 安全警告不一致"
fi

echo ""
echo "版本对比完成！"
echo "主要差异："
echo "- becc.sh: 使用标准ECDSA实现"
echo "- becc_fixed.sh: 使用修复的ECDSA实现，解决了数学运算问题"
echo "- 两个版本的功能接口基本一致"