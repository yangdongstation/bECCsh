#!/bin/bash

# 扩展大数运算 - 支持更多位数
# 完全使用Bash，突破32/64位整数限制

# 大数表示：使用字符串表示，支持任意精度
PUREBASH_BIGINT_PRECISION=256  # 默认256位精度

# 大数零
PUREBASH_BIGINT_ZERO="0"

# 大数一  
PUREBASH_BIGINT_ONE="1"

# 检查大数格式
purebash_bigint_validate() {
    local num="$1"
    if [[ ! "$num" =~ ^[0-9]+$ ]]; then
        echo "错误: 无效的大数格式: $num" >&2
        return 1
    fi
    return 0
}

# 大数比较
purebash_bigint_compare() {
    local a="$1" b="$2"
    
    purebash_bigint_validate "$a" || return 1
    purebash_bigint_validate "$b" || return 1
    
    # 移除前导零
    a="${a#${a%%[!0]*}}"; a="${a:-0}"
    b="${b#${b%%[!0]*}}"; b="${b:-0}"
    
    local len_a=${#a} len_b=${#b}
    
    # 长度比较
    if [[ $len_a -gt $len_b ]]; then
        echo "1"; return 0
    elif [[ $len_a -lt $len_b ]]; then
        echo "-1"; return 0
    fi
    
    # 长度相同，逐位比较
    for ((i=0; i<len_a; i++)); do
        local digit_a="${a:$i:1}" digit_b="${b:$i:1}"
        if [[ $digit_a -gt $digit_b ]]; then
            echo "1"; return 0
        elif [[ $digit_a -lt $digit_b ]]; then
            echo "-1"; return 0
        fi
    done
    
    echo "0"; return 0
}

# 大数加法
purebash_bigint_add() {
    local a="$1" b="$2"
    
    purebash_bigint_validate "$a" || return 1
    purebash_bigint_validate "$b" || return 1
    
    # 移除前导零
    a="${a#${a%%[!0]*}}"; a="${a:-0}"
    b="${b#${b%%[!0]*}}"; b="${b:-0}"
    
    local result=""
    local carry=0
    local len_a=${#a} len_b=${#b}
    local max_len=$((len_a > len_b ? len_a : len_b))
    
    # 补齐长度
    while [[ ${#a} -lt $max_len ]]; do a="0$a"; done
    while [[ ${#b} -lt $max_len ]]; do b="0$b"; done
    
    # 从右到左逐位相加
    for ((i=max_len-1; i>=0; i--)); do
        local digit_a="${a:$i:1}"
        local digit_b="${b:$i:1}"
        local sum=$((digit_a + digit_b + carry))
        
        result="$((sum % 10))$result"
        carry=$((sum / 10))
    done
    
    # 处理最后的进位
    while [[ $carry -gt 0 ]]; do
        result="$((carry % 10))$result"
        carry=$((carry / 10))
    done
    
    # 移除前导零
    result="${result#${result%%[!0]*}}"; result="${result:-0}"
    echo "$result"
}

# 大数减法
purebash_bigint_subtract() {
    local a="$1" b="$2"
    
    purebash_bigint_validate "$a" || return 1
    purebash_bigint_validate "$b" || return 1
    
    # 确保a >= b
    local cmp=$(purebash_bigint_compare "$a" "$b")
    if [[ "$cmp" -lt 0 ]]; then
        echo "错误: 被减数不能小于减数" >&2
        return 1
    elif [[ "$cmp" -eq 0 ]]; then
        echo "0"
        return 0
    fi
    
    # 移除前导零
    a="${a#${a%%[!0]*}}"; a="${a:-0}"
    b="${b#${b%%[!0]*}}"; b="${b:-0}"
    
    local result=""
    local borrow=0
    local len_a=${#a} len_b=${#b}
    local max_len=$((len_a > len_b ? len_a : len_b))
    
    # 补齐长度
    while [[ ${#a} -lt $max_len ]]; do a="0$a"; done
    while [[ ${#b} -lt $max_len ]]; do b="0$b"; done
    
    # 从右到左逐位相减
    for ((i=max_len-1; i>=0; i--)); do
        local digit_a="${a:$i:1}"
        local digit_b="${b:$i:1}"
        
        local diff=$((digit_a - digit_b - borrow))
        
        if [[ $diff -lt 0 ]]; then
            diff=$((diff + 10))
            borrow=1
        else
            borrow=0
        fi
        
        result="$diff$result"
    done
    
    # 移除前导零
    result="${result#${result%%[!0]*}}"; result="${result:-0}"
    echo "$result"
}

# 大数乘法（简化版 - 使用小学乘法算法）
purebash_bigint_multiply() {
    local a="$1" b="$2"
    
    purebash_bigint_validate "$a" || return 1
    purebash_bigint_validate "$b" || return 1
    
    # 处理零的情况
    if [[ "$a" == "0" ]] || [[ "$b" == "0" ]]; then
        echo "0"
        return 0
    fi
    
    # 移除前导零
    a="${a#${a%%[!0]*}}"; a="${a:-0}"
    b="${b#${b%%[!0]*}}"; b="${b:-0}"
    
    local result="0"
    local len_a=${#a} len_b=${#b}
    
    # 逐位相乘（简化实现）
    for ((i=len_b-1; i>=0; i--)); do
        local digit_b="${b:$i:1}"
        local partial=""
        local carry=0
        
        # 当前位乘法
        for ((j=len_a-1; j>=0; j--)); do
            local digit_a="${a:$j:1}"
            local product=$((digit_a * digit_b + carry))
            partial="$((product % 10))$partial"
            carry=$((product / 10))
        done
        
        # 处理进位
        while [[ $carry -gt 0 ]]; do
            partial="$((carry % 10))$partial"
            carry=$((carry / 10))
        done
        
        # 添加适当数量的零（位移）
        for ((k=0; k<len_b-1-i; k++)); do
            partial="${partial}0"
        done
        
        # 累加到结果
        result=$(purebash_bigint_add "$result" "$partial")
    done
    
    echo "$result"
}

# 大数模运算（简化版）
purebash_bigint_mod() {
    local a="$1" b="$2"
    
    purebash_bigint_validate "$a" || return 1
    purebash_bigint_validate "$b" || return 1
    
    if [[ "$b" == "0" ]]; then
        echo "错误: 模数不能为零" >&2
        return 1
    fi
    
    if [[ "$b" == "1" ]]; then
        echo "0"
        return 0
    fi
    
    # 使用减法实现模运算
    local result="$a"
    while true; do
        local cmp=$(purebash_bigint_compare "$result" "$b")
        if [[ "$cmp" -lt 0 ]]; then
            break
        fi
        result=$(purebash_bigint_subtract "$result" "$b")
    done
    
    echo "$result"
}

# 大数模幂运算（简化版）
purebash_bigint_mod_pow() {
    local base="$1" exp="$2" mod="$3"
    
    purebash_bigint_validate "$base" || return 1
    purebash_bigint_validate "$exp" || return 1
    purebash_bigint_validate "$mod" || return 1
    
    if [[ "$mod" == "1" ]]; then
        echo "0"
        return 0
    fi
    
    # 简化实现：使用重复平方算法
    local result="1"
    base=$(purebash_bigint_mod "$base" "$mod")
    
    while [[ "$exp" != "0" ]]; do
        local last_digit="${exp: -1}"
        if [[ "$last_digit" == "1" ]] || [[ "$last_digit" == "3" ]] || [[ "$last_digit" == "5" ]] || [[ "$last_digit" == "7" ]] || [[ "$last_digit" == "9" ]]; then
            result=$(purebash_bigint_mod "$(purebash_bigint_multiply "$result" "$base")" "$mod")
        fi
        
        base=$(purebash_bigint_mod "$(purebash_bigint_multiply "$base" "$base")" "$mod")
        exp="${exp%?}"  # 移除最后一位
    done
    
    echo "$result"
}

# 生成大素数（简化版 - 用于测试）
purebash_bigint_generate_prime() {
    local bits="$1"
    local candidate=""
    
    # 生成指定位数的随机数
    for ((i=0; i<bits; i++)); do
        candidate="$((RANDOM % 10))$candidate"
    done
    
    # 确保是奇数且不以0开头
    candidate="${candidate%1}1"
    candidate="${candidate#0}"
    if [[ -z "$candidate" ]]; then
        candidate="1"
    fi
    
    echo "$candidate"
}

# 测试扩展大数功能
purebash_bigint_test() {
    echo "=== 扩展大数功能测试 ==="
    echo "测试大数运算（支持任意精度）:"
    
    # 测试大数加法
    echo "1. 大数加法测试:"
    local big_num1="123456789012345678901234567890"
    local big_num2="987654321098765432109876543210"
    local sum=$(purebash_bigint_add "$big_num1" "$big_num2")
    echo "  $big_num1 + $big_num2 = $sum"
    
    # 测试大数减法
    echo "2. 大数减法测试:"
    local diff=$(purebash_bigint_subtract "$big_num2" "$big_num1")
    echo "  $big_num2 - $big_num1 = $diff"
    
    # 测试大数乘法
    echo "3. 大数乘法测试:"
    local product=$(purebash_bigint_multiply "12345" "67890")
    echo "  12345 × 67890 = $product"
    
    # 测试大数模运算
    echo "4. 大数模运算测试:"
    local mod_result=$(purebash_bigint_mod "123456789" "97")
    echo "  123456789 mod 97 = $mod_result"
    
    # 测试大数模幂运算
    echo "5. 大数模幂运算测试:"
    local pow_result=$(purebash_bigint_mod_pow "2" "10" "1000")
    echo "  2^10 mod 1000 = $pow_result"
    
    # 测试比较功能
    echo "6. 大数比较测试:"
    local cmp1=$(purebash_bigint_compare "123456" "654321")
    local cmp2=$(purebash_bigint_compare "999999" "111111")
    echo "  123456 vs 654321: $cmp1 (1表示大于)"
    echo "  999999 vs 111111: $cmp2 (1表示大于)"
    
    echo "✅ 扩展大数功能测试完成！"
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    purebash_bigint_test
fi