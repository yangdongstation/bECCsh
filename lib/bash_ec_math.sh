#!/bin/bash
# Bash EC Math - 纯Bash椭圆曲线数学运算
# 仅使用Bash内置功能，无外部依赖

set -euo pipefail

# 导入保护 - 防止重复定义
if [[ -n "${BASH_EC_MATH_LOADED:-}" ]]; then
    return 0
fi
readonly BASH_EC_MATH_LOADED=1

# 导入基础数学库
source "$(dirname "${BASH_SOURCE[0]}")/bash_math.sh"
source "$(dirname "${BASH_SOURCE[0]}")/bash_bigint.sh"

# 椭圆曲线点加法（简化版本，适用于小素数域）
bash_ec_point_add_simple() {
    local px="$1"
    local py="$2"
    local qx="$3"
    local qy="$4"
    local a="$5"    # 曲线参数a
    local p="$6"    # 素数模数
    
    # 验证输入
    if ! bashbigint_validate "$px" || ! bashbigint_validate "$py" || \
       ! bashbigint_validate "$qx" || ! bashbigint_validate "$qy" || \
       ! bashbigint_validate "$a" || ! bashbigint_validate "$p"; then
        echo "错误: 无效的输入" >&2
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
    
    # 检查是否是同一个点
    if [[ "$px" == "$qx" ]]; then
        if [[ "$py" == "$qy" ]]; then
            # 点倍运算
            bash_ec_point_double_simple "$px" "$py" "$a" "$p"
        else
            # 相反点，结果为无穷远点
            echo "0 0"
        fi
        return 0
    fi
    
    # 计算lambda = (qy - py) / (qx - px) mod p
    # 确保delta_y和delta_x为正数
    local delta_y_raw=$(bashbigint_subtract "$qy" "$py" 2>/dev/null || echo "")
    if [[ -z "$delta_y_raw" ]]; then
        # 如果减法失败（结果为负），使用模运算性质
        delta_y_raw=$(bashbigint_subtract "$qy" "$py")
        if [[ -z "$delta_y_raw" ]]; then
            delta_y_raw=$(bashbigint_add "$qy" "$p")
            delta_y_raw=$(bashbigint_subtract "$delta_y_raw" "$py")
        fi
    fi
    local delta_y=$(bashbigint_mod "$delta_y_raw" "$p")
    
    local delta_x_raw=$(bashbigint_subtract "$qx" "$px" 2>/dev/null || echo "")
    if [[ -z "$delta_x_raw" ]]; then
        # 如果减法失败（结果为负），使用模运算性质
        delta_x_raw=$(bashbigint_subtract "$qx" "$px")
        if [[ -z "$delta_x_raw" ]]; then
            delta_x_raw=$(bashbigint_add "$qx" "$p")
            delta_x_raw=$(bashbigint_subtract "$delta_x_raw" "$px")
        fi
    fi
    local delta_x=$(bashbigint_mod "$delta_x_raw" "$p")
    
    # 计算delta_x的模逆元
    local inv_delta_x=$(bashbigint_mod_inverse "$delta_x" "$p")
    if [[ $? -ne 0 ]]; then
        echo "错误: 无法计算模逆元" >&2
        return 1
    fi
    
    local lambda=$(bashbigint_mod $(bashbigint_multiply "$delta_y" "$inv_delta_x") "$p")
    
    # 计算xr = lambda^2 - px - qx mod p
    local lambda_squared=$(bashbigint_mod_pow "$lambda" "2" "$p")
    local xr=$(bashbigint_mod $(bashbigint_subtract "$lambda_squared" $(bashbigint_add "$px" "$qx")) "$p")
    
    # 计算yr = lambda * (px - xr) - py mod p
    local yr=$(bashbigint_mod $(bashbigint_subtract $(bashbigint_multiply "$lambda" $(bashbigint_subtract "$px" "$xr")) "$py") "$p")
    
    echo "$xr $yr"
}

