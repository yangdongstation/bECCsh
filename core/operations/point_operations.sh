#!/bin/bash
# 椭圆曲线点运算通用实现
# 支持多种椭圆曲线的点加、点乘等运算

set -euo pipefail

# 导入保护 - 防止重复定义
if [[ -n "${POINT_OPERATIONS_LOADED:-}" ]]; then
    return 0
fi
readonly POINT_OPERATIONS_LOADED=1

# 导入模运算库
source "$(dirname "${BASH_SOURCE[0]}")/ecc_arithmetic.sh"

# 椭圆曲线点的结构
# 每个点表示为: x y [infinity_flag]
# infinity_flag 为1表示无穷远点

# 检查点是否为无穷远点
point_is_infinity() {
    local point_x="$1"
    local point_y="$2"
    
    # 如果x和y都为空字符串，则为无穷远点
    if [[ -z "$point_x" ]] || [[ -z "$point_y" ]] || [[ "$point_x" == "infinity" ]] || [[ "$point_y" == "infinity" ]]; then
        return 0
    fi
    
    return 1
}

# 创建无穷远点
point_create_infinity() {
    echo "infinity infinity"
}

# 验证点是否在椭圆曲线上
# 参数: x, y, a, b, p (曲线参数)
# 验证: y^2 ≡ x^3 + ax + b (mod p)
point_on_curve() {
    local x="$1"
    local y="$2"
    local a="$3"
    local b="$4"
    local p="$5"
    
    # 输入验证
    if [[ -z "$x" ]] || [[ -z "$y" ]] || [[ -z "$a" ]] || [[ -z "$b" ]] || [[ -z "$p" ]]; then
        echo "错误: point_on_curve 需要五个参数" >&2
        return 1
    fi
    
    # 检查是否为无穷远点
    if point_is_infinity "$x" "$y"; then
        return 0
    fi
    
    # 计算左边: y^2 mod p
    local left=$(mod_square "$y" "$p")
    
    # 计算右边: x^3 + ax + b mod p
    local x_cubed=$(mod_pow "$x" "3" "$p")
    local ax=$(mod_mul "$a" "$x" "$p")
    local sum=$(mod_add "$x_cubed" "$ax" "$p")
    local right=$(mod_add "$sum" "$b" "$p")
    
    # 验证等式
    if [[ "$left" == "$right" ]]; then
        return 0
    else
        return 1
    fi
}

# 椭圆曲线点加法
# 参数: x1, y1, x2, y2, a, p (曲线参数)
# 返回: 结果点的x, y坐标
ec_point_add() {
    local x1="$1"
    local y1="$2"
    local x2="$3"
    local y2="$4"
    local a="$5"
    local p="$6"
    
    # 输入验证
    if [[ -z "$x1" ]] || [[ -z "$y1" ]] || [[ -z "$x2" ]] || [[ -z "$y2" ]] || [[ -z "$a" ]] || [[ -z "$p" ]]; then
        echo "错误: ec_point_add 需要六个参数" >&2
        return 1
    fi
    
    # 处理无穷远点的情况
    if point_is_infinity "$x1" "$y1"; then
        echo "$x2 $y2"
        return 0
    fi
    
    if point_is_infinity "$x2" "$y2"; then
        echo "$x1 $y1"
        return 0
    fi
    
    # 检查点是否在曲线上
    if ! point_on_curve "$x1" "$y1" "$a" "$b" "$p"; then
        echo "错误: 第一个点不在曲线上" >&2
        return 1
    fi
    
    if ! point_on_curve "$x2" "$y2" "$a" "$b" "$p"; then
        echo "错误: 第二个点不在曲线上" >&2
        return 1
    fi
    
    # 处理相同x坐标的情况
    if [[ "$x1" == "$x2" ]]; then
        # 相同点的情况 (y1 == y2)
        if [[ "$y1" == "$y2" ]]; then
            # 点加倍
            ec_point_double "$x1" "$y1" "$a" "$p"
            return $?
        else
            # 相反点的情况 (y1 == -y2 mod p)
            # 结果为无穷远点
            point_create_infinity
            return 0
        fi
    fi
    
    # 计算斜率 lambda = (y2 - y1) / (x2 - x1) mod p
    local dy=$(mod_sub "$y2" "$y1" "$p")
    local dx=$(mod_sub "$x2" "$x1" "$p")
    
    # 检查dx是否有逆元
    local dx_inv
    dx_inv=$(mod_inverse "$dx" "$p")
    if [[ $? -ne 0 ]] || [[ -z "$dx_inv" ]]; then
        echo "错误: 无法计算斜率，分母没有逆元" >&2
        return 1
    fi
    
    local lambda=$(mod_mul "$dy" "$dx_inv" "$p")
    
    # 计算 x3 = lambda^2 - x1 - x2 mod p
    local lambda_squared=$(mod_square "$lambda" "$p")
    local x1_plus_x2=$(mod_add "$x1" "$x2" "$p")
    local x3=$(mod_sub "$lambda_squared" "$x1_plus_x2" "$p")
    
    # 计算 y3 = lambda * (x1 - x3) - y1 mod p
    local x1_minus_x3=$(mod_sub "$x1" "$x3" "$p")
    local lambda_times_dx1=$(mod_mul "$lambda" "$x1_minus_x3" "$p")
    local y3=$(mod_sub "$lambda_times_dx1" "$y1" "$p")
    
    echo "$x3 $y3"
}

