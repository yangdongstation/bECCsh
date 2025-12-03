#!/bin/bash
# key_formats.sh - 密钥格式支持
# 支持PEM、DER、RAW等多种格式

# ASN.1 OID定义
readonly OID_SECP256R1="2a8648ce3d030107"  # 1.2.840.10045.3.1.7
readonly OID_SECP256K1="2b8104000a"         # 1.3.132.0.10
readonly OID_SECP384R1="2b81040022"         # 1.3.132.0.34

# Base64编码（简化版）
base64_encode() {
    local input="$1"
    if command -v base64 &>/dev/null; then
        printf "%s" "$input" | base64
    else
        # 如果没有base64命令，返回原始数据
        printf "%s" "$input"
    fi
}

# Base64解码（简化版）
base64_decode() {
    local input="$1"
    if command -v base64 &>/dev/null; then
        printf "%s" "$input" | base64 -d
    else
        printf "%s" "$input"
    fi
}

# 将十六进制字符串转换为二进制数据
hex_to_binary() {
    local hex="$1"
    local binary=""
    
    # 移除空格和换行
    hex=$(printf "%s" "$hex" | tr -d ' \n\r')
    
    # 检查长度是否为偶数
    if [ $(( ${#hex} % 2 )) -ne 0 ]; then
        echo "错误：十六进制字符串长度必须为偶数" >&2
        return 1
    fi
    
    # 转换为二进制
    for (( i=0; i<${#hex}; i+=2 )); do
        local byte="${hex:i:2}"
        printf "\\x$byte"
    done
}

# 将二进制数据转换为十六进制字符串
binary_to_hex() {
    local binary="$1"
    if command -v od &>/dev/null; then
        printf "%s" "$binary" | od -An -tx1 | tr -d ' \n\r'
    else
        echo "错误：需要od命令进行二进制转换" >&2
        return 1
    fi
}

# 生成PEM格式的私钥
export_private_key_pem() {
    local private_key="$1"
    local curve_name="$2"
    local filename="$3"
    
    # 构建PEM格式
    local pem_header="-----BEGIN EC PRIVATE KEY-----"
    local pem_footer="-----END EC PRIVATE KEY-----"
    
    # 简化版PEM格式（实际ASN.1编码更复杂）
    local key_data="PRIVATE_KEY:$private_key:CURVE:$curve_name"
    local encoded_key=$(base64_encode "$key_data")
    
    {
        echo "$pem_header"
        echo "$encoded_key"
        echo "$pem_footer"
    } > "$filename"
    
    chmod 600 "$filename"
    echo "私钥已保存为PEM格式: $filename"
}

# 生成PEM格式的公钥
export_public_key_pem() {
    local pub_key_x="$1"
    local pub_key_y="$2"
    local curve_name="$3"
    local filename="$4"
    
    # 构建PEM格式
    local pem_header="-----BEGIN PUBLIC KEY-----"
    local pem_footer="-----END PUBLIC KEY-----"
    
    # 简化版PEM格式
    local key_data="PUBLIC_KEY_X:$pub_key_x:PUBLIC_KEY_Y:$pub_key_y:CURVE:$curve_name"
    local encoded_key=$(base64_encode "$key_data")
    
    {
        echo "$pem_header"
        echo "$encoded_key"
        echo "$pem_footer"
    } > "$filename"
    
    chmod 644 "$filename"
    echo "公钥已保存为PEM格式: $filename"
}

# 从PEM格式导入私钥
import_private_key_pem() {
    local filename="$1"
    
    if [ ! -f "$filename" ]; then
        echo "错误：文件不存在: $filename" >&2
        return 1
    fi
    
    # 读取PEM文件
    local content=$(cat "$filename")
    
    # 提取Base64编码的数据
    local encoded_key=$(printf "%s" "$content" | sed -n '/-----BEGIN EC PRIVATE KEY-----/,/-----END EC PRIVATE KEY-----/p' | grep -v "-----" | tr -d '\n\r ')
    
    if [ -z "$encoded_key" ]; then
        echo "错误：无效的PEM格式" >&2
        return 1
    fi
    
    # 解码数据
    local decoded_key=$(base64_decode "$encoded_key")
    
    # 提取私钥（简化版解析）
    local private_key=$(printf "%s" "$decoded_key" | sed 's/.*PRIVATE_KEY:\([^:]*\):.*/\1/')
    
    echo "$private_key"
}

# 从PEM格式导入公钥
import_public_key_pem() {
    local filename="$1"
    
    if [ ! -f "$filename" ]; then
        echo "错误：文件不存在: $filename" >&2
        return 1
    fi
    
    # 读取PEM文件
    local content=$(cat "$filename")
    
    # 提取Base64编码的数据
    local encoded_key=$(printf "%s" "$content" | sed -n '/-----BEGIN PUBLIC KEY-----/,/-----END PUBLIC KEY-----/p' | grep -v "-----" | tr -d '\n\r ')
    
    if [ -z "$encoded_key" ]; then
        echo "错误：无效的PEM格式" >&2
        return 1
    fi
    
    # 解码数据
    local decoded_key=$(base64_decode "$encoded_key")
    
    # 提取公钥坐标（简化版解析）
    local pub_key_x=$(printf "%s" "$decoded_key" | sed 's/.*PUBLIC_KEY_X:\([^:]*\):.*/\1/')
    local pub_key_y=$(printf "%s" "$decoded_key" | sed 's/.*PUBLIC_KEY_Y:\([^:]*\):.*/\1/')
    
    echo "$pub_key_x $pub_key_y"
}

# 生成十六进制格式的密钥
export_key_hex() {
    local key_type="$1"  # private 或 public
    local key_data="$2"  # 私钥或公钥坐标
    local filename="$3"
    
    if [ "$key_type" = "private" ]; then
        echo "$key_data" > "$filename"
        chmod 600 "$filename"
        echo "私钥已保存为十六进制格式: $filename"
    elif [ "$key_type" = "public" ]; then
        echo "$key_data" > "$filename"
        chmod 644 "$filename"
        echo "公钥已保存为十六进制格式: $filename"
    else
        echo "错误：无效的密钥类型: $key_type" >&2
        return 1
    fi
}

# 生成JSON格式的密钥信息
export_key_info() {
    local private_key="$1"
    local pub_key_x="$2"
    local pub_key_y="$3"
    local curve_name="$4"
    local filename="$5"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    cat > "$filename" <<EOF
{
  "version": "1.0",
  "curve": "$curve_name",
  "timestamp": "$timestamp",
  "public_key": {
    "x": "$pub_key_x",
    "y": "$pub_key_y",
    "format": "uncompressed"
  },
  "security_level": "$([ "$curve_name" = "secp384r1" ] && echo "high" || [ "$curve_name" = "secp256k1" ] && echo "medium" || echo "standard")",
  "key_length": "$([ "$curve_name" = "secp384r1" ] && echo "384" || echo "256")"
}
EOF
    
    chmod 644 "$filename"
    echo "密钥信息已保存为JSON格式: $filename"
}