# 椭圆曲线点倍运算（简化版本）
bash_ec_point_double_simple() {
    local px="$1"
    local py="$2"
    local a="$3"    # 曲线参数a
    local p="$4"    # 素数模数
    
    # 验证输入
    if ! bashbigint_validate "$px" || ! bashbigint_validate "$py" || \
       ! bashbigint_validate "$a" || ! bashbigint_validate "$p"; then
        echo "错误: 无效的输入" >&2
        return 1
    fi
    
    # 处理无穷远点
    if [[ "$px" == "0" && "$py" == "0" ]]; then
        echo "0 0"
        return 0
    fi
    
    # 计算lambda = (3 * px^2 + a) / (2 * py) mod p
    local px_squared=$(bashbigint_mod_pow "$px" "2" "$p")
    local numerator=$(bashbigint_mod $(bashbigint_add $(bashbigint_multiply "3" "$px_squared") "$a") "$p")
    local denominator=$(bashbigint_mod $(bashbigint_multiply "2" "$py") "$p")
    
    # 计算denominator的模逆元
    local inv_denominator=$(bashbigint_mod_inverse "$denominator" "$p")
    if [[ $? -ne 0 ]]; then
        echo "错误: 无法计算模逆元" >&2
        return 1
    fi
    
    local lambda=$(bashbigint_mod $(bashbigint_multiply "$numerator" "$inv_denominator") "$p")
    
    # 计算xr = lambda^2 - 2 * px mod p
    local lambda_squared=$(bashbigint_mod_pow "$lambda" "2" "$p")
    local xr=$(bashbigint_mod $(bashbigint_subtract "$lambda_squared" $(bashbigint_multiply "2" "$px")) "$p")
    
    # 计算yr = lambda * (px - xr) - py mod p
    local yr=$(bashbigint_mod $(bashbigint_subtract $(bashbigint_multiply "$lambda" $(bashbigint_subtract "$px" "$xr")) "$py") "$p")
    
    echo "$xr $yr"
}

