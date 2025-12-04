#!/bin/bash
# 优化的椭圆曲线数学运算 - 性能修复版本
# 不在乎性能开销，只关注功能正确性

set -euo pipefail

# 大数运算函数 - 使用Python确保精度
bigint_add() {
    local a="$1"
    local b="$2"
    python3 -c "print($a + $b)"
}

bigint_subtract() {
    local a="$1"
    local b="$2"
    python3 -c "print($a - $b)"
}

bigint_multiply() {
    local a="$1"
    local b="$2"
    python3 -c "print($a * $b)"
}

bigint_mod() {
    local a="$1"
    local m="$2"
    python3 -c "print($a % $m)"
}

bigint_compare() {
    local a="$1"
    local b="$2"
    python3 -c "print(($a > $b) - ($a < $b))"
}

# 扩展欧几里得算法求模逆元
mod_inverse() {
    local a="$1"
    local m="$2"
    
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
}

# 优化的模运算
mod_add() {
    local a="$1" b="$2" p="$3"
    python3 -c "print(($a + $b) % $p)"
}

mod_sub() {
    local a="$1" b="$2" p="$3"
    python3 -c "print(($a - $b) % $p)"
}

mod_mult() {
    local a="$1" b="$2" p="$3"
    python3 -c "print(($a * $b) % $p)"
}

# 优化的椭圆曲线点加法 - 性能修复版本
ec_point_add_optimized() {
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
    
    # 使用Python进行精确计算，避免Bash大数问题
    python3 -c "
import sys
x1, y1, x2, y2, a, p = map(int, sys.argv[1:7])

if x1 == x2:
    if y1 == y2:
        # 倍点运算
        if y1 == 0:
            print('0 0')
            exit(0)
        
        # λ = (3x² + a) / (2y) mod p
        lam = (3 * x1 * x1 + a) * pow(2 * y1, -1, p) % p
    else:
        # P + (-P) = O
        print('0 0')
        exit(0)
else:
    # λ = (y₂ - y₁) / (x₂ - x₁) mod p
    numerator = (y2 - y1) % p
    denominator = (x2 - x1) % p
    if denominator == 0:
        print('0 0')
        exit(0)
    
    lam = numerator * pow(denominator, -1, p) % p

# 计算结果点
x3 = (lam * lam - x1 - x2) % p
y3 = (lam * (x1 - x3) - y1) % p

print(f'{x3} {y3}')
" "$x1" "$y1" "$x2" "$y2" "$a" "$p"
}

# 优化的标量乘法 - 性能修复版本
ec_scalar_mult_optimized() {
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
    local remaining_k="$k"
    
    # 使用Python进行高效计算
    python3 -c "
import sys
k, gx, gy, a, p = map(int, sys.argv[1:6])

result_x, result_y = 0, 0
current_x, current_y = gx, gy

while k > 0:
    if k % 2 == 1:
        if result_x == 0 and result_y == 0:
            result_x, result_y = current_x, current_y
        else:
            # 点加法
            if result_x == current_x:
                if result_y == current_y:
                    # 倍点运算
                    if result_y == 0:
                        result_x, result_y = 0, 0
                    else:
                        lambda_num = (3 * result_x * result_x + a) % p
                        lambda_den = pow(2 * result_y, -1, p)
                        if lambda_den == 0:
                            result_x, result_y = 0, 0
                        else:
                            lam = (lambda_num * lambda_den) % p
                            x3 = (lam * lam - 2 * result_x) % p
                            y3 = (lam * (result_x - x3) - result_y) % p
                            result_x, result_y = x3, y3
                else:
                    result_x, result_y = 0, 0
            else:
                # 一般点加法
                numerator = (current_y - result_y) % p
                denominator = (current_x - result_x) % p
                if denominator == 0:
                    result_x, result_y = 0, 0
                else:
                    lam = (numerator * pow(denominator, -1, p)) % p
                    x3 = (lam * lam - result_x - current_x) % p
                    y3 = (lam * (result_x - x3) - result_y) % p
                    result_x, result_y = x3, y3
    
    # 倍点运算
    if current_y == 0:
        current_x, current_y = 0, 0
    else:
        lambda_num = (3 * current_x * current_x + a) % p
        lambda_den = pow(2 * current_y, -1, p)
        if lambda_den == 0:
            current_x, current_y = 0, 0
        else:
            lam = (lambda_num * lambda_den) % p
            x3 = (lam * lam - 2 * current_x) % p
            y3 = (lam * (current_x - x3) - current_y) % p
            current_x, current_y = x3, y3
    
    k = k // 2

print(f'{result_x} {result_y}')
" "$k" "$gx" "$gy" "$a" "$p"
}

# 安全的确定性k值生成 - 性能优化版本
generate_deterministic_k_optimized() {
    local private_key="$1"
    local message_hash="$2"
    local curve_order="$3"
    local counter="${4:-0}"
    
    # 使用简单的确定性方法
    local hmac_input="${private_key}${message_hash}${counter}"
    local k_seed=$(echo -n "$hmac_input" | sha256sum | cut -d' ' -f1)
    
    # 生成k值
    local k=$(python3 -c "
import hashlib
seed = '$k_seed'
n = int('$curve_order')

# 生成确定性随机数
k = int(seed, 16)
k = (k % (n - 1)) + 1
print(k)
")
    
    # 验证k值有效性
    if [[ $(python3 -c "print($k > 1 and $k < $curve_order)") == "True" ]]; then
        echo "$k"
    else
        # 重新生成
        if [[ $counter -lt 5 ]]; then
            generate_deterministic_k_optimized "$private_key" "$message_hash" "$curve_order" $((counter + 1))
        else
            echo "$(python3 -c "print(($curve_order // 2) + 1)")"  # 回退值
        fi
    fi
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "优化的椭圆曲线数学运算测试"
    echo "==================================="
    
    # 测试基本运算
    echo "测试模运算:"
    echo "10 mod 7 = $(mod_add 10 0 7)"
    echo "15 mod 6 = $(mod_add 15 0 6)"
    
    # 测试模逆元
    echo "测试模逆元:"
    echo "3⁻¹ mod 7 = $(mod_inverse 3 7)"
    echo "5⁻¹ mod 11 = $(mod_inverse 5 11)"
    
    # 测试点加法
    echo "测试点加法:"
    test_result=$(ec_point_add_optimized "3" "4" "1" "2" "1" "7")
    echo "(3,4) + (1,2) on y² = x³ + x + 1 mod 7 = $test_result"
    
    echo "==================================="
    echo "✅ 优化的数学运算测试完成"
fi