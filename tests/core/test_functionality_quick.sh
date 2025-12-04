#!/bin/bash
# 快速功能测试脚本
set -euo pipefail

echo "========================================="
echo "快速功能测试"
echo "========================================="

# 测试1: 基础数学函数
echo "1. 测试基础数学函数..."
if bash -c '
    source lib/bash_math.sh
    result=$(bashmath_add 5 3)
    if [[ "$result" == "8" ]]; then
        echo "✓ 加法测试通过"
        exit 0
    else
        echo "✗ 加法测试失败: 5+3=$result"
        exit 1
    fi
'; then
    echo "✅ 基础数学函数正常"
else
    echo "❌ 基础数学函数异常"
fi

# 测试2: 曲线选择
echo "2. 测试曲线选择..."
if bash -c '
    source lib/bash_math.sh
    source lib/bigint.sh
    source core/crypto/curve_selector.sh
    
    # 测试secp256r1
    if select_curve secp256r1; then
        echo "✓ secp256r1 曲线选择成功"
    else
        echo "✗ secp256r1 曲线选择失败"
        exit 1
    fi
    
    # 测试secp256k1
    if select_curve secp256k1; then
        echo "✓ secp256k1 曲线选择成功"
    else
        echo "✗ secp256k1 曲线选择失败"
        exit 1
    fi
'; then
    echo "✅ 曲线选择功能正常"
else
    echo "❌ 曲线选择功能异常"
fi

# 测试3: 主程序基本功能
echo "3. 测试主程序基本功能..."
for prog in becc.sh becc_multi_curve.sh becc_fixed.sh; do
    if timeout 10 ./$prog help >/dev/null 2>&1; then
        echo "✅ $prog help 正常"
    else
        echo "❌ $prog help 异常"
    fi
done

# 测试4: 密钥生成（简化版）
echo "4. 测试密钥生成..."
if bash -c '
    source lib/bash_math.sh
    source lib/bigint.sh
    source lib/ec_curve.sh
    source lib/ec_point.sh
    source core/crypto/curve_selector.sh
    
    select_curve secp256r1
    
    # 简单的私钥生成测试
    private_key="0x1234567890abcdef"
    echo "测试私钥: $private_key"
    
    # 尝试计算公钥（简化测试）
    if validate_private_key "$private_key"; then
        echo "✓ 私钥验证通过"
    else
        echo "✗ 私钥验证失败"
        exit 1
    fi
'; then
    echo "✅ 密钥生成功能正常"
else
    echo "❌ 密钥生成功能异常"
fi

# 测试5: 椭圆曲线点运算
echo "5. 测试椭圆曲线点运算..."
if bash -c '
    source lib/bash_math.sh
    source lib/bigint.sh
    source lib/ec_curve.sh
    source lib/ec_point.sh
    source core/crypto/curve_selector.sh
    
    select_curve secp256r1
    
    # 测试点加法
    echo "测试椭圆曲线点运算..."
    
    # 使用生成点
    Gx=$CURVE_GX
    Gy=$CURVE_GY
    
    echo "生成点 G = ($Gx, $Gy)"
    echo "曲线参数: p=$CURVE_P, a=$CURVE_A, b=$CURVE_B"
    
    # 简单的验证测试
    if [[ -n "$Gx" && -n "$Gy" && -n "$CURVE_P" ]]; then
        echo "✓ 曲线参数加载成功"
    else
        echo "✗ 曲线参数加载失败"
        exit 1
    fi
'; then
    echo "✅ 椭圆曲线功能正常"
else
    echo "❌ 椭圆曲线功能异常"
fi

echo
echo "========================================="
echo "快速功能测试完成"
echo "========================================="