# 椭圆曲线点乘法（简化版本，使用二进制展开）
bash_ec_point_multiply_simple() {
    local k="$1"
    local px="$2"
    local py="$3"
    local a="$4"    # 曲线参数a
    local p="$5"    # 素数模数
    
    # 验证输入
    if ! bashbigint_validate "$k" || ! bashbigint_validate "$px" || \
       ! bashbigint_validate "$py" || ! bashbigint_validate "$a" || \
       ! bashbigint_validate "$p"; then
        echo "错误: 无效的输入" >&2
        return 1
    fi
    
    # 处理k=0的情况
    if [[ "$k" == "0" ]]; then
        echo "0 0"
        return 0
    fi
    
    # 处理k=1的情况
    if [[ "$k" == "1" ]]; then
        echo "$px $py"
        return 0
    fi
    
    # 使用二进制展开算法
    local result_x="0"
    local result_y="0"
    local current_x="$px"
    local current_y="$py"
    
    # 将k转换为二进制并处理每一位
    local binary_k=$(bashmath_dec_to_binary "$k")
    local len=${#binary_k}
    
    # 从左到右处理二进制位
    for ((i = 0; i < len; i++)); do
        # 当前点倍
        local doubled=$(bash_ec_point_double_simple "$current_x" "$current_y" "$a" "$p")
        current_x=$(echo "$doubled" | cut -d' ' -f1)
        current_y=$(echo "$doubled" | cut -d' ' -f2)
        
        # 如果当前位是1，加到结果中
        if [[ "${binary_k:$i:1}" == "1" ]]; then
            if [[ "$result_x" == "0" && "$result_y" == "0" ]]; then
                result_x="$current_x"
                result_y="$current_y"
            else
                local added=$(bash_ec_point_add_simple "$result_x" "$result_y" "$current_x" "$current_y" "$a" "$p")
                result_x=$(echo "$added" | cut -d' ' -f1)
                result_y=$(echo "$added" | cut -d' ' -f2)
            fi
        fi
    done
    
    echo "$result_x $result_y"
}

# 检查点是否在曲线上（简化版本）
bash_ec_is_on_curve_simple() {
    local x="$1"
    local y="$2"
    local a="$3"    # 曲线参数a
    local b="$4"    # 曲线参数b
    local p="$5"    # 素数模数
    
    # 计算左边: y^2 mod p
    local y_squared=$(bashbigint_mod_pow "$y" "2" "$p")
    
    # 计算右边: x^3 + ax + b mod p
    local x_cubed=$(bashbigint_mod_pow "$x" "3" "$p")
    local ax=$(bashbigint_mod $(bashbigint_multiply "$a" "$x") "$p")
    local rhs=$(bashbigint_mod $(bashbigint_add "$x_cubed" $(bashbigint_add "$ax" "$b")) "$p")
    
    # 比较左右两边
    if [[ "$y_squared" == "$rhs" ]]; then
        return 0  # 在曲线上
    else
        return 1  # 不在曲线上
    fi
}

# 生成曲线上的随机点（简化版本，仅用于测试）
bash_ec_generate_point_simple() {
    local a="$1"    # 曲线参数a
    local b="$2"    # 曲线参数b
    local p="$3"    # 素数模数
    local max_attempts=100
    
    for ((attempt = 0; attempt < max_attempts; attempt++)); do
        # 生成随机x坐标
        local x=$(bashbigint_random "256")
        x=$(bashbigint_mod "$x" "$p")
        
        # 计算x^3 + ax + b mod p
        local x_cubed=$(bashbigint_mod_pow "$x" "3" "$p")
        local ax=$(bashbigint_mod $(bashbigint_multiply "$a" "$x") "$p")
        local rhs=$(bashbigint_mod $(bashbigint_add "$x_cubed" $(bashbigint_add "$ax" "$b")) "$p")
        
        # 尝试找到对应的y坐标（简化：只检查平方根是否存在）
        # 这里使用一个简化的平方根检查
        for ((y = 0; y < 1000 && y < p; y++)); do
            local y_squared=$(bashbigint_mod_pow "$y" "2" "$p")
            if [[ "$y_squared" == "$rhs" ]]; then
                echo "$x $y"
                return 0
            fi
        done
    done
    
    echo "错误: 无法生成曲线上的点" >&2
    return 1
}

# 测试函数
bash_ec_test_simple() {
    echo "测试Bash EC Math (简化版本)..."
    
    # 使用小素数进行测试，使用已知的有效点
    local test_p="23"      # 素数模数
    local test_a="1"       # 曲线参数a
    local test_b="1"       # 曲线参数b
    local test_px="0"      # 测试点x (有效点)
    local test_py="1"      # 测试点y (有效点)
    
    echo "使用小素数域 p=$test_p 进行测试"
    echo "曲线参数: a=$test_a, b=$test_b"
    echo "测试点: P=($test_px, $test_py)"
    
    # 检查点是否在曲线上
    if bash_ec_is_on_curve_simple "$test_px" "$test_py" "$test_a" "$test_b" "$test_p"; then
        echo "✓ 测试点在曲线上"
    else
        echo "✗ 测试点不在曲线上"
        return 1
    fi
    
    # 测试点倍运算
    local doubled
    doubled=$(bash_ec_point_double_simple "$test_px" "$test_py" "$test_a" "$test_p")
    local double_x=$(echo "$doubled" | cut -d' ' -f1)
    local double_y=$(echo "$doubled" | cut -d' ' -f2)
    echo "点倍运算: 2P = ($double_x, $double_y)"
    
    # 测试点加法（P + P = 2P）
    local added
    added=$(bash_ec_point_add_simple "$test_px" "$test_py" "$test_px" "$test_py" "$test_a" "$test_p")
    local add_x=$(echo "$added" | cut -d' ' -f1)
    local add_y=$(echo "$added" | cut -d' ' -f2)
    echo "点加法: P + P = ($add_x, $add_y)"
    
    # 验证点加法和点倍结果相同
    if [[ "$double_x" == "$add_x" ]] && [[ "$double_y" == "$add_y" ]]; then
        echo "✓ 点加法与点倍结果一致"
    else
        echo "✗ 点加法与点倍结果不一致"
        return 1
    fi
    
    # 测试点乘法
    local multiplied
    multiplied=$(bash_ec_point_multiply_simple "3" "$test_px" "$test_py" "$test_a" "$test_p")
    local mult_x=$(echo "$multiplied" | cut -d' ' -f1)
    local mult_y=$(echo "$multiplied" | cut -d' ' -f2)
    echo "点乘法: 3P = ($mult_x, $mult_y)"
    
    echo "Bash EC Math测试完成!"
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    bash_ec_test_simple
fi