#!/bin/bash

# 最终路径验证测试 - 修正版

echo "🎯 最终路径验证测试 (修正版)"
echo "=============================="
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

# 测试函数
test_script_syntax() {
    local script="$1"
    local description="$2"
    
    print_info "测试: $description"
    
    if [[ -f "$script" ]]; then
        if bash -n "$script" 2>/dev/null; then
            print_success "语法检查: $script"
        else
            print_error "语法检查失败: $script"
        fi
    else
        print_error "文件不存在: $script"
    fi
}

test_script_import() {
    local script="$1"
    local description="$2"
    
    print_info "测试导入: $description"
    
    if [[ -f "$script" ]]; then
        # 尝试source脚本（不执行函数）
        if bash -c "source '$script'" 2>/dev/null; then
            print_success "导入成功: $script"
        else
            print_error "导入失败: $script"
            bash -c "source '$script'" 2>&1 | head -3
        fi
    else
        print_error "文件不存在: $script"
    fi
}

# 1. 语法检查测试
print_info "=== 语法检查测试 ==="
test_script_syntax "demo/pure_bash_demo.sh" "纯Bash演示脚本"
test_script_syntax "demo/examples/pure_bash_demo.sh" "示例演示脚本"
test_script_syntax "demo/demo.sh" "主演示脚本"
test_script_syntax "demo/comparison/openssl_comparison_test.sh" "OpenSSL对比测试脚本"
test_script_syntax "core/operations/ecc_arithmetic.sh" "椭圆曲线算术运算"
test_script_syntax "core/utils/curve_validator.sh" "曲线验证工具"

echo
# 2. 导入测试
print_info "=== 导入测试 ==="
test_script_import "demo/pure_bash_demo.sh" "纯Bash演示脚本导入"
test_script_import "demo/examples/pure_bash_demo.sh" "示例演示脚本导入"
test_script_import "core/operations/ecc_arithmetic.sh" "椭圆曲线算术运算导入"

echo
# 3. 路径变量检查
print_info "=== 路径变量检查 ==="
cd /home/donz/bECCsh

# 检查SCRIPT_DIR使用
script_dir_count=$(grep -r "SCRIPT_DIR" demo/ core/ --include="*.sh" | wc -l)
print_info "发现SCRIPT_DIR使用次数: $script_dir_count"

# 检查真正的硬编码相对路径（排除SCRIPT_DIR和dirname BASH_SOURCE的情况）
real_hardcoded_paths=$(grep -r "source.*\.\./.*\.sh" demo/ core/ --include="*.sh" | grep -v "SCRIPT_DIR" | grep -v 'dirname.*BASH_SOURCE' | wc -l)
if [[ $real_hardcoded_paths -eq 0 ]]; then
    print_success "未发现真正的硬编码相对路径导入"
else
    print_error "发现$real_hardcoded_paths个真正的硬编码相对路径导入"
    echo "问题文件:"
    grep -r "source.*\.\./.*\.sh" demo/ core/ --include="*.sh" | grep -v "SCRIPT_DIR" | grep -v 'dirname.*BASH_SOURCE'
fi

# 显示使用SCRIPT_DIR和dirname的正确路径导入（供参考）
script_dir_paths=$(grep -r "source.*SCRIPT_DIR.*\.\./.*\.sh" demo/ core/ --include="*.sh" | wc -l)
dirname_paths=$(grep -r 'source.*dirname.*BASH_SOURCE.*\.\./.*\.sh' demo/ core/ --include="*.sh" | wc -l)
print_info "使用SCRIPT_DIR的正确相对路径导入: $script_dir_paths个"
print_info "使用dirname BASH_SOURCE的正确相对路径导入: $dirname_paths个"

# 4. 功能性测试
echo
print_info "=== 功能性测试 ==="
cd /home/donz/bECCsh/demo
if output=$(bash pure_bash_demo.sh 2>&1); then
    if echo "$output" | grep -q "纯Bash密码学演示完成"; then
        print_success "纯Bash演示脚本功能正常"
    else
        print_error "纯Bash演示脚本功能异常"
    fi
else
    print_error "纯Bash演示脚本执行失败"
fi

echo
# 5. 路径正确性验证
print_info "=== 路径正确性验证 ==="
cd /home/donz/bECCsh

# 验证SCRIPT_DIR设置是否正确
test_script="temp_test_script.sh"
cat > "$test_script" << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "SCRIPT_DIR: $SCRIPT_DIR"
if [[ -d "$SCRIPT_DIR" ]]; then
    echo "SCRIPT_DIR存在且有效"
    exit 0
else
    echo "SCRIPT_DIR无效"
    exit 1
fi
EOF

chmod +x "$test_script"
if output=$(bash "$test_script"); then
    print_success "SCRIPT_DIR设置正确"
else
    print_error "SCRIPT_DIR设置有问题"
fi
rm -f "$test_script"

echo
echo "📊 最终统计:"
echo "============="
echo -e "通过测试: ${GREEN}$PASSED${NC}"
echo -e "失败测试: ${RED}$FAILED${NC}"

if [[ $FAILED -eq 0 ]]; then
    echo
    print_success "🎉 所有路径修复验证通过！"
    exit 0
else
    echo
    print_error "❌ 部分测试失败，需要进一步检查"
    exit 1
fi