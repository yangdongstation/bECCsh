#!/bin/bash
# BigInt - 纯Bash大数运算库
# 支持任意精度的大数运算，用于椭圆曲线密码学

set -euo pipefail

# 导入保护 - 防止重复定义
if [[ -n "${BIGINT_LOADED:-}" ]]; then
    return 0
fi
readonly BIGINT_LOADED=1

# 导入数学库
source "$(dirname "${BASH_SOURCE[0]}")/bash_math.sh"

# 全局变量
BIGINT_BASE=1000000000  # 10^9，用于分块计算
BIGINT_CHUNK_SIZE=9     # 每个块9位数字

# 错误处理
bigint_error() {
    echo "BigInt错误: $*" >&2
    return 1
}

# 导出函数以便子shell使用
export -f bigint_error

# 验证数字格式
bigint_validate() {
    local num="$1"
    # 处理空字符串的情况
    if [[ -z "$num" ]]; then
        bigint_error "无效的数字格式: 空字符串"
        return 1
    fi
    # 检查是否为有效的数字格式（包括0和负数）
    if [[ ! "$num" =~ ^[0-9]+$ ]] && [[ ! "$num" =~ ^-[0-9]+$ ]]; then
        bigint_error "无效的数字格式: $num"
        return 1
    fi
    return 0
}

