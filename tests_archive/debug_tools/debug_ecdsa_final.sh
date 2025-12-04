#!/bin/bash
# 详细调试ECDSA最终版本

set -euo pipefail

# 简化的椭圆曲线运算
mod_simple() {
    local a="$1"
    local m="$2"
    echo $((a % m))
}

mod_inverse_simple() {
    local a="$1"
    local m="$2"
    
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

# 正确的椭圆曲线点加法
curve_point_add_correct() {
    local x1="$1" y1="$2" x2="$3" y2="$4" a="$5" p="$6"
    
    echo "DEBUG: 点加法: ($x1,$y1) + ($x2,$y2) on y² = x³ + ${a}x + 1 mod $p" >&2
    
    # 处理无穷远点
    if [[ "$x1" == "0" && "$y1" == "0" ]]; then
        echo "DEBUG: 返回点2" >&2
        echo "$x2 $y2"
        return 0
    fi
    if [[ "$x2" == "0" && "$y2" == "0" ]]; then
        echo "DEBUG: 返回点1" >&2
        echo "$x1 $y1"
        return 0
    fi
    
    # 计算斜率
    local lambda
    if [[ "$x1" == "$x2" ]]; then
        if [[ "$y1" == "$y2" ]]; then
            # 倍点运算: λ = (3x² + a) / (2y) mod p
            echo "DEBUG: 倍点运算" >&2
            local three_x1_sq=$((3 * x1 * x1))
            local numerator=$((three_x1_sq + a))
            local two_y1=$((2 * y1))
            
            # 确保分子为正
            while [[ $numerator -lt 0 ]]; do
                numerator=$((numerator + p))
            done
            
            # 确保分母为正
            while [[ $two_y1 -lt 0 ]]; do
                two_y1=$((two_y1 + p))
            done
            
            # 计算模逆元
            local two_y1_inv=$(mod_inverse_simple "$two_y1" "$p")
            lambda=$(((numerator * two_y1_inv) % p))
            echo "DEBUG: λ = (3x₁² + a) / (2y₁) = $lambda" >&2
        else
            echo "DEBUG: P + (-P) = O" >&2
            echo "0 0"
            return 0
        fi
    else
        # 一般点加法: λ = (y₂ - y₁) / (x₂ - x₁) mod p
        echo "DEBUG: 一般点加法" >&2
        local numerator=$((y2 - y1))
        local denominator=$((x2 - x1))
        
        # 确保分子为正
        while [[ $numerator -lt 0 ]]; do
            numerator=$((numerator + p))
        done
        
        # 确保分母为正
        while [[ $denominator -lt 0 ]]; do
            denominator=$((denominator + p))
        done
        
        # 计算模逆元
        local denom_inv=$(mod_inverse_simple "$denominator" "$p")
        lambda=$(((numerator * denom_inv) % p))
        echo "DEBUG: λ = (y₂ - y₁) / (x₂ - x₁) = $lambda" >&2
    fi
    
    # 计算结果点
    local x3=$(((lambda * lambda - x1 - x2) % p))
    if [[ $x3 -lt 0 ]]; then
        x3=$((x3 + p))
    fi
    
    local y3=$(((lambda * (x1 - x3) - y1) % p))
    if [[ $y3 -lt 0 ]]; then
        y3=$((y3 + p))
    fi
    
    echo "DEBUG: 结果点: ($x3, $y3)" >&2
    echo "$x3 $y3"
}

# 正确的标量乘法
curve_scalar_mult_correct() {
    local k="$1" gx="$2" gy="$3" a="$4" p="$5"
    
    echo "DEBUG: 标量乘法: $k × ($gx, $gy)" >&2
    
    local result_x="0"
    local result_y="0"
    local current_x="$gx"
    local current_y="$gy"
    
    local step=0
    while [[ $k -gt 0 ]]; do
        echo "DEBUG: 步骤 $step: k = $k" >&2
        if [[ $((k % 2)) -eq 1 ]]; then
            echo "DEBUG: 添加当前点 ($current_x, $current_y) 到结果" >&2
            # result = result + current
            if [[ $result_x -ne 0 || $result_y -ne 0 ]]; then
                local result=$(curve_point_add_correct "$result_x" "$result_y" "$current_x" "$current_y" "$a" "$p")
                result_x=$(echo "$result" | cut -d' ' -f1)
                result_y=$(echo "$result" | cut -d' ' -f2)
                echo "DEBUG: 结果: ($result_x, $result_y)" >&2
            else
                result_x="$current_x"
                result_y="$current_y"
                echo "DEBUG: 结果: ($result_x, $result_y)" >&2
            fi
        fi
        
        # current = current + current (倍点)
        echo "DEBUG: 倍点运算: ($current_x, $current_y) + ($current_x, $current_y)" >&2
        local current=$(curve_point_add_correct "$current_x" "$current_y" "$current_x" "$current_y" "$a" "$p")
        current_x=$(echo "$current" | cut -d' ' -f1)
        current_y=$(echo "$current" | cut -d' ' -f2)
        echo "DEBUG: 当前点: ($current_x, $current_y)" >&2
        
        k=$((k / 2))
        step=$((step + 1))
    done
    
    echo "DEBUG: 最终结果: ($result_x, $result_y)" >&2
    echo "$result_x $result_y"
}

# 详细的ECDSA验证调试
debug_ecdsa_verify() {
    local public_key_x="$1"
    local public_key_y="$2"
    local message_hash="$3"
    local r="$4"
    local s="$5"
    local a="$6"
    local p="$7"
    local gx="$8"
    local gy="$9"
    local n="${10}"
    
    echo "=== ECDSA验证详细调试 ==="
    echo "公钥: ($public_key_x, $public_key_y)"
    echo "消息哈希: $message_hash"
    echo "签名: (r=$r, s=$s)"
    echo "曲线阶n: $n"
    echo ""
    
    # 验证r和s的范围
    echo "1. 验证r和s的范围:"
    if [[ $r -lt 1 || $r -gt $((n - 1)) ]]; then
        echo "❌ r = $r 超出范围 [1, $((n-1))]"
        return 1
    fi
    echo "✅ r = $r 在有效范围内"
    
    if [[ $s -lt 1 || $s -gt $((n - 1)) ]]; then
        echo "❌ s = $s 超出范围 [1, $((n-1))]"
        return 1
    fi
    echo "✅ s = $s 在有效范围内"
    echo ""
    
    # 计算 s⁻¹ mod n
    echo "2. 计算 s⁻¹ mod n:"
    local s_inv=$(mod_inverse_simple "$s" "$n")
    echo "s⁻¹ = $s_inv"
    
    if [[ "$s_inv" == "0" ]]; then
        echo "❌ 无法计算s的逆元"
        return 1
    fi
    echo "✅ s⁻¹ 计算成功"
    echo ""
    
    # 计算 u₁ = hash × s⁻¹ mod n
    echo "3. 计算 u₁ = hash × s⁻¹ mod n:"
    local u1=$(mod_simple "$((message_hash * s_inv))" "$n")
    echo "u₁ = $message_hash × $s_inv mod $n = $u1"
    echo "✅ u₁ 计算成功"
    echo ""
    
    # 计算 u₂ = r × s⁻¹ mod n
    echo "4. 计算 u₂ = r × s⁻¹ mod n:"
    local u2=$(mod_simple "$((r * s_inv))" "$n")
    echo "u₂ = $r × $s_inv mod $n = $u2"
    echo "✅ u₂ 计算成功"
    echo ""
    
    # 计算 P = u₁ × G + u₂ × Q
    echo "5. 计算 P = u₁ × G + u₂ × Q:"
    echo "u₁ = $u1"
    echo "u₂ = $u2"
    echo "G = ($gx, $gy)"
    echo "Q = ($public_key_x, $public_key_y)"
    
    local u1_point=$(curve_scalar_mult_correct "$u1" "$gx" "$gy" "$a" "$p")
    local u2_point=$(curve_scalar_mult_correct "$u2" "$public_key_x" "$public_key_y" "$a" "$p")
    
    local u1x=$(echo "$u1_point" | cut -d' ' -f1)
    local u1y=$(echo "$u1_point" | cut -d' ' -f2)
    local u2x=$(echo "$u2_point" | cut -d' ' -f1)
    local u2y=$(echo "$u2_point" | cut -d' ' -f2)
    
    echo "u₁×G = ($u1x, $u1y)"
    echo "u₂×Q = ($u2x, $u2y)"
    
    local sum_point=$(curve_point_add_correct "$u1x" "$u1y" "$u2x" "$u2y" "$a" "$p")
    local sum_x=$(echo "$sum_point" | cut -d' ' -f1)
    local sum_y=$(echo "$sum_point" | cut -d' ' -f2)
    
    echo "P = u₁×G + u₂×Q = ($sum_x, $sum_y)"
    echo "✅ 点加法计算成功"
    echo ""
    
    # 验证 v = sum_x mod n == r
    echo "6. 验证 v = sum_x mod n == r:"
    local v=$(mod_simple "$sum_x" "$n")
    echo "v = $sum_x mod $n = $v"
    echo "r = $r"
    
    if [[ $v -eq $r ]]; then
        echo "✅ 签名验证成功! v = r"
        return 0
    else
        echo "❌ 签名验证失败: v ≠ r"
        echo "期望: v = r = $r"
        echo "实际: v = $v"
        return 1
    fi
}

# 运行详细调试
run_debug_verify() {
    echo "详细ECDSA验证调试"
    echo "=================="
    echo ""
    
    # 使用之前的测试数据
    local public_key_x=11
    local public_key_y=3
    local message_hash=12345
    local r=18
    local s=8
    local a=1
    local p=23
    local gx=3
    local gy=10
    local n=29
    
    debug_ecdsa_verify "$public_key_x" "$public_key_y" "$message_hash" "$r" "$s" "$a" "$p" "$gx" "$gy" "$n"
}

# 如果直接运行此脚本，执行调试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_debug_verify
fi