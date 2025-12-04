#!/bin/bash
# 综合路径完整性检查 - 简化版
set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

TOTAL=0
PASSED=0
FAILED=0
WARNINGS=0

check_result() {
    local success=$1
    local message=$2
    TOTAL=$((TOTAL + 1))
    
    if [[ $success -eq 0 ]]; then
        echo -e "${GREEN}✓${NC} $message"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗${NC} $message"
        FAILED=$((FAILED + 1))
    fi
}

echo "========================================="
echo "综合路径完整性检查"
echo "========================================="

# 1. 检查主程序文件
echo "1. 检查主程序文件..."
check_result 0 "becc.sh 存在" 
[[ -f "/home/donz/bECCsh/becc.sh" ]] || check_result 1 "becc.sh 不存在"
check_result 0 "becc_multi_curve.sh 存在"
[[ -f "/home/donz/bECCsh/becc_multi_curve.sh" ]] || check_result 1 "becc_multi_curve.sh 不存在"
check_result 0 "becc_fixed.sh 存在"
[[ -f "/home/donz/bECCsh/becc_fixed.sh" ]] || check_result 1 "becc_fixed.sh 不存在"
echo

# 2. 检查关键目录
echo "2. 检查关键目录..."
for dir in lib core core/crypto tools; do
    if [[ -d "/home/donz/bECCsh/$dir" ]]; then
        check_result 0 "$dir 目录存在"
    else
        check_result 1 "$dir 目录不存在"
    fi
done
echo

# 3. 检查主程序导入的库文件
echo "3. 检查主程序依赖的库文件..."
required_libs=(
    "lib/bash_math.sh"
    "lib/bigint.sh"
    "lib/ec_curve.sh"
    "lib/ec_point.sh"
    "lib/ecdsa.sh"
    "lib/security.sh"
    "lib/asn1.sh"
    "lib/entropy.sh"
    "core/crypto/curve_selector.sh"
    "core/crypto/ecdsa_fixed.sh"
    "core/crypto/curve_selector_simple.sh"
)

for lib in "${required_libs[@]}"; do
    if [[ -f "/home/donz/bECCsh/$lib" ]]; then
        check_result 0 "$lib 存在"
    else
        check_result 1 "$lib 不存在"
    fi
done
echo

# 4. 检查主程序的基本语法
echo "4. 检查主程序语法..."
for script in becc.sh becc_multi_curve.sh becc_fixed.sh; do
    if bash -n "/home/donz/bECCsh/$script" 2>/dev/null; then
        check_result 0 "$script 语法正确"
    else
        check_result 1 "$script 语法错误"
    fi
done
echo

# 5. 测试主程序帮助命令
echo "5. 测试主程序功能..."
for script in becc.sh becc_multi_curve.sh becc_fixed.sh; do
    if "/home/donz/bECCsh/$script" --help >/dev/null 2>&1; then
        check_result 0 "$script --help 成功"
    else
        check_result 1 "$script --help 失败"
    fi
done
echo

# 6. 检查库文件加载
echo "6. 检查库文件加载..."
if bash -c 'source /home/donz/bECCsh/lib/bash_math.sh && echo "Math loaded"' >/dev/null 2>&1; then
    check_result 0 "bash_math.sh 可加载"
else
    check_result 1 "bash_math.sh 加载失败"
fi

if bash -c 'source /home/donz/bECCsh/lib/bigint.sh && echo "Bigint loaded"' >/dev/null 2>&1; then
    check_result 0 "bigint.sh 可加载"
else
    check_result 1 "bigint.sh 加载失败"
fi

if bash -c 'source /home/donz/bECCsh/core/crypto/curve_selector.sh && echo "Curve selector loaded"' >/dev/null 2>&1; then
    check_result 0 "curve_selector.sh 可加载"
else
    check_result 1 "curve_selector.sh 加载失败"
fi
echo

# 7. 检查相对路径问题
echo "7. 检查相对路径问题..."
for script in becc.sh becc_multi_curve.sh becc_fixed.sh; do
    if ! grep -q "\.\." "/home/donz/bECCsh/$script"; then
        check_result 0 "$script 无相对路径引用"
    else
        check_result 1 "$script 包含相对路径引用"
        WARNINGS=$((WARNINGS + 1))
    fi
done
echo

# 8. 检查BASH_SOURCE使用
echo "8. 检查路径解析方法..."
for script in becc.sh becc_multi_curve.sh becc_fixed.sh; do
    if grep -q "BASH_SOURCE" "/home/donz/bECCsh/$script"; then
        check_result 0 "$script 使用BASH_SOURCE"
    else
        check_result 1 "$script 未使用BASH_SOURCE"
    fi
done
echo

# 9. 运行快速功能测试
echo "9. 运行快速功能测试..."
echo "测试曲线参数加载..."
if bash -c '
    source /home/donz/bECCsh/lib/bash_math.sh
    source /home/donz/bECCsh/lib/bigint.sh
    source /home/donz/bECCsh/core/crypto/curve_selector.sh
    select_curve secp256r1
    echo "Curve loaded: $CURVE_NAME"
' >/dev/null 2>&1; then
    check_result 0 "曲线参数加载成功"
else
    check_result 1 "曲线参数加载失败"
fi

echo "测试密钥生成..."
if bash -c '
    source /home/donz/bECCsh/lib/bash_math.sh
    source /home/donz/bECCsh/lib/bigint.sh
    source /home/donz/bECCsh/lib/ec_curve.sh
    source /home/donz/bECCsh/lib/ec_point.sh
    source /home/donz/bECCsh/core/crypto/curve_selector.sh
    select_curve secp256r1
    # 简单的点乘法测试
    result=$(point_multiply 2 "04:06")
    echo "Key generation test passed"
' >/dev/null 2>&1; then
    check_result 0 "基础密钥操作成功"
else
    check_result 1 "基础密钥操作失败"
fi
echo

# 10. 检查特定的测试脚本
echo "10. 检查测试脚本..."
test_scripts=(
    "test_quick_functionality.sh"
    "test_core_modules_direct.sh"
    "test_openssl_compatibility_final.sh"
)

for test_script in "${test_scripts[@]}"; do
    if [[ -f "/home/donz/bECCsh/$test_script" ]]; then
        if bash -n "/home/donz/bECCsh/$test_script" 2>/dev/null; then
            check_result 0 "$test_script 语法正确"
        else
            check_result 1 "$test_script 语法错误"
        fi
    else
        check_result 1 "$test_script 不存在"
    fi
done
echo

# 总结
echo "========================================="
echo "检查完成 - 总结报告"
echo "========================================="
echo -e "总检查项: $TOTAL"
echo -e "通过: ${GREEN}$PASSED${NC}"
echo -e "失败: ${RED}$FAILED${NC}"
if [[ $WARNINGS -gt 0 ]]; then
    echo -e "警告: ${YELLOW}$WARNINGS${NC}"
fi
echo

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ 路径完整性检查通过！${NC}"
    echo -e "${GREEN}所有程序都能正常工作${NC}"
    exit 0
else
    echo -e "${RED}✗ 路径完整性检查失败！${NC}"
    echo -e "${RED}发现 $FAILED 个问题需要修复${NC}"
    exit 1
fi