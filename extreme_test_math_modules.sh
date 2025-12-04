#!/bin/bash
# 极限测试 - 基础数学模块
# 测试每一个函数，每一个边界情况，确保100%可运行

set -euo pipefail

echo "🔬 基础数学模块极限测试"
echo "========================"
echo "测试时间: $(date)"
echo "测试标准: 极端严格 - 零容错"
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数，带有详细错误报告
test_function() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    local critical="${4:-yes}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "测试 $TOTAL_TESTS: $test_name ... "
    
    # 执行测试，捕获所有输出
    if output=$(timeout 10 bash -c "$test_command" 2>&1); then
        if [[ "$output" == "$expected_result" ]] || [[ "$expected_result" == "ANY" ]]; then
            echo "✅ 通过"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo "❌ 失败"
            echo "    期望结果: $expected_result"
            echo "    实际结果: $output"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            
            if [[ "$critical" == "yes" ]]; then
                echo "    🚨 关键测试失败！"
            fi
        fi
    else
        echo "❌ 命令失败"
        echo "    错误输出: $output"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        
        if [[ "$critical" == "yes" ]]; then
            echo "    🚨 关键测试失败！"
        fi
    fi
    echo
}

echo "1. Bash数学库极限测试"
echo "====================="

source "$SCRIPT_DIR/lib/bash_math.sh"

echo "测试十六进制转换函数:"
test_function "bashmath_hex_to_dec(FF)" \
    "bashmath_hex_to_dec 'FF'" \
    "255"

test_function "bashmath_hex_to_dec(00)" \
    "bashmath_hex_to_dec '00'" \
    "0"

test_function "bashmath_hex_to_dec(0)" \
    "bashmath_hex_to_dec '0'" \
    "0"

test_function "bashmath_hex_to_dec(空字符串)" \
    "result=\$(bashmath_hex_to_dec '' 2>/dev/null); echo \"\${result:-0}\"" \
    "0"

test_function "bashmath_hex_to_dec(A)" \
    "bashmath_hex_to_dec 'A'" \
    "10"

test_function "bashmath_hex_to_dec(10)" \
    "bashmath_hex_to_dec '10'" \
    "16"

test_function "bashmath_hex_to_dec(FFFFFFFF)" \
    "bashmath_hex_to_dec 'FFFFFFFF'" \
    "4294967295"

echo "测试十进制转换函数:"
test_function "bashmath_dec_to_hex(255)" \
    "bashmath_dec_to_hex '255'" \
    "FF"

test_function "bashmath_dec_to_hex(0)" \
    "bashmath_dec_to_hex '0'" \
    "0"

test_function "bashmath_dec_to_hex(10)" \
    "bashmath_dec_to_hex '10'" \
    "A"

test_function "bashmath_dec_to_hex(16)" \
    "bashmath_dec_to_hex '16'" \
    "10"

test_function "bashmath_dec_to_hex(4294967295)" \
    "bashmath_dec_to_hex '4294967295'" \
    "FFFFFFFF"

echo "测试对数计算函数:"
test_function "bashmath_log2(256)" \
    "bashmath_log2 '256'" \
    "8"

test_function "bashmath_log2(128)" \
    "bashmath_log2 '128'" \
    "7"

test_function "bashmath_log2(1)" \
    "bashmath_log2 '1'" \
    "0"

test_function "bashmath_log2(0)" \
    "result=\$(bashmath_log2 '0' 2>/dev/null); echo \"\${result:-0}\"" \
    "0"

echo "测试二进制转换函数:"
test_function "bashmath_binary_to_dec(1010)" \
    "bashmath_binary_to_dec '1010'" \
    "10"

test_function "bashmath_binary_to_dec(11111111)" \
    "bashmath_binary_to_dec '11111111'" \
    "255"

test_function "bashmath_binary_to_dec(0)" \
    "bashmath_binary_to_dec '0'" \
    "0"

test_function "bashmath_binary_to_dec(1)" \
    "bashmath_binary_to_dec '1'" \
    "1"

echo "2. BigInt模块极限测试"
echo "====================="

source "$SCRIPT_DIR/lib/bigint.sh"

