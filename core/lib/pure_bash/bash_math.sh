#!/bin/bash
# Bash Math - 纯Bash数学运算库
# 提供数学运算功能，替代bc依赖

set -euo pipefail

# 导入保护 - 防止重复定义
if [[ -n "${BASH_MATH_LOADED:-}" ]]; then
    return 0
fi
readonly BASH_MATH_LOADED=1

# 十六进制转十进制
bashmath_hex_to_dec() {
    local hex="$1"
    hex=${hex#0x}  # 移除0x前缀
    hex=${hex#0X}  # 移除0X前缀
    hex="${hex^^}"  # 转换为大写
    
    # 验证十六进制格式
    if [[ ! "$hex" =~ ^[0-9A-F]+$ ]]; then
        echo "0"
        return 1
    fi
    
    local dec=0
    local digit
    local value
    local i
    
    # 逐字符转换
    for ((i=0; i<${#hex}; i++)); do
        digit="${hex:$i:1}"
        case "$digit" in
            0) value=0 ;;
            1) value=1 ;;
            2) value=2 ;;
            3) value=3 ;;
            4) value=4 ;;
            5) value=5 ;;
            6) value=6 ;;
            7) value=7 ;;
            8) value=8 ;;
            9) value=9 ;;
            A) value=10 ;;
            B) value=11 ;;
            C) value=12 ;;
            D) value=13 ;;
            E) value=14 ;;
            F) value=15 ;;
        esac
        dec=$((dec * 16 + value))
    done
    
    echo "$dec"
}

# 十进制转十六进制
bashmath_dec_to_hex() {
    local dec="$1"
    
    # 处理负数
    local negative=0
    if [[ "$dec" =~ ^- ]]; then
        negative=1
        dec=${dec#-}
    fi
    
    # 处理0
    if [[ "$dec" == "0" ]]; then
        echo "0"
        return 0
    fi
    
    # 验证数字格式
    if [[ ! "$dec" =~ ^[0-9]+$ ]]; then
        echo "0"
        return 1
    fi
    
    local hex=""
    local remainder
    local digit
    
    # 转换为十六进制
    while [[ "$dec" -gt "0" ]]; do
        remainder=$((dec % 16))
        dec=$((dec / 16))
        
        case "$remainder" in
            0) digit="0" ;;
            1) digit="1" ;;
            2) digit="2" ;;
            3) digit="3" ;;
            4) digit="4" ;;
            5) digit="5" ;;
            6) digit="6" ;;
            7) digit="7" ;;
            8) digit="8" ;;
            9) digit="9" ;;
            10) digit="A" ;;
            11) digit="B" ;;
            12) digit="C" ;;
            13) digit="D" ;;
            14) digit="E" ;;
            15) digit="F" ;;
        esac
        
        hex="${digit}${hex}"
    done
    
    # 处理负数
    if [[ $negative -eq 1 ]]; then
        hex="-${hex}"
    fi
    
    echo "$hex"
}

# 对数计算（用于位长度估算）
bashmath_log2() {
    local n="$1"
    
    # 验证输入
    if [[ ! "$n" =~ ^[0-9]+$ ]] || [[ "$n" -le "0" ]]; then
        echo "0"
        return 1
    fi
    
    local log2=0
    local temp_n="$n"
    
    while [[ "$temp_n" -gt "1" ]]; do
        temp_n=$((temp_n / 2))
        log2=$((log2 + 1))
    done
    
    echo "$log2"
    return 0
}

# 浮点数除法（简化版本）
bashmath_divide_float() {
    local dividend="$1"
    local divisor="$2"
    local precision="${3:-6}"
    
    # 验证输入
    if [[ ! "$dividend" =~ ^[0-9]+$ ]] || [[ ! "$divisor" =~ ^[0-9]+$ ]]; then
        echo "0"
        return 1
    fi
    
    if [[ "$divisor" == "0" ]]; then
        echo "0"
        return 1
    fi
    
    # 扩展精度计算
    local extended_dividend="${dividend}"
    for ((i=0; i<precision; i++)); do
        extended_dividend="${extended_dividend}0"
    done
    
    local result=$((extended_dividend / divisor))
    
    # 格式化输出
    if [[ ${#result} -le "$precision" ]]; then
        local padding=""
        for ((i=0; i<precision-${#result}+1; i++)); do
            padding="${padding}0"
        done
        result="${padding}${result}"
    fi
    
    local int_part=${result:0:-$precision}
    local frac_part=${result: -$precision}
    
    # 移除小数部分末尾的0
    frac_part=${frac_part%%0*}
    
    if [[ -n "$frac_part" ]]; then
        echo "${int_part}.${frac_part}"
    else
        echo "$int_part"
    fi
}

# 二进制转十进制
bashmath_binary_to_dec() {
    local binary="$1"
    
    # 验证二进制格式
    if [[ ! "$binary" =~ ^[01]+$ ]]; then
        echo "0"
        return 1
    fi
    
    local dec=0
    local i
    
    for ((i=0; i<${#binary}; i++)); do
        dec=$((dec * 2 + ${binary:$i:1}))
    done
    
    echo "$dec"
}

# 十进制转二进制
bashmath_dec_to_binary() {
    local dec="$1"
    
    # 处理0
    if [[ "$dec" == "0" ]]; then
        echo "0"
        return 0
    fi
    
    # 验证数字格式
    if [[ ! "$dec" =~ ^[0-9]+$ ]]; then
        echo "0"
        return 1
    fi
    
    local binary=""
    
    while [[ "$dec" -gt "0" ]]; do
        binary="$((dec % 2))${binary}"
        dec=$((dec / 2))
    done
    
    echo "$binary"
}

# 测试函数
bashmath_test() {
    echo "测试Bash数学函数库..."
    
    # 测试十六进制转换
    echo "十六进制转十进制:"
    echo "FF = $(bashmath_hex_to_dec "FF") (期望: 255)"
    echo "100 = $(bashmath_hex_to_dec "100") (期望: 256)"
    echo "A = $(bashmath_hex_to_dec "A") (期望: 10)"
    
    echo "十进制转十六进制:"
    echo "255 = $(bashmath_dec_to_hex "255") (期望: FF)"
    echo "256 = $(bashmath_dec_to_hex "256") (期望: 100)"
    echo "10 = $(bashmath_dec_to_hex "10") (期望: A)"
    
    # 测试对数
    echo "对数计算:"
    echo "log2(256) = $(bashmath_log2 "256") (期望: 8)"
    echo "log2(128) = $(bashmath_log2 "128") (期望: 7)"
    
    # 测试浮点除法
    echo "浮点除法:"
    echo "10/3 = $(bashmath_divide_float "10" "3") (期望: 3.333333)"
    echo "22/7 = $(bashmath_divide_float "22" "7") (期望: 3.142857)"
    
    # 测试二进制转换
    echo "二进制转换:"
    echo "1010 = $(bashmath_binary_to_dec "1010") (期望: 10)"
    echo "11111111 = $(bashmath_binary_to_dec "11111111") (期望: 255)"
    echo "10 = $(bashmath_dec_to_binary "10") (期望: 1010)"
    echo "255 = $(bashmath_dec_to_binary "255") (期望: 11111111)"
    
    echo "测试完成!"
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    bashmath_test
fi