# 标准化数字（去除前导零）
bigint_normalize() {
    local num="$1"
    local is_negative=0
    
    # 检查是否为负数
    if [[ "$num" =~ ^- ]]; then
        is_negative=1
        num=${num#-}  # 移除负号
    fi
    
    # 处理全0的情况
    if [[ "$num" =~ ^0+$ ]]; then
        num="0"
    elif [[ "$num" != "0" ]]; then
        # 移除前导零
        while [[ "$num" == 0* ]]; do
            num=${num#0}
            if [[ -z "$num" ]]; then
                num="0"
                break
            fi
        done
    fi
    
    # 重新添加负号，但处理-0特殊情况
    if [[ $is_negative -eq 1 ]] && [[ "$num" != "0" ]]; then
        echo "-$num"
    else
        echo "$num"
    fi
}

# 导出函数将在source后手动处理，避免导出不存在的函数

# 比较两个大数
bigint_compare() {
    local a="$1"
    local b="$2"
    
    # 处理符号
    local a_neg=0 b_neg=0
    if [[ "$a" =~ ^- ]]; then
        a_neg=1
        a=${a#-}
    fi
    if [[ "$b" =~ ^- ]]; then
        b_neg=1
        b=${b#-}
    fi
    
    # 符号不同
    if [[ $a_neg -ne $b_neg ]]; then
        if [[ $a_neg -eq 1 ]]; then
            echo -1  # a < b
        else
            echo 1   # a > b
        fi
        return 0
    fi
    
    # 符号相同，比较绝对值
    local len_a=${#a}
    local len_b=${#b}
    
    if [[ $len_a -lt $len_b ]]; then
        if [[ $a_neg -eq 1 ]]; then
            echo 1   # -a > -b
        else
            echo -1  # a < b
        fi
    elif [[ $len_a -gt $len_b ]]; then
        if [[ $a_neg -eq 1 ]]; then
            echo -1  # -a < -b
        else
            echo 1   # a > b
        fi
    else
        # 长度相同，逐位比较
        if [[ "$a" < "$b" ]]; then
            if [[ $a_neg -eq 1 ]]; then
                echo 1   # -a > -b
            else
                echo -1  # a < b
            fi
        elif [[ "$a" > "$b" ]]; then
            if [[ $a_neg -eq 1 ]]; then
                echo -1  # -a < -b
            else
                echo 1   # a > b
            fi
        else
            echo 0   # a = b
        fi
    fi
}

# 大数加法
bigint_add() {
    local a="$1"
    local b="$2"
    
    if ! bigint_validate "$a" || ! bigint_validate "$b"; then
        return 1
    fi
    
    # 处理符号
    if [[ "$a" =~ ^- ]]; then
        if [[ "$b" =~ ^- ]]; then
            # (-a) + (-b) = -(a + b)
            echo "-$(bigint_add "${a#-}" "${b#-}")"
            return 0
        else
            # (-a) + b = b - a
            bigint_subtract "$b" "${a#-}"
            return 0
        fi
    elif [[ "$b" =~ ^- ]]; then
        # a + (-b) = a - b
        bigint_subtract "$a" "${b#-}"
        return 0
    fi
    
    # 都是正数，直接相加
    local result=""
    local carry=0
    local len_a=${#a}
    local len_b=${#b}
    
    # 补零使长度相同
    while [[ $len_a -lt $len_b ]]; do
        a="0$a"
        ((len_a++))
    done
    while [[ $len_b -lt $len_a ]]; do
        b="0$b"
        ((len_b++))
    done
    
    # 从右到左逐位相加
    local i=$((len_a - 1))
    while [[ $i -ge 0 ]]; do
        local digit_a=${a:i:1}
        local digit_b=${b:i:1}
        local sum=$((digit_a + digit_b + carry))
        
        if [[ $sum -ge 10 ]]; then
            carry=1
            sum=$((sum - 10))
        else
            carry=0
        fi
        
        result="${sum}${result}"
        ((i--))
    done
    
    # 处理最后的进位
    if [[ $carry -eq 1 ]]; then
        result="1${result}"
    fi
    
    bigint_normalize "$result"
}

# 大数减法
bigint_subtract() {
    local a="$1"
    local b="$2"
    
    if ! bigint_validate "$a" || ! bigint_validate "$b"; then
        return 1
    fi
    
    # 处理符号
    if [[ "$a" =~ ^- ]]; then
        if [[ "$b" =~ ^- ]]; then
            # (-a) - (-b) = b - a
            bigint_subtract "${b#-}" "${a#-}"
            return 0
        else
            # (-a) - b = -(a + b)
            echo "-$(bigint_add "${a#-}" "$b")"
            return 0
        fi
    elif [[ "$b" =~ ^- ]]; then
        # a - (-b) = a + b
        bigint_add "$a" "${b#-}"
        return 0
    fi
    
    # 都是正数
    local cmp=$(bigint_compare "$a" "$b")
    
    if [[ $cmp -eq 0 ]]; then
        echo "0"
        return 0
    elif [[ $cmp -lt 0 ]]; then
        # 结果为负
        echo "-$(bigint_subtract "$b" "$a")"
        return 0
    fi
    
    # a > b，正常减法
    local result=""
    local borrow=0
    local len_a=${#a}
    local len_b=${#b}
    
    # 补零使长度相同
    while [[ $len_b -lt $len_a ]]; do
        b="0$b"
        ((len_b++))
    done
    
    # 从右到左逐位相减
    local i=$((len_a - 1))
    while [[ $i -ge 0 ]]; do
        local digit_a=${a:i:1}
        local digit_b=${b:i:1}
        local diff=$((digit_a - digit_b - borrow))
        
        if [[ $diff -lt 0 ]]; then
            diff=$((diff + 10))
            borrow=1
        else
            borrow=0
        fi
        
        result="${diff}${result}"
        ((i--))
    done
    
    bigint_normalize "$result"
}

# 大数乘法（使用分块算法优化）
bigint_multiply() {
    local a="$1"
    local b="$2"
    
    if ! bigint_validate "$a" || ! bigint_validate "$b"; then
        return 1
    fi
    
    # 处理零
    if [[ "$a" == "0" || "$b" == "0" ]]; then
        echo "0"
        return 0
    fi
    
    # 处理符号
    local result_sign=""
    if [[ "$a" =~ ^- ]]; then
        a=${a#-}
        if [[ "$b" =~ ^- ]]; then
            b=${b#-}
        else
            result_sign="-"
        fi
    elif [[ "$b" =~ ^- ]]; then
        b=${b#-}
        result_sign="-"
    fi
    
    # 对于大数，使用分块乘法
    if [[ ${#a} -gt 100 || ${#b} -gt 100 ]]; then
        # 使用Karatsuba算法
        local result=$(bigint_karatsuba "$a" "$b")
        if [[ -n "$result_sign" ]]; then
            echo "$result_sign$result"
        else
            echo "$result"
        fi
        return 0
    fi
    
    # 普通乘法
    local result="0"
    local len_b=${#b}
    local i=$((len_b - 1))
    local shift=0
    
    while [[ $i -ge 0 ]]; do
        local digit_b=${b:i:1}
        local partial_product=$(bigint_multiply_by_digit "$a" "$digit_b")
        
        # 添加零移位
        local j
        for ((j=0; j<shift; j++)); do
            partial_product="${partial_product}0"
        done
        
        result=$(bigint_add "$result" "$partial_product")
        ((i--))
        ((shift++))
    done
    
    if [[ -n "$result_sign" ]]; then
        echo "$result_sign$result"
    else
        echo "$result"
    fi
}

# 乘以单个数字
bigint_multiply_by_digit() {
    local a="$1"
    local digit="$2"
    
    local result=""
    local carry=0
    local len_a=${#a}
    local i=$((len_a - 1))
    
    while [[ $i -ge 0 ]]; do
        local digit_a=${a:i:1}
        local product=$((digit_a * digit + carry))
        
        result="$((product % 10))${result}"
        carry=$((product / 10))
        
        ((i--))
    done
    
    if [[ $carry -gt 0 ]]; then
        result="${carry}${result}"
    fi
    
    echo "$result"
}

# Karatsuba乘法算法（用于大数）
bigint_karatsuba() {
    local x="$1"
    local y="$2"
    
    # 基本情况
    if [[ ${#x} -le 4 || ${#y} -le 4 ]]; then
        bigint_multiply_simple "$x" "$y"
        return 0
    fi
    
    # 使长度相同
    local max_len=${#x}
    if [[ ${#y} -gt $max_len ]]; then
        max_len=${#y}
    fi
    
    # 补零
    while [[ ${#x} -lt $max_len ]]; do
        x="0$x"
    done
    while [[ ${#y} -lt $max_len ]]; do
        y="0$y"
    done
    
    # 分割数字
    local split=$((max_len / 2))
    if [[ $split -eq 0 ]]; then
        split=1
    fi
    
    local high_x=${x:0:split}
    local low_x=${x:split}
    local high_y=${y:0:split}
    local low_y=${y:split}
    
    # 递归计算
    local z0=$(bigint_karatsuba "$low_x" "$low_y")
    local z1=$(bigint_karatsuba $(bigint_add "$low_x" "$high_x") $(bigint_add "$low_y" "$high_y"))
    local z2=$(bigint_karatsuba "$high_x" "$high_y")
    
    # 计算结果
    local term1=$z2
    local term2=$(bigint_subtract "$z1" $(bigint_add "$z2" "$z0"))
    local term3=$z0
    
    # 移位
    local i
    for ((i=0; i<2*split; i++)); do
        term1="${term1}0"
    done
    for ((i=0; i<split; i++)); do
        term2="${term2}0"
    done
    
    # 组合结果
    bigint_add "$term1" $(bigint_add "$term2" "$term3")
}

# 简单乘法（用于较小数字）
bigint_multiply_simple() {
    local a="$1"
    local b="$2"
    
    local result="0"
    local len_b=${#b}
    local i=$((len_b - 1))
    local shift=0
    
    while [[ $i -ge 0 ]]; do
        local digit_b=${b:i:1}
        local partial_product=$(bigint_multiply_by_digit "$a" "$digit_b")
        
        # 添加零移位
        local j
        for ((j=0; j<shift; j++)); do
            partial_product="${partial_product}0"
        done
        
        result=$(bigint_add "$result" "$partial_product")
        ((i--))
        ((shift++))
    done
    
    echo "$result"
}

# 大数除法（返回商）
bigint_divide() {
    local dividend="$1"
    local divisor="$2"
    
    if ! bigint_validate "$dividend" || ! bigint_validate "$divisor"; then
        return 1
    fi
    
    if [[ "$divisor" == "0" ]]; then
        bigint_error "除数不能为零"
        return 1
    fi
    
    # 处理符号
    local result_sign=""
    if [[ "$dividend" =~ ^- ]]; then
        dividend=${dividend#-}
        if [[ "$divisor" =~ ^- ]]; then
            divisor=${divisor#-}
        else
            result_sign="-"
        fi
    elif [[ "$divisor" =~ ^- ]]; then
        divisor=${divisor#-}
        result_sign="-"
    fi
    
    # 比较大小
    local cmp=$(bigint_compare "$dividend" "$divisor")
    if [[ $cmp -lt 0 ]]; then
        echo "0"
        return 0
    elif [[ $cmp -eq 0 ]]; then
        if [[ -n "$result_sign" ]]; then
            echo "-1"
        else
            echo "1"
        fi
        return 0
    fi
    
    # 长除法
    local quotient="0"
    local current=""
    local len_dividend=${#dividend}
    
    for ((i=0; i<len_dividend; i++)); do
        current="${current}${dividend:i:1}"
        current=$(bigint_normalize "$current")
        
        local count="0"
        while [[ $(bigint_compare "$current" "$divisor") -ge 0 ]]; do
            current=$(bigint_subtract "$current" "$divisor")
            count=$(bigint_add "$count" "1")
        done
        
        quotient="${quotient}${count}"
    done
    
    quotient=$(bigint_normalize "$quotient")
    
    if [[ -n "$result_sign" ]]; then
        echo "$result_sign$quotient"
    else
        echo "$quotient"
    fi
}

# 大数模运算
bigint_mod() {
    local dividend="$1"
    local divisor="$2"
    
    if ! bigint_validate "$dividend" || ! bigint_validate "$divisor"; then
        return 1
    fi
    
    if [[ "$divisor" == "0" ]]; then
        bigint_error "模数不能为零"
        return 1
    fi
    
    # 处理符号
    local dividend_neg=0
    if [[ "$dividend" =~ ^- ]]; then
        dividend=${dividend#-}
        dividend_neg=1
    fi
    
    if [[ "$divisor" =~ ^- ]]; then
        divisor=${divisor#-}
    fi
    
    # 计算商
    local quotient=$(bigint_divide "$dividend" "$divisor")
    
    # 计算余数
    local product=$(bigint_multiply "$quotient" "$divisor")
    local remainder=$(bigint_subtract "$dividend" "$product")
    
    # 处理负数的模运算
    if [[ $dividend_neg -eq 1 ]]; then
        remainder=$(bigint_subtract "$divisor" "$remainder")
    fi
    
    echo "$remainder"
}

# 大数幂运算
bigint_pow() {
    local base="$1"
    local exponent="$2"
    
    if ! bigint_validate "$base" || ! bigint_validate "$exponent"; then
        return 1
    fi
    
    # 处理负指数
    if [[ "$exponent" =~ ^- ]]; then
        bigint_error "不支持负指数"
        return 1
    fi
    
    # 快速幂算法
    local result="1"
    local current_power="$base"
    
    # 移除前导零避免八进制解释
    exponent="${exponent#0*}"
    if [[ -z "$exponent" ]]; then
        exponent="0"
    fi
    
    while [[ "$exponent" -gt "0" ]]; do
        if [[ $(bigint_mod "$exponent" "2") == "1" ]]; then
            result=$(bigint_multiply "$result" "$current_power")
        fi
        current_power=$(bigint_multiply "$current_power" "$current_power")
        exponent=$(bigint_divide "$exponent" "2")
        # 移除前导零
        exponent="${exponent#0*}"
        if [[ -z "$exponent" ]]; then
            exponent="0"
        fi
    done
    
    echo "$result"
}

# 大数模幂运算（用于密码学）
bigint_mod_pow() {
    local base="$1"
    local exponent="$2"
    local modulus="$3"
    
    if ! bigint_validate "$base" || ! bigint_validate "$exponent" || ! bigint_validate "$modulus"; then
        return 1
    fi
    
    if [[ "$modulus" == "1" ]]; then
        echo "0"
        return 0
    fi
    
    # 处理负指数
    if [[ "$exponent" =~ ^- ]]; then
        # 计算模逆元
        base=$(bigint_mod_inverse "$base" "$modulus")
        if [[ $? -ne 0 ]]; then
            return 1
        fi
        exponent=${exponent#-}
    fi
    
    # 模幂运算
    local result="1"
    base=$(bigint_mod "$base" "$modulus")
    
    while [[ "$exponent" -gt "0" ]]; do
        if [[ $(bigint_mod "$exponent" "2") == "1" ]]; then
            result=$(bigint_mod $(bigint_multiply "$result" "$base") "$modulus")
        fi
        base=$(bigint_mod $(bigint_multiply "$base" "$base") "$modulus")
        exponent=$(bigint_divide "$exponent" "2")
    done
    
    echo "$result"
}

# 扩展欧几里得算法
bigint_extended_gcd() {
    local a="$1"
    local b="$2"
    
    if [[ "$b" == "0" ]]; then
        echo "$a 1 0"
        return 0
    fi
    
    local result=$(bigint_extended_gcd "$b" $(bigint_mod "$a" "$b"))
    local gcd=$(echo "$result" | cut -d' ' -f1)
    local x=$(echo "$result" | cut -d' ' -f2)
    local y=$(echo "$result" | cut -d' ' -f3)
    
    local new_x=$y
    local new_y=$(bigint_subtract "$x" $(bigint_multiply "$y" $(bigint_divide "$a" "$b")))
    
    echo "$gcd $new_x $new_y"
}

# 模逆元计算
bigint_mod_inverse() {
    local a="$1"
    local m="$2"
    
    local result=$(bigint_extended_gcd "$a" "$m")
    local gcd=$(echo "$result" | cut -d' ' -f1)
    local x=$(echo "$result" | cut -d' ' -f2)
    
    if [[ "$gcd" != "1" ]]; then
        bigint_error "模逆元不存在"
        return 1
    fi
    
    # 确保结果是正数
    if [[ "$x" =~ ^- ]]; then
        x=$(bigint_add "$x" "$m")
    fi
    
    bigint_mod "$x" "$m"
}

# 生成随机大数
bigint_random() {
    local bits="$1"
    local max_attempts=10
    local attempts=0
    
    while [[ $attempts -lt $max_attempts ]]; do
        local random_hex=$(openssl rand -hex $(( (bits + 7) / 8 )) 2>/dev/null || \
                          head -c $(( (bits + 7) / 8 )) /dev/urandom | xxd -p -c 256)
        
        if [[ -n "$random_hex" ]]; then
            # 转换为十进制
            local random_decimal=$(bashmath_hex_to_dec "$random_hex" || echo "0")
            if [[ "$random_decimal" != "0" ]]; then
                echo "$random_decimal"
                return 0
            fi
        fi
        
        ((attempts++))
    done
    
    # 备用：使用时间戳
    local timestamp=$(date +%s%N)
    echo "$timestamp"
}

# 测试函数
bigint_test() {
    echo "运行BigInt库测试..."
    
    # 基本运算测试
    local test_a="12345678901234567890"
    local test_b="98765432109876543210"
    
    echo "测试数字: $test_a, $test_b"
    
    # 加法
    local sum=$(bigint_add "$test_a" "$test_b")
    echo "加法: $test_a + $test_b = $sum"
    
    # 减法
    local diff=$(bigint_subtract "$test_b" "$test_a")
    echo "减法: $test_b - $test_a = $diff"
    
    # 乘法
    local product=$(bigint_multiply "$test_a" "12345")
    echo "乘法: $test_a * 12345 = $product"
    
    # 除法
    local quotient=$(bigint_divide "$test_b" "12345")
    echo "除法: $test_b / 12345 = $quotient"
    
    # 模运算
    local remainder=$(bigint_mod "$test_b" "12345")
    echo "模: $test_b % 12345 = $remainder"
    
    # 幂运算
    local power=$(bigint_pow "2" "100")
    echo "幂: 2^100 = ${power:0:20}... (截断显示)"
    
    # 模逆元
    local inv=$(bigint_mod_inverse "17" "3120")
    echo "模逆元: 17^-1 mod 3120 = $inv"
    
    echo "BigInt测试完成"
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    bigint_test
fi