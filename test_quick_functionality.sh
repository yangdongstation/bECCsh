#!/bin/bash
# 快速功能测试 - 验证核心功能是否正常

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== bECCsh 快速功能测试 ==="
echo "测试时间: $(date)"
echo ""

# 测试1: 基本密钥生成
echo "1. 测试基本密钥生成..."
if timeout 3 "$SCRIPT_DIR/becc.sh" keygen -c secp256k1 -f /tmp/quick_test.pem 2>/dev/null; then
    if [[ -f /tmp/quick_test.pem && -f /tmp/quick_test_public.pem ]]; then
        echo "✅ 密钥生成成功"
        rm -f /tmp/quick_test.pem /tmp/quick_test_public.pem
    else
        echo "❌ 密钥文件未生成"
        exit 1
    fi
else
    echo "❌ 密钥生成失败或超时"
    exit 1
fi

# 测试2: 修复版本密钥生成
echo "2. 测试修复版本密钥生成..."
if timeout 3 "$SCRIPT_DIR/becc_fixed.sh" keygen -c secp256k1 -f /tmp/quick_fixed_test.pem 2>/dev/null; then
    if [[ -f /tmp/quick_fixed_test.pem && -f /tmp/quick_fixed_test_public.pem ]]; then
        echo "✅ 修复版本密钥生成成功"
        rm -f /tmp/quick_fixed_test.pem /tmp/quick_fixed_test_public.pem
    else
        echo "❌ 修复版本密钥文件未生成"
        exit 1
    fi
else
    echo "❌ 修复版本密钥生成失败或超时"
    exit 1
fi

# 测试3: 曲线选择器
echo "3. 测试曲线选择器..."
if "$SCRIPT_DIR/core/crypto/curve_selector_simple.sh" 2>/dev/null | grep -q "支持的椭圆曲线"; then
    echo "✅ 曲线选择器运行正常"
else
    echo "❌ 曲线选择器运行异常"
    exit 1
fi

# 测试4: 简化ECDSA测试
echo "4. 测试简化ECDSA功能..."
if timeout 10 "$SCRIPT_DIR/test_ecdsa_final_simple.sh" 2>/dev/null | grep -q "所有测试通过"; then
    echo "✅ 简化ECDSA测试通过"
else
    echo "❌ 简化ECDSA测试失败或超时"
    exit 1
fi

# 测试5: 参数验证
echo "5. 测试椭圆曲线参数..."
if python3 -c "
p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
Gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
Gy = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8
left = (Gy * Gy) % p
right = (Gx * Gx * Gx + 7) % p
print('SECP256K1参数验证:', '通过' if left == right else '失败')
" 2>/dev/null | grep -q "通过"; then
    echo "✅ SECP256K1参数验证通过"
else
    echo "❌ SECP256K1参数验证失败"
    exit 1
fi

echo ""
echo "🎉 所有快速测试通过！"
echo "bECCsh 核心功能运行正常！"
echo "软件包可运行度: 高 ✅"