# 椭圆曲线点加倍
# 参数: x, y, a, p (曲线参数)
# 返回: 结果点的x, y坐标
ec_point_double() {
    local x="$1"
    local y="$2"
    local a="$3"
    local p="$4"
    
    # 输入验证
    if [[ -z "$x" ]] || [[ -z "$y" ]] || [[ -z "$a" ]] || [[ -z "$p" ]]; then
        echo "错误: ec_point_double 需要四个参数" >&2
        return 1
    fi
    
    # 处理无穷远点的情况
    if point_is_infinity "$x" "$y"; then
        point_create_infinity
        return 0
    fi
    
    # 检查y是否为零（切线垂直的情况）
    if [[ "$y" -eq 0 ]]; then
        # 结果为无穷远点
        point_create_infinity
        return 0
    fi
    
    # 检查点是否在曲线上
    if ! point_on_curve "$x" "$y" "$a" "$b" "$p"; then
        echo "错误: 点不在曲线上" >&2
        return 1
    fi
    
    # 计算斜率 lambda = (3x^2 + a) / (2y) mod p
    local x_squared=$(mod_square "$x" "$p")
    local three_x_squared=$(mod_mul "3" "$x_squared" "$p")
    local numerator=$(mod_add "$three_x_squared" "$a" "$p")
    
    local two_y=$(mod_mul "2" "$y" "$p")
    local two_y_inv
    two_y_inv=$(mod_inverse "$two_y" "$p")
    if [[ $? -ne 0 ]] || [[ -z "$two_y_inv" ]]; then
        echo "错误: 无法计算斜率，分母没有逆元" >&2
        return 1
    fi
    
    local lambda=$(mod_mul "$numerator" "$two_y_inv" "$p")
    
    # 计算 x3 = lambda^2 - 2x mod p
    local lambda_squared=$(mod_square "$lambda" "$p")
    local two_x=$(mod_mul "2" "$x" "$p")
    local x3=$(mod_sub "$lambda_squared" "$two_x" "$p")
    
    # 计算 y3 = lambda * (x - x3) - y mod p
    local x_minus_x3=$(mod_sub "$x" "$x3" "$p")
    local lambda_times_dx=$(mod_mul "$lambda" "$x_minus_x3" "$p")
    local y3=$(mod_sub "$lambda_times_dx" "$y" "$p")
    
    echo "$x3 $y3"
}

