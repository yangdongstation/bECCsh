#!/bin/bash
# 调试ECDSA计算过程

set -euo pipefail

# 简化的模运算
mod_simple() {
    local a="$1"
    local m="$2"
    echo $((a % m))
}

# 简化的模逆元
mod_inverse_simple() {
    local a="$1"
    local m="$2"
    
    # 扩展欧几里得算法简化版
    local t=0 newt=1
    local r=$m newr=$a
    
    while [[ $newr -ne 0 ]]; do
        local quotient=$((r / newr))
        local temp=$newr
        newr=$((r - quotient * newr))
        r=$temp
        
        temp=$newt
        newt=$((t - quotient * newt))
        t=$temp
    done
    
    if [[ $t -lt 0 ]]; then
        t=$((t + m))
    fi
    
    echo $t
}

# 简化的椭圆曲线点加法
curve_point_add() {
    local x1="$1" y1="$2" x2="$3" y2="$4" a="$5" p="$6"
    
    echo "点加法: ($x1,$y1) + ($x2,$y2) on y² = x³ + ${a}x + ${b} mod $p" >&2
    
    # 处理无穷远点
    if [[ "$x1" == "0" && "$y1" == "0" ]]; then
        echo "$x2 $y2"
        return 0
    fi
    if [[ "$x2" == "0" && "$y2" == "0" ]]; then
        echo "$x1 $y1"
        return 0
    fi
    
    # 计算斜率
    local lambda
    if [[ "$x1" == "$x2" ]]; then
        if [[ "$y1" == "$y2" ]]; then
            # 倍点运算: λ = (3x² + a) / (2y) mod p
            echo "倍点运算" >&2
            local three_x1_sq=$((3 * x1 * x1))
            echo "3x₁² = $three_x1_sq" >&2
            local numerator=$((three_x1_sq + a))
            echo "分子 = 3x₁² + a = $numerator" >&2
            local two_y1=$((2 * y1))
            echo "分母 = 2y₁ = $two_y1" >&2
            
            # 检查分母是否有逆元
            if [[ $((two_y1 % p)) -eq 0 ]]; then
                echo "错误: 分母为0，无法计算逆元" >&2
                echo "0 0"
                return 1
            fi
            
            # 手动计算模逆元（对于小素数）
            local two_y1_inv=1
            for ((i=1; i<p; i++)); do
                if [[ $((two_y1 * i % p)) -eq 1 ]]; then
                    two_y1_inv=$i
                    break
                fi
            done
            echo "分母逆元 = $two_y1_inv" >&2
            
            lambda=$(((numerator * two_y1_inv) % p))
            echo "λ = (3x₁² + a) / (2y₁) = $lambda" >&2
        else
            echo "P + (-P) = O" >&2
            echo "0 0"
            return 0
        fi
    else
        # 一般点加法: λ = (y₂ - y₁) / (x₂ - x₁) mod p
        echo "一般点加法" >&2
        local numerator=$(((y2 - y1 + p) % p))
        echo "分子 = y₂ - y₁ = $numerator" >&2
        local denominator=$(((x2 - x1 + p) % p))
        echo "分母 = x₂ - x₁ = $denominator" >&2
        
        # 手动计算模逆元
        local denom_inv=1
        for ((i=1; i<p; i++)); do
            if [[ $((denominator * i % p)) -eq 1 ]]; then
                denom_inv=$i
                break
            fi
        done
        echo "分母逆元 = $denom_inv" >&2
        
        lambda=$(((numerator * denom_inv) % p))
        echo "λ = (y₂ - y₁) / (x₂ - x₁) = $lambda" >&2
    fi
    
    # 计算结果点
    local x3=$(((lambda * lambda - x1 - x2 + 2 * p) % p))
    local y3=$(((lambda * (x1 - x3) - y1 + p) % p))
    
    echo "x₃ = λ² - x₁ - x₂ = $x3" >&2
    echo "y₃ = λ(x₁ - x₃) - y₁ = $y3" >&2
    
    echo "$x3 $y3"
}

