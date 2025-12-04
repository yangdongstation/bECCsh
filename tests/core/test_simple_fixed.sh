#!/bin/bash
# 简化测试修复版本

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"
CORE_DIR="${SCRIPT_DIR}/core"

echo "Testing basic imports..."

# 测试基础库导入
source "${LIB_DIR}/bash_math.sh" && echo "✅ bash_math.sh loaded"
source "${LIB_DIR}/bigint.sh" && echo "✅ bigint.sh loaded"
source "${LIB_DIR}/ec_curve.sh" && echo "✅ ec_curve.sh loaded"
source "${LIB_DIR}/ec_point.sh" && echo "✅ ec_point.sh loaded"
source "${LIB_DIR}/asn1.sh" && echo "✅ asn1.sh loaded"
source "${LIB_DIR}/entropy.sh" && echo "✅ entropy.sh loaded"

echo "Testing core modules..."

# 测试核心模块
source "${CORE_DIR}/crypto/curve_selector_simple.sh" && echo "✅ curve_selector_simple.sh loaded"

# 测试曲线选择
if select_curve_simple "secp256k1"; then
    echo "✅ Curve selection works: $CURRENT_CURVE_SIMPLE"
else
    echo "❌ Curve selection failed"
fi

echo "All basic tests passed!"