#!/bin/bash

# 修正的路径验证测试

echo "🔧 修正的路径验证测试"
echo "======================"
echo

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED++))
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED++))
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# 真正检查硬编码相对路径（没有使用SCRIPT_DIR或dirname的）
print_info "=== 真正的硬编码相对路径检查 ==="

# 查找真正的问题：直接以source开头，包含../的
real_problems=$(grep -r "^\s*source.*\.\.\/.*\.sh" demo/ core/ --include="*.sh" | grep -v "SCRIPT_DIR" | grep -v 'dirname.*BASH_SOURCE' | wc -l)

if [[ $real_problems -eq 0 ]]; then
    print_success "未发现真正的硬编码相对路径导入"
else
    print_error "发现$real_problems个真正的硬编码相对路径导入"
    echo "问题文件:"
    grep -r "^\s*source.*\.\.\/.*\.sh" demo/ core/ --include="*.sh" | grep -v "SCRIPT_DIR" | grep -v 'dirname.*BASH_SOURCE'
fi

echo
print_info "=== SCRIPT_DIR使用统计 ==="
script_dir_usage=$(grep -r "SCRIPT_DIR" demo/ core/ --include="*.sh" | wc -l)
print_info "SCRIPT_DIR使用次数: $script_dir_usage"

echo
print_info "=== dirname BASH_SOURCE使用统计 ==="
dirname_usage=$(grep -r 'dirname.*BASH_SOURCE' demo/ core/ --include="*.sh" | wc -l)
print_info "dirname BASH_SOURCE使用次数: $dirname_usage"

echo
print_info "=== 路径处理质量评估 ==="
total_scripts=$(find demo/ core/ -name "*.sh" | wc -l)
good_scripts=$(grep -rl "SCRIPT_DIR\|dirname.*BASH_SOURCE" demo/ core/ --include="*.sh" | wc -l)

print_info "总脚本数量: $total_scripts"
print_info "使用正确路径处理的脚本: $good_scripts"

if [[ $good_scripts -eq $total_scripts ]]; then
    print_success "所有脚本都使用了正确的路径处理方式！"
else
    print_info "路径处理覆盖率: $(( good_scripts * 100 / total_scripts ))%"
fi

echo
print_info "=== 功能性验证 ==="

# 测试几个关键脚本的实际功能
cd /home/donz/bECCsh

print_info "测试demo/pure_bash_demo.sh功能..."
if bash demo/pure_bash_demo.sh | grep -q "纯Bash密码学演示完成"; then
    print_success "demo/pure_bash_demo.sh功能正常"
else
    print_error "demo/pure_bash_demo.sh功能异常"
fi

print_info "测试demo/examples/pure_bash_demo.sh功能..."
cd demo/examples
if bash pure_bash_demo.sh | grep -q "纯Bash密码学演示完成"; then
    print_success "demo/examples/pure_bash_demo.sh功能正常"
else
    print_error "demo/examples/pure_bash_demo.sh功能异常"
fi

cd /home/donz/bECCsh
print_info "测试core/operations/ecc_arithmetic.sh导入..."
if bash -c 'source core/operations/ecc_arithmetic.sh && echo "导入成功"' 2>/dev/null; then
    print_success "core/operations/ecc_arithmetic.sh导入正常"
else
    print_error "core/operations/ecc_arithmetic.sh导入失败"
fi

echo
echo "📊 最终统计:"
echo "============="
echo -e "通过测试: ${GREEN}$PASSED${NC}"
echo -e "失败测试: ${RED}$FAILED${NC}"

if [[ $FAILED -eq 0 ]]; then
    echo
    print_success "🎉 所有路径修复验证通过！"
    print_success "✨ 项目中的相对路径导入问题已完全解决！"
    exit 0
else
    echo
    print_error "❌ 部分测试失败，需要进一步检查"
    exit 1
fi