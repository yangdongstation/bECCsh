#!/bin/bash
# Bash BigInt - 纯Bash大数运算库
# 仅使用Bash内置功能，无外部依赖

set -euo pipefail

# 导入保护 - 防止重复定义
if [[ -n "${BASH_BIGINT_LOADED:-}" ]]; then
    return 0
fi
readonly BASH_BIGINT_LOADED=1

# 错误处理
bashbigint_error() {
    echo "BashBigInt错误: $*" >&2
    return 1
}

# 验证数字格式（只允许数字）
bashbigint_validate() {
    local num="$1"
    if [[ ! "$num" =~ ^[0-9]+$ ]]; then
        bashbigint_error "无效的数字格式: $num"
        return 1
    fi
    return 0
}

# 移除前导零
bashbigint_normalize() {
    local num="$1"
    # 移除前导零
    num="${num#0*}"
    if [[ -z "$num" ]]; then
        num="0"
    fi
    echo "$num"
}

# 大数加法（纯Bash实现）
bashbigint_add() {
    local a="$1"
    local b="$2"
    
    if ! bashbigint_validate "$a" || ! bashbigint_validate "$b"; then
        return 1
    fi
    
    # 处理特殊情况
    if [[ "$a" == "0" ]]; then
        echo "$b"
        return 0
    fi
    if [[ "$b" == "0" ]]; then
        echo "$a"
        return 0
    fi
    
    # 使用竖式加法算法
    local result=""
    local carry=0
    local len_a=${#a}
    local len_b=${#b}
    local max_len=$((len_a > len_b ? len_a : len_b))
    
    # 从右到左逐位相加
    for ((i = 1; i <= max_len; i++)); do
        local digit_a=0
        local digit_b=0
        
        # 获取当前位（从右往左）
        if [[ $i -le $len_a ]]; then
            digit_a="${a: -$i:1}"
        fi
        if [[ $i -le $len_b ]]; then
            digit_b="${b: -$i:1}"
        fi
        
        # 计算和
        local sum=$((digit_a + digit_b + carry))
        carry=$((sum / 10))
        local digit=$((sum % 10))
        
        result="${digit}${result}"
    done
    
    # 处理最后的进位
    if [[ $carry -gt 0 ]]; then
        result="${carry}${result}"
    fi
    
    echo "$result"
}

# 大数减法（纯Bash实现）
bashbigint_subtract() {
    local a="$1"
    local b="$2"
    
    if ! bashbigint_validate "$a" || ! bashbigint_validate "$b"; then
        return 1
    fi
    
    # 确保a >= b
    local cmp=$(bashbigint_compare "$a" "$b")
    if [[ $cmp -lt 0 ]]; then
        bashbigint_error "减法结果为负数，不支持"
        return 1
    fi
    
    # 处理特殊情况
    if [[ "$b" == "0" ]]; then
        echo "$a"
        return 0
    fi
    if [[ "$a" == "$b" ]]; then
        echo "0"
        return 0
    fi
    
    # 使用竖式减法算法
    local result=""
    local borrow=0
    local len_a=${#a}
    local len_b=${#b}
    
    # 从右到左逐位相减
    for ((i = 1; i <= len_a; i++)); do
        local digit_a="${a: -$i:1}"
        local digit_b=0
        
        if [[ $i -le $len_b ]]; then
            digit_b="${b: -$i:1}"
        fi
        
        # 处理借位
        local temp_a=$((digit_a - borrow))
        borrow=0
        
        if [[ $temp_a -lt $digit_b ]]; then
            temp_a=$((temp_a + 10))
            borrow=1
        fi
        
        local digit=$((temp_a - digit_b))
        result="${digit}${result}"
    done
    
    # 移除前导零
    result="${result#0*}"
    if [[ -z "$result" ]]; then
        result="0"
    fi
    
    echo "$result"
}

# 大数乘法（纯Bash实现）
bashbigint_multiply() {
    local a="$1"
    local b="$2"
    
    if ! bashbigint_validate "$a" || ! bashbigint_validate "$b"; then
        return 1
    fi
    
    # 处理特殊情况
    if [[ "$a" == "0" ]] || [[ "$b" == "0" ]]; then
        echo "0"
        return 0
    fi
    if [[ "$a" == "1" ]]; then
        echo "$b"
        return 0
    fi
    if [[ "$b" == "1" ]]; then
        echo "$a"
        return 0
    fi
    
    # 对于大数，使用简单的逐位乘法
    local result="0"
    local len_b=${#b}
    
    # 从右到左处理乘数的每一位
    for ((i = 1; i <= len_b; i++)); do
        local digit_b="${b: -$i:1}"
        
        # 跳过0
        if [[ "$digit_b" == "0" ]]; then
            continue
        fi
        
        # 计算部分积：被乘数 × 当前位
        local partial_product=""
        local carry=0
        local len_a=${#a}
        
        # 从右到左处理被乘数的每一位
        for ((j = 1; j <= len_a; j++)); do
            local digit_a="${a: -$j:1}"
            local product=$((digit_a * digit_b + carry))
            carry=$((product / 10))
            local digit=$((product % 10))
            partial_product="${digit}${partial_product}"
        done
        
        # 处理最后的进位
        if [[ $carry -gt 0 ]]; then
            partial_product="${carry}${partial_product}"
        fi
        
        # 添加适当数量的零（位值）
        for ((k = 1; k < i; k++)); do
            partial_product="${partial_product}0"
        done
        
        # 累加到结果
        result=$(bashbigint_add "$result" "$partial_product")
    done
    
    echo "$result"
}

# 大数除法（纯Bash实现）
bashbigint_divide() {
    local dividend="$1"
    local divisor="$2"
    
    if ! bashbigint_validate "$dividend" || ! bashbigint_validate "$divisor"; then
        return 1
    fi
    
    if [[ "$divisor" == "0" ]]; then
        bashbigint_error "除数不能为零"
        return 1
    fi
    
    # 处理特殊情况
    if [[ "$dividend" == "0" ]]; then
        echo "0"
        return 0
    fi
    
    local cmp=$(bashbigint_compare "$dividend" "$divisor")
    if [[ $cmp -lt 0 ]]; then
        echo "0"
        return 0
    fi
    if [[ $cmp -eq 0 ]]; then
        echo "1"
        return 0
    fi
    
    # 使用长除法
    local quotient=""
    local current=""
    local len=${#dividend}
    local first_digit=true
    
    # 从左到右处理被除数的每一位
    for ((i = 0; i < len; i++)); do
        current="${current}${dividend:$i:1}"
        current=$(bashbigint_normalize "$current")
        
        # 如果当前数小于除数，商为0
        if [[ $(bashbigint_compare "$current" "$divisor") -lt 0 ]]; then
            # 只在不是第一个数字时添加0
            if [[ "$first_digit" == "false" ]]; then
                quotient="${quotient}0"
            fi
            continue
        fi
        
        first_digit=false
        
        # 找到最大的数字使得 current >= divisor * digit
        local digit=0
        local temp_product="0"
        
        while [[ $(bashbigint_compare "$temp_product" "$current") -le 0 ]]; do
            digit=$((digit + 1))
            temp_product=$(bashbigint_multiply "$divisor" "$digit")
        done
        
        digit=$((digit - 1))
        temp_product=$(bashbigint_multiply "$divisor" "$digit")
        
        # 更新商和当前余数
        quotient="${quotient}${digit}"
        current=$(bashbigint_subtract "$current" "$temp_product")
        
        if [[ "$current" == "0" ]]; then
            current=""
        fi
    done
    
    # 如果商为空，说明结果是0
    if [[ -z "$quotient" ]]; then
        quotient="0"
    fi
    
    echo "$quotient"
}

# 大数模运算（纯Bash实现）
bashbigint_mod() {
    local dividend="$1"
    local divisor="$2"
    
    if ! bashbigint_validate "$dividend" || ! bashbigint_validate "$divisor"; then
        return 1
    fi
    
    if [[ "$divisor" == "0" ]]; then
        bashbigint_error "模数不能为零"
        return 1
    fi
    
    # 特殊情况
    if [[ "$dividend" == "0" ]]; then
        echo "0"
        return 0
    fi
    
    # 比较被除数和除数
    local cmp=$(bashbigint_compare "$dividend" "$divisor")
    if [[ $cmp -lt 0 ]]; then
        # 被除数小于除数，被除数就是余数
        echo "$dividend"
        return 0
    elif [[ $cmp -eq 0 ]]; then
        # 被除数等于除数，余数为0
        echo "0"
        return 0
    fi
    
    # 被除数大于除数，计算余数
    local quotient=$(bashbigint_divide "$dividend" "$divisor")
    local product=$(bashbigint_multiply "$quotient" "$divisor")
    
    # 确保减法不会产生负数
    local remainder
    if [[ $(bashbigint_compare "$dividend" "$product") -ge 0 ]]; then
        remainder=$(bashbigint_subtract "$dividend" "$product")
    else
        # 这种情况不应该发生，但作为保护
        remainder="0"
    fi
    
    echo "$remainder"
}

# 大数比较（纯Bash实现）
bashbigint_compare() {
    local a="$1"
    local b="$2"
    
    if ! bashbigint_validate "$a" || ! bashbigint_validate "$b"; then
        return 1
    fi
    
    # 比较长度
    local len_a=${#a}
    local len_b=${#b}
    
    if [[ $len_a -lt $len_b ]]; then
        echo -1  # a < b
        return 0
    elif [[ $len_a -gt $len_b ]]; then
        echo 1   # a > b
        return 0
    fi
    
    # 长度相同，逐位比较
    if [[ "$a" < "$b" ]]; then
        echo -1
    elif [[ "$a" > "$b" ]]; then
        echo 1
    else
        echo 0
    fi
}

# 大数模幂运算（纯Bash实现）
bashbigint_mod_pow() {
    local base="$1"
    local exponent="$2"
    local modulus="$3"
    
    if ! bashbigint_validate "$base" || ! bashbigint_validate "$exponent" || ! bashbigint_validate "$modulus"; then
        return 1
    fi
    
    if [[ "$modulus" == "0" ]]; then
        bashbigint_error "模数不能为零"
        return 1
    fi
    
    # 处理特殊情况
    if [[ "$exponent" == "0" ]]; then
        echo "1"
        return 0
    fi
    if [[ "$modulus" == "1" ]]; then
        echo "0"
        return 0
    fi
    
    # 将base归一化
    base=$(bashbigint_mod "$base" "$modulus")
    if [[ "$base" == "0" ]]; then
        echo "0"
        return 0
    fi
    
    # 使用快速幂算法
    local result="1"
    local current_power="$base"
    
    # 处理指数，避免大数问题，使用字符串比较
    while [[ "$exponent" != "0" ]]; do
        # 检查指数是否为奇数（个位数）
        local last_digit="${exponent: -1}"
        if [[ $((last_digit % 2)) == 1 ]]; then
            result=$(bashbigint_mod $(bashbigint_multiply "$result" "$current_power") "$modulus")
        fi
        current_power=$(bashbigint_mod $(bashbigint_multiply "$current_power" "$current_power") "$modulus")
        exponent=$(bashbigint_divide "$exponent" "2")
    done
    
    echo "$result"
}

# 大数随机数生成（简化版本）
bashbigint_random() {
    local bits="$1"
    
    if ! bashbigint_validate "$bits"; then
        return 1
    fi
    
    # 简单的随机数生成：使用时间和进程ID
    local random_seed=$(date +%s%N)$$
    local random_num=""
    
    # 生成指定位数的随机数
    local bytes=$(((bits + 7) / 8))
    for ((i = 0; i < bytes; i++)); do
        local byte=$((RANDOM % 256))
        random_num="${random_num}$(printf "%02X" $byte)"
    done
    
    # 转换为十进制并限制范围
    random_num=$(bashmath_hex_to_dec "$random_num")
    local max_value=$(bashbigint_pow "2" "$bits")
    bashbigint_mod "$random_num" "$max_value"
}

# 扩展欧几里得算法（纯Bash实现）
bashbigint_extended_gcd() {
    local a="$1"
    local b="$2"
    
    if ! bashbigint_validate "$a" || ! bashbigint_validate "$b"; then
        return 1
    fi
    
    if [[ "$b" == "0" ]]; then
        echo "1 0 $a"
        return 0
    fi
    
    local quotient=$(bashbigint_divide "$a" "$b")
    local remainder=$(bashbigint_mod "$a" "$b")
    
    local result=$(bashbigint_extended_gcd "$b" "$remainder")
    local x=$(echo "$result" | cut -d' ' -f1)
    local y=$(echo "$result" | cut -d' ' -f2)
    local gcd=$(echo "$result" | cut -d' ' -f3)
    
    local new_x="$y"
    local new_y=$(bashbigint_subtract "$x" $(bashbigint_multiply "$y" "$quotient"))
    
    echo "$new_x $new_y $gcd"
}

# 模逆元计算（纯Bash实现）
bashbigint_mod_inverse() {
    local a="$1"
    local m="$2"
    
    if ! bashbigint_validate "$a" || ! bashbigint_validate "$m"; then
        return 1
    fi
    
    if [[ "$m" == "0" ]]; then
        bashbigint_error "模数不能为零"
        return 1
    fi
    
    local result=$(bashbigint_extended_gcd "$a" "$m")
    local x=$(echo "$result" | cut -d' ' -f1)
    local gcd=$(echo "$result" | cut -d' ' -f3)
    
    # 检查gcd是否为1
    if [[ "$gcd" != "1" ]]; then
        bashbigint_error "模逆元不存在"
        return 1
    fi
    
    # 确保x为正数
    if [[ $(bashbigint_compare "$x" "0") -lt 0 ]]; then
        x=$(bashbigint_add "$x" "$m")
    fi
    
    bashbigint_mod "$x" "$m"
}

# 测试函数
bashbigint_test() {
    echo "测试BashBigInt库..."
    
    # 基本运算测试
    echo "加法: 123 + 456 = $(bashbigint_add "123" "456") (期望: 579)"
    echo "减法: 579 - 456 = $(bashbigint_subtract "579" "456") (期望: 123)"
    echo "乘法: 123 × 456 = $(bashbigint_multiply "123" "456") (期望: 56088)"
    echo "除法: 56088 ÷ 456 = $(bashbigint_divide "56088" "456") (期望: 123)"
    echo "模运算: 56088 % 456 = $(bashbigint_mod "56088" "456") (期望: 0)"
    echo "比较: 123 vs 456 = $(bashbigint_compare "123" "456") (期望: -1)"
    echo "模幂: 2^10 mod 1000 = $(bashbigint_mod_pow "2" "10" "1000") (期望: 24)"
    
    # 大数测试
    local big_a="12345678901234567890"
    local big_b="98765432109876543210"
    echo "大数加法: $big_a + $big_b = $(bashbigint_add "$big_a" "$big_b")"
    echo "大数乘法: $big_a × 2 = $(bashbigint_multiply "$big_a" "2")"
    
    echo "BashBigInt测试完成!"
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    bashbigint_test
fi