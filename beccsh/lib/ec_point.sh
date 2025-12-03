#!/bin/bash
# ec_point.sh - 椭圆曲线点加法与标量乘法

source big_math.sh

# 点加倍 P + P
point_double() {
    local x="$1" y="$2"
    
    # λ = (3x² + a) / (2y) mod p
    local numerator
    numerator=$(bn_mod_add $(bn_mod_mul "3" $(bn_mod_mul "$x" "$x" "$CURVE_P") "$CURVE_P") "$CURVE_A" "$CURVE_P")
    
    local denominator
    denominator=$(bn_mod_mul "2" "$y" "$CURVE_P")
    
    local lambda
    lambda=$(bn_mod_mul "$numerator" $(bn_mod_inverse "$denominator" "$CURVE_P") "$CURVE_P")
    
    # x₃ = λ² - 2x mod p
    local x3
    x3=$(bn_mod_sub $(bn_mod_mul "$lambda" "$lambda" "$CURVE_P") $(bn_mod_mul "2" "$x" "$CURVE_P") "$CURVE_P")
    
    # y₃ = λ(x - x₃) - y mod p
    local y3
    y3=$(bn_mod_sub $(bn_mod_mul "$lambda" $(bn_mod_sub "$x" "$x3" "$CURVE_P") "$CURVE_P") "$y" "$CURVE_P")
    
    echo "$x3 $y3"
}

# 点加法 P + Q
point_add() {
    local x1="$1" y1="$2" x2="$3" y2="$4"
    
    # 处理无穷远点
    if [ "$x1" = "" ] || [ "$y1" = "" ]; then
        echo "$x2 $y2"
        return
    fi
    
    if [ "$x2" = "" ] || [ "$y2" = "" ]; then
        echo "$x1 $y1"
        return
    fi
    
    # 如果两点相同，使用点加倍
    if [ "$x1" = "$x2" ] && [ "$y1" = "$y2" ]; then
        point_double "$x1" "$y1"
        return
    fi
    
    # λ = (y₂ - y₁) / (x₂ - x₁) mod p
    local numerator
    numerator=$(bn_mod_sub "$y2" "$y1" "$CURVE_P")
    
    local denominator
    denominator=$(bn_mod_sub "$x2" "$x1" "$CURVE_P")
    
    local lambda
    lambda=$(bn_mod_mul "$numerator" $(bn_mod_inverse "$denominator" "$CURVE_P") "$CURVE_P")
    
    # x₃ = λ² - x₁ - x₂ mod p
    local x3
    x3=$(bn_mod_sub $(bn_mod_sub $(bn_mod_mul "$lambda" "$lambda" "$CURVE_P") "$x1" "$CURVE_P") "$x2" "$CURVE_P")
    
    # y₃ = λ(x₁ - x₃) - y₁ mod p
    local y3
    y3=$(bn_mod_sub $(bn_mod_mul "$lambda" $(bn_mod_sub "$x1" "$x3" "$CURVE_P") "$CURVE_P") "$y1" "$CURVE_P")
    
    echo "$x3 $y3"
}

# 标量乘法 k * P（二进制算法）
scalar_mult() {
    local k="$1" px="$2" py="$3"
    
    # 结果点（初始为无穷远点）
    local rx="" ry=""
    
    # 当前倍点
    local cx="$px" cy="$py"
    
    # 遍历k的每一位（从LSB到MSB）
    local i bit
    for (( i = 0; i < 256; i++ )); do
        bit=$(( (k >> i) & 1 ))
        
        if [ $bit -eq 1 ]; then
            # rx, ry = rx, ry + cx, cy
            read -r rx ry < <(point_add "$rx" "$ry" "$cx" "$cy")
        fi
        
        # cx, cy = 2*cx, cy
        read -r cx cy < <(point_double "$cx" "$cy")
        
        # 进度显示（每16位显示一次）
        if [ $(( i % 16 )) -eq 15 ]; then
            printf "%d%% " $(( (i + 1) * 100 / 256 )) >&2
        fi
    done
    
    echo "$rx $ry"
}