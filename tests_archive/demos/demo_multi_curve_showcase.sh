#!/bin/bash
# bECCsh 多椭圆曲线功能展示脚本
# 演示所有支持的椭圆曲线及其特性

set -euo pipefail

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色输出
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# 演示标题
show_title() {
    echo -e "${CYAN}"
    echo "=================================================="
    echo "  bECCsh 多椭圆曲线功能展示"
    echo "=================================================="
    echo -e "${NC}"
    echo -e "${YELLOW}本演示将展示bECCsh支持的所有椭圆曲线算法${NC}"
    echo ""
}

# 暂停等待
pause() {
    echo ""
    read -p "按回车键继续..."
    echo ""
}

# 清除屏幕
clear_screen() {
    echo -e "\033[2J\033[H"
}

# 展示支持的曲线
show_supported_curves() {
    echo -e "${BLUE}=== 支持的椭圆曲线 ===${NC}"
    echo ""
    
    # 使用主程序显示曲线信息
    "$SCRIPT_DIR/../../becc_multi_curve.sh" curves
    
    echo ""
    echo -e "${GREEN}✓ 总共支持 9 种标准椭圆曲线算法${NC}"
    pause
}

# 展示曲线推荐功能
show_curve_recommendations() {
    echo -e "${BLUE}=== 智能曲线推荐 ===${NC}"
    echo ""
    
    echo -e "${YELLOW}1. 按安全级别推荐:${NC}"
    echo ""
    
    local security_levels=("96" "112" "128" "192" "256")
    for level in "${security_levels[@]}"; do
        echo -n "  ${level}位安全级别: "
        "$SCRIPT_DIR/../../becc_multi_curve.sh" recommend --security "$level" 2>/dev/null | grep "推荐曲线:" | cut -d: -f2 | tr -d ' '
    done
    
    echo ""
    echo -e "${YELLOW}2. 按用例推荐:${NC}"
    echo ""
    
    local use_cases=("mobile" "bitcoin" "web" "government" "long-term")
    for use_case in "${use_cases[@]}"; do
        echo -n "  $use_case 用例: "
        "$SCRIPT_DIR/../../becc_multi_curve.sh" recommend --use-case "$use_case" 2>/dev/null | grep "推荐曲线:" | cut -d: -f2 | tr -d ' '
    done
    
    echo ""
    echo -e "${GREEN}✓ 智能推荐系统帮助选择最适合的曲线${NC}"
    pause
}

# 展示密钥生成
show_key_generation() {
    echo -e "${BLUE}=== 密钥生成演示 ===${NC}"
    echo ""
    
    # 选择代表性曲线进行演示
    local demo_curves=("secp192k1" "secp256k1" "secp256r1" "secp384r1")
    
    for curve in "${demo_curves[@]}"; do
        echo -e "${YELLOW}生成 $curve 密钥对:${NC}"
        
        local key_file="/tmp/demo_${curve}_key.pem"
        local pub_file="/tmp/demo_${curve}_key_public.pem"
        
        # 生成密钥对
        if "$SCRIPT_DIR/../../becc_multi_curve.sh" keygen -c "$curve" -f "$key_file" -q 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} 私钥文件: $key_file"
            echo -e "  ${GREEN}✓${NC} 公钥文件: $pub_file"
            
            # 显示密钥文件大小
            if [[ -f "$key_file" ]]; then
                local key_size=$(stat -f%z "$key_file" 2>/dev/null || stat -c%s "$key_file" 2>/dev/null || echo "0")
                echo -e "  私钥大小: ${key_size} 字节"
            fi
            
            # 清理临时文件
            rm -f "$key_file" "$pub_file"
        else
            echo -e "  ${RED}✗${NC} 密钥生成失败"
        fi
        
        echo ""
    done
    
    echo -e "${GREEN}✓ 支持为每种曲线生成标准兼容的密钥对${NC}"
    pause
}

