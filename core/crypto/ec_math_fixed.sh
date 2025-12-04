#!/bin/bash
# 修复的椭圆曲线数学运算
# 简化的ECDSA签名实现

set -euo pipefail

# 大数模运算 - 修复版本
bigint_mod() {
    local num="$1"
    local mod="$2"
    
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "print($num % $mod)"
    elif command -v python >/dev/null 2>&1; then
        python -c "print($num % $mod)"
    elif command -v bc >/dev/null 2>&1; then
        echo "$num % $mod" | BC_LINE_LENGTH=0 bc
    else
        echo "错误: 需要python或bc进行大数运算" >&2
        return 1
    fi
}

# 大数比较
bigint_compare() {
    local a="$1"
    local b="$2"
    
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "print(($a > $b) - ($a < $b))"
    elif command -v python >/dev/null 2>&1; then
        python -c "print(($a > $b) - ($a < $b))"
    elif command -v bc >/dev/null 2>&1; then
        echo "if ($a > $b) 1 else if ($a < $b) -1 else 0" | BC_LINE_LENGTH=0 bc
    else
        echo "0"
    fi
}

# 大数减法
bigint_subtract() {
    local a="$1"
    local b="$2"
    
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "print($a - $b)"
    elif command -v python >/dev/null 2>&1; then
        python -c "print($a - $b)"
    elif command -v bc >/dev/null 2>&1; then
        echo "$a - $b" | BC_LINE_LENGTH=0 bc
    else
        echo "0"
    fi
}

