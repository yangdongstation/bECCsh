#!/bin/bash
# SECP521R1 (P-521) 椭圆曲线参数定义
# NIST标准曲线，提供最高安全级别，用于长期保密应用

set -euo pipefail

# 导入保护 - 防止重复定义
if [[ -n "${SECP521R1_PARAMS_LOADED:-}" ]]; then
    return 0
fi
readonly SECP521R1_PARAMS_LOADED=1

# SECP521R1 参数 (十六进制表示)
# 素数p: 2^521 - 1
readonly SECP521R1_P_HEX="000001ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"

# 系数a: -3 (mod p)
readonly SECP521R1_A_HEX="000001fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc"

# 系数b
readonly SECP521R1_B_HEX="00000051953eb9618e1c9a1f929a21a0b68540eea2da725b99b315f3b8b489918ef109e156193951ec7e937b1652c0bd3bb1bf073573df883d2c34f1ef451fd46b503f00"

# 基点G的x坐标
readonly SECP521R1_GX_HEX="000000c6858e06b70404e9cd9e3ecb662395b4429c648139053fb521f828af606b4d3dbaa14b5e77efe75928fe1dc127a2ffa8de3348b3c1856a429bf97e7e31c2e5bd66"

# 基点G的y坐标
readonly SECP521R1_GY_HEX="0000011839296a789a3bc0045c8a5fb42c7d1bd998f54449579b446817afbd17273e662c97ee72995ef42640c550b9013fad0761353c7086a272c24088be94769fd16650"

# 基点G的阶n
readonly SECP521R1_N_HEX="000001fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa51868783bf2f966b7fcc0148f709a5d03bb5c9b8899c47aebb6fb71e91386409"

# 余因子h
readonly SECP521R1_H="1"

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
if [[ -z "${SECP521R1_P:-}" ]]; then
    readonly SECP521R1_P="$(hex_to_decimal "$SECP521R1_P_HEX")"
fi

if [[ -z "${SECP521R1_A:-}" ]]; then
    readonly SECP521R1_A="$(hex_to_decimal "$SECP521R1_A_HEX")"
fi

if [[ -z "${SECP521R1_B:-}" ]]; then
    readonly SECP521R1_B="$(hex_to_decimal "$SECP521R1_B_HEX")"
fi

if [[ -z "${SECP521R1_GX:-}" ]]; then
    readonly SECP521R1_GX="$(hex_to_decimal "$SECP521R1_GX_HEX")"
fi

if [[ -z "${SECP521R1_GY:-}" ]]; then
    readonly SECP521R1_GY="$(hex_to_decimal "$SECP521R1_GY_HEX")"
fi

if [[ -z "${SECP521R1_N:-}" ]]; then
    readonly SECP521R1_N="$(hex_to_decimal "$SECP521R1_N_HEX")"
fi

# 获取SECP521R1参数函数
get_secp521r1_params() {
    echo "$SECP521R1_P $SECP521R1_A $SECP521R1_B $SECP521R1_GX $SECP521R1_GY $SECP521R1_N $SECP521R1_H"
}

# 获取SECP521R1参数（十六进制）
get_secp521r1_params_hex() {
    echo "$SECP521R1_P_HEX $SECP521R1_A_HEX $SECP521R1_B_HEX $SECP521R1_GX_HEX $SECP521R1_GY_HEX $SECP521R1_N_HEX $SECP521R1_H"
}

# 验证SECP521R1参数的有效性
validate_secp521r1_params() {
    local error_count=0
    
    # 检查参数是否为空
    if [[ -z "$SECP521R1_P" ]] || [[ -z "$SECP521R1_A" ]] || [[ -z "$SECP521R1_B" ]] || 
       [[ -z "$SECP521R1_GX" ]] || [[ -z "$SECP521R1_GY" ]] || [[ -z "$SECP521R1_N" ]]; then
        echo "错误: SECP521R1参数未正确初始化" >&2
        return 1
    fi
    
    # 检查参数是否为有效的数字
    for param_name in P A B GX GY N; do
        local param_var="SECP521R1_$param_name"
        local param_value="${!param_var}"
        if [[ ! "$param_value" =~ ^[0-9]+$ ]]; then
            echo "错误: SECP521R1参数$param_name包含非数字字符" >&2
            ((error_count++))
        fi
    done
    
    # 检查p是否为素数（简化检查）
    if [[ "$SECP521R1_P" -lt 2 ]]; then
        echo "错误: SECP521R1参数p必须大于1" >&2
        ((error_count++))
    fi
    
    # 检查基点是否在曲线上（简化验证）
    # 这里可以添加更严格的椭圆曲线方程验证
    
    if [[ $error_count -gt 0 ]]; then
        echo "错误: SECP521R1参数验证失败，发现 $error_count 个错误" >&2
        return 1
    fi
    
    return 0
}

# 获取曲线信息
get_secp521r1_info() {
    cat << EOF
SECP521R1 (P-521) 椭圆曲线信息:
  标准: NIST P-521, RFC 5480
  用途: 最高安全级别、长期保密、政府顶级机密
  安全级别: 256位
  密钥长度: 521位
  素数p: $SECP521R1_P_HEX
  系数a: $SECP521R1_A_HEX
  系数b: $SECP521R1_B_HEX
  基点Gx: $SECP521R1_GX_HEX
  基点Gy: $SECP521R1_GY_HEX
  阶n: $SECP521R1_N_HEX
  余因子h: $SECP521R1_H
EOF
}