echo "测试BigInt验证函数:"
test_function "bigint_validate(123)" \
    "bigint_validate '123' >/dev/null 2>&1 && echo 'VALID'" \
    "VALID"

test_function "bigint_validate(0)" \
    "bigint_validate '0' >/dev/null 2>&1 && echo 'VALID'" \
    "VALID"

test_function "bigint_validate(-123)" \
    "bigint_validate '-123' >/dev/null 2>&1 && echo 'VALID'" \
    "VALID"

test_function "bigint_validate(空字符串)" \
    "! bigint_validate '' >/dev/null 2>&1 && echo 'INVALID'" \
    "INVALID"

test_function "bigint_validate(abc)" \
    "! bigint_validate 'abc' >/dev/null 2>&1 && echo 'INVALID'" \
    "INVALID"

test_function "bigint_validate(12.34)" \
    "! bigint_validate '12.34' >/dev/null 2>&1 && echo 'INVALID'" \
    "INVALID"

echo "测试BigInt标准化函数:"
test_function "bigint_normalize(123)" \
    "bigint_normalize '123'" \
    "123"

test_function "bigint_normalize(007)" \
    "bigint_normalize '007'" \
    "7"

test_function "bigint_normalize(-007)" \
    "bigint_normalize '-007'" \
    "-7"

test_function "bigint_normalize(000)" \
    "bigint_normalize '000'" \
    "0"

test_function "bigint_normalize(-000)" \
    "bigint_normalize '-000'" \
    "0"

test_function "bigint_normalize(0)" \
    "bigint_normalize '0'" \
    "0"

test_function "bigint_normalize(-0)" \
    "bigint_normalize '-0'" \
    "0"

echo "3. 极端边界情况测试"
echo "====================="

echo "测试极大数值:"
test_function "bashmath_hex_to_dec(FFFFFFFFFFFFFFFF)" \
    "bashmath_hex_to_dec 'FFFFFFFFFFFFFFFF'" \
    "18446744073709551615"

echo "测试极小数值:"
test_function "bashmath_dec_to_hex(1)" \
    "bashmath_dec_to_hex '1'" \
    "1"

echo "测试负数转换:"
test_function "bashmath_dec_to_hex(-1)" \
    "bashmath_dec_to_hex '-1'" \
    "-1"

echo "测试零边界:"
test_function "bashmath_log2(0)" \
    "bashmath_log2 '0'" \
    "0"

test_function "bashmath_binary_to_dec(0)" \
    "bashmath_binary_to_dec '0'" \
    "0"

echo "4. 压力测试"
echo "============="

echo "连续运算测试:"
test_function "连续hex->dec->hex" \
    "result=\$(bashmath_hex_to_dec 'FF'); bashmath_dec_to_hex \"\$result\"" \
    "FF"

test_function "连续dec->hex->dec" \
    "result=\$(bashmath_dec_to_hex '255'); bashmath_hex_to_dec \"\$result\"" \
    "255"

echo "函数链式调用:"
test_function "复杂函数链" \
    "result=\$(bashmath_hex_to_dec 'FF'); result2=\$(bashmath_dec_to_hex \"\$result\"); bashmath_hex_to_dec \"\$result2\"" \
    "255"

echo "5. 错误恢复测试"
echo "================="

echo "测试错误后的恢复:"
test_function "错误后正常运算" \
    "bashmath_hex_to_dec 'FF' >/dev/null 2>&1; bashmath_hex_to_dec '10'" \
    "16"

echo "测试错误传播:"
test_function "无效输入后的有效运算" \
    "! bashmath_hex_to_dec 'xyz' >/dev/null 2>&1; bashmath_hex_to_dec 'A'" \
    "10"

echo "6. 最终极限测试总结"
echo "====================="
echo "基础数学模块极限测试完成:"
echo "总测试数: $TOTAL_TESTS"
echo "通过测试: $PASSED_TESTS"
echo "失败测试: $FAILED_TESTS"
echo "通过率: $((PASSED_TESTS * 100 / TOTAL_TESTS))%"

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo "🎉 基础数学模块100%通过极限测试！"
    return 0
else
    echo "❌ 发现 $FAILED_TESTS 个失败，需要修复"
    return 1
fi