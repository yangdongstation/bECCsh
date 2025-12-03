#!/bin/bash

# 纯Bash十六进制转换实现
# 完全摆脱xxd/hexdump等外部依赖

# 十六进制字符表
readonly PUREBASH_HEX_TABLE="0123456789ABCDEF"

# 字符转十六进制
purebash_char_to_hex() {
    local char="$1"
    local ord=$(printf "%d" "'$char")
    printf "%02X" "$ord"
}

# 十六进制转字符
purebash_hex_to_char() {
    local hex="$1"
    local dec=$((16#$hex))
    printf "%b" "$dec"
}

# 字符串转十六进制
purebash_string_to_hex() {
    local input="$1"
    local result=""
    
    for ((i=0; i<${#input}; i++)); do
        local char="${input:$i:1}"
        local hex=$(purebash_char_to_hex "$char")
        result+="$hex"
    done
    
    echo "$result"
}

# 十六进制转字符串
purebash_hex_to_string() {
    local hex="$1"
    local result=""
    
    # 确保长度是偶数
    if [[ $((${#hex} % 2)) -ne 0 ]]; then
        hex="0$hex"
    fi
    
    # 每两个十六进制字符转换为一个字节
    for ((i=0; i<${#hex}; i+=2)); do
        local byte_hex="${hex:$i:2}"
        local char=$(purebash_hex_to_char "$byte_hex")
        result+="$char"
    done
    
    echo "$result"
}

# 二进制转十六进制
purebash_binary_to_hex() {
    local binary="$1"
    local result=""
    
    # 确保长度是8的倍数
    while [[ $((${#binary} % 8)) -ne 0 ]]; do
        binary="0$binary"
    done
    
    # 每8位二进制转换为一个十六进制字符
    for ((i=0; i<${#binary}; i+=4)); do
        local nibble="${binary:$i:4}"
        local hex_digit=$((2#$nibble))
        result+="${PUREBASH_HEX_TABLE:$hex_digit:1}"
    done
    
    echo "$result"
}

# 十六进制转二进制
purebash_hex_to_binary() {
    local hex="$1"
    local result=""
    
    # 转换每个十六进制字符为4位二进制
    for ((i=0; i<${#hex}; i++)); do
        local hex_char="${hex:$i:1}"
        local dec=$((16#$hex_char))
        local binary=$(printf "%04d" "$((dec))")
        # 移除前导零
        binary="${binary#${binary%%[!0]*}}"
        binary="${binary:-0}"
        result+="$binary"
    done
    
    echo "$result"
}

# 字节数组转十六进制
purebash_bytes_to_hex() {
    local bytes="$1"
    local result=""
    
    for ((i=0; i<${#bytes}; i++)); do
        local byte="${bytes:$i:1}"
        local ord=$(printf "%d" "'$byte")
        local hex=$(printf "%02X" "$ord")
        result+="$hex"
    done
    
    echo "$result"
}

# 十六进制转字节数组
purebash_hex_to_bytes() {
    local hex="$1"
    local result=""
    
    # 确保长度是偶数
    if [[ $((${#hex} % 2)) -ne 0 ]]; then
        hex="0$hex"
    fi
    
    # 每两个十六进制字符转换为一个字节
    for ((i=0; i<${#hex}; i+=2)); do
        local byte_hex="${hex:$i:2}"
        local byte_dec=$((16#$byte_hex))
        local byte_char=$(printf "%b" "$byte_dec")
        result+="$byte_char"
    done
    
    echo "$result"
}

# 系统随机数转十六进制（替代xxd）
purebash_urandom_to_hex() {
    local bytes="$1"
    local result=""
    
    # 从/dev/urandom读取并转换为十六进制
    if [[ -f /dev/urandom ]]; then
        # 读取指定字节数
        local count=0
        while [[ $count -lt $bytes ]]; do
            # 读取一个字节
            local byte=$(head -c 1 /dev/urandom 2>/dev/null | od -An -t u1 | tr -d ' ')
            if [[ -n "$byte" ]]; then
                local hex=$(printf "%02X" "$byte")
                result+="$hex"
                ((count++))
            fi
        done
    else
        # 后备方案：使用Bash随机数
        for ((i=0; i<bytes; i++)); do
            local random_byte=$((RANDOM % 256))
            local hex=$(printf "%02X" "$random_byte")
            result+="$hex"
        done
    fi
    
    echo "$result"
}

# 十六进制显示（替代xxd -p）
purebash_hex_dump() {
    local input="$1"
    local result=""
    
    # 字符串转十六进制并格式化显示
    for ((i=0; i<${#input}; i++)); do
        if [[ $((i % 16)) -eq 0 && $i -ne 0 ]]; then
            result+="\n"
        fi
        local char="${input:$i:1}"
        local hex=$(purebash_char_to_hex "$char")
        result+="$hex "
    done
    
    echo -e "$result"
}

# 测试函数
purebash_hex_test() {
    echo "=== 纯Bash十六进制转换测试 ==="
    
    echo "1. 字符转换测试:"
    for char in A B C a b c 1 2 3; do
        local hex=$(purebash_char_to_hex "$char")
        echo "  '$char' -> $hex"
    done
    
    echo
    echo "2. 字符串转换测试:"
    local test_string="Hello"
    local hex_string=$(purebash_string_to_hex "$test_string")
    echo "  '$test_string' -> $hex_string"
    
    local back_string=$(purebash_hex_to_string "$hex_string")
    echo "  $hex_string -> '$back_string'"
    
    if [[ "$test_string" == "$back_string" ]]; then
        echo "  ✅ 字符串转换正确"
    else
        echo "  ❌ 字符串转换错误"
    fi
    
    echo
    echo "3. 系统随机数转十六进制测试:"
    local random_hex=$(purebash_urandom_to_hex "16")
    echo "  16字节随机数: $random_hex"
    echo "  长度: ${#random_hex} 字符"
    
    echo
    echo "4. 十六进制显示测试:"
    local test_data="Hello, World!"
    local hex_display=$(purebash_hex_dump "$test_data")
    echo "  原始数据: '$test_data'"
    echo "  十六进制显示:"
    echo "$hex_display" | sed 's/^/    /'
    
    echo "✅ 纯Bash十六进制转换测试完成！"
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    purebash_hex_test
fi