# 椭圆曲线点乘法（使用双倍加算法）
# 参数: scalar, x, y, a, p (标量和曲线参数)
# 返回: 结果点的x, y坐标
ec_point_multiply() {
    local scalar="$1"
    local x="$2"
    local y="$3"
    local a="$4"
    local p="$5"
    
    # 输入验证
    if [[ -z "$scalar" ]] || [[ -z "$x" ]] || [[ -z "$y" ]] || [[ -z "$a" ]] || [[ -z "$p" ]]; then
        echo "错误: ec_point_multiply 需要五个参数" >&2
        return 1
    fi
    
    if [[ ! "$scalar" =~ ^[0-9]+$ ]]; then
        echo "错误: 标量必须是正整数" >&2
        return 1
    fi
    
    # 处理标量为0的情况
    if [[ "$scalar" -eq 0 ]]; then
        point_create_infinity
        return 0
    fi
    
    # 处理标量为1的情况
    if [[ "$scalar" -eq 1 ]]; then
        echo "$x $y"
        return 0
    fi
    
    # 使用双倍加算法
    local result=$(point_create_infinity)
    local current_point="$x $y"
    local current_scalar="$scalar"
    
    while [[ "$current_scalar" -gt 0 ]]; do
        # 如果当前标量是奇数，加上当前点
        if [[ $((current_scalar % 2)) -eq 1 ]]; then
            local result_x=$(echo "$result" | cut -d' ' -f1)
            local result_y=$(echo "$result" | cut -d' ' -f2)
            local current_x=$(echo "$current_point" | cut -d' ' -f1)
            local current_y=$(echo "$current_point" | cut -d' ' -f2)
            
            result=$(ec_point_add "$result_x" "$result_y" "$current_x" "$current_y" "$a" "$p")
            if [[ $? -ne 0 ]]; then
                return 1
            fi
        fi
        
        # 双倍当前点
        local current_x=$(echo "$current_point" | cut -d' ' -f1)
        local current_y=$(echo "$current_point" | cut -d' ' -f2)
        
        current_point=$(ec_point_double "$current_x" "$current_y" "$a" "$p")
        if [[ $? -ne 0 ]]; then
            return 1
        fi
        
        # 标量除以2
        current_scalar=$((current_scalar / 2))
    done
    
    echo "$result"
}

# 椭圆曲线点取反
# 参数: x, y, p (曲线参数)
# 返回: 相反点的x, y坐标
ec_point_negate() {
    local x="$1"
    local y="$2"
    local p="$3"
    
    # 输入验证
    if [[ -z "$x" ]] || [[ -z "$y" ]] || [[ -z "$p" ]]; then
        echo "错误: ec_point_negate 需要三个参数" >&2
        return 1
    fi
    
    # 处理无穷远点的情况
    if point_is_infinity "$x" "$y"; then
        echo "$x $y"
        return 0
    fi
    
    # 相反点: (x, -y mod p)
    local neg_y=$(mod_reduce "-$y" "$p")
    echo "$x $neg_y"
}

# 验证两个点是否相等
points_equal() {
    local x1="$1"
    local y1="$2"
    local x2="$3"
    local y2="$4"
    
    # 处理无穷远点的情况
    if point_is_infinity "$x1" "$y1" && point_is_infinity "$x2" "$y2"; then
        return 0
    fi
    
    if point_is_infinity "$x1" "$y1" || point_is_infinity "$x2" "$y2"; then
        return 1
    fi
    
    # 比较坐标
    if [[ "$x1" == "$x2" ]] && [[ "$y1" == "$y2" ]]; then
        return 0
    else
        return 1
    fi
}

# 运行点运算基本测试
test_point_operations() {
    echo "测试椭圆曲线点运算..."
    
    # 使用简单的测试曲线参数
    local test_p="23"  # 小素数用于测试
    local test_a="1"
    local test_b="1"
    
    local test_passed=0
    local test_failed=0
    
    # 测试无穷远点
    local inf=$(point_create_infinity)
    local inf_x=$(echo "$inf" | cut -d' ' -f1)
    local inf_y=$(echo "$inf" | cut -d' ' -f2)
    
    if point_is_infinity "$inf_x" "$inf_y"; then
        ((test_passed++))
    else
        ((test_failed++))
        echo "无穷远点测试失败"
    fi
    
    # 测试点加倍
    local x="3"
    local y="10"
    if point_on_curve "$x" "$y" "$test_a" "$test_b" "$test_p"; then
        local doubled
        doubled=$(ec_point_double "$x" "$y" "$test_a" "$test_p")
        if [[ $? -eq 0 ]] && [[ -n "$doubled" ]]; then
            ((test_passed++))
        else
            ((test_failed++))
            echo "点加倍测试失败"
        fi
    else
        ((test_failed++))
        echo "测试点不在曲线上"
    fi
    
    # 测试点乘法
    local multiplied
    multiplied=$(ec_point_multiply "2" "$x" "$y" "$test_a" "$test_p")
    if [[ $? -eq 0 ]] && [[ -n "$multiplied" ]]; then
        ((test_passed++))
    else
        ((test_failed++))
        echo "点乘法测试失败"
    fi
    
    echo "点运算测试完成: 通过 $test_passed, 失败 $test_failed"
    
    if [[ $test_failed -gt 0 ]]; then
        return 1
    fi
    
    return 0
}