# 模逆元 - 使用扩展欧几里得算法
mod_inverse() {
    local a="$1"
    local m="$2"
    
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
def extended_gcd(a, b):
    if a == 0:
        return b, 0, 1
    gcd, x1, y1 = extended_gcd(b % a, a)
    x = y1 - (b // a) * x1
    y = x1
    return gcd, x, y

def mod_inverse(a, m):
    gcd, x, y = extended_gcd(a, m)
    if gcd != 1:
        return None
    return (x % m + m) % m

result = mod_inverse($a, $m)
print(result if result is not None else 0)
"
    elif command -v python >/dev/null 2>&1; then
        python -c "
def extended_gcd(a, b):
    if a == 0:
        return b, 0, 1
    gcd, x1, y1 = extended_gcd(b % a, a)
    x = y1 - (b // a) * x1
    y = x1
    return gcd, x, y

def mod_inverse(a, m):
    gcd, x, y = extended_gcd(a, m)
    if gcd != 1:
        return None
    return (x % m + m) % m

result = mod_inverse($a, $m)
print(result if result is not None else 0)
"
    elif command -v bc >/dev/null 2>&1; then
        # 使用bc的简单实现
        echo "define inv(a, m) {
    if (a < 0) a = a + m
    return (m + inv_helper(a, m)) % m
}
define inv_helper(a, m) {
    if (a == 1) return 0
    return ((m - inv_helper(m % a, a)) * m / a)
}
inv($a, $m)" | BC_LINE_LENGTH=0 bc
    else
        echo "1"
    fi
}

# 模加法
mod_add() {
    local a="$1" b="$2" p="$3"
    
    local result=$(bigint_add "$a" "$b")
    bigint_mod "$result" "$p"
}

# 模减法
mod_sub() {
    local a="$1" b="$2" p="$3"
    
    local result=$(bigint_subtract "$a" "$b")
    # 确保结果为正
    while [[ $(bigint_compare "$result" "0") -lt 0 ]]; do
        result=$(bigint_add "$result" "$p")
    done
    bigint_mod "$result" "$p"
}

# 模乘法
mod_mult() {
    local a="$1" b="$2" p="$3"
    
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "print(($a * $b) % $p)"
    elif command -v python >/dev/null 2>&1; then
        python -c "print(($a * $b) % $p)"
    elif command -v bc >/dev/null 2>&1; then
        echo "($a * $b) % $p" | BC_LINE_LENGTH=0 bc
    else
        echo "0"
    fi
}

# 大数加法
bigint_add() {
    local a="$1"
    local b="$2"
    
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "print($a + $b)"
    elif command -v python >/dev/null 2>&1; then
        python -c "print($a + $b)"
    elif command -v bc >/dev/null 2>&1; then
        echo "$a + $b" | BC_LINE_LENGTH=0 bc
    else
        echo "0"
    fi
}

# 椭圆曲线点加法 - 简化实现
ec_point_add() {
    local x1="$1" y1="$2" x2="$3" y2="$4" a="$5" p="$6"
    
    # 处理无穷远点
    if [[ "$x1" == "0" && "$y1" == "0" ]]; then
        echo "$x2 $y2"
        return 0
    fi
    if [[ "$x2" == "0" && "$y2" == "0" ]]; then
        echo "$x1 $y1"
        return 0
    fi
    
    # 检查是否相同点
    if [[ "$x1" == "$x2" ]]; then
        if [[ "$y1" == "$y2" ]]; then
            # 倍点运算
            local three_x1_sq=$(mod_mult "3" "$(mod_mult "$x1" "$x1" "$p")" "$p")
            local lambda=$(mod_add "$three_x1_sq" "$a" "$p")
            local two_y1=$(mod_mult "2" "$y1" "$p")
            local two_y1_inv=$(mod_inverse "$two_y1" "$p")
            
            if [[ "$two_y1_inv" == "0" ]]; then
                echo "0 0"  # 无穷远点
                return 0
            fi
            
            lambda=$(mod_mult "$lambda" "$two_y1_inv" "$p")
        else
            # P + (-P) = O
            echo "0 0"
            return 0
        fi
    else
        # 一般点加法
        local lambda=$(mod_sub "$y2" "$y1" "$p")
        local denom=$(mod_sub "$x2" "$x1" "$p")
        local denom_inv=$(mod_inverse "$denom" "$p")
        
        if [[ "$denom_inv" == "0" ]]; then
            echo "0 0"  # 无穷远点
            return 0
        fi
        
        lambda=$(mod_mult "$lambda" "$denom_inv" "$p")
    fi
    
    # 计算结果点
    local x3=$(mod_sub "$(mod_mult "$lambda" "$lambda" "$p")" "$x1" "$p")
    x3=$(mod_sub "$x3" "$x2" "$p")
    
    local y3=$(mod_sub "$x1" "$x3" "$p")
    y3=$(mod_mult "$lambda" "$y3" "$p")
    y3=$(mod_sub "$y3" "$y1" "$p")
    
    echo "$x3 $y3"
}

# 椭圆曲线标量乘法 - 双倍加法算法
ec_scalar_mult() {
    local k="$1" gx="$2" gy="$3" a="$4" p="$5"
    
    # 处理k=0的情况
    if [[ "$k" == "0" ]]; then
        echo "0 0"
        return 0
    fi
    
    local result_x="0"
    local result_y="0"
    local current_x="$gx"
    local current_y="$gy"
    
    while [[ "$k" -gt 0 ]]; do
        if [[ $((k % 2)) -eq 1 ]]; then
            # result = result + current
            if [[ "$result_x" != "0" || "$result_y" != "0" ]]; then
                local result=$(ec_point_add "$result_x" "$result_y" "$current_x" "$current_y" "$a" "$p")
                result_x=$(echo "$result" | cut -d' ' -f1)
                result_y=$(echo "$result" | cut -d' ' -f2)
            else
                result_x="$current_x"
                result_y="$current_y"
            fi
        fi
        
        # current = current + current (倍点)
        local current=$(ec_point_add "$current_x" "$current_y" "$current_x" "$current_y" "$a" "$p")
        current_x=$(echo "$current" | cut -d' ' -f1)
        current_y=$(echo "$current" | cut -d' ' -f2)
        
        k=$((k / 2))
    done
    
    echo "$result_x $result_y"
}

# 简化的ECDSA签名
ecdsa_sign_simple() {
    local private_key="$1"
    local message_hash="$2"
    local curve_name="$3"
    
    # 获取曲线参数
    local params
    case "$curve_name" in
        "secp256k1")
            source "${SCRIPT_DIR}/core/curves/secp256k1_params.sh" 2>/dev/null || return 1
            params=$(get_secp256k1_params)
            ;;
        "secp256r1")
            source "${SCRIPT_DIR}/core/curves/secp256r1_params.sh" 2>/dev/null || return 1
            params=$(get_secp256r1_params)
            ;;
        *)
            echo "错误: 不支持的曲线 $curve_name" >&2
            return 1
            ;;
    esac
    
    local p=$(echo "$params" | cut -d' ' -f1)
    local a=$(echo "$params" | cut -d' ' -f2)
    local b=$(echo "$params" | cut -d' ' -f3)
    local gx=$(echo "$params" | cut -d' ' -f4)
    local gy=$(echo "$params" | cut -d' ' -f5)
    local n=$(echo "$params" | cut -d' ' -f6)
    
    # 确保私钥在有效范围内
    if [[ $(bigint_compare "$private_key" "1") -lt 0 || \
          $(bigint_compare "$private_key" $(bigint_subtract "$n" "1")) -gt 0 ]]; then
        echo "错误: 私钥超出有效范围" >&2
        return 1
    fi
    
    # 简单的k值生成 (实际应用中应使用更安全的随机数生成)
    local k=$(bigint_mod "$(date +%s%N)" "$n")
    if [[ $(bigint_compare "$k" "1") -le 0 ]]; then
        k="2"
    fi
    
    # 计算 k × G
    local k_point=$(ec_scalar_mult "$k" "$gx" "$gy" "$a" "$p")
    local rx=$(echo "$k_point" | cut -d' ' -f1)
    local ry=$(echo "$k_point" | cut -d' ' -f2)
    
    # 计算 r = rx mod n
    local r=$(bigint_mod "$rx" "$n")
    if [[ "$r" == "0" ]]; then
        echo "错误: r = 0，需要重新生成k" >&2
        return 1
    fi
    
    # 计算 s = k⁻¹(hash + private_key × r) mod n
    local k_inv=$(mod_inverse "$k" "$n")
    if [[ "$k_inv" == "0" ]]; then
        echo "错误: 无法计算k的逆元" >&2
        return 1
    fi
    
    local dr=$(bigint_mod "$(bigint_multiply "$private_key" "$r")" "$n")
    local hash_dr=$(bigint_mod "$(bigint_add "$message_hash" "$dr")" "$n")
    local s=$(bigint_mod "$(bigint_multiply "$k_inv" "$hash_dr")" "$n")
    
    if [[ "$s" == "0" ]]; then
        echo "错误: s = 0，需要重新生成k" >&2
        return 1
    fi
    
    # 返回签名
    echo "$r $s"
}

