#!/bin/bash
# ASN.1 - ASN.1编码/解码支持
# 实现DER编码格式，用于ECDSA签名

set -euo pipefail

# 导入保护 - 防止重复定义
if [[ -n "${ASN1_LOADED:-}" ]]; then
    return 0
fi
readonly ASN1_LOADED=1

# 导入数学库
source "$(dirname "${BASH_SOURCE[0]}")/bash_math.sh"

# ASN.1标签定义
ASN1_TAG_INTEGER=0x02
ASN1_TAG_SEQUENCE=0x30
ASN1_TAG_OCTET_STRING=0x04
readonly ASN1_TAG_OBJECT_IDENTIFIER=0x06
readonly ASN1_TAG_NULL=0x05

# ASN.1错误处理
asn1_error() {
    echo "ASN.1错误: $*" >&2
    return 1
}

# 长度编码（DER）
asn1_encode_length() {
    local length="$1"
    
    if [[ $length -lt 128 ]]; then
        # 短形式
        printf "%02X" $length
    else
        # 长形式
        local length_bytes=""
        local temp=$length
        
        while [[ $temp -gt 0 ]]; do
            length_bytes=$(printf "%02X" $((temp & 0xFF)))$length_bytes
            temp=$((temp >> 8))
        done
        
        local num_bytes=$((${#length_bytes} / 2))
        printf "8%X%s" $num_bytes $length_bytes
    fi
}

# 整数编码（DER）
asn1_encode_integer() {
    local value="$1"
    
    # 处理负数
    if [[ "$value" =~ ^- ]]; then
        value=${value#-}
        # 对于负数，需要补码表示
        # 这里简化处理，假设都是正数
    fi
    
    # 转换为十六进制
    local hex_value=$(bashmath_dec_to_hex "$value" | tr '[:lower:]' '[:upper:]')
    
    # 确保偶数位
    if [[ $((${#hex_value} % 2)) -eq 1 ]]; then
        hex_value="0$hex_value"
    fi
    
    # 如果最高位是1，需要添加前导零
    if [[ "${hex_value:0:1}" =~ [89ABCDEF] ]]; then
        hex_value="00$hex_value"
    fi
    
    local length=$((${#hex_value} / 2))
    local encoded_length=$(asn1_encode_length $length)
    
    printf "%02X%s%s" $ASN1_TAG_INTEGER $encoded_length $hex_value
}

# ECDSA签名编码（DER）
encode_ecdsa_signature() {
    local r="$1"
    local s="$2"
    
    # 编码r和s
    local r_encoded=$(asn1_encode_integer "$r")
    local s_encoded=$(asn1_encode_integer "$s")
    
    # 组合序列
    local sequence_content="$r_encoded$s_encoded"
    local sequence_length=$((${#sequence_content} / 2))
    local encoded_sequence_length=$(asn1_encode_length $sequence_length)
    
    # 最终DER编码
    local der_encoded=$(printf "%02X%s%s" $ASN1_TAG_SEQUENCE $encoded_sequence_length $sequence_content)
    
    # 转换为base64
    echo -n "$der_encoded" | xxd -r -p | base64 -w0
}

# ECDSA签名解码（DER）
decode_ecdsa_signature() {
    local signature_b64="$1"
    
    # 从base64解码
    local signature_hex=$(echo -n "$signature_b64" | base64 -d 2>/dev/null | xxd -p | tr -d '\\n')
    
    if [[ -z "$signature_hex" ]]; then
        # 尝试直接处理十六进制
        signature_hex=$(echo "$signature_b64" | tr -d '[:space:]')
    fi
    
    # 检查序列标签
    if [[ "${signature_hex:0:2}" != "30" ]]; then
        asn1_error "无效的ASN.1序列标签"
        return 1
    fi
    
    # 解析长度
    local pos=2
    local length_byte="${signature_hex:pos:2}"
    
    if [[ $((16#$length_byte)) -lt 128 ]]; then
        # 短形式长度
        local sequence_length=$((16#$length_byte))
        pos=$((pos + 2))
    else
        # 长形式长度
        local num_length_bytes=$((16#$length_byte & 0x7F))
        pos=$((pos + 2))
        local length_hex="${signature_hex:pos:num_length_bytes*2}"
        local sequence_length=$(bashmath_hex_to_dec "$length_hex")
        pos=$((pos + num_length_bytes * 2))
    fi
    
    # 解析r
    if [[ "${signature_hex:pos:2}" != "02" ]]; then
        asn1_error "无效的r整数标签"
        return 1
    fi
    
    pos=$((pos + 2))
    local r_length=$((16#${signature_hex:pos:2}))
    pos=$((pos + 2))
    
    # 处理长形式长度
    if [[ $r_length -ge 128 ]]; then
        local num_r_length_bytes=$((r_length & 0x7F))
        pos=$((pos + 2))
        local r_length_hex="${signature_hex:pos:num_r_length_bytes*2}"
        r_length=$(bashmath_hex_to_dec "$r_length_hex")
        pos=$((pos + num_r_length_bytes * 2))
    fi
    
    local r_hex="${signature_hex:pos:r_length*2}"
    local r=$(bashmath_hex_to_dec "$r_hex")
    pos=$((pos + r_length * 2))
    
    # 解析s
    if [[ "${signature_hex:pos:2}" != "02" ]]; then
        asn1_error "无效的s整数标签"
        return 1
    fi
    
    pos=$((pos + 2))
    local s_length=$((16#${signature_hex:pos:2}))
    pos=$((pos + 2))
    
    # 处理长形式长度
    if [[ $s_length -ge 128 ]]; then
        local num_s_length_bytes=$((s_length & 0x7F))
        pos=$((pos + 2))
        local s_length_hex="${signature_hex:pos:num_s_length_bytes*2}"
        s_length=$(bashmath_hex_to_dec "$s_length_hex")
        pos=$((pos + num_s_length_bytes * 2))
    fi
    
    local s_hex="${signature_hex:pos:s_length*2}"
    local s=$(bashmath_hex_to_dec "$s_hex")
    
    # 设置输出变量
    eval "$2='$r'"
    eval "$3='$s'"
}

# PEM格式编码
pem_encode() {
    local data="$1"
    local label="$2"
    
    local pem_header="-----BEGIN $label-----"
    local pem_footer="-----END $label-----"
    
    # 每64个字符换行
    local formatted_data=$(echo "$data" | fold -w 64)
    
    echo "$pem_header"
    echo "$formatted_data"
    echo "$pem_footer"
}

# PEM格式解码
pem_decode() {
    local pem_data="$1"
    
    # 移除PEM头和尾
    local base64_data=$(echo "$pem_data" | grep -v "^----" | tr -d '[:space:]')
    
    # 解码base64
    echo -n "$base64_data" | base64 -d 2>/dev/null
}

# 私钥PEM格式编码
encode_private_key_pem() {
    local private_key="$1"
    local curve_name="${2:-secp256r1}"
    
    # ECPrivateKey结构
    local version="020100"  # INTEGER 0 (版本)
    local private_key_octets=$(i2osp "$private_key" 32)
    local private_key_encoded=$(asn1_encode_octet_string "$private_key_octets")
    
    # 曲线OID（简化处理）
    local curve_oid
    case "$curve_name" in
        "secp256r1")
            curve_oid="06082A8648CE3D030107"  # 1.2.840.10045.3.1.7
            ;;
        "secp256k1")
            curve_oid="06052B8104000A"  # 1.3.132.0.10
            ;;
        *)
            curve_oid="06082A8648CE3D030107"  # 默认secp256r1
            ;;
    esac
    
    # 公钥（可选）
    local public_key_str=$(ecdsa_get_public_key "$private_key")
    local public_key_x=$(echo "$public_key_str" | cut -d' ' -f1)
    local public_key_y=$(echo "$public_key_str" | cut -d' ' -f2)
    local public_key_point=$(encode_ec_point "$public_key_x" "$public_key_y")
    
    # 组合ECPrivateKey
    local ecpk_sequence="$version$curve_oid$private_key_encoded$public_key_point"
    local ecpk_length=$(asn1_encode_length $((${#ecpk_sequence} / 2)))
    local ecpk_der=$(printf "%02X%s%s" $ASN1_TAG_SEQUENCE $ecpk_length $ecpk_sequence)
    
    # 转换为PEM
    local ecpk_base64=$(echo -n "$ecpk_der" | xxd -r -p | base64 -w64)
    pem_encode "$ecpk_base64" "EC PRIVATE KEY"
}

# 公钥PEM格式编码
encode_public_key_pem() {
    local public_key_x="$1"
    local public_key_y="$2"
    local curve_name="${3:-secp256r1}"
    
    # 编码公钥点
    local public_key_point=$(encode_ec_point "$public_key_x" "$public_key_y")
    
    # 算法标识符
    local algorithm_identifier
    case "$curve_name" in
        "secp256r1")
            algorithm_identifier="06072A8648CE3D020106082A8648CE3D030107"
            ;;
        "secp256k1")
            algorithm_identifier="06072A8648CE3D020106052B8104000A"
            ;;
        *)
            algorithm_identifier="06072A8648CE3D020106082A8648CE3D030107"
            ;;
    esac
    
    # 组合SubjectPublicKeyInfo
    local spki_sequence="$algorithm_identifier$public_key_point"
    local spki_length=$(asn1_encode_length $((${#spki_sequence} / 2)))
    local spki_der=$(printf "%02X%s%s" $ASN1_TAG_SEQUENCE $spki_length $spki_sequence)
    
    # 转换为PEM
    local spki_base64=$(echo -n "$spki_der" | xxd -r -p | base64 -w64)
    pem_encode "$spki_base64" "EC PUBLIC KEY"
}

# 编码椭圆曲线点
encode_ec_point() {
    local x="$1"
    local y="$2"
    
    # 转换为十六进制并确保偶数位
    local x_hex=$(bashmath_dec_to_hex "$x" | tr '[:lower:]' '[:upper:]')
    local y_hex=$(bashmath_dec_to_hex "$y" | tr '[:lower:]' '[:upper:]')
    
    # 补零到32字节（256位）
    while [[ ${#x_hex} -lt 64 ]]; do
        x_hex="0$x_hex"
    done
    while [[ ${#y_hex} -lt 64 ]]; do
        y_hex="0$y_hex"
    done
    
    # 组合公钥点（未压缩格式）
    local public_key_uncompressed="04$x_hex$y_hex"
    
    # 编码为BIT STRING
    local bit_string_content="00$public_key_uncompressed"  # 00表示未使用位
    local bit_string_length=$(asn1_encode_length $((${#bit_string_content} / 2)))
    
    printf "%02X%s%s" $ASN1_TAG_OCTET_STRING $bit_string_length $bit_string_content
}

# 编码八位字节串
asn1_encode_octet_string() {
    local octets="$1"
    
    local length=$((${#octets} / 2))
    local encoded_length=$(asn1_encode_length $length)
    
    printf "%02X%s%s" $ASN1_TAG_OCTET_STRING $encoded_length $octets
}

# 测试ASN.1功能
asn1_test() {
    echo "测试ASN.1编码/解码..."
    
    # 测试整数编码
    echo -e "\n测试整数编码..."
    local test_int="123456789"
    local encoded_int=$(asn1_encode_integer "$test_int")
    echo "整数 $test_int 编码为: $encoded_int"
    
    # 测试ECDSA签名编码
    echo -e "\n测试ECDSA签名编码..."
    local test_r="1234567890123456789012345678901234567890123456789012345678901234"
    local test_s="567890123456789012345678901234567890123456789012345678901234567890"
    
    local signature_b64=$(encode_ecdsa_signature "$test_r" "$test_s")
    echo "签名编码完成 (Base64): ${signature_b64:0:50}..."
    
    # 测试解码
    echo -e "\n测试签名解码..."
    local decoded_r decoded_s
    decode_ecdsa_signature "$signature_b64" decoded_r decoded_s
    
    echo "解码结果:"
    echo "r = $decoded_r"
    echo "s = $decoded_s"
    
    if [[ "$decoded_r" == "$test_r" && "$decoded_s" == "$test_s" ]]; then
        echo "✓ 编码解码验证通过"
    else
        echo "✗ 编码解码验证失败"
    fi
    
    # 测试PEM编码
    echo -e "\n测试PEM编码..."
    local pem_private=$(encode_private_key_pem "$test_r")
    echo "私钥PEM格式:"
    echo "$pem_private"
    
    echo -e "\nASN.1测试完成"
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 初始化必要的库
    source "$(dirname "${BASH_SOURCE[0]}")/ecdsa.sh"
    asn1_test
fi