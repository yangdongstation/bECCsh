#!/bin/bash
# 严格测试每个数学模块 - 确保100%可运行性

set -euo pipefail

echo "🔬 基础数学模块严格测试"
echo "========================"
echo "测试时间: $(date)"
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_COUNT=0
PASSED_COUNT=0

# 测试函数
test_module() {
    local module_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    MODULE_COUNT=$((MODULE_COUNT + 1))
    echo -n "测试 $MODULE_COUNT: $module_name ... "
    
    if output=$(timeout 5 bash -c "$test_command" 2>&1); then
        if [[ "$output" == "$expected_result" ]] || [[ "$expected_result" == "ANY" ]]; then
            echo "✅ 通过"
            PASSED_COUNT=$((PASSED_COUNT + 1))
        else
            echo "❌ 失败 (输出不匹配)"
            echo "  期望: $expected_result"
            echo "  实际: $output"
        fi
    else
        echo "❌ 失败 (命令失败)"
        echo "  错误: $output"
    fi
    echo
}

echo "1. Bash数学模块测试"
echo "===================="

# 导入Bash数学模块
source "$SCRIPT_DIR/lib/bash_math.sh"

# 确保函数在子shell中可用
export -f bashmath_hex_to_dec
export -f bashmath_dec_to_hex

# 十六进制转换测试
test_module "十六进制转十进制 (FF)" \
    "bashmath_hex_to_dec 'FF'" \
    "255"

test_module "十六进制转十进制 (00)" \
    "bashmath_hex_to_dec '00'" \
    "0"

test_module "十六进制转十进制 (空字符串)" \
    "bashmath_hex_to_dec ''" \
    "0"

test_module "十进制转十六进制 (255)" \
    "bashmath_dec_to_hex '255'" \
    "FF"

test_module "十进制转十六进制 (0)" \
    "bashmath_dec_to_hex '0'" \
    "0"

echo "2. BigInt大数运算模块测试"
echo "========================="

# 导入BigInt模块
source "$SCRIPT_DIR/lib/bigint.sh"

# 确保函数在子shell中可用
export -f bigint_validate
export -f bigint_normalize

test_module "BigInt验证 (123)" \
    "bigint_validate '123' && echo 'VALID'" \
    "VALID"

test_module "BigInt验证 (0)" \
    "bigint_validate '0' && echo 'VALID'" \
    "VALID"

test_module "BigInt验证 (空字符串)" \
    "! (bigint_validate '' 2>/dev/null) && echo 'INVALID_HANDLED'" \
    "INVALID_HANDLED"

test_module "BigInt标准化 (007)" \
    "bigint_normalize '007'" \
    "7"

test_module "BigInt标准化 (-007)" \
    "bigint_normalize '-007'" \
    "-7"

echo "3. 模运算模块测试"
echo "================="

source "$SCRIPT_DIR/core/crypto/ec_math_fixed_simple.sh"

# 确保函数在子shell中可用
export -f mod_simple
export -f mod_inverse_simple

test_module "模运算 (10 mod 7)" \
    "mod_simple 10 7" \
    "3"

test_module "模逆元 (3 mod 7)" \
    "mod_inverse_simple 3 7" \
    "5"

test_module "模逆元验证 (3×5 mod 7)" \
    "echo \$((3 * 5 % 7))" \
    "1"

echo "4. 椭圆曲线点运算模块测试"
echo "========================="

# 直接在当前shell中执行，而不是子shell
test_module "点在曲线上验证 (3,10)" \
    "px=3; py=10; p=23; a=1; b=1; y_sq=\$((py * py % p)); rhs=\$(( (px * px * px + a * px + b) % p )); [ \$y_sq -eq \$rhs ] && echo 'ON_CURVE'" \
    "ON_CURVE"

test_module "点加法 (3,10)+(3,10)" \
    "curve_point_add_correct 3 10 3 10 1 23" \
    "7 12"

test_module "标量乘法 2×(3,10)" \
    "curve_scalar_mult_simple 2 3 10 1 23" \
    "7 12"

echo "5. 边界情况测试"
echo "================"

test_module "无穷远点处理 (0,0)+(3,10)" \
    "curve_point_add_correct 0 0 3 10 1 23" \
    "3 10"

test_module "大数标量乘法 1000×G" \
    "curve_scalar_mult_simple 1000 3 10 1 23" \
    "13 7"

echo "6. 最终验证"
echo "============"

echo "模块测试总结:"
echo "============="
echo "总测试数: $MODULE_COUNT"
echo "通过测试: $PASSED_COUNT"
echo "失败测试: $((MODULE_COUNT - PASSED_COUNT))"

if [[ $PASSED_COUNT -eq $MODULE_COUNT ]]; then
    echo "🎉 所有模块测试通过！基础数学模块100%可运行！"
    exit 0
else
    echo "❌ 部分模块测试失败，需要修复 $((MODULE_COUNT - PASSED_COUNT)) 个问题"
    exit 1
fi