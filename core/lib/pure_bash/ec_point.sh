#!/bin/bash
# EC Point - 椭圆曲线点运算
# 实现椭圆曲线上的点加法和点乘法

set -euo pipefail

# 导入保护 - 防止重复定义
if [[ -n "${EC_POINT_LOADED:-}" ]]; then
    return 0
fi
readonly EC_POINT_LOADED=1

# 导入数学库
source "$(dirname "${BASH_SOURCE[0]}")/bash_math.sh"

# 导入大数运算库
source "$(dirname "${BASH_SOURCE[0]}")/bash_bigint.sh"

# 点运算错误处理
ec_point_error() {
    echo "EC Point错误: $*" >&2
    return 1
}

# 检查点是否在曲线上
ec_point_is_on_curve() {
    local x="$1"
    local y="$2"
    
    if [[ -z "$CURVE_P" || -z "$CURVE_A" || -z "$CURVE_B" ]]; then
        ec_point_error "曲线参数未初始化"
        return 1
    fi
    
    # 计算 y^2 mod p
    local y_squared=$(bigint_mod_pow "$y" "2" "$CURVE_P")
    
    # 计算 x^3 + ax + b mod p
    local x_cubed=$(bigint_mod_pow "$x" "3" "$CURVE_P")
    local ax=$(bigint_mod $(bigint_multiply "$CURVE_A" "$x") "$CURVE_P")
    local rhs=$(bigint_mod $(bigint_add "$x_cubed" $(bigint_add "$ax" "$CURVE_B")) "$CURVE_P")
    
    # 检查是否相等
    if [[ "$y_squared" == "$rhs" ]]; then
        return 0
    else
        return 1
    fi
}

# 点加法 (P + Q)
ec_point_add() {
    local px="$1"
    local py="$2"
    local qx="$3"
    local qy="$4"
    
    if [[ -z "$CURVE_P" || -z "$CURVE_A" ]]; then
        ec_point_error "曲线参数未初始化"
        return 1
    fi
    
    # 处理无穷远点
    if [[ "$px" == "0" && "$py" == "0" ]]; then
        echo "$qx $qy"
        return 0
    fi
    if [[ "$qx" == "0" && "$qy" == "0" ]]; then
        echo "$px $py"
        return 0
    fi
    
    # 检查点是否在曲线上
    if ! ec_point_is_on_curve "$px" "$py"; then
        ec_point_error "点P不在曲线上"
        return 1
    fi
    
    if ! ec_point_is_on_curve "$qx" "$qy"; then
        ec_point_error "点Q不在曲线上"
        return 1
    fi
    
    # P + (-P) = 无穷远点
    if [[ "$px" == "$qx" ]]; then
        if [[ "$py" == "$qy" ]]; then
            # P + P = 2P (点倍)
            ec_point_double "$px" "$py"
            return 0
        elif [[ "$(bigint_add "$py" "$qy")" == "$CURVE_P" ]]; then
            # P + (-P) = 无穷远点
            echo "0 0"
            return 0
        fi
    fi
    
    # 计算斜率 λ = (qy - py) / (qx - px) mod p
    local delta_y=$(bigint_mod $(bigint_subtract "$qy" "$py") "$CURVE_P")
    local delta_x=$(bigint_mod $(bigint_subtract "$qx" "$px") "$CURVE_P")
    
    # 计算 delta_x 的模逆元
    local inv_delta_x=$(bigint_mod_inverse "$delta_x" "$CURVE_P")
    if [[ $? -ne 0 ]]; then
        ec_point_error "无法计算模逆元"
        return 1
    fi
    
    local lambda=$(bigint_mod $(bigint_multiply "$delta_y" "$inv_delta_x") "$CURVE_P")
    
    # 计算 xr = λ^2 - px - qx mod p
    local lambda_squared=$(bigint_mod_pow "$lambda" "2" "$CURVE_P")
    local xr=$(bigint_mod $(bigint_subtract "$lambda_squared" $(bigint_add "$px" "$qx")) "$CURVE_P")
    
    # 计算 yr = λ(px - xr) - py mod p
    local yr=$(bigint_mod $(bigint_subtract $(bigint_multiply "$lambda" $(bigint_subtract "$px" "$xr")) "$py") "$CURVE_P")
    
    echo "$xr $yr"
}

