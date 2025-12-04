#!/bin/bash
# SECP256R1 (P-256) 椭圆曲线参数定义
# NIST标准曲线，广泛用于TLS 1.3、JWT、政府标准

set -euo pipefail

# 导入保护 - 防止重复定义
if [[ -n "${SECP256R1_PARAMS_LOADED:-}" ]]; then
    return 0
fi
readonly SECP256R1_PARAMS_LOADED=1

# SECP256R1 参数 (十六进制表示)
# 素数p: 2^256 - 2^224 + 2^192 + 2^96 - 1
readonly SECP256R1_P_HEX="ffffffff00000001000000000000000000000000ffffffffffffffffffffffff"

# 系数a: -3 (mod p)
readonly SECP256R1_A_HEX="ffffffff00000001000000000000000000000000fffffffffffffffffffffffc"

# 系数b
readonly SECP256R1_B_HEX="5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b"

# 基点G的x坐标
readonly SECP256R1_GX_HEX="6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296"

# 基点G的y坐标
readonly SECP256R1_GY_HEX="4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5"

# 基点G的阶n
readonly SECP256R1_N_HEX="ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551"

# 余因子h
readonly SECP256R1_H="1"

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
if [[ -z "${SECP256R1_P:-}" ]]; then
    readonly SECP256R1_P="$(hex_to_decimal "$SECP256R1_P_HEX")"
fi

if [[ -z "${SECP256R1_A:-}" ]]; then
    readonly SECP256R1_A="$(hex_to_decimal "$SECP256R1_A_HEX")"
fi

if [[ -z "${SECP256R1_B:-}" ]]; then
    readonly SECP256R1_B="$(hex_to_decimal "$SECP256R1_B_HEX")"
fi

if [[ -z "${SECP256R1_GX:-}" ]]; then
    readonly SECP256R1_GX="$(hex_to_decimal "$SECP256R1_GX_HEX")"
fi

if [[ -z "${SECP256R1_GY:-}" ]]; then
    readonly SECP256R1_GY="$(hex_to_decimal "$SECP256R1_GY_HEX")"
fi

if [[ -z "${SECP256R1_N:-}" ]]; then
    readonly SECP256R1_N="$(hex_to_decimal "$SECP256R1_N_HEX")"
fi

# 获取SECP256R1参数函数
get_secp256r1_params() {
    echo "$SECP256R1_P $SECP256R1_A $SECP256R1_B $SECP256R1_GX $SECP256R1_GY $SECP256R1_N $SECP256R1_H"
}

# 获取SECP256R1参数（十六进制）
get_secp256r1_params_hex() {
    echo "$SECP256R1_P_HEX $SECP256R1_A_HEX $SECP256R1_B_HEX $SECP256R1_GX_HEX $SECP256R1_GY_HEX $SECP256R1_N_HEX $SECP256R1_H"
}

# 验证SECP256R1参数的有效性
validate_secp256r1_params() {
    local error_count=0
    
    # 检查参数是否为空
    if [[ -z "$SECP256R1_P" ]] || [[ -z "$SECP256R1_A" ]] || [[ -z "$SECP256R1_B" ]] || 
       [[ -z "$SECP256R1_GX" ]] || [[ -z "$SECP256R1_GY" ]] || [[ -z "$SECP256R1_N" ]]; then
        echo "错误: SECP256R1参数未正确初始化" >&2
        return 1
    fi
    
    # 检查参数是否为有效的数字
    for param_name in P A B GX GY N; do
        local param_var="SECP256R1_$param_name"
        local param_value="${!param_var}"
        if [[ ! "$param_value" =~ ^[0-9]+$ ]]; then
            echo "错误: SECP256R1参数$param_name包含非数字字符" >&2
            ((error_count++))
        fi
    done
    
    # 检查p是否为素数（简化检查）
    if [[ "$SECP256R1_P" -lt 2 ]]; then
        echo "错误: SECP256R1参数p必须大于1" >&2
        ((error_count++))
    fi
    
    # 检查基点是否在曲线上（简化验证）
    # 这里可以添加更严格的椭圆曲线方程验证
    
    if [[ $error_count -gt 0 ]]; then
        echo "错误: SECP256R1参数验证失败，发现 $error_count 个错误" >&2
        return 1
    fi
    
    return 0
}

# 获取曲线信息
get_secp256r1_info() {
    cat << EOF
SECP256R1 (P-256) 椭圆曲线信息:
  标准: NIST P-256, RFC 5480
  用途: TLS 1.3, JWT, 政府标准
  安全级别: 128位
  密钥长度: 256位
  素数p: $SECP256R1_P_HEX
  系数a: $SECP256R1_A_HEX
  系数b: $SECP256R1_B_HEX
  基点Gx: $SECP256R1_GX_HEX
  基点Gy: $SECP256R1_GY_HEX
  阶n: $SECP256R1_N_HEX
  余因子h: $SECP256R1_H
EOF
}