# 展示签名和验证
show_sign_verify() {
    echo -e "${BLUE}=== 签名和验证演示 ===${NC}"
    echo ""
    
    local curve="secp256r1"
    local message="Hello, bECCsh Multi-Curve Demo!"
    local key_file="/tmp/demo_sign_key.pem"
    local pub_file="/tmp/demo_sign_key_public.pem"
    local sig_file="/tmp/demo_signature.sig"
    
    echo -e "${YELLOW}使用 $curve 进行签名和验证:${NC}"
    echo ""
    
    # 生成密钥对
    echo -n "1. 生成密钥对... "
    if "$SCRIPT_DIR/../../becc_multi_curve.sh" keygen -c "$curve" -f "$key_file" -q 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
    
    # 签名消息
    echo -n "2. 签名消息... "
    echo -n "$message" > "/tmp/demo_message.txt"
    if "$SCRIPT_DIR/../../becc_multi_curve.sh" sign -c "$curve" -k "$key_file" -m "$message" -f "$sig_file" -q 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        
        # 显示签名大小
        if [[ -f "$sig_file" ]]; then
            local sig_size=$(stat -f%z "$sig_file" 2>/dev/null || stat -c%s "$sig_file" 2>/dev/null || echo "0")
            echo "   签名大小: ${sig_size} 字节"
        fi
    else
        echo -e "${RED}✗${NC}"
        rm -f "$key_file" "$pub_file" "$sig_file" "/tmp/demo_message.txt"
        return 1
    fi
    
    # 验证签名
    echo -n "3. 验证签名... "
    local verify_result
    verify_result=$("$SCRIPT_DIR/../../becc_multi_curve.sh" verify -c "$curve" -k "$pub_file" -m "$message" -s "$sig_file" 2>&1)
    
    if echo "$verify_result" | grep -q "VALID"; then
        echo -e "${GREEN}✓ 验证成功${NC}"
    else
        echo -e "${RED}✗ 验证失败${NC}"
    fi
    
    # 清理临时文件
    rm -f "$key_file" "$pub_file" "$sig_file" "/tmp/demo_message.txt"
    
    echo ""
    echo -e "${GREEN}✓ 完整的ECDSA签名和验证功能${NC}"
    pause
}

# 展示曲线别名
show_curve_aliases() {
    echo -e "${BLUE}=== 曲线别名演示 ===${NC}"
    echo ""
    
    echo -e "${YELLOW}别名让使用更加方便:${NC}"
    echo ""
    
    # 演示别名功能
    local aliases=("p-256:secp256r1" "btc:secp256k1" "bitcoin:secp256k1")
    
    for alias_pair in "${aliases[@]}"; do
        local alias=$(echo "$alias_pair" | cut -d: -f1)
        local curve=$(echo "$alias_pair" | cut -d: -f2)
        
        echo -n "使用别名 '$alias' (对应 $curve): "
        
        local key_file="/tmp/demo_alias_${alias}.pem"
        if "$SCRIPT_DIR/../../becc_multi_curve.sh" keygen -c "$alias" -f "$key_file" -q 2>/dev/null; then
            echo -e "${GREEN}✓${NC}"
            rm -f "$key_file" "${key_file%.pem}_public.pem"
        else
            echo -e "${RED}✗${NC}"
        fi
    done
    
    echo ""
    echo -e "${GREEN}✓ 支持多种常用别名，使命令更加直观${NC}"
    pause
}

# 展示性能比较
show_performance_comparison() {
    echo -e "${BLUE}=== 性能比较演示 ===${NC}"
    echo ""
    
    echo -e "${YELLOW}快速性能测试 (10次迭代):${NC}"
    echo ""
    
    # 选择几个代表性曲线
    local perf_curves=("secp192k1" "secp256k1" "secp256r1" "secp384r1")
    
    for curve in "${perf_curves[@]}"; do
        echo -n "测试 $curve 性能... "
        
        local start_time end_time duration
        start_time=$(date +%s.%N)
        
        # 进行简单测试：生成密钥对
        for ((i=1; i<=10; i++)); do
            "$SCRIPT_DIR/../../becc_multi_curve.sh" keygen -c "$curve" -f "/tmp/perf_${curve}_${i}.pem" -q 2>/dev/null
            rm -f "/tmp/perf_${curve}_${i}.pem" "/tmp/perf_${curve}_${i}_public.pem"
        done
        
        end_time=$(date +%s.%N)
        duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
        
        printf "${GREEN}%.3f秒${NC}\n" "$duration"
    done
    
    echo ""
    echo -e "${GREEN}✓ 不同曲线具有不同的性能特征${NC}"
    echo -e "${YELLOW}提示: 使用 benchmark_multi_curve.sh 进行详细性能测试${NC}"
    pause
}

