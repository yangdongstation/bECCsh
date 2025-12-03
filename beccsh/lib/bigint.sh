#!/bin/bash
# bigint.sh - 纯bash大数运算库
# 实现256位整数的加减乘除和模运算
# 完全不依赖bc或其他外部工具

# 大数表示：使用字符串表示，每个字符代表一个十进制数字
# 支持任意精度，但主要用于256位整数运算

# 初始化大数库
init_bigint() {
    # 预计算一些常用值
    declare -g BIGINT_ZERO="0"
    declare -g BIGINT_ONE="1"
    declare -g BIGINT_TWO="2"
    declare -g BIGINT_TEN="10"
}

# 大数比较
# 返回：0(相等), 1(大于), 2(小于)
bigint_compare() {
    local a="$1"
    local b="$2"
    
    # 移除前导零
    a=$(bigint_remove_leading_zeros "$a")
    b=$(bigint_remove_leading_zeros "$b")
    
    # 比较长度
    local len_a=${#a}
    local len_b=${#b}
    
    if [[ $len_a -gt $len_b ]]; then
        return 1  # a > b
    elif [[ $len_a -lt $len_b ]]; then
        return 2  # a < b
    fi
    
    # 长度相同，逐位比较
    for ((i=0; i<len_a; i++)); do
        local digit_a=${a:i:1}
        local digit_b=${b:i:1}
        
        if [[ $digit_a -gt $digit_b ]]; then
            return 1  # a > b
        elif [[ $digit_a -lt $digit_b ]]; then
            return 2  # a < b
        fi
    done
    
    return 0  # a = b
}

# 移除前导零
bigint_remove_leading_zeros() {
    local num="$1"
    
    # 特殊情况：全零
    if [[ $num =~ ^0+$ ]]; then
        echo "0"
        return
    fi
    
    # 移除前导零
    num=${num#0}
    
    # 如果为空，返回0
    if [[ -z $num ]]; then
        echo "0"
    else
        echo "$num"
    fi
}

# 大数加法
bigint_add() {
    local a="$1"
    local b="$2"
    
    # 处理负数（简化版，只支持正数）
    if [[ $a =~ ^- ]]; then
        echo "错误：不支持负数" >&2
        return 1
    fi
    
    if [[ $b =~ ^- ]]; then
        echo "错误：不支持负数" >&2
        return 1
    fi
    
    # 确保a是较长的数
    if [[ ${#a} -lt ${#b} ]]; then
        local temp="$a"
        a="$b"
        b="$temp"
    fi
    
    local result=""
    local carry=0
    local len_a=${#a}
    local len_b=${#b}
    
    # 从右到左逐位相加
    for ((i=1; i<=len_a; i++)); do
        local digit_a=${a:len_a-i:1}
        local digit_b=0
        
        if [[ $i -le $len_b ]]; then
            digit_b=${b:len_b-i:1}
        fi
        
        local sum=$((digit_a + digit_b + carry))
        carry=$((sum / 10))
        local digit=$((sum % 10))
        
        result="${digit}${result}"
    done
    
    # 处理最后的进位
    while [[ $carry -gt 0 ]]; do
        result="${carry}${result}"
        carry=$((carry / 10))
    done
    
    echo "$result"
}

# 大数减法（要求a >= b）
bigint_sub() {
    local a="$1"
    local b="$2"
    
    # 比较大小
    bigint_compare "$a" "$b"
    local cmp=$?
    
    if [[ $cmp -eq 2 ]]; then
        echo "错误：被减数小于减数" >&2
        return 1
    elif [[ $cmp -eq 0 ]]; then
        echo "0"
        return 0
    fi
    
    local result=""
    local borrow=0
    local len_a=${#a}
    local len_b=${#b}
    
    # 从右到左逐位相减
    for ((i=1; i<=len_a; i++)); do
        local digit_a=${a:len_a-i:1}
        local digit_b=0
        
        if [[ $i -le $len_b ]]; then
            digit_b=${b:len_b-i:1}
        fi
        
        local diff=$((digit_a - digit_b - borrow))
        
        if [[ $diff -lt 0 ]]; then
            diff=$((diff + 10))
            borrow=1
        else
            borrow=0
        fi
        
        result="${diff}${result}"
    done
    
    # 移除前导零
    result=$(bigint_remove_leading_zeros "$result")
    echo "$result"
}

# 大数乘法（小学乘法算法）
bigint_mul() {
    local a="$1"
    local b="$2"
    
    # 处理零
    if [[ $a == "0" ]] || [[ $b == "0" ]]; then
        echo "0"
        return 0
    fi
    
    # 确保a是较短的数（优化性能）
    if [[ ${#a} -gt ${#b} ]]; then
        local temp="$a"
        a="$b"
        b="$temp"
    fi
    
    local result="0"
    local len_a=${#a}
    
    # 逐位相乘
    for ((i=1; i<=len_a; i++)); do
        local digit_a=${a:len_a-i:1}
        
        if [[ $digit_a -eq 0 ]]; then
            continue
        fi
        
        # 计算当前位的乘积
        local partial=""
        local carry=0
        local len_b=${#b}
        
        for ((j=1; j<=len_b; j++)); do
            local digit_b=${b:len_b-j:1}
            local product=$((digit_a * digit_b + carry))
            carry=$((product / 10))
            local digit=$((product % 10))
            partial="${digit}${partial}"
        done
        
        # 处理进位
        while [[ $carry -gt 0 ]]; do
            partial="${carry}${partial}"
            carry=$((carry / 10))
        done
        
        # 添加适当的零（位移）
        for ((k=1; k<i; k++)); do
            partial="${partial}0"
        done
        
        # 累加到结果
        result=$(bigint_add "$result" "$partial")
    done
    
    echo "$result"
}

# 大数除法（长除法）
bigint_div() {
    local dividend="$1"
    local divisor="$2"
    
    # 处理除零错误
    if [[ $divisor == "0" ]]; then
        echo "错误：除零" >&2
        return 1
    fi
    
    # 处理被除数小于除数的情况
    bigint_compare "$dividend" "$divisor"
    local cmp=$?
    
    if [[ $cmp -eq 2 ]]; then
        echo "0"
        return 0
    elif [[ $cmp -eq 0 ]]; then
        echo "1"
        return 0
    fi
    
    local quotient=""
    local remainder=""
    local temp=""
    
    # 长除法
    for ((i=0; i<${#dividend}; i++)); do
        temp="${temp}${dividend:i:1}"
        temp=$(bigint_remove_leading_zeros "$temp")
        
        local digit=0
        while true; do
            bigint_compare "$temp" "$divisor"
            local cmp_temp=$?
            
            if [[ $cmp_temp -eq 1 ]] || [[ $cmp_temp -eq 0 ]]; then
                temp=$(bigint_sub "$temp" "$divisor")
                digit=$((digit + 1))
            else
                break
            fi
        done
        
        quotient="${quotient}${digit}"
    done
    
    quotient=$(bigint_remove_leading_zeros "$quotient")
    echo "$quotient"
}

# 大数取模
bigint_mod() {
    local dividend="$1"
    local divisor="$2"
    
    # 处理除零错误
    if [[ $divisor == "0" ]]; then
        echo "错误：模零" >&2
        return 1
    fi
    
    # 处理被除数小于除数的情况
    bigint_compare "$dividend" "$divisor"
    local cmp=$?
    
    if [[ $cmp -eq 2 ]]; then
        echo "$dividend"
        return 0
    elif [[ $cmp -eq 0 ]]; then
        echo "0"
        return 0
    fi
    
    # 计算商
    local quotient
    quotient=$(bigint_div "$dividend" "$divisor")
    
    # 计算余数：remainder = dividend - quotient * divisor
    local product
    product=$(bigint_mul "$quotient" "$divisor")
    
    local remainder
    remainder=$(bigint_sub "$dividend" "$product")
    
    echo "$remainder"
}

# 大数幂运算（平方乘算法）
bigint_pow() {
    local base="$1"
    local exponent="$2"
    
    # 处理指数为0的情况
    if [[ $exponent == "0" ]]; then
        echo "1"
        return 0
    fi
    
    # 处理指数为1的情况
    if [[ $exponent == "1" ]]; then
        echo "$base"
        return 0
    fi
    
    local result="1"
    local power="$base"
    
    # 二进制方法
    while [[ $exponent -gt 0 ]]; do
        local digit=$((exponent % 2))
        exponent=$((exponent / 2))
        
        if [[ $digit -eq 1 ]]; then
            result=$(bigint_mul "$result" "$power")
        fi
        
        power=$(bigint_mul "$power" "$power")
    done
    
    echo "$result"
}

# 大数幂模运算
bigint_powmod() {
    local base="$1"
    local exponent="$2"
    local modulus="$3"
    
    # 处理指数为0的情况
    if [[ $exponent == "0" ]]; then
        echo "1"
        return 0
    fi
    
    # 处理模数为1的情况
    if [[ $modulus == "1" ]]; then
        echo "0"
        return 0
    fi
    
    local result="1"
    local power=$(bigint_mod "$base" "$modulus")
    
    # 二进制方法
    while [[ $exponent -gt 0 ]]; do
        local digit=$((exponent % 2))
        exponent=$((exponent / 2))
        
        if [[ $digit -eq 1 ]]; then
            result=$(bigint_mul "$result" "$power")
            result=$(bigint_mod "$result" "$modulus")
        fi
        
        power=$(bigint_mul "$power" "$power")
        power=$(bigint_mod "$power" "$modulus")
    done
    
    echo "$result"
}

# 扩展欧几里得算法求逆元
bigint_inverse() {
    local a="$1"
    local m="$2"
    
    # 检查是否互质
    if [[ $(bigint_gcd "$a" "$m") != "1" ]]; then
        echo "错误：逆元不存在" >&2
        return 1
    fi
    
    # 使用扩展欧几里得算法
    local t=0
    local newt=1
    local r="$m"
    local newr="$a"
    
    while [[ $newr != "0" ]]; do
        local quotient=$(bigint_div "$r" "$newr")
        
        local temp=$newt
        newt=$(bigint_sub "$t" $(bigint_mul "$quotient" "$newt"))
        t=$temp
        
        temp=$newr
        newr=$(bigint_sub "$r" $(bigint_mul "$quotient" "$newr"))
        r=$temp
    done
    
    # 确保结果是正数
    if [[ $(bigint_compare "$t" "0") -eq 2 ]]; then
        t=$(bigint_add "$t" "$m")
    fi
    
    echo "$t"
}

# 计算最大公约数（欧几里得算法）
bigint_gcd() {
    local a="$1"
    local b="$2"
    
    while [[ $b != "0" ]]; do
        local temp=$b
        b=$(bigint_mod "$a" "$b")
        a=$temp
    done
    
    echo "$a"
}

# 测试大数运算能力
test_bigint_capabilities() {
    # 测试基本运算
    local a="123456789012345678901234567890"
    local b="987654321098765432109876543210"
    
    # 加法测试
    local sum=$(bigint_add "$a" "$b")
    if [[ -z "$sum" ]]; then
        return 1
    fi
    
    # 乘法测试
    local product=$(bigint_mul "$a" "$b")
    if [[ -z "$product" ]]; then
        return 1
    fi
    
    # 模运算测试
    local mod=$(bigint_mod "$product" "1000000007")
    if [[ -z "$mod" ]]; then
        return 1
    fi
    
    return 0
}

# 大数转十六进制
bigint_to_hex() {
    local num="$1"
    local hex=""
    
    if [[ $num == "0" ]]; then
        echo "0"
        return
    fi
    
    while [[ $num != "0" ]]; do
        local remainder=$(bigint_mod "$num" "16")
        local digit
        
        case $remainder in
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
            10) digit="a" ;;
            11) digit="b" ;;
            12) digit="c" ;;
            13) digit="d" ;;
            14) digit="e" ;;
            15) digit="f" ;;
        esac
        
        hex="${digit}${hex}"
        num=$(bigint_div "$num" "16")
    done
    
    echo "$hex"
}

# 十六进制转大数
hex_to_bigint() {
    local hex="${1,,}"  # 转换为小写
    local num="0"
    
    for ((i=0; i<${#hex}; i++)); do
        local digit=${hex:i:1}
        local value
        
        case $digit in
            [0-9]) value=$digit ;;
            a) value=10 ;;
            b) value=11 ;;
            c) value=12 ;;
            d) value=13 ;;
            e) value=14 ;;
            f) value=15 ;;
            *) echo "错误：无效的十六进制字符: $digit" >&2; return 1 ;;
        esac
        
        num=$(bigint_add $(bigint_mul "$num" "16") "$value")
    done
    
    echo "$num"
}

# 初始化大数库
init_bigint