#!/bin/bash
# 多椭圆曲线支持演示脚本
# 展示bECCsh的多曲线功能

set -euo pipefail

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
core_dir="$SCRIPT_DIR/core"

# 颜色输出
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# 打印标题
print_title() {
    local title="$1"
    echo -e "${CYAN}"
    echo "=================================================="
    echo "  $title"
    echo "=================================================="
    echo -e "${NC}"
}

# 打印小节标题
print_section() {
    local section="$1"
    echo -e "${BLUE}--- $section ---${NC}"
}

# 演示曲线选择功能
demo_curve_selection() {
    print_title "椭圆曲线选择演示"
    
    # 导入曲线选择器
    source "$core_dir/crypto/curve_selector.sh"
    
    echo -e "${GREEN}支持的椭圆曲线:${NC}"
    list_supported_curves
    echo ""
    
    # 演示不同曲线的选择
    local demo_curves=("secp256k1" "secp256r1" "p-256" "prime256v1")
    
    for curve in "${demo_curves[@]}"; do
        echo -e "${YELLOW}选择曲线: $curve${NC}"
        
        if select_curve "$curve"; then
            echo -e "${GREEN}✓ 成功选择曲线 $curve${NC}"
            echo "  曲线名称: $CURVE_NAME"
            echo "  安全级别: $(get_curve_security_level "$curve")"
            echo "  用途: $(get_curve_usage_description "$curve")"
            echo "  素数p: ${CURVE_P:0:30}..."
            echo "  基点Gx: ${CURVE_GX:0:30}..."
            echo "  基点Gy: ${CURVE_GY:0:30}..."
            echo "  阶n: ${CURVE_N:0:30}..."
        else
            echo -e "${RED}✗ 无法选择曲线 $curve${NC}"
        fi
        echo ""
    done
}

# 演示曲线参数验证
demo_curve_validation() {
    print_title "椭圆曲线参数验证演示"
    
    # 导入验证工具
    source "$core_dir/utils/curve_validator.sh"
    
    local demo_curves=("secp256k1" "secp256r1")
    
    for curve in "${demo_curves[@]}"; do
        echo -e "${YELLOW}验证曲线: $curve${NC}"
        
        if validate_standard_curve "$curve"; then
            echo -e "${GREEN}✓ $curve 参数验证通过${NC}"
        else
            echo -e "${RED}✗ $curve 参数验证失败${NC}"
        fi
        echo ""
    done
}

# 演示模运算功能
demo_modular_arithmetic() {
    print_title "模运算功能演示"
    
    # 导入模运算库
    source "$core_dir/operations/ecc_arithmetic.sh"
    
    print_section "基本模运算演示"
    
    # 使用小素数进行演示
    local demo_p="97"
    echo "使用素数 p = $demo_p"
    echo ""
    
    # 模加法演示
    local a="42"
    local b="35"
    local result=$(mod_add "$a" "$b" "$demo_p")
    echo "($a + $b) mod $demo_p = $result"
    
    # 模乘法演示
    result=$(mod_mul "$a" "$b" "$demo_p")
    echo "($a × $b) mod $demo_p = $result"
    
    # 模平方演示
    result=$(mod_square "$a" "$demo_p")
    echo "($a²) mod $demo_p = $result"
    
    # 模幂运算演示
    local exp="5"
    result=$(mod_pow "$a" "$exp" "$demo_p")
    echo "($a^$exp) mod $demo_p = $result"
    
    # 模逆元演示
    local inv_a=$(mod_inverse "$a" "$demo_p")
    echo "$a 的模逆元 mod $demo_p = $inv_a"
    echo "验证: ($a × $inv_a) mod $demo_p = $(mod_mul "$a" "$inv_a" "$demo_p")"
    
    echo ""
    print_section "大数模运算演示"
    
    # 导入曲线选择器获取大素数
    source "$core_dir/crypto/curve_selector.sh"
    select_curve "secp256k1"
    
    echo "使用SECP256K1素数进行大数运算:"
    echo "p = ${CURVE_P:0:30}..."
    
    local big_a="115792089237316195423570985008687907852837564279074904382605163141518161494336"
    local big_b="115792089237316195423570985008687907852837564279074904382605163141518161494337"
    
    result=$(mod_add "$big_a" "$big_b" "$CURVE_P")
    echo "大数模加法完成: ${result:0:30}..."
    
    result=$(mod_mul "$big_a" "2" "$CURVE_P")
    echo "大数模乘法完成: ${result:0:30}..."
}

# 演示椭圆曲线点运算
demo_point_operations() {
    print_title "椭圆曲线点运算演示"
    
    # 导入必要的库
    source "$core_dir/crypto/curve_selector.sh"
    source "$core_dir/operations/point_operations.sh"
    
    print_section "简单曲线点运算演示"
    
    # 使用小素数曲线进行演示
    local demo_p="23"
    local demo_a="1"
    local demo_b="1"
    
    echo "使用演示曲线: y² = x³ + ${demo_a}x + ${demo_b} (mod $demo_p)"
    echo ""
    
    # 选择一个在曲线上的点
    local x="3"
    local y="10"
    
    echo "测试点 P = ($x, $y)"
    if point_on_curve "$x" "$y" "$demo_a" "$demo_b" "$demo_p"; then
        echo -e "${GREEN}✓ 点P在曲线上${NC}"
        
        # 点加倍
        local doubled=$(ec_point_double "$x" "$y" "$demo_a" "$demo_p")
        local dx=$(echo "$doubled" | cut -d' ' -f1)
        local dy=$(echo "$doubled" | cut -d' ' -f2)
        echo "2P = ($dx, $dy)"
        
        # 验证结果
        if point_on_curve "$dx" "$dy" "$demo_a" "$demo_b" "$demo_p"; then
            echo -e "${GREEN}✓ 2P在曲线上${NC}"
        else
            echo -e "${RED}✗ 2P不在曲线上${NC}"
        fi
        
        # 点乘法
        local multiplied=$(ec_point_multiply "3" "$x" "$y" "$demo_a" "$demo_p")
        local mx=$(echo "$multiplied" | cut -d' ' -f1)
        local my=$(echo "$multiplied" | cut -d' ' -f2)
        echo "3P = ($mx, $my)"
        
        # 验证结果
        if point_on_curve "$mx" "$my" "$demo_a" "$demo_b" "$demo_p"; then
            echo -e "${GREEN}✓ 3P在曲线上${NC}"
        else
            echo -e "${RED}✗ 3P不在曲线上${NC}"
        fi
    else
        echo -e "${RED}✗ 点P不在曲线上${NC}"
    fi
    
    echo ""
    print_section "标准曲线点运算演示"
    
    # 使用标准曲线
    select_curve "secp256k1"
    
    echo "使用SECP256K1标准曲线:"
    echo "基点 G = (${CURVE_GX:0:20}..., ${CURVE_GY:0:20}...)"
    
    # 基点倍乘
    local result=$(ec_point_multiply "2" "$CURVE_GX" "$CURVE_GY" "$CURVE_A" "$CURVE_P")
    local rx=$(echo "$result" | cut -d' ' -f1)
    local ry=$(echo "$result" | cut -d' ' -f2)
    echo "2G = (${rx:0:20}..., ${ry:0:20}...)"
    
    # 验证结果
    if point_on_curve "$rx" "$ry" "$CURVE_A" "$CURVE_B" "$CURVE_P"; then
        echo -e "${GREEN}✓ 2G在曲线上${NC}"
    else
        echo -e "${RED}✗ 2G不在曲线上${NC}"
    fi
}

# 演示多曲线对比
demo_multi_curve_comparison() {
    print_title "多曲线对比演示"
    
    # 导入必要的库
    source "$core_dir/crypto/curve_selector.sh"
    source "$core_dir/operations/point_operations.sh"
    
    echo -e "${YELLOW}对比不同曲线的性能特征${NC}"
    echo ""
    
    local curves=("secp256k1" "secp256r1")
    
    for curve in "${curves[@]}"; do
        echo -e "${PURPLE}测试曲线: $curve${NC}"
        
        if select_curve "$curve"; then
            echo "安全级别: $(get_curve_security_level "$curve")"
            echo "用途: $(get_curve_usage_description "$curve")"
            echo "素数p长度: ${#CURVE_P} 位十进制数"
            echo "基点阶n长度: ${#CURVE_N} 位十进制数"
            
            # 测试基点倍乘性能
            echo "测试基点倍乘性能..."
            local start_time=$(date +%s.%N)
            
            local result=$(ec_point_multiply "5" "$CURVE_GX" "$CURVE_GY" "$CURVE_A" "$CURVE_P")
            
            local end_time=$(date +%s.%N)
            local duration=$(echo "$end_time - $start_time" | bc)
            
            local rx=$(echo "$result" | cut -d' ' -f1)
            local ry=$(echo "$result" | cut -d' ' -f2)
            
            echo "5G = (${rx:0:20}..., ${ry:0:20}...)"
            echo "计算耗时: ${duration}秒"
            echo ""
        else
            echo -e "${RED}✗ 无法选择曲线 $curve${NC}"
        fi
    done
}