# 简化的标量乘法
curve_scalar_mult() {
    local k="$1" gx="$2" gy="$3" a="$4" p="$5"
    
    echo "标量乘法: $k × ($gx, $gy)" >&2
    
    local result_x="0"
    local result_y="0"
    local current_x="$gx"
    local current_y="$gy"
    
    local step=0
    while [[ $k -gt 0 ]]; do
        echo "步骤 $step: k = $k" >&2
        if [[ $((k % 2)) -eq 1 ]]; then
            echo "  添加当前点 ($current_x, $current_y) 到结果" >&2
            # result = result + current
            if [[ $result_x -ne 0 || $result_y -ne 0 ]]; then
                local result=$(curve_point_add "$result_x" "$result_y" "$current_x" "$current_y" "$a" "$p")
                result_x=$(echo "$result" | cut -d' ' -f1)
                result_y=$(echo "$result" | cut -d' ' -f2)
                echo "  结果: ($result_x, $result_y)" >&2
            else
                result_x="$current_x"
                result_y="$current_y"
                echo "  结果: ($result_x, $result_y)" >&2
            fi
        fi
        
        # current = current + current (倍点)
        echo "  倍点运算: ($current_x, $current_y) + ($current_x, $current_y)" >&2
        local current=$(curve_point_add "$current_x" "$current_y" "$current_x" "$current_y" "$a" "$p")
        current_x=$(echo "$current" | cut -d' ' -f1)
        current_y=$(echo "$current" | cut -d' ' -f2)
        echo "  当前点: ($current_x, $current_y)" >&2
        
        k=$((k / 2))
        step=$((step + 1))
    done
    
    echo "最终结果: ($result_x, $result_y)" >&2
    echo "$result_x $result_y"
}

