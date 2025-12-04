#!/bin/bash
# SECP192K1 椭圆曲线参数定义
# Koblitz曲线，轻量级应用，物联网设备，较小密钥尺寸，适合资源受限环境

set -euo pipefail

# 导入保护 - 防止重复定义
if [[ -n "${SECP192K1_PARAMS_LOADED:-}" ]]; then
    return 0
fi
readonly SECP192K1_PARAMS_LOADED=1

# SECP192K1 参数 (十六进制表示)
# 素数p: 2^192 - 2^96 - 1
readonly SECP192K1_P_HEX="fffffffffffffffffffffffffffffffffffffffeffffee37"

# 系数a
readonly SECP192K1_A_HEX="0"

# 系数b
readonly SECP192K1_B_HEX="3"

# 基点G的x坐标
readonly SECP192K1_GX_HEX="db4ff10ec057e9ae26b07d0280b7f4341da5d1b1eae06c7d"

# 基点G的y坐标
readonly SECP192K1_GY_HEX="9b2f2f6d9c5628a7844163d015be86344082aa88d95e2f9d"

# 基点G的阶n
readonly SECP192K1_N_HEX="fffffffffffffffffffffffe26f2fc170f69466a74defd8d"

# 余因子h
readonly SECP192K1_H="1"

# 转换为十进制数的辅助函数
hex_to_decimal() {
    local hex_value="$1"
    # 移除空格并转换为大写
    hex_value=$(echo "$hex_value" | tr -d ' ' | tr '[:lower:]' '[:upper:]')
    
    # 使用python进行大数十六进制到十进制转换（如果可用）
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "print(int('$hex_value', 16))"
    elif command -v python >/dev/null 2>&1; then
        python -c "print(int('$hex_value', 16))"
    elif command -v bc >/dev/null 2>&1; then
        # 使用bc进行转换
        echo "ibase=16; $hex_value" | BC_LINE_LENGTH=0 bc
    else
        echo "错误: 需要python或bc进行大数转换" >&2
        return 1
    fi
}

# 十进制表示的参数（缓存以提高性能）
if [[ -z "${SECP192K1_P:-}" ]]; then
    readonly SECP192K1_P="$(hex_to_decimal "$SECP192K1_P_HEX")"
fi

if [[ -z "${SECP192K1_A:-}" ]]; then
    readonly SECP192K1_A="$(hex_to_decimal "$SECP192K1_A_HEX")"
fi

if [[ -z "${SECP192K1_B:-}" ]]; then
    readonly SECP192K1_B="$(hex_to_decimal "$SECP192K1_B_HEX")"
fi

if [[ -z "${SECP192K1_GX:-}" ]]; then
    readonly SECP192K1_GX="$(hex_to_decimal "$SECP192K1_GX_HEX")"
fi

if [[ -z "${SECP192K1_GY:-}" ]]; then
    readonly SECP192K1_GY="$(hex_to_decimal "$SECP192K1_GY_HEX")"
fi

if [[ -z "${SECP192K1_N:-}" ]]; then
    readonly SECP192K1_N="$(hex_to_decimal "$SECP192K1_N_HEX")"
fi

# 获取SECP192K1参数函数
get_secp192k1_params() {
    echo "$SECP192K1_P $SECP192K1_A $SECP192K1_B $SECP192K1_GX $SECP192K1_GY $SECP192K1_N $SECP192K1_H"
}

# 获取SECP192K1参数（十六进制）
get_secp192k1_params_hex() {
    echo "$SECP192K1_P_HEX $SECP192K1_A_HEX $SECP192K1_B_HEX $SECP192K1_GX_HEX $SECP192K1_GY_HEX $SECP192K1_N_HEX $SECP192K1_H"
}

# 验证SECP192K1参数的有效性
validate_secp192k1_params() {
    local error_count=0
    
    # 检查参数是否为空
    if [[ -z "$SECP192K1_P" ]] || [[ -z "$SECP192K1_A" ]] || [[ -z "$SECP192K1_B" ]] || 
       [[ -z "$SECP192K1_GX" ]] || [[ -z "$SECP192K1_GY" ]] || [[ -z "$SECP192K1_N" ]]; then
        echo "错误: SECP192K1参数未正确初始化" >&2
        return 1
    fi
    
    # 检查参数是否为有效的数字
    for param_name in P A B GX GY N; do
        local param_var="SECP192K1_$param_name"
        local param_value="${!param_var}"
        if [[ ! "$param_value" =~ ^[0-9]+$ ]]; then
            echo "错误: SECP192K1参数$param_name包含非数字字符" >&2
            ((error_count++))
        fi
    done
    
    # 检查p是否为素数（简化检查）
    if [[ "$SECP192K1_P" -lt 2 ]]; then
        echo "错误: SECP192K1参数p必须大于1" >&2
        ((error_count++))
    fi
    
    # 检查基点是否在曲线上（简化验证）
    # 这里可以添加更严格的椭圆曲线方程验证
    
    if [[ $error_count -gt 0 ]]; then
        echo "错误: SECP192K1参数验证失败，发现 $error_count 个错误" >&2
        return 1
    fi
    
    return 0
}

# 获取曲线信息
get_secp192k1_info() {
    cat << EOF
SECP192K1 椭圆曲线信息:
  标准: SECG Koblitz曲线
  用途: 轻量级应用、物联网设备、资源受限环境
  安全级别: 96位
  密钥长度: 192位
  特点: Koblitz曲线，计算效率高，较小密钥尺寸
  素数p: $SECP192K1_P_HEX
  系数a: $SECP192K1_A_HEX
  系数b: $SECP192K1_B_HEX
  基点Gx: $SECP192K1_GX_HEX
  基点Gy: $SECP192K1_GY_HEX
  阶n: $SECP192K1_N_HEX
  余因子h: $SECP192K1_H
EOF
}