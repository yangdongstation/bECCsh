#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 导入所有多曲线相关库
source "$SCRIPT_DIR/core/crypto/curve_selector_simple.sh"

# 导出所有多曲线相关函数
export -f select_curve_simple

echo "✅ 多曲线环境创建成功"
echo "✅ 所有多曲线函数已导出"
