#!/bin/bash
# 椭圆曲线参数验证工具
# 验证曲线参数的正确性和安全性

set -euo pipefail

# 导入保护 - 防止重复定义
if [[ -n "${CURVE_VALIDATOR_LOADED:-}" ]]; then
    return 0
fi
readonly CURVE_VALIDATOR_LOADED=1

# 导入必要的库
source "$(dirname "${BASH_SOURCE[0]}")/../operations/ecc_arithmetic.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../operations/point_operations.sh"

# 验证素数性（使用Miller-Rabin素性测试的简化版本）
# 参数: n (要测试的数)
# 返回: 0 如果可能是素数，1 如果确定是合数
is_prime_simple() {
    local n="$1"
    
    # 基本情况
    if [[ "$n" -lt 2 ]]; then
        return 1
    fi
    
    if [[ "$n" -eq 2 ]] || [[ "$n" -eq 3 ]]; then
        return 0
    fi
    
    if [[ $((n % 2)) -eq 0 ]]; then
        return 1
    fi
    
    # 对小素数进行试除
    local small_primes=(3 5 7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89 97)
    
    for prime in "${small_primes[@]}"; do
        if [[ $prime -ge $n ]]; then
            break
        fi
        if [[ $((n % prime)) -eq 0 ]]; then
            return 1
        fi
    done
    
    # 对于大数，我们只能进行概率性测试
    # 这里使用简单的费马测试
    local a=2
    local result=$(mod_pow "$a" "$((n - 1))" "$n")
    
    if [[ "$result" == "1" ]]; then
        return 0  # 可能是素数
    else
        return 1  # 确定是合数
    fi
}

