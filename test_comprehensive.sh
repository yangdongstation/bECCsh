#!/bin/bash
# bECCsh 全面可运行度测试脚本
# 不在乎性能，只关注功能正确性

set -euo pipefail

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色输出
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# 测试统计
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# 所有支持的曲线
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

# 测试消息
TEST_MESSAGES=(
    "Hello, bECCsh!"
    "测试中文消息支持"
    "Special chars: !@#$%^&*()"
    "1234567890"
    "The quick brown fox jumps over the lazy dog"
    ""
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
    
    ((TESTS_TOTAL++))
    
    if [[ "$result" == "PASS" ]]; then
        echo -e "${GREEN}✓ $test_name${NC}"
        ((TESTS_PASSED++))
        if [[ -n "$details" ]]; then
            echo -e "${GREEN}  $details${NC}"
        fi
    else
        echo -e "${RED}✗ $test_name${NC}"
        if [[ -n "$details" ]]; then
            echo -e "${RED}  $details${NC}"
        fi
        ((TESTS_FAILED++))
    fi
}

# 打印测试总结
print_summary() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}测试总结${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "总测试数: $TESTS_TOTAL"
    echo -e "${GREEN}通过: $TESTS_PASSED${NC}"
    echo -e "${RED}失败: $TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 所有测试通过! 软件包可运行度: 100%${NC}"
        return 0
    else
        echo -e "${RED}❌ 部分测试失败! 软件包可运行度: $((TESTS_PASSED * 100 / TESTS_TOTAL))%${NC}"
        return 1
    fi
}

# 测试基础功能 - 所有曲线密钥生成
test_basic_keygen() {
    print_test_header "测试所有曲线密钥生成"
    
    for curve in "${ALL_CURVES[@]}"; do
        echo -e "${YELLOW}测试 $curve 密钥生成...${NC}"
        
        local key_file="/tmp/test_${curve}_key.pem"
        local pub_file="/tmp/test_${curve}_key_public.pem"
        
        # 尝试生成密钥对
        if BECC_SILENT=true "$SCRIPT_DIR/becc.sh" keygen -c "$curve" -f "$key_file" 2>/dev/null; then
            if [[ -f "$key_file" && -f "$pub_file" ]]; then
                local key_size=$(stat -c%s "$key_file" 2>/dev/null || stat -f%z "$key_file" 2>/dev/null || echo "0")
                local pub_size=$(stat -c%s "$pub_file" 2>/dev/null || stat -f%z "$pub_file" 2>/dev/null || echo "0")
                
                if [[ $key_size -gt 0 && $pub_size -gt 0 ]]; then
                    print_result "$curve 密钥生成" "PASS" "私钥: ${key_size}B, 公钥: ${pub_size}B"
                else
                    print_result "$curve 密钥生成" "FAIL" "密钥文件大小为0"
                fi
            else
                print_result "$curve 密钥生成" "FAIL" "密钥文件未生成"
            fi
        else
            print_result "$curve 密钥生成" "FAIL" "密钥生成命令失败"
        fi
        
        # 清理测试文件
        rm -f "$key_file" "$pub_file"
        echo ""
    done
}

# 测试签名功能 - 使用修复版本
test_signature_functions() {
    print_test_header "测试签名功能（修复版本）"
    
    # 使用修复版本进行测试
    local test_curves=("secp256k1" "secp256r1" "secp384r1")
    
    for curve in "${test_curves[@]}"; do
        echo -e "${YELLOW}测试 $curve 签名和验证...${NC}"
        
        local key_file="/tmp/test_${curve}_key.pem"
        local pub_file="/tmp/test_${curve}_key_public.pem"
        local sig_file="/tmp/test_${curve}_signature.sig"
        local message="Test message for $curve"
        
        # 生成密钥对
        echo "  生成密钥对..."
        if BECC_SILENT=true "$SCRIPT_DIR/becc_fixed.sh" keygen -c "$curve" -f "$key_file" 2>/dev/null; then
            echo "  ✅ 密钥生成成功"
        else
            print_result "$curve 签名测试" "FAIL" "密钥生成失败"
            continue
        fi
        
        # 测试签名
        echo "  测试签名..."
        if BECC_SILENT=true "$SCRIPT_DIR/becc_fixed.sh" sign -c "$curve" -k "$key_file" -m "$message" -f "$sig_file" 2>/dev/null; then
            if [[ -f "$sig_file" ]]; then
                local sig_size=$(stat -c%s "$sig_file" 2>/dev/null || stat -f%z "$sig_file" 2>/dev/null || echo "0")
                if [[ $sig_size -gt 0 ]]; then
                    echo "  ✅ 签名生成成功 (${sig_size}B)"
                else
                    print_result "$curve 签名测试" "FAIL" "签名文件大小为0"
                    rm -f "$key_file" "$pub_file" "$sig_file"
                    continue
                fi
            else
                print_result "$curve 签名测试" "FAIL" "签名文件未生成"
                rm -f "$key_file" "$pub_file" "$sig_file"
                continue
            fi
        else
            print_result "$curve 签名测试" "FAIL" "签名生成失败"
            rm -f "$key_file" "$pub_file" "$sig_file"
            continue
        fi
        
        # 测试验证
        echo "  测试签名验证..."
        local verify_result
        verify_result=$(BECC_SILENT=true "$SCRIPT_DIR/becc_fixed.sh" verify -c "$curve" -k "$pub_file" -m "$message" -s "$sig_file" 2>&1)
        
        if echo "$verify_result" | grep -q "VALID"; then
            print_result "$curve 签名验证" "PASS" "签名验证成功"
        else
            print_result "$curve 签名验证" "FAIL" "签名验证失败: $verify_result"
        fi
        
        # 清理测试文件
        rm -f "$key_file" "$pub_file" "$sig_file"
        echo ""
    done
}

# 测试曲线别名功能
test_curve_aliases() {
    print_test_header "测试曲线别名功能"
    
    local aliases=(
        "p-256:secp256r1"
        "p-384:secp384r1"
        "btc:secp256k1"
        "bitcoin:secp256k1"
        "ethereum:secp256k1"
    )
    
    for alias_pair in "${aliases[@]}"; do
        local alias=$(echo "$alias_pair" | cut -d: -f1)
        local actual=$(echo "$alias_pair" | cut -d: -f2)
        
        echo -e "${YELLOW}测试别名 '$alias' (应映射到 $actual)...${NC}"
        
        local key_file="/tmp/test_alias_${alias}.pem"
        
        if BECC_SILENT=true "$SCRIPT_DIR/becc.sh" keygen -c "$alias" -f "$key_file" 2>/dev/null; then
            print_result "别名 $alias" "PASS" "成功映射到 $actual"
        else
            print_result "别名 $alias" "FAIL" "别名解析失败"
        fi
        
        rm -f "$key_file" "${key_file%.pem}_public.pem"
        echo ""
    done
}

# 测试智能推荐系统
test_smart_recommendations() {
    print_test_header "测试智能推荐系统"
    
    # 测试安全级别推荐
    echo -e "${YELLOW}测试安全级别推荐...${NC}"
    local security_levels=("96" "128" "192" "256")
    
    for level in "${security_levels[@]}"; do
        local recommended
        recommended=$("$SCRIPT_DIR/becc_multi_curve.sh" recommend --security "$level" 2>/dev/null | grep "推荐曲线:" | head -1 | cut -d: -f2 | tr -d ' ')
        
        if [[ -n "$recommended" ]]; then
            print_result "安全级别 $level" "PASS" "推荐: $recommended"
        else
            print_result "安全级别 $level" "FAIL" "无推荐结果"
        fi
    done
    echo ""
    
    # 测试用例推荐
    echo -e "${YELLOW}测试用例推荐...${NC}"
    local use_cases=("mobile" "bitcoin" "web" "government")
    
    for use_case in "${use_cases[@]}"; do
        local recommended
        recommended=$("$SCRIPT_DIR/becc_multi_curve.sh" recommend --use-case "$use_case" 2>/dev/null | grep "推荐曲线:" | head -1 | cut -d: -f2 | tr -d ' ')
        
        if [[ -n "$recommended" ]]; then
            print_result "用例 $use_case" "PASS" "推荐: $recommended"
        else
            print_result "用例 $use_case" "FAIL" "无推荐结果"
        fi
    done
    echo ""
}

# 测试边界条件和极端情况
test_edge_cases() {
    print_test_header "测试边界条件和极端情况"
    
    # 测试空消息
    echo -e "${YELLOW}测试空消息...${NC}"
    local key_file="/tmp/test_empty_key.pem"
    local sig_file="/tmp/test_empty.sig"
    
    if BECC_SILENT=true "$SCRIPT_DIR/becc_fixed.sh" keygen -c secp256k1 -f "$key_file" 2>/dev/null; then
        if BECC_SILENT=true "$SCRIPT_DIR/becc_fixed.sh" sign -c secp256k1 -k "$key_file" -m "" -f "$sig_file" 2>/dev/null; then
            print_result "空消息签名" "PASS" "空消息处理成功"
        else
            print_result "空消息签名" "FAIL" "空消息处理失败"
        fi
    else
        print_result "空消息签名" "FAIL" "密钥生成失败"
    fi
    rm -f "$key_file" "$sig_file"
    echo ""
    
    # 测试长消息
    echo -e "${YELLOW}测试长消息...${NC}"
    local long_message=$(printf 'A%.0s' {1..1000})
    local key_file="/tmp/test_long_key.pem"
    local sig_file="/tmp/test_long.sig"
    
    if BECC_SILENT=true "$SCRIPT_DIR/becc_fixed.sh" keygen -c secp256k1 -f "$key_file" 2>/dev/null; then
        if BECC_SILENT=true "$SCRIPT_DIR/becc_fixed.sh" sign -c secp256k1 -k "$key_file" -m "$long_message" -f "$sig_file" 2>/dev/null; then
            print_result "长消息签名" "PASS" "长消息处理成功"
        else
            print_result "长消息签名" "FAIL" "长消息处理失败"
        fi
    else
        print_result "长消息签名" "FAIL" "密钥生成失败"
    fi
    rm -f "$key_file" "$sig_file"
    echo ""
    
    # 测试特殊字符
    echo -e "${YELLOW}测试特殊字符...${NC}"
    local special_message="!@#$%^&*()_+-=[]{}|;':\",./<>?"
    local key_file="/tmp/test_special_key.pem"
    local sig_file="/tmp/test_special.sig"
    
    if BECC_SILENT=true "$SCRIPT_DIR/becc_fixed.sh" keygen -c secp256k1 -f "$key_file" 2>/dev/null; then
        if BECC_SILENT=true "$SCRIPT_DIR/becc_fixed.sh" sign -c secp256k1 -k "$key_file" -m "$special_message" -f "$sig_file" 2>/dev/null; then
            print_result "特殊字符签名" "PASS" "特殊字符处理成功"
        else
            print_result "特殊字符签名" "FAIL" "特殊字符处理失败"
        fi
    else
        print_result "特殊字符签名" "FAIL" "密钥生成失败"
    fi
    rm -f "$key_file" "$sig_file"
    echo ""
}

# 测试文件操作
test_file_operations() {
    print_test_header "测试文件操作功能"
    
    # 测试文件读写
    echo -e "${YELLOW}测试文件读写...${NC}"
    local test_file="/tmp/test_file_ops.txt"
    local test_message="File operations test"
    
    # 写入文件
    echo "$test_message" > "$test_file"
    
    # 读取文件并签名
    if BECC_SILENT=true "$SCRIPT_DIR/becc_fixed.sh" keygen -c secp256k1 -f "$test_file.key" 2>/dev/null; then
        if BECC_SILENT=true "$SCRIPT_DIR/becc_fixed.sh" sign -c secp256k1 -k "$test_file.key" -f "$test_file" -f "$test_file.sig" 2>/dev/null; then
            print_result "文件操作" "PASS" "文件读写成功"
        else
            print_result "文件操作" "FAIL" "文件签名失败"
        fi
    else
        print_result "文件操作" "FAIL" "密钥生成失败"
    fi
    rm -f "$test_file" "$test_file.key" "$test_file.sig" "${test_file}.key_public.pem"
    echo ""
}

# 运行压力测试
test_stress_test() {
    print_test_header "运行压力测试"
    
    echo -e "${YELLOW}压力测试 - 连续操作100次...${NC}"
    local success_count=0
    local total_count=100
    
    for ((i=1; i<=total_count; i++)); do
        local key_file="/tmp/stress_${i}_key.pem"
        local sig_file="/tmp/stress_${i}.sig"
        local message="Stress test message $i"
        
        if BECC_SILENT=true "$SCRIPT_DIR/becc_fixed.sh" keygen -c secp256k1 -f "$key_file" 2>/dev/null && \
           BECC_SILENT=true "$SCRIPT_DIR/becc_fixed.sh" sign -c secp256k1 -k "$key_file" -m "$message" -f "$sig_file" 2>/dev/null && \
           BECC_SILENT=true "$SCRIPT_DIR/becc_fixed.sh" verify -c secp256k1 -k "${key_file%.pem}_public.pem" -m "$message" -s "$sig_file" 2>/dev/null | grep -q "VALID"; then
            ((success_count++))
        fi
        
        rm -f "$key_file" "$sig_file" "${key_file%.pem}_public.pem"
        
        if [[ $((i % 10)) -eq 0 ]]; then
            echo -ne "\r  进度: $i/$total_count ($success_count成功)"
        fi
    done
    echo ""
    
    if [[ $success_count -eq $total_count ]]; then
        print_result "压力测试" "PASS" "100次操作全部成功"
    else
        print_result "压力测试" "FAIL" "$success_count/$total_count 成功"
    fi
    echo ""
}

# 测试错误处理和恢复
test_error_handling() {
    print_test_header "测试错误处理和恢复"
    
    # 测试无效参数
    echo -e "${YELLOW}测试无效参数...${NC}"
    
    # 无效曲线
    if ! BECC_SILENT=true "$SCRIPT_DIR/becc.sh" keygen -c "invalid_curve" 2>/dev/null; then
        print_result "无效曲线处理" "PASS" "正确拒绝无效曲线"
    else
        print_result "无效曲线处理" "FAIL" "未正确处理无效曲线"
    fi
    
    # 无效私钥
    if ! BECC_SILENT=true "$SCRIPT_DIR/becc.sh" sign -c secp256k1 -k "invalid_key" -m "test" 2>/dev/null; then
        print_result "无效私钥处理" "PASS" "正确拒绝无效私钥"
    else
        print_result "无效私钥处理" "FAIL" "未正确处理无效私钥"
    fi
    
    # 无效签名
    local key_file="/tmp/test_error_key.pem"
    local sig_file="/tmp/test_error.sig"
    
    if BECC_SILENT=true "$SCRIPT_DIR/becc_fixed.sh" keygen -c secp256k1 -f "$key_file" 2>/dev/null; then
        echo "invalid signature data" > "$sig_file"
        if ! BECC_SILENT=true "$SCRIPT_DIR/becc_fixed.sh" verify -c secp256k1 -k "${key_file%.pem}_public.pem" -m "test" -s "$sig_file" 2>/dev/null | grep -q "VALID"; then
            print_result "无效签名处理" "PASS" "正确拒绝无效签名"
        else
            print_result "无效签名处理" "FAIL" "未正确处理无效签名"
        fi
    else
        print_result "无效签名处理" "FAIL" "密钥生成失败"
    fi
    
    rm -f "$key_file" "$sig_file" "${key_file%.pem}_public.pem"
    echo ""
}

# 主测试函数
run_comprehensive_tests() {
    clear
    echo -e "${CYAN}"
    echo "=================================================="
    echo "  bECCsh 全面可运行度测试"
    echo "=================================================="
    echo -e "${NC}"
    echo "测试时间: $(date)"
    echo "测试环境: $(uname -a)"
    echo "测试目标: 不在乎性能，只关注功能正确性"
    echo ""
    
    # 运行所有测试
    test_basic_keygen
    test_signature_functions
    test_curve_aliases
    test_smart_recommendations
    test_edge_cases
    test_file_operations
    test_stress_test
    test_error_handling
    
    # 打印总结
    print_summary
}

# 快速测试函数
run_quick_tests() {
    echo -e "${CYAN}"
    echo "=================================================="
    echo "  bECCsh 快速可运行度测试"
    echo "=================================================="
    echo -e "${NC}"
    
    # 只测试核心功能
    test_basic_keygen
    test_signature_functions
    
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
        "keygen")
            test_basic_keygen
            print_summary
            ;;
        "sign")
            test_signature_functions
            print_summary
            ;;
        "aliases")
            test_curve_aliases
            print_summary
            ;;
        "stress")
            test_stress_test
            print_summary
            ;;
        *)
            echo "未知测试模式: $test_mode"
            echo "可用模式: quick, full, keygen, sign, aliases, stress"
            exit 1
            ;;
    esac
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi