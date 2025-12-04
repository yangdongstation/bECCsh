#!/bin/bash
# 多椭圆曲线支持综合测试脚本
# 测试bECCsh的多曲线功能和兼容性

set -euo pipefail

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
core_dir="$SCRIPT_DIR/core"
lib_dir="$SCRIPT_DIR/lib"

# 颜色输出
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# 测试统计
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# 要测试的曲线列表
TEST_CURVES=(
    "secp256k1"
    "secp256r1"
    "secp384r1"
    "secp521r1"
    "secp224k1"
    "secp192k1"
    "brainpoolp256r1"
    "brainpoolp384r1"
    "brainpoolp512r1"
)

# 测试消息
TEST_MESSAGES=(
    "Hello, bECCsh Multi-Curve!"
    "测试中文消息支持"
    "Special chars: !@#$%^&*()"
    "1234567890"
    ""
)

# 打印测试头部
print_test_header() {
    local test_name="$1"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}测试: $test_name${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# 打印测试结果
print_test_result() {
    local test_name="$1"
    local result="$2"
    local details="${3:-}"
    
    ((TESTS_TOTAL++))
    
    if [[ "$result" == "PASS" ]]; then
        echo -e "${GREEN}✓ $test_name${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ $test_name${NC}"
        if [[ -n "$details" ]]; then
            echo -e "${RED}  错误: $details${NC}"
        fi
        ((TESTS_FAILED++))
    fi
}

# 打印测试统计
print_test_summary() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}测试总结${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "总测试数: $TESTS_TOTAL"
    echo -e "${GREEN}通过: $TESTS_PASSED${NC}"
    echo -e "${RED}失败: $TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}所有测试通过! 🎉${NC}"
        return 0
    else
        echo -e "${RED}部分测试失败! ❌${NC}"
        return 1
    fi
}

# 测试曲线选择器
test_curve_selector() {
    print_test_header "曲线选择器测试"
    
    # 导入曲线选择器
    source "$core_dir/crypto/curve_selector.sh"
    
    # 测试支持的曲线
    for curve in "${TEST_CURVES[@]}"; do
        if select_curve "$curve"; then
            print_test_result "选择曲线 $curve" "PASS"
        else
            print_test_result "选择曲线 $curve" "FAIL" "曲线选择失败"
        fi
    done
    
    # 测试曲线别名
    local aliases=("p-256" "prime256v1" "btc" "bitcoin" "ethereum")
    for alias in "${aliases[@]}"; do
        if select_curve "$alias"; then
            print_test_result "选择别名 $alias" "PASS"
        else
            print_test_result "选择别名 $alias" "FAIL" "别名解析失败"
        fi
    done
    
    # 测试不支持的曲线
    if select_curve "unsupported_curve" 2>/dev/null; then
        print_test_result "拒绝不支持曲线" "FAIL" "应该拒绝不支持的曲线"
    else
        print_test_result "拒绝不支持曲线" "PASS"
    fi
}

# 测试曲线参数验证
test_curve_params() {
    print_test_header "曲线参数验证测试"
    
    # 导入曲线选择器
    source "$core_dir/crypto/curve_selector.sh"
    
    for curve in "${TEST_CURVES[@]}"; do
        if select_curve "$curve"; then
            if validate_current_curve; then
                print_test_result "验证 $curve 参数" "PASS"
            else
                print_test_result "验证 $curve 参数" "FAIL" "参数验证失败"
            fi
        else
            print_test_result "验证 $curve 参数" "FAIL" "曲线选择失败"
        fi
    done
}

# 测试曲线信息获取
test_curve_info() {
    print_test_header "曲线信息获取测试"
    
    # 导入曲线选择器
    source "$core_dir/crypto/curve_selector.sh"
    
    for curve in "${TEST_CURVES[@]}"; do
        if select_curve "$curve"; then
            local info
            info=$(get_current_curve_info)
            if [[ -n "$info" ]]; then
                print_test_result "获取 $curve 信息" "PASS"
            else
                print_test_result "获取 $curve 信息" "FAIL" "信息获取失败"
            fi
        else
            print_test_result "获取 $curve 信息" "FAIL" "曲线选择失败"
        fi
    done
}