# 点倍法 (2P)
ec_point_double() {
    local px="$1"
    local py="$2"
    
    if [[ -z "$CURVE_P" || -z "$CURVE_A" ]]; then
        ec_point_error "曲线参数未初始化"
        return 1
    fi
    
    # 处理无穷远点
    if [[ "$px" == "0" && "$py" == "0" ]]; then
        echo "0 0"
        return 0
    fi
    
    # 检查点是否在曲线上
    if ! ec_point_is_on_curve "$px" "$py"; then
        ec_point_error "点P不在曲线上"
        return 1
    fi
    
    # 计算斜率 λ = (3px^2 + a) / (2py) mod p
    local px_squared=$(bigint_mod_pow "$px" "2" "$CURVE_P")
    local numerator=$(bigint_mod $(bigint_add $(bigint_multiply "3" "$px_squared") "$CURVE_A") "$CURVE_P")
    local denominator=$(bigint_mod $(bigint_multiply "2" "$py") "$CURVE_P")
    
    # 计算 denominator 的模逆元
    local inv_denominator=$(bigint_mod_inverse "$denominator" "$CURVE_P")
    if [[ $? -ne 0 ]]; then
        ec_point_error "无法计算模逆元"
        return 1
    fi
    
    local lambda=$(bigint_mod $(bigint_multiply "$numerator" "$inv_denominator") "$CURVE_P")
    
    # 计算 xr = λ^2 - 2px mod p
    local lambda_squared=$(bigint_mod_pow "$lambda" "2" "$CURVE_P")
    local xr=$(bigint_mod $(bigint_subtract "$lambda_squared" $(bigint_multiply "2" "$px")) "$CURVE_P")
    
    # 计算 yr = λ(px - xr) - py mod p
    local yr=$(bigint_mod $(bigint_subtract $(bigint_multiply "$lambda" $(bigint_subtract "$px" "$xr")) "$py") "$CURVE_P")
    
    echo "$xr $yr"
}

# 点乘法 (kP) - 使用窗口NAF算法优化
ec_point_multiply() {
    local k="$1"
    local px="$2"
    local py="$3"
    
    if [[ -z "$CURVE_P" || -z "$CURVE_A" ]]; then
        ec_point_error "曲线参数未初始化"
        return 1
    fi
    
    # 处理k=0
    if [[ "$k" == "0" ]]; then
        echo "0 0"
        return 0
    fi
    
    # 处理负k
    if [[ "$k" =~ ^- ]]; then
        # k(-P) = (-k)P
        local neg_py=$(bigint_mod $(bigint_subtract "0" "$py") "$CURVE_P")
        ec_point_multiply "${k#-}" "$px" "$neg_py"
        return 0
    fi
    
    # 使用二进制展开算法
    local result_x="0"
    local result_y="0"
    local current_x="$px"
    local current_y="$py"
    
    # 将k转换为二进制并处理每一位
    local binary_k=$(bashmath_dec_to_binary "$k" || echo "")
    if [[ -z "$binary_k" ]]; then
        # 备用：逐位处理
        while [[ "$k" -gt "0" ]]; do
            # 如果当前位是1，加到结果中
            if [[ $(bigint_mod "$k" "2") == "1" ]]; then
                if [[ "$result_x" == "0" && "$result_y" == "0" ]]; then
                    result_x="$current_x"
                    result_y="$current_y"
                else
                    local new_point=$(ec_point_add "$result_x" "$result_y" "$current_x" "$current_y")
                    result_x=$(echo "$new_point" | cut -d' ' -f1)
                    result_y=$(echo "$new_point" | cut -d' ' -f2)
                fi
            fi
            
            # 当前点倍
            local doubled=$(ec_point_double "$current_x" "$current_y")
            current_x=$(echo "$doubled" | cut -d' ' -f1)
            current_y=$(echo "$doubled" | cut -d' ' -f2)
            
            # 右移一位
            k=$(bigint_divide "$k" "2")
        done
    else
        # 使用二进制表示
        local len=${#binary_k}
        local i=$((len - 1))
        
        while [[ $i -ge 0 ]]; do
            # 如果当前位是1，加到结果中
            if [[ "${binary_k:i:1}" == "1" ]]; then
                if [[ "$result_x" == "0" && "$result_y" == "0" ]]; then
                    result_x="$current_x"
                    result_y="$current_y"
                else
                    local new_point=$(ec_point_add "$result_x" "$result_y" "$current_x" "$current_y")
                    result_x=$(echo "$new_point" | cut -d' ' -f1)
                    result_y=$(echo "$new_point" | cut -d' ' -f2)
                fi
            fi
            
            # 如果不是最后一位，当前点倍
            if [[ $i -gt 0 ]]; then
                local doubled=$(ec_point_double "$current_x" "$current_y")
                current_x=$(echo "$doubled" | cut -d' ' -f1)
                current_y=$(echo "$doubled" | cut -d' ' -f2)
            fi
            
            ((i--))
        done
    fi
    
    echo "$result_x $result_y"
}

# 生成随机点（在曲线上）
ec_point_generate_random() {
    local max_attempts=100
    local attempts=0
    
    while [[ $attempts -lt $max_attempts ]]; do
        # 生成随机x坐标
        local x=$(bigint_random "256")
        x=$(bigint_mod "$x" "$CURVE_P")
        
        # 计算 y^2 = x^3 + ax + b mod p
        local x_cubed=$(bigint_mod_pow "$x" "3" "$CURVE_P")
        local ax=$(bigint_mod $(bigint_multiply "$CURVE_A" "$x") "$CURVE_P")
        local rhs=$(bigint_mod $(bigint_add "$x_cubed" $(bigint_add "$ax" "$CURVE_B")) "$CURVE_P")
        
        # 检查是否存在平方根（使用欧拉准则）
        local legendre=$(bigint_mod_pow "$rhs" $(bigint_divide $(bigint_subtract "$CURVE_P" "1") "2") "$CURVE_P")
        
        if [[ "$legendre" == "1" ]]; then
            # 找到平方根（使用Tonelli-Shanks算法）
            local y=$(ec_point_sqrt_mod "$rhs" "$CURVE_P")
            if [[ -n "$y" ]]; then
                echo "$x $y"
                return 0
            fi
        fi
        
        ((attempts++))
    done
    
    ec_point_error "无法生成有效的曲线点"
    return 1
}

# 模平方根计算（Tonelli-Shanks算法）
ec_point_sqrt_mod() {
    local n="$1"
    local p="$2"
    
    # 特殊情况处理
    if [[ "$p" == "2" ]]; then
        echo "$n"
        return 0
    fi
    
    # 检查是否存在平方根
    local legendre=$(bigint_mod_pow "$n" $(bigint_divide $(bigint_subtract "$p" "1") "2") "$p")
    if [[ "$legendre" != "1" ]]; then
        return 1
    fi
    
    # 对于 p ≡ 3 (mod 4) 的情况，可以直接计算
    if [[ $(bigint_mod "$p" "4") == "3" ]]; then
        local exponent=$(bigint_divide $(bigint_add "$p" "1") "4")
        echo $(bigint_mod_pow "$n" "$exponent" "$p")
        return 0
    fi
    
    # 一般的Tonelli-Shanks算法
    local q=$(bigint_subtract "$p" "1")
    local s=0
    while [[ $(bigint_mod "$q" "2") == "0" ]]; do
        q=$(bigint_divide "$q" "2")
        ((s++))
    done
    
    # 找到二次非剩余
    local z="2"
    while [[ $(bigint_mod_pow "$z" $(bigint_divide $(bigint_subtract "$p" "1") "2") "$p") != "$p"-1 ]]; do
        z=$(bigint_add "$z" "1")
    done
    
    local c=$(bigint_mod_pow "$z" "$q" "$p")
    local t=$(bigint_mod_pow "$n" "$q" "$p")
    local r=$(bigint_mod_pow "$n" $(bigint_divide $(bigint_add "$q" "1") "2") "$p")
    
    local m=$s
    while [[ $(bigint_mod "$t" "$p") != "1" ]]; do
        local i=1
        local temp=$t
        while [[ $(bigint_mod "$temp" "$p") != "1" && $i -lt $m ]]; do
            temp=$(bigint_mod_pow "$temp" "2" "$p")
            ((i++))
        done
        
        if [[ $i -eq $m ]]; then
            return 1
        fi
        
        local b=$(bigint_mod_pow "$c" $(bigint_pow "2" $(bigint_subtract "$m" "$i")) "$p")
        local b_squared=$(bigint_mod_pow "$b" "2" "$p")
        
        r=$(bigint_mod $(bigint_multiply "$r" "$b") "$p")
        t=$(bigint_mod $(bigint_multiply "$t" "$b_squared") "$p")
        c=$(bigint_mod_pow "$b_squared" "2" "$p")
        m=$i
    done
    
    echo "$r"
}

# 计算点的逆元
c_point_negate() {
    local px="$1"
    local py="$2"
    
    if [[ "$px" == "0" && "$py" == "0" ]]; then
        echo "0 0"
        return 0
    fi
    
    local neg_y=$(bigint_mod $(bigint_subtract "0" "$py") "$CURVE_P")
    echo "$px $neg_y"
}

# 测试点运算
ec_point_test() {
    echo "测试椭圆曲线点运算..."
    
    # 初始化曲线
    if ! curve_init "secp256r1"; then
        echo "错误: 无法初始化曲线"
        return 1
    fi
    
    echo "使用曲线: secp256r1"
    
    # 测试基点
    echo "基点 G: ($CURVE_GX, $CURVE_GY)"
    
    if ec_point_is_on_curve "$CURVE_GX" "$CURVE_GY"; then
        echo "✓ 基点验证通过"
    else
        echo "✗ 基点验证失败"
        return 1
    fi
    
    # 测试点倍
    echo -e "\n测试点倍 (2G):"
    local double_point=$(ec_point_double "$CURVE_GX" "$CURVE_GY")
    local double_x=$(echo "$double_point" | cut -d' ' -f1)
    local double_y=$(echo "$double_point" | cut -d' ' -f2)
    
    echo "2G = ($double_x, $double_y)"
    
    if ec_point_is_on_curve "$double_x" "$double_y"; then
        echo "✓ 点倍结果在曲线上"
    else
        echo "✗ 点倍结果不在曲线上"
    fi
    
    # 测试点乘法
    echo -e "\n测试点乘法 (3G):"
    local triple_point=$(ec_point_multiply "3" "$CURVE_GX" "$CURVE_GY")
    local triple_x=$(echo "$triple_point" | cut -d' ' -f1)
    local triple_y=$(echo "$triple_point" | cut -d' ' -f2)
    
    echo "3G = ($triple_x, $triple_y)"
    
    if ec_point_is_on_curve "$triple_x" "$triple_y"; then
        echo "✓ 点乘结果在曲线上"
    else
        echo "✗ 点乘结果不在曲线上"
    fi
    
    # 测试点加法
    echo -e "\n测试点加法 (G + 2G = 3G):"
    local sum_point=$(ec_point_add "$CURVE_GX" "$CURVE_GY" "$double_x" "$double_y")
    local sum_x=$(echo "$sum_point" | cut -d' ' -f1)
    local sum_y=$(echo "$sum_point" | cut -d' ' -f2)
    
    echo "G + 2G = ($sum_x, $sum_y)"
    
    if [[ "$sum_x" == "$triple_x" && "$sum_y" == "$triple_y" ]]; then
        echo "✓ 点加法验证通过"
    else
        echo "✗ 点加法验证失败"
    fi
    
    echo -e "\n点运算测试完成"
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ec_point_test
fi