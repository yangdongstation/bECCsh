#!/bin/bash
# 简单的路径检查 - 验证关键文件是否存在

echo "🔍 bECCsh 简单路径检查"
echo "========================"

SCRIPT_DIR="/home/donz/bECCsh"
LIB_DIR="${SCRIPT_DIR}/lib"
CORE_DIR="${SCRIPT_DIR}/core"
CRYPTO_DIR="${CORE_DIR}/crypto"

errors=0

check_file() {
    local file="$1"
    local description="$2"
    
    if [[ -f "$file" ]]; then
        echo "✅ $description"
    else
        echo "❌ $description - 文件不存在"
        ((errors++))
    fi
}

check_dir() {
    local dir="$1"
    local description="$2"
    
    if [[ -d "$dir" ]]; then
        echo "✅ $description"
    else
        echo "❌ $description - 目录不存在"
        ((errors++))
    fi
}

echo "1. 检查关键目录..."
check_dir "$LIB_DIR" "库目录"
check_dir "$CORE_DIR" "核心目录"
check_dir "$CRYPTO_DIR" "加密目录"

echo ""
echo "2. 检查核心库文件..."
check_file "$LIB_DIR/bash_math.sh" "Bash数学库"
check_file "$LIB_DIR/bigint.sh" "大数运算库"
check_file "$LIB_DIR/ec_curve.sh" "椭圆曲线库"
check_file "$LIB_DIR/ec_point.sh" "椭圆曲线点库"
check_file "$LIB_DIR/ecdsa.sh" "ECDSA库"

echo ""
echo "3. 检查核心加密文件..."
check_file "$CRYPTO_DIR/ecdsa_fixed.sh" "修复版ECDSA"
check_file "$CRYPTO_DIR/curve_selector_simple.sh" "简化曲线选择器"

echo ""
echo "4. 检查测试脚本..."
check_file "$SCRIPT_DIR/test_simple_fixed.sh" "简单修复测试"
check_file "$SCRIPT_DIR/test_becc_fixed.sh" "修复版本测试"

echo ""
echo "5. 检查曲线参数..."
check_file "$CORE_DIR/curves/secp256k1_params.sh" "SECP256K1参数"
check_file "$CORE_DIR/curves/secp256r1_params.sh" "SECP256R1参数"

echo ""
echo "========================"
echo "检查完成"
echo "错误数量: $errors"

if [[ $errors -eq 0 ]]; then
    echo "🎉 所有关键路径检查通过！"
    exit 0
else
    echo "⚠️  发现 $errors 个问题需要修复"
    exit 1
fi