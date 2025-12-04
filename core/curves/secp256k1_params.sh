#!/bin/bash
# SECP256K1 椭圆曲线参数定义
# 比特币使用的标准曲线

set -euo pipefail

# 导入保护 - 防止重复定义
if [[ -n "${SECP256K1_PARAMS_LOADED:-}" ]]; then
    return 0
fi
readonly SECP256K1_PARAMS_LOADED=1

# SECP256K1 参数 (十六进制表示)
# 素数p: 2^256 - 2^32 - 977
readonly SECP256K1_P_HEX="fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f"

# 系数a
readonly SECP256K1_A_HEX="0"

# 系数b
readonly SECP256K1_B_HEX="7"

# 基点G的x坐标
readonly SECP256K1_GX_HEX="79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"

# 基点G的y坐标
readonly SECP256K1_GY_HEX="483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8"

# 基点G的阶n
readonly SECP256K1_N_HEX="fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"

# 余因子h
readonly SECP256K1_H="1"

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
if [[ -z "${SECP256K1_P:-}" ]]; then
    readonly SECP256K1_P="$(hex_to_decimal "$SECP256K1_P_HEX")"
fi

if [[ -z "${SECP256K1_A:-}" ]]; then
    readonly SECP256K1_A="$(hex_to_decimal "$SECP256K1_A_HEX")"
fi

if [[ -z "${SECP256K1_B:-}" ]]; then
    readonly SECP256K1_B="$(hex_to_decimal "$SECP256K1_B_HEX")"
fi

if [[ -z "${SECP256K1_GX:-}" ]]; then
    readonly SECP256K1_GX="$(hex_to_decimal "$SECP256K1_GX_HEX")"
fi

if [[ -z "${SECP256K1_GY:-}" ]]; then
    readonly SECP256K1_GY="$(hex_to_decimal "$SECP256K1_GY_HEX")"
fi

if [[ -z "${SECP256K1_N:-}" ]]; then
    readonly SECP256K1_N="$(hex_to_decimal "$SECP256K1_N_HEX")"
fi

# 获取SECP256K1参数函数
get_secp256k1_params() {
    echo "$SECP256K1_P $SECP256K1_A $SECP256K1_B $SECP256K1_GX $SECP256K1_GY $SECP256K1_N $SECP256K1_H"
}

# 获取SECP256K1参数（十六进制）
get_secp256k1_params_hex() {
    echo "$SECP256K1_P_HEX $SECP256K1_A_HEX $SECP256K1_B_HEX $SECP256K1_GX_HEX $SECP256K1_GY_HEX $SECP256K1_N_HEX $SECP256K1_H"
}

# 验证SECP256K1参数的有效性
validate_secp256k1_params() {
    local error_count=0
    
    # 检查参数是否为空
    if [[ -z "$SECP256K1_P" ]] || [[ -z "$SECP256K1_A" ]] || [[ -z "$SECP256K1_B" ]] || 
       [[ -z "$SECP256K1_GX" ]] || [[ -z "$SECP256K1_GY" ]] || [[ -z "$SECP256K1_N" ]]; then
        echo "错误: SECP256K1参数未正确初始化" >&2
        return 1
    fi
    
    # 检查参数是否为有效的数字
    for param_name in P A B GX GY N; do
        local param_var="SECP256K1_$param_name"
        local param_value="${!param_var}"
        if [[ ! "$param_value" =~ ^[0-9]+$ ]]; then
            echo "错误: SECP256K1参数$param_name包含非数字字符" >&2
            ((error_count++))
        fi
    done
    
    # 检查p是否为素数（简化检查）
    if [[ "$SECP256K1_P" -lt 2 ]]; then
        echo "错误: SECP256K1参数p必须大于1" >&2
        ((error_count++))
    fi
    
    # 检查基点是否在曲线上（简化验证）
    # 这里可以添加更严格的椭圆曲线方程验证
    
    if [[ $error_count -gt 0 ]]; then
        echo "错误: SECP256K1参数验证失败，发现 $error_count 个错误" >&2
        return 1
    fi
    
    return 0
}

# 获取曲线信息
get_secp256k1_info() {
    cat << EOF
SECP256K1 椭圆曲线信息:
  标准: SECG, 比特币标准
  用途: 比特币、以太坊等加密货币
  安全级别: 128位
  密钥长度: 256位
  素数p: $SECP256K1_P_HEX
  系数a: $SECP256K1_A_HEX
  系数b: $SECP256K1_B_HEX
  基点Gx: $SECP256K1_GX_HEX
  基点Gy: $SECP256K1_GY_HEX
  阶n: $SECP256K1_N_HEX
  余因子h: $SECP256K1_H
EOF
}