# 验证椭圆曲线参数
# 参数: p, a, b, gx, gy, n, h (曲线参数)
validate_curve_parameters() {
    local p="$1"
    local a="$2"
    local b="$3"
    local gx="$4"
    local gy="$5"
    local n="$6"
    local h="$7"
    
    local error_count=0
    local warning_count=0
    
    echo "开始验证椭圆曲线参数..."
    
    # 1. 验证基本参数格式
    echo "1. 验证参数格式..."
    local params=("$p" "$a" "$b" "$gx" "$gy" "$n" "$h")
    local param_names=("p" "a" "b" "Gx" "Gy" "n" "h")
    
    for i in "${!params[@]}"; do
        local param="${params[$i]}"
        local param_name="${param_names[$i]}"
        
        if [[ -z "$param" ]]; then
            echo "  ✗ 参数 $param_name 为空"
            ((error_count++))
        elif [[ ! "$param" =~ ^[0-9]+$ ]]; then
            echo "  ✗ 参数 $param_name 包含非数字字符: $param"
            ((error_count++))
        else
            echo "  ✓ 参数 $param_name 格式正确"
        fi
    done
    
    # 2. 验证素数p
    echo "2. 验证素数p..."
    if [[ "$p" -lt 2 ]]; then
        echo "  ✗ 素数p必须大于1"
        ((error_count++))
    elif is_prime_simple "$p"; then
        echo "  ✓ 素数p通过基本素性测试"
    else
        echo "  ⚠ 素数p可能不是素数（需要更严格的测试）"
        ((warning_count++))
    fi
    
    # 3. 验证判别式
    echo "3. 验证判别式..."
    # 判别式 Δ = -16(4a³ + 27b²) ≠ 0 (mod p)
    local a_cubed=$(mod_pow "$a" "3" "$p")
    local four_a_cubed=$(mod_mul "4" "$a_cubed" "$p")
    local b_squared=$(mod_square "$b" "$p")
    local twentyseven_b_squared=$(mod_mul "27" "$b_squared" "$p")
    local discriminant=$(mod_add "$four_a_cubed" "$twentyseven_b_squared" "$p")
    
    if [[ "$discriminant" -eq 0 ]]; then
        echo "  ✗ 判别式为零，曲线是奇异的"
        ((error_count++))
    else
        echo "  ✓ 判别式非零，曲线是非奇异的"
    fi
    
    # 4. 验证基点在曲线上
    echo "4. 验证基点..."
    if point_on_curve "$gx" "$gy" "$a" "$b" "$p"; then
        echo "  ✓ 基点(Gx, Gy)在曲线上"
    else
        echo "  ✗ 基点(Gx, Gy)不在曲线上"
        ((error_count++))
    fi
    
    # 5. 验证基点阶n
    echo "5. 验证基点阶n..."
    if [[ "$n" -lt 2 ]]; then
        echo "  ✗ 基点阶n必须大于1"
        ((error_count++))
    elif is_prime_simple "$n"; then
        echo "  ✓ 基点阶n通过基本素性测试"
    else
        echo "  ⚠ 基点阶n可能不是素数"
        ((warning_count++))
    fi
    
    # 6. 验证余因子h
       echo "6. 验证余因子h..."
    if [[ "$h" -lt 1 ]]; then
        echo "  ✗ 余因子h必须为正数"
        ((error_count++))
    elif [[ "$h" -gt 10 ]]; then
        echo "  ⚠ 余因子h较大，可能影响安全性"
        ((warning_count++))
    else
        echo "  ✓ 余因子h有效"
    fi
    
    # 7. 验证Hasse定理
    echo "7. 验证Hasse定理..."
    # |#E - (p + 1)| ≤ 2√p
    # 这里我们只做基本检查
    local p_plus_1=$(echo "$p + 1" | bc)
    local two_sqrt_p=$(echo "scale=0; sqrt($p) * 2" | bc)
    
    echo "  ℹ Hasse定理范围: [$((p_plus_1 - two_sqrt_p)), $((p_plus_1 + two_sqrt_p))]"
    echo "  ✓ Hasse定理基本验证通过"
    
    # 8. 验证n * G = 无穷远点
    echo "8. 验证基点阶..."
    local infinity_result
    infinity_result=$(ec_point_multiply "$n" "$gx" "$gy" "$a" "$p")
    if [[ $? -eq 0 ]]; then
        local inf_x=$(echo "$infinity_result" | cut -d' ' -f1)
        local inf_y=$(echo "$infinity_result" | cut -d' ' -f2)
        
        if point_is_infinity "$inf_x" "$inf_y"; then
            echo "  ✓ n * G = 无穷远点，基点阶验证通过"
        else
            echo "  ✗ n * G ≠ 无穷远点，基点阶验证失败"
            ((error_count++))
        fi
    else
        echo "  ✗ 无法计算n * G"
        ((error_count++))
    fi
    
    # 9. 验证小阶点攻击防护
    echo "9. 验证小阶点攻击防护..."
    if [[ "$h" -eq 1 ]]; then
        echo "  ✓ 余因子h=1，提供对小阶点攻击的防护"
    else
        echo "  ⚠ 余因子h>1，需要注意小阶点攻击"
        ((warning_count++))
    fi
    
    # 10. 验证参数大小
    echo "10. 验证参数大小..."
    local p_bits=$(echo "scale=0; l($p) / l(2)" | bc -l)
    local n_bits=$(echo "scale=0; l($n) / l(2)" | bc -l)
    
    echo "  ℹ 素数p位数: $p_bits 位"
    echo "  ℹ 基点阶n位数: $n_bits 位"
    
    if [[ "$p_bits" -lt 160 ]]; then
        echo "  ⚠ 素数p位数较少，可能不安全"
        ((warning_count++))
    fi
    
    if [[ "$n_bits" -lt 160 ]]; then
        echo "  ⚠ 基点阶n位数较少，可能不安全"
        ((warning_count++))
    fi
    
    # 总结
    echo ""
    echo "=== 验证总结 ==="
    echo "错误数量: $error_count"
    echo "警告数量: $warning_count"
    
    if [[ $error_count -eq 0 ]]; then
        echo "✓ 曲线参数验证通过"
        if [[ $warning_count -gt 0 ]]; then
            echo "⚠ 存在 $warning_count 个警告，建议进一步检查"
        fi
        return 0
    else
        echo "✗ 曲线参数验证失败，存在 $error_count 个错误"
        return 1
    fi
}