# 演示安全特性
demo_security_features() {
    print_title "安全特性演示"
    
    # 导入必要的库
    source "$core_dir/crypto/curve_selector.sh"
    source "$core_dir/utils/curve_validator.sh"
    
    print_section "曲线参数安全验证"
    
    echo -e "${YELLOW}验证标准曲线的安全性${NC}"
    echo ""
    
    local curves=("secp256k1" "secp256r1")
    
    for curve in "${curves[@]}"; do
        echo "验证 $curve 的安全特性:"
        
        if validate_standard_curve "$curve"; then
            echo -e "${GREEN}✓ $curve 通过安全验证${NC}"
        else
            echo -e "${RED}✗ $curve 安全验证失败${NC}"
        fi
        echo ""
    done
    
    print_section "错误处理演示"
    
    echo -e "${YELLOW}测试系统对错误输入的处理${NC}"
    echo ""
    
    # 测试无效曲线
    echo "测试无效曲线名称: 'invalid_curve'"
    if ! select_curve "invalid_curve" 2>/dev/null; then
        echo -e "${GREEN}✓ 正确处理无效曲线名称${NC}"
    else
        echo -e "${RED}✗ 未正确处理无效曲线名称${NC}"
    fi
    
    # 测试模运算错误
    echo "测试模运算除零错误:"
    source "$core_dir/operations/ecc_arithmetic.sh"
    if ! mod_div "10" "0" "5" 2>/dev/null; then
        echo -e "${GREEN}✓ 正确处理除零错误${NC}"
    else
        echo -e "${RED}✗ 未正确处理除零错误${NC}"
    fi
}

# 主演示函数
main() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║     bECCsh 多椭圆曲线支持功能演示              ║"
    echo "║     (纯Bash椭圆曲线密码学库)                   ║"
    echo "╚════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    # 检查核心文件
    echo "检查核心文件..."
    local required_files=(
        "$core_dir/curves/secp256r1_params.sh"
        "$core_dir/curves/secp256k1_params.sh"
        "$core_dir/crypto/curve_selector.sh"
        "$core_dir/operations/ecc_arithmetic.sh"
        "$core_dir/operations/point_operations.sh"
        "$core_dir/utils/curve_validator.sh"
    )
    
    local all_files_exist=true
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "  ✓ $(basename "$file")"
        else
            echo "  ✗ $(basename "$file") - 缺失"
            all_files_exist=false
        fi
    done
    
    if ! $all_files_exist; then
        echo -e "${RED}错误: 缺少必要的核心文件${NC}"
        return 1
    fi
    
    echo ""
    
    # 运行所有演示
    demo_curve_selection
    echo ""
    
    demo_curve_validation
    echo ""
    
    demo_modular_arithmetic
    echo ""
    
    demo_point_operations
    echo ""
    
    demo_multi_curve_comparison
    echo ""
    
    demo_security_features
    
    # 总结
    echo ""
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║     演示完成！                                 ║"
    echo "║     bECCsh 多椭圆曲线支持功能已成功实现        ║"
    echo "╚════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${CYAN}已实现的功能:${NC}"
    echo "  ✓ SECP256R1 (P-256) 参数定义"
    echo "  ✓ SECP256K1 参数定义（兼容性）"
    echo "  ✓ 通用曲线选择器接口"
    echo "  ✓ 通用ECC运算核心框架"
    echo "  ✓ 模运算和点运算通用实现"
    echo "  ✓ 曲线参数验证工具"
    echo "  ✓ 多曲线测试验证"
    echo "  ✓ 完整的错误处理"
    echo ""
    echo -e "${CYAN}支持的曲线:${NC}"
    echo "  • secp256k1 (比特币标准)"
    echo "  • secp256r1 / p-256 / prime256v1 (NIST标准)"
    echo ""
    echo -e "${CYAN}下一步计划:${NC}"
    echo "  • 实现SECP384R1和SECP521R1支持"
    echo "  • 添加Brainpool曲线系列"
    echo "  • 优化性能算法"
    echo "  • 增加更多测试向量"
}

# 运行主函数
main "$@"