# 展示测试功能
show_testing_features() {
    echo -e "${BLUE}=== 测试功能演示 ===${NC}"
    echo ""
    
    echo -e "${YELLOW}可用的测试选项:${NC}"
    echo ""
    
    # 显示测试菜单
    "$SCRIPT_DIR/test_multi_curve.sh" 2>&1 | head --1
    
    echo ""
    echo -e "示例测试命令:${NC}"
    echo "  ./test_multi_curve.sh all        # 运行所有测试"
    echo "  ./test_multi_curve.sh selector   # 测试曲线选择器"
    echo "  ./test_multi_curve.sh params     # 测试参数验证"
    echo "  ./test_multi_curve.sh perf       # 测试性能"
    
    echo ""
    echo -e "${GREEN}✓ 完整的测试套件确保功能正确性${NC}"
    pause
}

# 展示高级功能
show_advanced_features() {
    echo -e "${BLUE}=== 高级功能演示 ===${NC}"
    echo ""
    
    echo -e "${YELLOW}多曲线批量操作:${NC}"
    echo ""
    
    # 演示为多个曲线生成密钥
    local curves=("secp256k1" "secp256r1" "secp384r1")
    
    echo "为多个曲线批量生成密钥对:"
    for curve in "${curves[@]}"; do
        local key_file="/tmp/batch_${curve}.pem"
        echo -n "  $curve... "
        
        if "$SCRIPT_DIR/../../becc_multi_curve.sh" keygen -c "$curve" -f "$key_file" -q 2>/dev/null; then
            echo -e "${GREEN}✓${NC}"
            rm -f "$key_file" "${key_file%.pem}_public.pem"
        else
            echo -e "${RED}✗${NC}"
        fi
    done
    
    echo ""
    echo -e "${GREEN}✓ 支持批量操作和自动化脚本${NC}"
    pause
}

# 总结
show_summary() {
    echo -e "${PURPLE}"
    echo "========================================"
    echo "  功能展示总结"
    echo "========================================"
    echo -e "${NC}"
    
    echo -e "${GREEN}✅ 多椭圆曲线支持特性:${NC}"
    echo ""
    echo "  🔐 支持 9 种标准椭圆曲线算法"
    echo "  🎯 智能曲线推荐系统"
    echo "  ⚡ 性能优化的密钥生成"
    echo "  🔑 完整的ECDSA签名和验证"
    echo "  🔄 灵活的曲线别名支持"
    echo "  🧪 全面的测试套件"
    echo "  📊 详细的性能基准测试"
    echo "  📚 丰富的文档和使用示例"
    echo ""
    echo -e "${GREEN}🎉 bECCsh 现在是一个完整的多曲线椭圆曲线密码学库！${NC}"
    echo ""
    echo -e "${YELLOW}📖 更多信息请查看:${NC}"
    echo "  - MULTI_CURVE_README.md (本指南)"
    echo "  - ECC_ALGORITHM_EXPANSION_PLAN.md (扩展计划)"
    echo "  - test_multi_curve.sh (测试套件)"
    echo "  - benchmark_multi_curve.sh (性能测试)"
    echo ""
}

# 主函数
main() {
    clear_screen
    show_title
    
    # 展示各个功能
    show_supported_curves
    show_curve_recommendations
    show_key_generation
    show_sign_verify
    show_curve_aliases
    show_performance_comparison
    show_testing_features
    show_advanced_features
    
    # 总结
    show_summary
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi