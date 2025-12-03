#!/bin/bash
# asn1.sh - ASN.1编码/解码库
# 实现基本的ASN.1 DER编码格式

# ASN.1标签定义
readonly ASN1_TAG_BOOLEAN=0x01
readonly ASN1_TAG_INTEGER=0x02
readonly ASN1_TAG_BIT_STRING=0x03
readonly ASN1_TAG_OCTET_STRING=0x04
readonly ASN1_TAG_NULL=0x05
readonly ASN1_TAG_OBJECT_IDENTIFIER=0x06
readonly ASN1_TAG_SEQUENCE=0x30
readonly ASN1_TAG_SET=0x31
readonly ASN1_TAG_PRINTABLE_STRING=0x13
readonly ASN1_TAG_IA5_STRING=0x16
readonly ASN1_TAG_UTC_TIME=0x17
readonly ASN1_TAG_GENERALIZED_TIME=0x18

# ASN.1类定义
readonly ASN1_CLASS_UNIVERSAL=0x00
readonly ASN1_CLASS_APPLICATION=0x40
readonly ASN1_CLASS_CONTEXT_SPECIFIC=0x80
readonly ASN1_CLASS_PRIVATE=0xC0

# 长度编码常量
readonly ASN1_LONG_FORM_FLAG=0x80

# 初始化ASN.1库
init_asn1() {
    log_professional INFO "初始化ASN.1编码库..."
    
    # 预定义OID
    declare -gA ASN1_OID_MAP
    ASN1_OID_MAP["1.2.840.10045.2.1"]="ecPublicKey"  # ECDSA公钥
    ASN1_OID_MAP["1.2.840.10045.3.1.7"]="prime256v1"  # secp256r1
    ASN1_OID_MAP["1.3.132.0.10"]="secp256k1"          # secp256k1
    ASN1_OID_MAP["1.3.132.0.34"]="secp384r1"          # secp384r1
    ASN1_OID_MAP["1.2.840.10045.4.1"]="ecdsa-with-SHA1"
    ASN1_OID_MAP["1.2.840.10045.4.3.2"]="ecdsa-with-SHA256"
    ASN1_OID_MAP["1.2.840.10045.4.3.3"]="ecdsa-with-SHA384"
    ASN1_OID_MAP["1.2.840.10045.4.3.4"]="ecdsa-with-SHA512"
    
    log_professional INFO "ASN.1编码库初始化完成"
}

# 整数到十六进制字符串
int_to_hex() {
    local value="$1"
    local min_length="${2:-0}"
    
    # 转换为十六进制
    local hex=$(printf "%x" "$value")
    
    # 确保偶数长度
    if [[ $(( ${#hex} % 2 )) -eq 1 ]]; then
        hex="0${hex}"
    fi
    
    # 填充到最小长度
    while [[ ${#hex} -lt $min_length ]]; do
        hex="00${hex}"
    done
    
    echo "$hex"
}

# 十六进制字符串到整数
hex_to_int() {
    local hex="$1"
    printf "%d" "0x$hex"
}

# 编码长度字段
encode_length() {
    local length="$1"
    
    if [[ $length -lt 128 ]]; then
        # 短格式
        int_to_hex "$length"
    else
        # 长格式
        local length_hex=$(int_to_hex "$length")
        local length_bytes=$(( ${#length_hex} / 2 ))
        local first_byte=$((length_bytes | ASN1_LONG_FORM_FLAG))
        
        echo "$(int_to_hex "$first_byte")${length_hex}"
    fi
}

# 解码长度字段
decode_length() {
    local data="$1"
    local pos="$2"
    
    local first_byte=$(hex_to_int "${data:pos:2}")
    
    if [[ $((first_byte & ASN1_LONG_FORM_FLAG)) -eq 0 ]]; then
        # 短格式
        echo "$((first_byte)) $((pos + 2))"
    else
        # 长格式
        local length_bytes=$((first_byte & 0x7F))
        local length=0
        
        for ((i=0; i<length_bytes; i++)); do
            local byte=$(hex_to_int "${data:pos+2+i*2:2}")
            length=$((length * 256 + byte))
        done
        
        echo "$length $((pos + 2 + length_bytes * 2))"
    fi
}

# 编码整数
encode_integer() {
    local value="$1"
    
    # 处理负数（使用补码表示）
    if [[ $value -lt 0 ]]; then
        value=$((value + 256))  # 简化处理
    fi
    
    # 转换为十六进制
    local hex_value=$(int_to_hex "$value")
    
    # 移除前导零，但保留至少一个字节
    while [[ ${#hex_value} -gt 2 ]] && [[ ${hex_value:0:2} == "00" ]]; do
        hex_value=${hex_value:2}
    done
    
    # 如果最高位是1，添加前导零
    if [[ $(hex_to_int "${hex_value:0:2}") -ge 128 ]]; then
        hex_value="00${hex_value}"
    fi
    
    local length=$((${#hex_value} / 2))
    local encoded_length=$(encode_length "$length")
    
    echo "$(int_to_hex $ASN1_TAG_INTEGER)${encoded_length}${hex_value}"
}

# 解码整数
decode_integer() {
    local data="$1"
    local pos="$2"
    
    # 检查标签
    local tag=$(hex_to_int "${data:pos:2}")
    if [[ $tag -ne $ASN1_TAG_INTEGER ]]; then
        echo "错误：不是整数标签" >&2
        return 1
    fi
    
    # 解码长度
    local length_info
    read -r length new_pos <<< $(decode_length "$data" "$((pos + 2))")
    
    # 提取值
    local value_hex=${data:new_pos:length*2}
    local value=$(hex_to_int "$value_hex")
    
    echo "$value $((new_pos + length * 2))"
}

# 编码八位字节串
encode_octet_string() {
    local data="$1"
    
    # 计算长度
    local length=$((${#data} / 2))
    local encoded_length=$(encode_length "$length")
    
    echo "$(int_to_hex $ASN1_TAG_OCTET_STRING)${encoded_length}${data}"
}

# 解码八位字节串
decode_octet_string() {
    local data="$1"
    local pos="$2"
    
    # 检查标签
    local tag=$(hex_to_int "${data:pos:2}")
    if [[ $tag -ne $ASN1_TAG_OCTET_STRING ]]; then
        echo "错误：不是八位字节串标签" >&2
        return 1
    fi
    
    # 解码长度
    local length_info
    read -r length new_pos <<< $(decode_length "$data" "$((pos + 2))")
    
    # 提取值
    local value=${data:new_pos:length*2}
    
    echo "$value $((new_pos + length * 2))"
}

# 编码对象标识符
encode_oid() {
    local oid="$1"
    
    # 简化的OID编码
    local encoded_oid=""
    
    # 这里应该实现完整的OID编码规则
    # 为简化，我们使用预定义的OID映射
    
    case "$oid" in
        "1.2.840.10045.2.1")
            encoded_oid="2a8648ce3d0201"
            ;;
        "1.2.840.10045.3.1.7")
            encoded_oid="2a8648ce3d030107"
            ;;
        "1.3.132.0.10")
            encoded_oid="2b8104000a"
            ;;
        "1.3.132.0.34")
            encoded_oid="2b81040022"
            ;;
        *)
            echo "错误：不支持的OID: $oid" >&2
            return 1
            ;;
    esac
    
    local length=$((${#encoded_oid} / 2))
    local encoded_length=$(encode_length "$length")
    
    echo "$(int_to_hex $ASN1_TAG_OBJECT_IDENTIFIER)${encoded_length}${encoded_oid}"
}

# 编码序列
encode_sequence() {
    local elements=("$@")
    local sequence_data=""
    
    for element in "${elements[@]}"; do
        sequence_data="${sequence_data}${element}"
    done
    
    local length=$((${#sequence_data} / 2))
    local encoded_length=$(encode_length "$length")
    
    echo "$(int_to_hex $ASN1_TAG_SEQUENCE)${encoded_length}${sequence_data}"
}

# 编码ECDSA签名
encode_ecdsa_signature() {
    local r="$1"
    local s="$2"
    
    # 确保r和s是正确长度（32字节对于256位曲线）
    local r_hex=$(bigint_to_hex "$r")
    local s_hex=$(bigint_to_hex "$s")
    
    # 填充到64个十六进制字符（32字节）
    while [[ ${#r_hex} -lt 64 ]]; do
        r_hex="00${r_hex}"
    done
    
    while [[ ${#s_hex} -lt 64 ]]; do
        s_hex="00${s_hex}"
    done
    
    # 编码r和s为整数
    local r_encoded=$(encode_integer "$(hex_to_int "$r_hex")")
    local s_encoded=$(encode_integer "$(hex_to_int "$s_hex")")
    
    # 编码为序列
    encode_sequence "$r_encoded" "$s_encoded"
}

# 解码ECDSA签名
decode_ecdsa_signature() {
    local signature_der="$1"
    local pos="$2"
    
    # 检查序列标签
    local tag=$(hex_to_int "${signature_der:pos:2}")
    if [[ $tag -ne $ASN1_TAG_SEQUENCE ]]; then
        echo "错误：不是序列标签" >&2
        return 1
    fi
    
    # 解码序列长度
    local length_info
    read -r length new_pos <<< $(decode_length "$signature_der" "$((pos + 2))")
    
    # 解码r
    local r_info
    read -r r_value r_pos <<< $(decode_integer "$signature_der" "$new_pos")
    
    # 解码s
    local s_info
    read -r s_value s_pos <<< $(decode_integer "$signature_der" "$r_pos")
    
    # 转换为十六进制字符串
    local r_hex=$(int_to_hex "$r_value" 64)
    local s_hex=$(int_to_hex "$s_value" 64)
    
    echo "${r_hex}${s_hex} $s_pos"
}

# 编码EC私钥（简化版）
encode_ec_private_key() {
    local private_key="$1"
    local curve_oid="$2"
    local public_key_x="$3"
    local public_key_y="$4"
    
    # 版本号 (1)
    local version_encoded=$(encode_integer "1")
    
    # 私钥
    local private_key_hex=$(bigint_to_hex "$private_key")
    # 填充到正确长度
    while [[ ${#private_key_hex} -lt 64 ]]; do
        private_key_hex="00${private_key_hex}"
    done
    local private_key_encoded=$(encode_octet_string "$private_key_hex")
    
    # 曲线OID
    local oid_encoded=$(encode_oid "$curve_oid")
    
    # 公钥（可选）
    local public_key_point="04$(bigint_to_hex "$public_key_x")$(bigint_to_hex "$public_key_y")"
    # 填充公钥
    while [[ ${#public_key_point} -lt 130 ]]; do  # 04 + 32字节x + 32字节y
        public_key_point="${public_key_point}00"
    done
    local public_key_encoded=$(encode_octet_string "$public_key_point")
    
    # 构建序列
    local sequence_data="${version_encoded}${private_key_encoded}${oid_encoded}${public_key_encoded}"
    local length=$((${#sequence_data} / 2))
    local encoded_length=$(encode_length "$length")
    
    # 添加EC私钥特定头部
    local ec_private_key_header="$(int_to_hex $ASN1_TAG_SEQUENCE)${encoded_length}${sequence_data}"
    
    echo "$ec_private_key_header"
}

# 编码EC公钥（简化版）
encode_ec_public_key() {
    local public_key_x="$1"
    local public_key_y="$2"
    local curve_oid="$3"
    
    # 算法标识符
    local algorithm_oid=$(encode_oid "1.2.840.10045.2.1")  # ecPublicKey
    local parameters=$(encode_oid "$curve_oid")
    local algorithm_identifier=$(encode_sequence "$algorithm_oid" "$parameters")
    
    # 公钥点
    local public_key_point="04$(bigint_to_hex "$public_key_x")$(bigint_to_hex "$public_key_y")"
    # 确保正确长度
    while [[ ${#public_key_point} -lt 130 ]]; do
        public_key_point="${public_key_point}00"
    done
    local public_key_bit_string=$(encode_octet_string "$public_key_point")
    
    # 构建公钥序列
    local subject_public_key_info=$(encode_sequence "$algorithm_identifier" "$public_key_bit_string")
    
    echo "$subject_public_key_info"
}

# 将DER编码转换为PEM格式
der_to_pem() {
    local der_data="$1"
    local pem_type="$2"
    
    local pem_header="-----BEGIN ${pem_type}-----"
    local pem_footer="-----END ${pem_type}-----"
    
    # Base64编码（简化版，实际应该使用真正的Base64）
    local base64_data=$(echo -n "$der_data" | base64 2>/dev/null || echo "$der_data")
    
    # 格式化PEM
    echo "$pem_header"
    echo "$base64_data"
    echo "$pem_footer"
}

# 将PEM格式转换为DER编码
pem_to_der() {
    local pem_data="$1"
    
    # 移除PEM头部和尾部
    local der_data=$(echo "$pem_data" | grep -v "-----BEGIN" | grep -v "-----END" | tr -d '\n\r ')
    
    # Base64解码（简化版）
    echo -n "$der_data" | base64 -d 2>/dev/null || echo "$der_data"
}

# 测试ASN.1编码/解码
test_asn1() {
    log_professional INFO "测试ASN.1编码/解码..."
    
    # 测试整数编码
    local int_encoded=$(encode_integer "12345")
    local int_decoded
    read -r int_value int_pos <<< $(decode_integer "$int_encoded" "0")
    
    if [[ $int_value -ne 12345 ]]; then
        log_professional ERROR "整数编码/解码测试失败"
        return 1
    fi
    
    # 测试序列编码
    local seq1=$(encode_integer "100")
    local seq2=$(encode_integer "200")
    local seq_encoded=$(encode_sequence "$seq1" "$seq2")
    
    log_professional INFO "ASN.1测试通过"
    return 0
}

# 初始化ASN.1库
init_asn1