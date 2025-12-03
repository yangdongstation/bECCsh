#!/bin/bash

# 纯Bash编码解码功能
# 完全摆脱外部依赖，仅使用Bash内置功能

# Base64编码表
readonly PUREBASH_BASE64_TABLE="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

# 获取字符在Base64表中的索引
purebash_base64_index() {
    local char="$1"
    case $char in
        A) echo 0 ;; B) echo 1 ;; C) echo 2 ;; D) echo 3 ;;
        E) echo 4 ;; F) echo 5 ;; G) echo 6 ;; H) echo 7 ;;
        I) echo 8 ;; J) echo 9 ;; K) echo 10 ;; L) echo 11 ;;
        M) echo 12 ;; N) echo 13 ;; O) echo 14 ;; P) echo 15 ;;
        Q) echo 16 ;; R) echo 17 ;; S) echo 18 ;; T) echo 19 ;;
        U) echo 20 ;; V) echo 21 ;; W) echo 22 ;; X) echo 23 ;;
        Y) echo 24 ;; Z) echo 25 ;; a) echo 26 ;; b) echo 27 ;;
        c) echo 28 ;; d) echo 29 ;; e) echo 30 ;; f) echo 31 ;;
        g) echo 32 ;; h) echo 33 ;; i) echo 34 ;; j) echo 35 ;;
        k) echo 36 ;; l) echo 37 ;; m) echo 38 ;; n) echo 39 ;;
        o) echo 40 ;; p) echo 41 ;; q) echo 42 ;; r) echo 43 ;;
        s) echo 44 ;; t) echo 45 ;; u) echo 46 ;; v) echo 47 ;;
        w) echo 48 ;; x) echo 49 ;; y) echo 50 ;; z) echo 51 ;;
        0) echo 52 ;; 1) echo 53 ;; 2) echo 54 ;; 3) echo 55 ;;
        4) echo 56 ;; 5) echo 57 ;; 6) echo 58 ;; 7) echo 59 ;;
        8) echo 60 ;; 9) echo 61 ;; +) echo 62 ;; /) echo 63 ;;
        =) echo -1 ;;  # 填充字符
        *) echo -2 ;;   # 无效字符
    esac
}

# 纯Bash Base64编码
purebash_base64_encode() {
    local input="$1"
    local result=""
    local len=${#input}
    
    # 处理每个3字节组
    for ((i=0; i<len; i+=3)); do
        local byte1=0 byte2=0 byte3=0
        local padding=0
        
        # 获取字节
        if [[ $i -lt $len ]]; then
            byte1=$(printf "%d" "'${input:$i:1}")
        fi
        
        if [[ $((i+1)) -lt $len ]]; then
            byte2=$(printf "%d" "'${input:$((i+1)):1}")
        else
            padding=2
        fi
        
        if [[ $((i+2)) -lt $len ]]; then
            byte3=$(printf "%d" "'${input:$((i+2)):1}")
        else
            padding=$((padding + 1))
        fi
        
        # 组合24位数据
        local combined=$(( (byte1 << 16) | (byte2 << 8) | byte3 ))
        
        # 提取6位组并编码
        for ((j=0; j<4; j++)); do
            if [[ $padding -gt 0 && $j -ge $((4-padding)) ]]; then
                result+="="
            else
                local index=$(( (combined >> (18 - j * 6)) & 0x3F ))
                result+="${PUREBASH_BASE64_TABLE:$index:1}"
            fi
        done
    done
    
    echo "$result"
}

# 纯Bash Base64解码
purebash_base64_decode() {
    local input="$1"
    local result=""
    local len=${#input}
    
    # 移除换行符和空格
    input="${input//[$'\n\r ']/}"
    len=${#input}
    
    # 处理每个4字符组
    for ((i=0; i<len; i+=4)); do
        local char1="${input:$i:1}"
        local char2="${input:$((i+1)):1}"
        local char3="${input:$((i+2)):1}"
        local char4="${input:$((i+3)):1}"
        
        local index1=$(purebash_base64_index "$char1")
        local index2=$(purebash_base64_index "$char2")
        local index3=$(purebash_base64_index "$char3")
        local index4=$(purebash_base64_index "$char4")
        
        # 组合24位数据
        local combined=$(( (index1 << 18) | (index2 << 12) | (index3 << 6) | index4 ))
        
        # 提取字节
        if [[ $index3 -ne -1 ]]; then
            result+=$(printf "%b" $(( (combined >> 16) & 0xFF )))
        fi
        
        if [[ $index4 -ne -1 ]]; then
            result+=$(printf "%b" $(( (combined >> 8) & 0xFF )))
            result+=$(printf "%b" $(( combined & 0xFF )))
        fi
    done
    
    echo "$result"
}

# 字符转ASCII码
purebash_ord() {
    local char="$1"
    printf "%d" "'$char"
}

# ASCII码转字符
purebash_chr() {
    local code=$1
    printf "%b" "$code"
}

# 十六进制字符串转二进制
purebash_hex_to_bytes() {
    local hex="$1"
    local result=""
    
    # 移除空格和分隔符
    hex="${hex// /}"
    hex="${hex//:/}"
    
    # 检查长度是否为偶数
    local len=${#hex}
    if [[ $((len % 2)) -ne 0 ]]; then
        hex="0$hex"
        len=${#hex}
    fi
    
    # 转换每两个十六进制字符为一个字节
    for ((i=0; i<len; i+=2)); do
        local byte_hex="${hex:$i:2}"
        local byte_dec=$((16#$byte_hex))
        result+=$(printf "%b" "$byte_dec")
    done
    
    echo "$result"
}

# 二进制转十六进制字符串
purebash_bytes_to_hex() {
    local input="$1"
    local result=""
    
    local len=${#input}
    for ((i=0; i<len; i++)); do
        local char="${input:$i:1}"
        local ord=$(printf "%d" "'$char")
        result+=$(printf "%02x" "$ord")
    done
    
    echo "$result"
}

# 位操作函数
purebash_bit_and() {
    local a=$1 b=$2
    echo $((a & b))
}

purebash_bit_or() {
    local a=$1 b=$2
    echo $((a | b))
}

purebash_bit_xor() {
    local a=$1 b=$2
    echo $((a ^ b))
}

purebash_bit_not() {
    local a=$1
    echo $((~a))
}

purebash_bit_shift_left() {
    local a=$1 shift=$2
    echo $((a << shift))
}

purebash_bit_shift_right() {
    local a=$1 shift=$2
    echo $((a >> shift))
}

# 字节异或操作
purebash_bytes_xor() {
    local bytes1="$1"
    local bytes2="$2"
    local result=""
    
    local len1=${#bytes1}
    local len2=${#bytes2}
    local min_len=$((len1 < len2 ? len1 : len2))
    
    for ((i=0; i<min_len; i++)); do
        local byte1=$(printf "%d" "'${bytes1:$i:1}")
        local byte2=$(printf "%d" "'${bytes2:$i:1}")
        local xor_result=$((byte1 ^ byte2))
        result+=$(printf "%b" "$xor_result")
    done
    
    echo "$result"
}

# 字节反转（小端转大端）
purebash_bytes_reverse() {
    local input="$1"
    local result=""
    
    local len=${#input}
    for ((i=len-1; i>=0; i--)); do
        result+="${input:$i:1}"
    done
    
    echo "$result"
}

# 零填充
purebash_zero_pad() {
    local input="$1"
    local target_length=$2
    
    local current_length=${#input}
    if [[ $current_length -ge $target_length ]]; then
        echo "$input"
        return
    fi
    
    local padding_length=$((target_length - current_length))
    local padding=""
    
    for ((i=0; i<padding_length; i++)); do
        padding+="\x00"
    done
    
    echo "${padding}${input}"
}

# 移除填充
purebash_remove_pad() {
    local input="$1"
    local result="$input"
    
    # 移除前导零字节
    while [[ ${#result} -gt 0 ]]; do
        local first_byte=$(printf "%d" "'${result:0:1}")
        if [[ $first_byte -eq 0 ]]; then
            result="${result:1}"
        else
            break
        fi
    done
    
    echo "$result"
}

# 测试所有编码解码功能
purebash_encoding_test() {
    echo "=== 纯Bash编码解码功能测试 ==="
    
    echo "Base64编码测试:"
    local test_strings=(
        "Hello, World!"
        "abc"
        "The quick brown fox jumps over the lazy dog"
        ""
        "1234567890"
    )
    
    for str in "${test_strings[@]}"; do
        echo "  原始: '$str'"
        local encoded=$(purebash_base64_encode "$str")
        echo "  Base64: '$encoded'"
        local decoded=$(purebash_base64_decode "$encoded")
        echo "  解码: '$decoded'"
        if [[ "$str" == "$decoded" ]]; then
            echo "  ✅ 测试通过"
        else
            echo "  ❌ 测试失败"
        fi
        echo
    done
    
    echo "十六进制转换测试:"
    local hex_test="48656c6c6f20576f726c6421"  # "Hello World!"
    echo "  十六进制: '$hex_test'"
    local bytes=$(purebash_hex_to_bytes "$hex_test")
    echo "  二进制: '$bytes'"
    local hex_back=$(purebash_bytes_to_hex "$bytes")
    echo "  转回十六进制: '$hex_back'"
    if [[ "$hex_test" == "$hex_back" ]]; then
        echo "  ✅ 十六进制转换测试通过"
    else
        echo "  ❌ 十六进制转换测试失败"
    fi
    
    echo
    echo "位操作测试:"
    local a=0xFF b=0x0F
    echo "  a = 0xFF, b = 0x0F"
    echo "  a & b = 0x$(printf "%02x" $(purebash_bit_and $a $b))"
    echo "  a | b = 0x$(printf "%02x" $(purebash_bit_or $a $b))"
    echo "  a ^ b = 0x$(printf "%02x" $(purebash_bit_xor $a $b))"
    echo "  ~a = 0x$(printf "%08x" $(purebash_bit_not $a))"
    echo "  a << 2 = 0x$(printf "%04x" $(purebash_bit_shift_left $a 2))"
    echo "  a >> 2 = 0x$(printf "%02x" $(purebash_bit_shift_right $a 2))"
    
    echo
    echo "字节异或测试:"
    local data1="Hello"
    local data2="World"
    local xor_result=$(purebash_bytes_xor "$data1" "$data2")
    echo "  数据1: '$data1'"
    echo "  数据2: '$data2'"
    echo "  XOR结果长度: ${#xor_result} 字节"
    echo "  XOR结果十六进制: $(purebash_bytes_to_hex "$xor_result")"
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    purebash_encoding_test
fi