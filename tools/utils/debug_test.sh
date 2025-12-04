#!/bin/bash
# 调试测试
set -x

echo "=== 步骤1: 加载基础库 ==="
source lib/bash_math.sh || { echo "bash_math.sh 加载失败"; exit 1; }
source lib/bigint.sh || { echo "bigint.sh 加载失败"; exit 1; }
source lib/ec_curve.sh || { echo "ec_curve.sh 加载失败"; exit 1; }
source lib/ec_point.sh || { echo "ec_point.sh 加载失败"; exit 1; }
source lib/asn1.sh || { echo "asn1.sh 加载失败"; exit 1; }
source lib/entropy.sh || { echo "entropy.sh 加载失败"; exit 1; }
echo "✅ 基础库加载成功"

echo "=== 步骤2: 加载修复的ECDSA ==="
source core/crypto/ecdsa_fixed.sh || { echo "ecdsa_fixed.sh 加载失败"; exit 1; }
echo "✅ ECDSA修复版加载成功"

echo "=== 步骤3: 加载曲线选择器 ==="
source core/crypto/curve_selector_simple.sh || { echo "curve_selector_simple.sh 加载失败"; exit 1; }
echo "✅ 曲线选择器加载成功"

echo "=== 步骤4: 检查变量 ==="
echo "CURRENT_CURVE_SIMPLE=${CURRENT_CURVE_SIMPLE:-undefined}"

echo "=== 步骤5: 测试函数 ==="
if command -v generate_ecdsa_signature >/dev/null; then
    echo "✅ generate_ecdsa_signature 函数存在"
else
    echo "❌ generate_ecdsa_signature 函数不存在"
fi

echo "=== 调试完成 ==="