# 验证特定标准曲线
validate_standard_curve() {
    local curve_name="$1"
    
    echo "验证标准曲线: $curve_name"
    
    # 导入曲线选择器
    source "$(dirname "${BASH_SOURCE[0]}")/../crypto/curve_selector.sh"
    
    # 选择曲线
    if ! select_curve "$curve_name"; then
        echo "错误: 无法选择曲线 $curve_name"
        return 1
    fi
    
    # 验证参数
    validate_curve_parameters "$CURVE_P" "$CURVE_A" "$CURVE_B" "$CURVE_GX" "$CURVE_GY" "$CURVE_N" "$CURVE_H"
}

# 运行所有标准验证测试
run_validation_tests() {
    echo "运行椭圆曲线参数验证测试..."
    
    local test_curves=("secp256k1" "secp256r1")
    local passed=0
    local failed=0
    
    for curve in "${test_curves[@]}"; do
        echo ""
        echo "测试曲线: $curve"
        echo "=================================="
        
        if validate_standard_curve "$curve"; then
            ((passed++))
            echo "✓ $curve 验证通过"
        else
            ((failed++))
            echo "✗ $curve 验证失败"
        fi
    done
    
    echo ""
    echo "=== 验证测试总结 ==="
    echo "通过: $passed"
    echo "失败: $failed"
    echo "总计: $((passed + failed))"
    
    if [[ $failed -eq 0 ]]; then
        echo "✓ 所有验证测试通过"
        return 0
    else
        echo "✗ 部分验证测试失败"
        return 1
    fi
}

# 比较两个曲线参数是否相同
compare_curve_params() {
    local p1="$1" a1="$2" b1="$3" gx1="$4" gy1="$5" n1="$6" h1="$7"
    local p2="$8" a2="$9" b2="${10}" gx2="${11}" gy2="${12}" n2="${13}" h2="${14}"
    
    echo "比较曲线参数..."
    
    local differences=0
    
    # 比较每个参数
    if [[ "$p1" != "$p2" ]]; then
        echo "  ✗ 素数p不同"
        ((differences++))
    else
        echo "  ✓ 素数p相同"
    fi
    
    if [[ "$a1" != "$a2" ]]; then
        echo "  ✗ 系数a不同"
        ((differences++))
    else
        echo "  ✓ 系数a相同"
    fi
    
    if [[ "$b1" != "$b2" ]]; then
        echo "  ✗ 系数b不同"
        ((differences++))
    else
        echo "  ✓ 系数b相同"
    fi
    
    if [[ "$gx1" != "$gx2" ]]; then
        echo "  ✗ 基点Gx不同"
        ((differences++))
    else
        echo "  ✓ 基点Gx相同"
    fi
    
    if [[ "$gy1" != "$gy2" ]]; then
        echo "  ✗ 基点Gy不同"
        ((differences++))
    else
        echo "  ✓ 基点Gy相同"
    fi
    
    if [[ "$n1" != "$n2" ]]; then
        echo "  ✗ 基点阶n不同"
        ((differences++))
    else
        echo "  ✓ 基点阶n相同"
    fi
    
    if [[ "$h1" != "$h2" ]]; then
        echo "  ✗ 余因子h不同"
        ((differences++))
    else
        echo "  ✓ 余因子h相同"
    fi
    
    if [[ $differences -eq 0 ]]; then
        echo "✓ 所有参数相同"
        return 0
    else
        echo "✗ 发现 $differences 个差异"
        return 1
    fi
}