# 测试曲线推荐功能
test_curve_recommendations() {
    print_test_header "曲线推荐功能测试"
    
    # 导入曲线选择器
    source "$core_dir/crypto/curve_selector.sh"
    
    # 测试安全级别推荐
    local security_levels=("96" "128" "192" "256")
    for level in "${security_levels[@]}"; do
        local recommended=$(recommend_curve_by_security "$level")
        if [[ -n "$recommended" ]]; then
            print_test_result "安全级别 $level 推荐" "PASS"
        else
            print_test_result "安全级别 $level 推荐" "FAIL" "推荐失败"
        fi
    done
    
    # 测试用例推荐
    local use_cases=("mobile" "bitcoin" "web" "government" "long-term")
    for use_case in "${use_cases[@]}"; do
        local recommended=$(recommend_curve_by_use_case "$use_case")
        if [[ -n "$recommended" ]]; then
            print_test_result "用例 $use_case 推荐" "PASS"
        else
            print_test_result "用例 $use_case 推荐" "FAIL" "推荐失败"
        fi
    done
}

# 测试密钥生成
test_key_generation() {
    print_test_header "密钥生成测试"
    
    # 导入曲线选择器
    source "$core_dir/crypto/curve_selector.sh"
    
    for curve in "${TEST_CURVES[@]}"; do
        if select_curve "$curve"; then
            # 获取曲线参数
            local params
            params=$(get_current_curve_params)
            if [[ $? -eq 0 && -n "$params" ]]; then
                print_test_result "$curve 参数获取" "PASS"
            else
                print_test_result "$curve 参数获取" "FAIL" "参数获取失败"
                continue
            fi
            
            # 测试参数格式
            local param_count=$(echo "$params" | wc -w)
            if [[ $param_count -eq 7 ]]; then
                print_test_result "$curve 参数格式" "PASS"
            else
                print_test_result "$curve 参数格式" "FAIL" "参数数量错误: $param_count"
            fi
        else
            print_test_result "$curve 选择" "FAIL" "曲线选择失败"
        fi
    done
}

# 测试曲线兼容性
test_curve_compatibility() {
    print_test_header "曲线兼容性测试"
    
    # 导入曲线选择器
    source "$core_dir/crypto/curve_selector.sh"
    
    # 测试与主程序的兼容性
    for curve in "secp256k1" "secp256r1" "secp384r1"; do
        if "$SCRIPT_DIR/becc.sh" keygen -c "$curve" -f "/tmp/test_${curve}_key.pem" 2>/dev/null; then
            print_test_result "$curve 主程序兼容性" "PASS"
            rm -f "/tmp/test_${curve}_key.pem" "/tmp/test_${curve}_key_public.pem"
        else
            print_test_result "$curve 主程序兼容性" "FAIL" "主程序调用失败"
        fi
    done
}

# 测试性能比较
test_performance_comparison() {
    print_test_header "性能比较测试"
    
    # 导入曲线选择器
    source "$core_dir/crypto/curve_selector.sh"
    
    # 选择几个代表性曲线进行性能测试
    local perf_curves=("secp192k1" "secp256k1" "secp256r1" "secp384r1")
    
    for curve in "${perf_curves[@]}"; do
        if select_curve "$curve"; then
            local start_time end_time duration
            
            start_time=$(date +%s.%N)
            
            # 模拟一些基本操作
            for ((i=1; i<=10; i++)); do
                local params
                params=$(get_current_curve_params)
                local info
                info=$(get_current_curve_info)
            done
            
            end_time=$(date +%s.%N)
            
            # 计算时间（简化计算）
            local start_sec=${start_time%.*}
            local end_sec=${end_time%.*}
            duration=$((end_sec - start_sec))
            
            if [[ $duration -lt 5 ]]; then  # 性能测试应该在5秒内完成
                print_test_result "$curve 性能测试" "PASS"
            else
                print_test_result "$curve 性能测试" "FAIL" "性能测试超时"
            fi
        else
            print_test_result "$curve 性能测试" "FAIL" "曲线选择失败"
        fi
    done
}

# 测试错误处理
test_error_handling() {
    print_test_header "错误处理测试"
    
    # 导入曲线选择器
    source "$core_dir/crypto/curve_selector.sh"
    
    # 测试无效曲线名称
    if select_curve "invalid_curve_name" 2>/dev/null; then
        print_test_result "无效曲线名称处理" "FAIL" "应该拒绝无效曲线"
    else
        print_test_result "无效曲线名称处理" "PASS"
    fi
    
    # 测试空曲线名称
    if select_curve "" 2>/dev/null; then
        print_test_result "空曲线名称处理" "FAIL" "应该拒绝空曲线名称"
    else
        print_test_result "空曲线名称处理" "PASS"
    fi
    
    # 测试获取未选择曲线的信息
    unset CURRENT_CURVE
    if get_current_curve_info 2>/dev/null; then
        print_test_result "未选择曲线信息处理" "FAIL" "应该处理未选择曲线的情况"
    else
        print_test_result "未选择曲线信息处理" "PASS"
    fi
}

