#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 导入所有ECDSA相关库
source "$SCRIPT_DIR/core/crypto/curve_selector_simple.sh"
source "$SCRIPT_DIR/core/crypto/ec_math_fixed_simple.sh"

# 导出所有ECDSA相关函数
export -f select_curve_simple
export -f mod_simple mod_inverse_simple
export -f curve_point_add_correct curve_scalar_mult_simple

echo "✅ ECDSA功能环境创建成功"
echo "✅ 所有ECDSA功能函数已导出"
