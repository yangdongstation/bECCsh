#!/bin/bash
# 多椭圆曲线支持核心功能测试
# 专注于基础功能的验证

set -euo pipefail

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
core_dir="$SCRIPT_DIR/core"

# 颜色输出
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# 测试计数
TESTS_PASSED=0
TESTS_FAILED=0

# 简单的测试函数
test_pass() {
    echo -e "${GREEN}✓ $1${NC}"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "${RED}✗ $1${NC}"
    ((TESTS_FAILED++))
}

# 测试1: 曲线参数文件存在性
test_curve_files() {
    echo -e "${BLUE}测试1: 曲线参数文件${NC}"
    
    local files=("$core_dir/curves/secp256r1_params.sh" "$core_dir/curves/secp256k1_params.sh")
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            test_pass "文件存在: $(basename "$file")"
        else
            test_fail "文件缺失: $(basename "$file")"
        fi
    done
}

# 测试2: 曲线参数加载
test_curve_params() {
    echo -e "${BLUE}测试2: 曲线参数加载${NC}"
    
    # 测试SECP256R1参数
    if source "$core_dir/curves/secp256r1_params.sh" 2>/dev/null; then
        if [[ -n "${SECP256R1_P:-}" ]] && [[ ${#SECP256R1_P} -gt 50 ]]; then
            test_pass "SECP256R1参数加载成功"
        else
            test_fail "SECP256R1参数加载失败"
        fi
    else
        test_fail "SECP256R1参数文件加载错误"
    fi
    
    # 测试SECP256K1参数
    if source "$core_dir/curves/secp256k1_params.sh" 2>/dev/null; then
        if [[ -n "${SECP256K1_P:-}" ]] && [[ ${#SECP256K1_P} -gt 50 ]]; then
            test_pass "SECP256K1参数加载成功"
        else
            test_fail "SECP256K1参数加载失败"
        fi
    else
        test_fail "SECP256K1参数文件加载错误"
    fi
}

# 测试3: 曲线选择器
test_curve_selector() {
    echo -e "${BLUE}测试3: 曲线选择器${NC}"
    
    # 导入曲线选择器
    if source "$core_dir/crypto/curve_selector.sh" 2>/dev/null; then
        test_pass "曲线选择器加载成功"
    else
        test_fail "曲线选择器加载失败"
        return 1
    fi
    
    # 测试支持的曲线
    local test_curves=("secp256k1" "secp256r1" "p-256" "prime256v1")
    
    for curve in "${test_curves[@]}"; do
        if select_curve "$curve" 2>/dev/null; then
            test_pass "选择曲线: $curve"
        else
            test_fail "选择曲线失败: $curve"
        fi
    done
    
    # 测试不支持的曲线
    if ! select_curve "invalid_curve" 2>/dev/null; then
        test_pass "正确拒绝无效曲线"
    else
        test_fail "未正确处理无效曲线"
    fi
}

# 测试4: 模运算功能
test_modular_arithmetic() {
    echo -e "${BLUE}测试4: 模运算功能${NC}"
    
    # 导入模运算库
    if source "$core_dir/operations/ecc_arithmetic.sh" 2>/dev/null; then
        test_pass "模运算库加载成功"
    else
        test_fail "模运算库加载失败"
        return 1
    fi
    
    # 测试基本模运算
    local test_p="97"
    local result
    
    # 模加法
    result=$(mod_add "42" "35" "$test_p" 2>/dev/null)
    if [[ "$result" == "73" ]]; then
        test_pass "模加法测试"
    else
        test_fail "模加法测试 (得到: $result)"
    fi
    
    # 模乘法
    result=$(mod_mul "5" "7" "$test_p" 2>/dev/null)
    if [[ "$result" == "35" ]]; then
        test_pass "模乘法测试"
    else
        test_fail "模乘法测试 (得到: $result)"
    fi
    
    # 模逆元
    result=$(mod_inverse "3" "$test_p" 2>/dev/null)
    if [[ -n "$result" ]] && [[ "$result" =~ ^[0-9]+$ ]]; then
        test_pass "模逆元测试"
    else
        test_fail "模逆元测试"
    fi
}

# 测试5: 点运算功能
test_point_operations() {
    echo -e "${BLUE}测试5: 点运算功能${NC}"
    
    # 导入点运算库
    if source "$core_dir/operations/point_operations.sh" 2>/dev/null; then
        test_pass "点运算库加载成功"
    else
        test_fail "点运算库加载失败"
        return 1
    fi
    
    # 使用简单曲线参数进行测试
    local test_p="23"
    local test_a="1"
    local test_b="1"
    local x="3"
    local y="10"
    
    # 测试点是否在曲线上
    if point_on_curve "$x" "$y" "$test_a" "$test_b" "$test_p" 2>/dev/null; then
        test_pass "点在曲线上测试"
    else
        test_fail "点在曲线上测试"
    fi
    
    # 测试点加倍
    local result
    result=$(ec_point_double "$x" "$y" "$test_a" "$test_p" 2>/dev/null)
    if [[ -n "$result" ]]; then
        test_pass "点加倍测试"
    else
        test_fail "点加倍测试"
    fi
}

# 测试6: 曲线验证
test_curve_validation() {
    echo -e "${BLUE}测试6: 曲线验证${NC}"
    
    # 导入验证工具
    if source "$core_dir/utils/curve_validator.sh" 2>/dev/null; then
        test_pass "曲线验证工具加载成功"
    else
        test_fail "曲线验证工具加载失败"
        return 1
    fi
    
    # 测试标准曲线验证
    if validate_standard_curve "secp256k1" >/dev/null 2>&1; then
        test_pass "SECP256K1验证通过"
    else
        test_fail "SECP256K1验证失败"
    fi
    
    if validate_standard_curve "secp256r1" >/dev/null 2>&1; then
        test_pass "SECP256R1验证通过"
    else
        test_fail "SECP256R1验证失败"
    fi
}

# 测试7: 兼容性测试
test_compatibility() {
    echo -e "${BLUE}测试7: 兼容性测试${NC}"
    
    # 测试与现有lib目录的兼容性
    if [[ -f "$SCRIPT_DIR/lib/ec_curve.sh" ]]; then
        test_pass "现有ec_curve.sh存在"
        
        # 导入现有库
        if source "$SCRIPT_DIR/lib/ec_curve.sh" 2>/dev/null; then
            test_pass "现有库加载成功"
            
            # 检查支持的曲线
            if [[ " ${SUPPORTED_CURVES[@]} " =~ " secp256k1 " ]]; then
                test_pass "支持secp256k1曲线"
            else
                test_fail "不支持secp256k1曲线"
            fi
        else
            test_fail "现有库加载失败"
        fi
    else
        test_fail "现有ec_curve.sh不存在"
    fi
}

# 主测试函数
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}bECCsh 多椭圆曲线支持核心功能测试${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # 运行所有测试
    test_curve_files
    test_curve_params
    test_curve_selector
    test_modular_arithmetic
    test_point_operations
    test_curve_validation
    test_compatibility
    
    # 总结
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}测试总结${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}通过: $TESTS_PASSED${NC}"
    echo -e "${RED}失败: $TESTS_FAILED${NC}"
    echo -e "总计: $((TESTS_PASSED + TESTS_FAILED))"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ 所有核心功能测试通过！${NC}"
        echo -e "${GREEN}多椭圆曲线支持核心功能已成功实现${NC}"
        return 0
    else
        echo -e "${RED}✗ 部分测试失败${NC}"
        return 1
    fi
}

# 运行主函数
main "$@"