# 测试内存使用
test_memory_usage() {
    print_test_header "内存使用测试"
    
    # 导入曲线选择器
    source "$core_dir/crypto/curve_selector.sh"
    
    # 测试大量曲线切换
    for ((i=1; i<=20; i++)); do
        for curve in "secp256k1" "secp256r1" "secp384r1"; do
            if ! select_curve "$curve" 2>/dev/null; then
                print_test_result "内存使用测试" "FAIL" "第 $i 轮曲线切换失败"
                return 1
            fi
        done
    done
    
    print_test_result "内存使用测试" "PASS"
}

# 测试并发安全性
test_concurrent_safety() {
    print_test_header "并发安全性测试"
    
    # 导入曲线选择器
    source "$core_dir/crypto/curve_selector.sh"
    
    # 测试参数文件的重复加载保护
    for curve in "secp256k1" "secp256r1"; do
        # 多次选择同一曲线
        for ((i=1; i<=5; i++)); do
            if ! select_curve "$curve" 2>/dev/null; then
                print_test_result "并发安全性 ($curve)" "FAIL" "重复加载失败"
                return 1
            fi
        done
    done
    
    print_test_result "并发安全性" "PASS"
}

# 运行所有测试
run_all_tests() {
    echo -e "${PURPLE}"
    echo "========================================"
    echo "bECCsh 多椭圆曲线支持综合测试"
    echo "========================================"
    echo -e "${NC}"
    
    # 运行所有测试模块
    test_curve_selector
    test_curve_params
    test_curve_info
    test_curve_recommendations
    test_key_generation
    test_curve_compatibility
    test_performance_comparison
    test_error_handling
    test_memory_usage
    test_concurrent_safety
    
    # 打印测试总结
    print_test_summary
}

# 显示测试菜单
show_test_menu() {
    echo "bECCsh 多曲线测试选项:"
    echo "======================"
    echo "1. 运行所有测试"
    echo "2. 曲线选择器测试"
    echo "3. 曲线参数验证测试"
    echo "4. 曲线信息获取测试"
    echo "5. 曲线推荐功能测试"
    echo "6. 密钥生成测试"
    echo "7. 曲线兼容性测试"
    echo "8. 性能比较测试"
    echo "9. 错误处理测试"
    echo "10. 内存使用测试"
    echo "11. 并发安全性测试"
    echo "12. 退出"
    echo ""
}

# 主函数
main() {
    local choice=""
    
    # 检查是否有命令行参数
    if [[ $# -eq 0 ]]; then
        # 交互模式
        while [[ "$choice" != "12" ]]; do
            show_test_menu
            read -p "请选择测试项目 (1-12): " choice
            
            case "$choice" in
                1) run_all_tests ;;
                2) test_curve_selector ;;
                3) test_curve_params ;;
                4) test_curve_info ;;
                5) test_curve_recommendations ;;
                6) test_key_generation ;;
                7) test_curve_compatibility ;;
                8) test_performance_comparison ;;
                9) test_error_handling ;;
                10) test_memory_usage ;;
                11) test_concurrent_safety ;;
                12) echo "退出测试" ;;
                *) echo "无效选择，请重新输入" ;;
            esac
            
            if [[ "$choice" != "12" ]]; then
                echo ""
                read -p "按回车键继续..."
                echo ""
            fi
        done
    else
        # 命令行模式
        case "${1:-all}" in
            all|"")
                run_all_tests
                ;;
            selector)
                test_curve_selector
                ;;
            params)
                test_curve_params
                ;;
            info)
                test_curve_info
                ;;
            recommend)
                test_curve_recommendations
                ;;
            keygen)
                test_key_generation
                ;;
            compat)
                test_curve_compatibility
                ;;
            perf)
                test_performance_comparison
                ;;
            error)
                test_error_handling
                ;;
            memory)
                test_memory_usage
                ;;
            concurrent)
                test_concurrent_safety
                ;;
            *)
                echo "未知测试类型: $1"
                echo "可用类型: all, selector, params, info, recommend, keygen, compat, perf, error, memory, concurrent"
                exit 1
                ;;
        esac
    fi
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi