#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 导入所有必要的库
source "$SCRIPT_DIR/lib/bash_math.sh"
source "$SCRIPT_DIR/lib/bigint.sh"
source "$SCRIPT_DIR/core/crypto/ec_math_fixed_simple.sh"
source "$SCRIPT_DIR/core/crypto/curve_selector_simple.sh"

# 导出所有函数以便子shell使用
export -f bashmath_hex_to_dec bashmath_dec_to_hex bashmath_log2 bashmath_divide_float bashmath_binary_to_dec bashmath_dec_to_binary
export -f bigint_error bigint_validate bigint_normalize bigint_compare bigint_add bigint_subtract bigint_multiply bigint_divide bigint_mod
export -f mod_simple mod_inverse_simple
export -f curve_point_add_correct curve_scalar_mult_simple
export -f select_curve_simple

echo "✅ 测试环境创建成功"
echo "✅ 所有数学模块已加载"
echo "✅ 所有函数已导出"
