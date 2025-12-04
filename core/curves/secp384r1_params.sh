#!/bin/bash
# SECP384R1 (P-384) 椭圆曲线参数定义
# NIST标准曲线，广泛用于高安全性应用和政府加密

set -euo pipefail

# 导入保护 - 防止重复定义
if [[ -n "${SECP384R1_PARAMS_LOADED:-}" ]]; then
    return 0
fi
readonly SECP384R1_PARAMS_LOADED=1

# SECP384R1 参数 (十六进制表示)
# 素数p: 2^384 - 2^128 - 2^96 + 2^32 - 1
readonly SECP384R1_P_HEX="fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000ffffffff"

# 系数a: -3 (mod p)
readonly SECP384R1_A_HEX="fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000fffffffc"

# 系数b
readonly SECP384R1_B_HEX="b3312fa7e23ee7e4988e056be3f82d19181d9c6efe8141120314088f5013875ac656398d8a2ed19d2a85c8edd3ec2aef"

# 基点G的x坐标
readonly SECP384R1_GX_HEX="aa87ca22be8b05378eb1c71ef320ad746e1d3b628ba79b9859f741e082542a385502f25dbf55296c3a545e3872760ab7"

# 基点G的y坐标
readonly SECP384R1_GY_HEX="3617de4a96262c6f5d9e98bf9292dc29f8f41dbd289a147ce9da3113b5f0b8c00a60b1ce1d7e819d7a431d7c90ea0e5f"

# 基点G的阶n
readonly SECP384R1_N_HEX="ffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc52973"

# 余因子h
readonly SECP384R1_H="1"

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
if [[ -z "${SECP384R1_P:-}" ]]; then
    readonly SECP384R1_P="$(hex_to_decimal "$SECP384R1_P_HEX")"
fi

if [[ -z "${SECP384R1_A:-}" ]]; then
    readonly SECP384R1_A="$(hex_to_decimal "$SECP384R1_A_HEX")"
fi

if [[ -z "${SECP384R1_B:-}" ]]; then
    readonly SECP384R1_B="$(hex_to_decimal "$SECP384R1_B_HEX")"
fi

if [[ -z "${SECP384R1_GX:-}" ]]; then
    readonly SECP384R1_GX="$(hex_to_decimal "$SECP384R1_GX_HEX")"
fi

if [[ -z "${SECP384R1_GY:-}" ]]; then
    readonly SECP384R1_GY="$(hex_to_decimal "$SECP384R1_GY_HEX")"
fi

if [[ -z "${SECP384R1_N:-}" ]]; then
    readonly SECP384R1_N="$(hex_to_decimal "$SECP384R1_N_HEX")"
fi

# 获取SECP384R1参数函数
get_secp384r1_params() {
    echo "$SECP384R1_P $SECP384R1_A $SECP384R1_B $SECP384R1_GX $SECP384R1_GY $SECP384R1_N $SECP384R1_H"
}

# 获取SECP384R1参数（十六进制）
get_secp384r1_params_hex() {
    echo "$SECP384R1_P_HEX $SECP384R1_A_HEX $SECP384R1_B_HEX $SECP384R1_GX_HEX $SECP384R1_GY_HEX $SECP384R1_N_HEX $SECP384R1_H"
}

# 验证SECP384R1参数的有效性
validate_secp384r1_params() {
    local error_count=0
    
    # 检查参数是否为空
    if [[ -z "$SECP384R1_P" ]] || [[ -z "$SECP384R1_A" ]] || [[ -z "$SECP384R1_B" ]] || 
       [[ -z "$SECP384R1_GX" ]] || [[ -z "$SECP384R1_GY" ]] || [[ -z "$SECP384R1_N" ]]; then
        echo "错误: SECP384R1参数未正确初始化" >&2
        return 1
    fi
    
    # 检查参数是否为有效的数字
    for param_name in P A B GX GY N; do
        local param_var="SECP384R1_$param_name"
        local param_value="${!param_var}"
        if [[ ! "$param_value" =~ ^[0-9]+$ ]]; then
            echo "错误: SECP384R1参数$param_name包含非数字字符" >&2
            ((error_count++))
        fi
    done
    
    # 检查p是否为素数（简化检查）
    if [[ "$SECP384R1_P" -lt 2 ]]; then
        echo "错误: SECP384R1参数p必须大于1" >&2
        ((error_count++))
    fi
    
    # 检查基点是否在曲线上（简化验证）
    # 这里可以添加更严格的椭圆曲线方程验证
    
    if [[ $error_count -gt 0 ]]; then
        echo "错误: SECP384R1参数验证失败，发现 $error_count 个错误" >&2
        return 1
    fi
    
    return 0
}

# 获取曲线信息
get_secp384r1_info() {
    cat << EOF
SECP384R1 (P-384) 椭圆曲线信息:
  标准: NIST P-384, RFC 5480
  用途: 高安全性应用、政府加密、TLS 1.3
  安全级别: 192位
  密钥长度: 384位
  素数p: $SECP384R1_P_HEX
  系数a: $SECP384R1_A_HEX
  系数b: $SECP384R1_B_HEX
  基点Gx: $SECP384R1_GX_HEX
  基点Gy: $SECP384R1_GY_HEX
  阶n: $SECP384R1_N_HEX
  余因子h: $SECP384R1_H
EOF
}