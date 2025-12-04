#!/bin/bash
# 测试becc_fixed.sh的简化版本

set -euo pipefail

# 基础路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"
CORE_DIR="${SCRIPT_DIR}/core"

# 导入基础库
echo "Loading libraries..."
source "${LIB_DIR}/bash_math.sh"
echo "bash_math loaded"
source "${LIB_DIR}/bigint.sh"
echo "bigint loaded"
source "${LIB_DIR}/ec_curve.sh"
echo "ec_curve loaded"
source "${LIB_DIR}/ec_point.sh"
echo "ec_point loaded"
source "${LIB_DIR}/asn1.sh"
echo "asn1 loaded"
source "${LIB_DIR}/entropy.sh"
echo "entropy loaded"

# 导入修复的ECDSA函数
echo "Loading core modules..."
source "${CORE_DIR}/crypto/ecdsa_fixed.sh"
echo "ecdsa_fixed loaded"

# 导入多曲线支持
source "${CORE_DIR}/crypto/curve_selector_simple.sh"
echo "curve_selector loaded"

echo "All libraries loaded successfully!"