# 主调试函数
debug_main() {
    echo "=== 椭圆曲线ECDSA调试 ==="
    echo ""
    
    # 曲线: y² = x³ + x + 1 mod 13
    local p=13
    local a=1
    local b=1
    # 基点 G = (0, 1)
    local gx=0
    local gy=1
    
    echo "曲线: y² = x³ + ${a}x + ${b} mod $p"
    echo "基点G: ($gx, $gy)"
    echo ""
    
    # 验证基点是否在曲线上
    echo "验证基点G是否在曲线上:"
    echo "左边: y² = $gy² = $((gy * gy)) mod $p = $(($((gy * gy)) % p))"
    echo "右边: x³ + ${a}x + ${b} = $gx³ + ${a}×$gx + ${b} = $(($((gx * gx * gx)) + a * gx + b)) mod $p = $(($((gx * gx * gx + a * gx + b)) % p))"
    echo ""
    
    # 测试标量乘法
    echo "测试标量乘法:"
    local test_private_key=8
    echo "私钥: $test_private_key"
    echo "计算 $test_private_key × G..."
    
    local public_key=$(curve_scalar_mult "$test_private_key" "$gx" "$gy" "$a" "$p")
    local pub_x=$(echo "$public_key" | cut -d' ' -f1)
    local pub_y=$(echo "$public_key" | cut -d' ' -f2)
    
    echo "公钥: ($pub_x, $pub_y)"
    echo ""
    
    # 测试ECDSA参数（小素数域）
    echo "=== ECDSA参数测试 ==="
    # 阶 n = 19 (已知)
    local n=19
    echo "曲线阶n: $n"
    echo ""
    
    # 测试消息和哈希
    local test_message="Hello, ECDSA!"
    local test_hash=12345  # 简化哈希值
    echo "测试消息: $test_message"
    echo "测试哈希: $test_hash"
    echo ""
    
    # 测试签名
    echo "=== ECDSA签名测试 ==="
    echo "私钥: $test_private_key"
    echo "消息哈希: $test_hash"
    
    # 手动实现ECDSA签名
    echo "手动计算ECDSA签名..."
    
    # 使用简单的k值（实际应用中应使用安全随机数）
    local k=7
    echo "k值: $k"
    
    # 计算 k × G
    echo "计算 k × G..."
    local k_point=$(curve_scalar_mult "$k" "$gx" "$gy" "$a" "$p")
    local rx=$(echo "$k_point" | cut -d' ' -f1)
    local ry=$(echo "$k_point" | cut -d' ' -f2)
    
    echo "k×G = ($rx, $ry)"
    
    # 计算 r = rx mod n
    local r=$((rx % n))
    echo "r = $rx mod $n = $r"
    
    if [[ $r -eq 0 ]]; then
        echo "❌ r = 0，签名失败"
        return 1
    fi
    
    echo "✅ r ≠ 0，继续计算"
    
    # 计算 s = k⁻¹(hash + private_key × r) mod n
    echo "计算 s = k⁻¹(hash + private_key × r) mod n..."
    
    # 计算 k⁻¹ mod n
    local k_inv=$(mod_inverse_simple "$k" "$n")
    echo "k⁻¹ = $k_inv"
    
    # 计算 private_key × r mod n
    local dr=$(((private_key * r) % n))
    echo "private_key × r mod n = $dr"
    
    # 计算 hash + dr mod n
    local hash_dr=$(((test_hash + dr) % n))
    echo "hash + dr mod n = $hash_dr"
    
    # 计算 s = k⁻¹ × (hash + dr) mod n
    local s=$(((k_inv * hash_dr) % n))
    echo "s = k⁻¹ × (hash + dr) mod n = $s"
    
    if [[ $s -eq 0 ]]; then
        echo "❌ s = 0，签名失败"
        return 1
    fi
    
    echo "✅ s ≠ 0，签名生成成功"
    echo "签名: r=$r, s=$s"
    
    # 测试验证
    echo ""
    echo "=== ECDSA验证测试 ==="
    echo "公钥: ($pub_x, $pub_y)"
    echo "签名: (r=$r, s=$s)"
    
    # 手动实现ECDSA验证
    echo "手动计算ECDSA验证..."
    
    # 验证r和s的范围
    if [[ $r -lt 1 || $r -gt $((n - 1)) || $s -lt 1 || $s -gt $((n - 1)) ]]; then
        echo "❌ r或s超出有效范围"
        return 1
    fi
    
    # 计算 s⁻¹ mod n
    local s_inv=$(mod_inverse_simple "$s" "$n")
    echo "s⁻¹ = $s_inv"
    
    # 计算 u₁ = hash × s⁻¹ mod n
    local u1=$(((test_hash * s_inv) % n))
    echo "u₁ = hash × s⁻¹ mod n = $u1"
    
    # 计算 u₂ = r × s⁻¹ mod n
    local u2=$(((r * s_inv) % n))
    echo "u₂ = r × s⁻¹ mod n = $u2"
    
    # 计算 P = u₁ × G + u₂ × Q
    echo "计算 P = u₁ × G + u₂ × Q..."
    local u1_point=$(curve_scalar_mult "$u1" "$gx" "$gy" "$a" "$p")
    local u2_point=$(curve_scalar_mult "$u2" "$pub_x" "$pub_y" "$a" "$p")
    
    local u1x=$(echo "$u1_point" | cut -d' ' -f1)
    local u1y=$(echo "$u1_point" | cut -d' ' -f2)
    local u2x=$(echo "$u2_point" | cut -d' ' -f1)
    local u2y=$(echo "$u2_point" | cut -d' ' -f2)
    
    echo "u₁×G = ($u1x, $u1y)"
    echo "u₂×Q = ($u2x, $u2y)"
    
    local sum_point=$(curve_point_add "$u1x" "$u1y" "$u2x" "$u2y" "$a" "$p")
    local sum_x=$(echo "$sum_point" | cut -d' ' -f1)
    local sum_y=$(echo "$sum_point" | cut -d' ' -f2)
    
    echo "P = u₁×G + u₂×Q = ($sum_x, $sum_y)"
    
    # 验证 v = sum_x mod n == r
    local v=$((sum_x % n))
    echo "v = sum_x mod n = $v"
    echo "r = $r"
    
    if [[ $v -eq $r ]]; then
        echo "✅ 签名验证成功! v = r"
    else
        echo "❌ 签名验证失败: v ≠ r"
    fi
    
    echo ""
    echo "=== 调试完成 ==="
}

# 运行调试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    debug_main
fi