# 简化的ECDSA验证
ecdsa_verify_simple() {
    local public_key_x="$1"
    local public_key_y="$2"
    local message_hash="$3"
    local r="$4"
    local s="$5"
    local curve_name="$6"
    
    # 获取曲线参数
    local params
    case "$curve_name" in
        "secp256k1")
            source "${SCRIPT_DIR}/core/curves/secp256k1_params.sh" 2>/dev/null || return 1
            params=$(get_secp256k1_params)
            ;;
        "secp256r1")
            source "${SCRIPT_DIR}/core/curves/secp256r1_params.sh" 2>/dev/null || return 1
            params=$(get_secp256r1_params)
            ;;
        *)
            echo "错误: 不支持的曲线 $curve_name" >&2
            return 1
            ;;
    esac
    
    local p=$(echo "$params" | cut -d' ' -f1)
    local a=$(echo "$params" | cut -d' ' -f2)
    local b=$(echo "$params" | cut -d' ' -f3)
    local gx=$(echo "$params" | cut -d' ' -f4)
    local gy=$(echo "$params" | cut -d' ' -f5)
    local n=$(echo "$params" | cut -d' ' -f6)
    
    # 验证r和s的范围
    if [[ $(bigint_compare "$r" "1") -lt 0 || \
          $(bigint_compare "$r" $(bigint_subtract "$n" "1")) -gt 0 ]]; then
        return 1
    fi
    
    if [[ $(bigint_compare "$s" "1") -lt 0 || \
          $(bigint_compare "$s" $(bigint_subtract "$n" "1")) -gt 0 ]]; then
        return 1
    fi
    
    # 计算 s⁻¹
    local s_inv=$(mod_inverse "$s" "$n")
    if [[ "$s_inv" == "0" ]]; then
        return 1
    fi
    
    # 计算 u₁ = hash × s⁻¹ mod n
    local u1=$(bigint_mod "$(bigint_multiply "$message_hash" "$s_inv")" "$n")
    
    # 计算 u₂ = r × s⁻¹ mod n
    local u2=$(bigint_mod "$(bigint_multiply "$r" "$s_inv")" "$n")
    
    # 计算 P = u₁ × G + u₂ × Q
    local u1_point=$(ec_scalar_mult "$u1" "$gx" "$gy" "$a" "$p")
    local u2_point=$(ec_scalar_mult "$u2" "$public_key_x" "$public_key_y" "$a" "$p")
    
    local u1x=$(echo "$u1_point" | cut -d' ' -f1)
    local u1y=$(echo "$u1_point" | cut -d' ' -f2)
    local u2x=$(echo "$u2_point" | cut -d' ' -f1)
    local u2y=$(echo "$u2_point" | cut -d' ' -f2)
    
    local sum_point=$(ec_point_add "$u1x" "$u1y" "$u2x" "$u2y" "$a" "$p")
    local sum_x=$(echo "$sum_point" | cut -d' ' -f1)
    
    # 验证 v = sum_x mod n == r
    local v=$(bigint_mod "$sum_x" "$n")
    
    if [[ "$v" == "$r" ]]; then
        return 0  # 验证通过
    else
        return 1  # 验证失败
    fi
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "修复的椭圆曲线数学运算测试"
    echo "==================================="
    
    # 测试基本运算
    echo "测试模运算:"
    echo "10 mod 7 = $(bigint_mod 10 7)"
    echo "15 mod 6 = $(bigint_mod 15 6)"
    
    # 测试模逆元
    echo "测试模逆元:"
    echo "3⁻¹ mod 7 = $(mod_inverse 3 7)"
    echo "5⁻¹ mod 11 = $(mod_inverse 5 11)"
    
    # 测试点加法（使用小参数）
    echo "测试点加法:"
    test_result=$(ec_point_add "3" "4" "1" "2" "1" "7")
    echo "(3,4) + (1,2) on y² = x³ + x + 1 mod 7 = $test_result"
    
    echo "==================================="
    echo "✅ 基础数学运算测试完成"
fi