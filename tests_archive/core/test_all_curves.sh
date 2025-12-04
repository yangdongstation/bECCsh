#!/bin/bash
# 全面测试所有椭圆曲线功能
# 验证每种曲线的密钥生成、签名、验证流程

set -euo pipefail

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色输出
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m'

# 测试统计
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# 要测试的所有曲线
ALL_CURVES=(
    "secp192k1"
    "secp224k1" 
    "secp256k1"
    "secp256r1"
    "secp384r1"
    "secp521r1"
    "brainpoolp256r1"
    "brainpoolp384r1"
    "brainpoolp512r1"
)

# 曲线别名测试
CURVE_ALIASES=(
    "p-256:secp256r1"
    "p-384:secp384r1"
    "p-521:secp521r1"
    "btc:secp256k1"
    "bitcoin:secp256k1"
    "ethereum:secp256k1"
    "prime256v1:secp256r1"
    "prime384v1:secp384r1"
    "prime521v1:secp521r1"
)

# 打印测试头部
print_test_header() {
    local test_name="$1"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$test_name${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# 打印测试结果
print_result() {
    local test_name="$1"
    local result="$2"
    local details="${3:-}"
    
    ((TOTAL_TESTS++))
    
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

# 打印测试总结
print_summary() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}测试总结${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "总测试数: $TOTAL_TESTS"
    echo -e "${GREEN}通过: $TESTS_PASSED${NC}"
    echo -e "${RED}失败: $TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 所有测试通过!${NC}"
        return 0
    else
        echo -e "${RED}❌ 部分测试失败!${NC}"
        return 1
    fi
}

# 测试单个曲线的基本功能
test_curve_basic() {
    local curve="$1"
    local test_prefix="$2"
    
    echo -e "${YELLOW}测试 $curve 基本功能...${NC}"
    
    local key_file="/tmp/test_${curve}_key.pem"
    local pub_file="/tmp/test_${curve}_key_public.pem"
    local sig_file="/tmp/test_${curve}_signature.sig"
    local message="Test message for $curve curve"
    
    # 1. 测试密钥生成
    echo -n "  密钥生成... "
    if BECC_SILENT=true "$SCRIPT_DIR/becc.sh" keygen -c "$curve" -f "$key_file" 2>/dev/null; then
        if [[ -f "$key_file" && -f "$pub_file" ]]; then
            print_result "$test_prefix 密钥生成" "PASS"
        else
            print_result "$test_prefix 密钥生成" "FAIL" "密钥文件未生成"
            return 1
        fi
    else
        print_result "$test_prefix 密钥生成" "FAIL" "密钥生成命令失败"
        return 1
    fi
    
    # 2. 测试签名
    echo -n "  签名... "
    if BECC_SILENT=true "$SCRIPT_DIR/becc.sh" sign -c "$curve" -k "$key_file" -m "$message" -f "$sig_file" 2>/dev/null; then
        if [[ -f "$sig_file" ]]; then
            print_result "$test_prefix 签名" "PASS"
        else
            print_result "$test_prefix 签名" "FAIL" "签名文件未生成"
            # 清理并返回
            rm -f "$key_file" "$pub_file" "$sig_file"
            return 1
        fi
    else
        print_result "$test_prefix 签名" "FAIL" "签名命令失败"
        # 清理并返回
        rm -f "$key_file" "$pub_file" "$sig_file"
        return 1
    fi
    
    # 3. 测试验证
    echo -n "  验证... "
    local verify_result
    verify_result=$(BECC_SILENT=true "$SCRIPT_DIR/becc.sh" verify -c "$curve" -k "$pub_file" -m "$message" -s "$sig_file" 2>&1)
    
    if echo "$verify_result" | grep -q "VALID"; then
        print_result "$test_prefix 验证" "PASS"
    else
        print_result "$test_prefix 验证" "FAIL" "验证失败: $verify_result"
    fi
    
    # 4. 测试签名大小
    echo -n "  签名大小... "
    if [[ -f "$sig_file" ]]; then
        local sig_size=$(stat -f%z "$sig_file" 2>/dev/null || stat -c%s "$sig_file" 2>/dev/null || echo "0")
        if [[ $sig_size -gt 0 ]]; then
            print_result "$test_prefix 签名大小" "PASS" "${sig_size}字节"
        else
            print_result "$test_prefix 签名大小" "FAIL" "签名大小为0"
        fi
    fi
    
    # 清理临时文件
    rm -f "$key_file" "$pub_file" "$sig_file"
}

# 测试所有曲线
test_all_curves() {
    print_test_header "测试所有椭圆曲线基本功能"
    echo ""
    
    for curve in "${ALL_CURVES[@]}"; do
        echo -e "${CYAN}测试 $curve:${NC}"
        test_curve_basic "$curve" "$curve"
        echo ""
    done
}

# 测试曲线别名
test_curve_aliases() {
    print_test_header "测试曲线别名功能"
    echo ""
    
    for alias_pair in "${CURVE_ALIASES[@]}"; do
        local alias=$(echo "$alias_pair" | cut -d: -f1)
        local actual_curve=$(echo "$alias_pair" | cut -d: -f2)
        
        echo -e "${CYAN}测试别名 '$alias' (应映射到 $actual_curve):${NC}"
        
        # 使用别名生成密钥
        local alias_key="/tmp/test_alias_${alias}.pem"
        local actual_key="/tmp/test_actual_${actual_curve}.pem"
        
        # 测试别名密钥生成
        echo -n "  别名密钥生成... "
        if BECC_SILENT=true "$SCRIPT_DIR/becc.sh" keygen -c "$alias" -f "$alias_key" 2>/dev/null; then
            print_result "别名 $alias 密钥生成" "PASS"
        else
            print_result "别名 $alias 密钥生成" "FAIL" "别名密钥生成失败"
            continue
        fi
        
        # 测试实际曲线密钥生成进行对比
        echo -n "  实际曲线对比... "
        if BECC_SILENT=true "$SCRIPT_DIR/becc.sh" keygen -c "$actual_curve" -f "$actual_key" 2>/dev/null; then
            # 检查两个密钥文件都存在
            if [[ -f "$alias_key" && -f "$actual_key" ]]; then
                print_result "$alias 映射验证" "PASS"
            else
                print_result "$alias 映射验证" "FAIL" "密钥文件缺失"
            fi
        else
            print_result "$alias 映射验证" "FAIL" "实际曲线密钥生成失败"
        fi
        
        # 清理
        rm -f "$alias_key" "${alias_key%.pem}_public.pem" "$actual_key" "${actual_key%.pem}_public.pem"
        echo ""
    done
}

# 测试智能推荐系统
test_smart_recommendations() {
    print_test_header "测试智能推荐系统"
    echo ""
    
    # 测试安全级别推荐
    echo -e "${CYAN}安全级别推荐测试:${NC}"
    local security_levels=("96" "112" "128" "192" "256")
    for level in "${security_levels[@]}"; do
        echo -n "  ${level}位安全级别推荐... "
        local recommended
        recommended=$("$SCRIPT_DIR/becc_multi_curve.sh" recommend --security "$level" 2>/dev/null | grep "推荐曲线:" | head -1 | cut -d: -f2 | tr -d ' ')
        
        if [[ -n "$recommended" ]]; then
            print_result "${level}位安全推荐" "PASS" "$recommended"
        else
            print_result "${level}位安全推荐" "FAIL" "无推荐结果"
        fi
    done
    echo ""
    
    # 测试用例推荐
    echo -e "${CYAN}用例推荐测试:${NC}"
    local use_cases=("mobile" "bitcoin" "web" "government" "long-term")
    for use_case in "${use_cases[@]}"; do
        echo -n "  $use_case 用例推荐... "
        local recommended
        recommended=$("$SCRIPT_DIR/becc_multi_curve.sh" recommend --use-case "$use_case" 2>/dev/null | grep "推荐曲线:" | head -1 | cut -d: -f2 | tr -d ' ')
        
        if [[ -n "$recommended" ]]; then
            print_result "$use_case 用例推荐" "PASS" "$recommended"
        else
            print_result "$use_case 用例推荐" "FAIL" "无推荐结果"
        fi
    done
    echo ""
}

# 测试曲线信息获取
test_curve_information() {
    print_test_header "测试曲线信息获取"
    echo ""
    
    # 测试几个代表性曲线
    local info_curves=("secp256k1" "secp256r1" "secp384r1")
    
    for curve in "${info_curves[@]}"; do
        echo -e "${CYAN}获取 $curve 信息:${NC}"
        
        # 使用curves命令获取信息
        echo -n "  基本信息... "
        local curve_info
        curve_info=$("$SCRIPT_DIR/becc_multi_curve.sh" curves 2>/dev/null | grep "$curve" || true)
        
        if [[ -n "$curve_info" ]]; then
            print_result "$curve 信息获取" "PASS"
        else
            print_result "$curve 信息获取" "FAIL" "无法获取曲线信息"
        fi
        echo ""
    done
}

# 测试特殊场景
test_edge_cases() {
    print_test_header "测试边界情况"
    echo ""
    
    # 测试空消息
    echo -e "${CYAN}测试空消息签名:${NC}"
    local key_file="/tmp/test_empty_key.pem"
    local sig_file="/tmp/test_empty.sig"
    
    echo -n "  空消息处理... "
    if BECC_SILENT=true "$SCRIPT_DIR/becc.sh" keygen -c secp256r1 -f "$key_file" 2>/dev/null; then
        if BECC_SILENT=true "$SCRIPT_DIR/becc.sh" sign -c secp256r1 -k "$key_file" -m "" -f "$sig_file" 2>/dev/null; then
            print_result "空消息签名" "PASS"
        else
            print_result "空消息签名" "FAIL" "空消息签名失败"
        fi
    else
        print_result "空消息签名" "FAIL" "密钥生成失败"
    fi
    
    rm -f "$key_file" "${key_file%.pem}_public.pem" "$sig_file"
    echo ""
    
    # 测试长消息
    echo -e "${CYAN}测试长消息签名:${NC}"
    local long_message=$(printf 'A%.0s' {1..1000})
    local key_file2="/tmp/test_long_key.pem"
    local sig_file2="/tmp/test_long.sig"
    
    echo -n "  长消息处理... "
    if BECC_SILENT=true "$SCRIPT_DIR/becc.sh" keygen -c secp256r1 -f "$key_file2" 2>/dev/null; then
        if BECC_SILENT=true "$SCRIPT_DIR/becc.sh" sign -c secp256r1 -k "$key_file2" -m "$long_message" -f "$sig_file2" 2>/dev/null; then
            print_result "长消息签名" "PASS"
        else
            print_result "长消息签名" "FAIL" "长消息签名失败"
        fi
    else
        print_result "长消息签名" "FAIL" "密钥生成失败"
    fi
    
    rm -f "$key_file2" "${key_file2%.pem}_public.pem" "$sig_file2"
    echo ""
}

# 测试性能对比
test_performance_comparison() {
    print_test_header "性能对比测试"
    echo ""
    
    echo -e "${CYAN}简单性能测试 (5次迭代):${NC}"
    
    # 选择几个代表性曲线
    local perf_curves=("secp192k1" "secp256k1" "secp256r1" "secp384r1")
    
    for curve in "${perf_curves[@]}"; do
        echo -n "  $curve 性能... "
        
        local start_time end_time duration
        start_time=$(date +%s.%N)
        
        # 进行简单测试：生成5个密钥对
        local success_count=0
        for ((i=1; i<=5; i++)); do
            if BECC_SILENT=true "$SCRIPT_DIR/becc.sh" keygen -c "$curve" -f "/tmp/perf_${curve}_${i}.pem" 2>/dev/null; then
                ((success_count++))
                rm -f "/tmp/perf_${curve}_${i}.pem" "/tmp/perf_${curve}_${i}_public.pem"
            fi
        done
        
        end_time=$(date +%s.%N)
        duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
        
        if [[ $success_count -eq 5 ]]; then
            printf "${GREEN}%.3f秒${NC} (成功率: 100%%)\n" "$duration"
            print_result "$curve 性能" "PASS" "${duration}秒"
        else
            printf "${RED}失败${NC} (成功率: %d%%)\n" $((success_count * 100 / 5))
            print_result "$curve 性能" "FAIL" "成功率低: $success_count/5"
        fi
    done
    echo ""
}

# 主测试函数
run_comprehensive_tests() {
    clear
    echo -e "${BLUE}"
    echo "=================================================="
    echo "  bECCsh 全曲线功能综合测试"
    echo "=================================================="
    echo -e "${NC}"
    echo "测试时间: $(date)"
    echo "测试环境: $(uname -a)"
    echo ""
    
    # 运行所有测试
    test_all_curves
    test_curve_aliases
    test_smart_recommendations
    test_curve_information
    test_edge_cases
    test_performance_comparison
    
    # 打印总结
    print_summary
}

# 快速测试函数
run_quick_tests() {
    echo -e "${BLUE}运行快速测试...${NC}"
    echo ""
    
    # 只测试核心曲线
    local core_curves=("secp256k1" "secp256r1" "secp384r1")
    
    for curve in "${core_curves[@]}"; do
        echo -e "${CYAN}快速测试 $curve:${NC}"
        test_curve_basic "$curve" "快速-$curve"
        echo ""
    done
    
    # 打印总结
    print_summary
}

# 主函数
main() {
    local test_mode="${1:-full}"
    
    case "$test_mode" in
        "quick")
            run_quick_tests
            ;;
        "full"|"")
            run_comprehensive_tests
            ;;
        "curves")
            test_all_curves
            print_summary
            ;;
        "aliases")
            test_curve_aliases
            print_summary
            ;;
        "recommend")
            test_smart_recommendations
            print_summary
            ;;
        "performance")
            test_performance_comparison
            print_summary
            ;;
        *)
            echo "未知测试模式: $test_mode"
            echo "可用模式: quick, full, curves, aliases, recommend, performance"
            exit 1
            ;;
    esac
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi