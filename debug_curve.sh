#!/bin/bash

# 调试曲线选择器
echo "调试曲线选择器..."

# 导入曲线选择器
source core/crypto/curve_selector.sh

echo "测试选择 secp256r1:"
if select_curve "secp256r1"; then
    echo "选择成功"
    echo "CURVE_NAME = '$CURVE_NAME'"
    echo "CURVE_P 长度 = ${#CURVE_P}"
    echo "CURVE_P 前20字符 = '${CURVE_P:0:20}'"
    echo "CURVE_P 是否为空: $([[ -z "$CURVE_P" ]] && echo "是" || echo "否")"
    echo "CURVE_P 是否为数字: $([[ "$CURVE_P" =~ ^[0-9]+$ ]] && echo "是" || echo "否")"
    echo "CURVE_P 数值比较测试: $CURVE_P -lt 2"
    if [[ "$CURVE_P" -lt 2 ]]; then
        echo "CURVE_P 小于 2"
    else
        echo "CURVE_P 大于等于 2"
    fi
else
    echo "选择失败"
fi