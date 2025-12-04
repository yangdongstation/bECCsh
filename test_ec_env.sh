#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 导入所有椭圆曲线数学库
source "$SCRIPT_DIR/core/crypto/ec_math_fixed_simple.sh"

# 导出所有椭圆曲线数学函数
export -f mod_simple mod_inverse_simple
export -f curve_point_add_correct curve_scalar_mult_simple

echo "✅ 椭圆曲线数学环境创建成功"
echo "✅ 所有椭圆曲线数学函数已导出"
