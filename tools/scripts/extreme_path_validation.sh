#!/bin/bash
# 极端严格的路径完整性检查脚本
# 确保所有程序都能正确找到依赖文件

set -euo pipefail

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# 计数器
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# 检查函数
check_file_exists() {
    local file="$1"
    local context="$2"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓${NC} $context: $file 存在"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $context: $file 不存在"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_directory_exists() {
    local dir="$1"
    local context="$2"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [[ -d "$dir" ]]; then
        echo -e "${GREEN}✓${NC} $context: $dir 目录存在"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $context: $dir 目录不存在"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_source_path() {
    local script="$1"
    local source_line="$2"
    local context="$3"
    
    # 提取source路径
    local source_path=$(echo "$source_line" | sed -n 's/.*source[[:space:]]*["'\'']\?\([^"'\'']*\)["'\'']\?.*/\1/p')
    
    if [[ -z "$source_path" ]]; then
        return 0
    fi
    
    # 处理变量替换
    local resolved_path="$source_path"
    if [[ "$resolved_path" == *"${LIB_DIR}"* ]]; then
        resolved_path="${resolved_path//\${LIB_DIR}/\/home\/donz\/bECCsh\/lib}"
    elif [[ "$resolved_path" == *"${SCRIPT_DIR}"* ]]; then
        resolved_path="${resolved_path//\${SCRIPT_DIR}/\/home\/donz\/bECCsh}"
    elif [[ "$resolved_path" == *"${CORE_DIR}"* ]]; then
        resolved_path="${resolved_path//\${CORE_DIR}/\/home\/donz\/bECCsh\/core}"
    elif [[ "$resolved_path" == *".."* ]]; then
        # 处理相对路径
        local script_dir=$(dirname "$script")
        local full_path="$script_dir/$resolved_path"
        # 规范化路径
        resolved_path=$(cd "$script_dir" && cd "$(dirname "$resolved_path")" 2>/dev/null && pwd)/$(basename "$resolved_path") 2>/dev/null || echo "$full_path"
    else
        # 相对路径
        local script_dir=$(dirname "$script")
        resolved_path="$script_dir/$resolved_path"
    fi
    
    check_file_exists "$resolved_path" "$context"
}

# 主检查程序
echo "========================================="
echo "极端严格的路径完整性检查"
echo "========================================="
echo

# 1. 检查主程序文件
echo "1. 检查主程序文件..."
check_file_exists "/home/donz/bECCsh/becc.sh" "主程序"
check_file_exists "/home/donz/bECCsh/becc_multi_curve.sh" "多曲线版本"
check_file_exists "/home/donz/bECCsh/becc_fixed.sh" "修复版本"
echo

# 2. 检查关键目录
echo "2. 检查关键目录..."
check_directory_exists "/home/donz/bECCsh/lib" "库目录"
check_directory_exists "/home/donz/bECCsh/core" "核心目录"
check_directory_exists "/home/donz/bECCsh/core/crypto" "加密目录"
check_directory_exists "/home/donz/bECCsh/tools" "工具目录"
echo

# 3. 检查主程序的导入路径
echo "3. 检查主程序的导入路径..."
for script in "becc.sh" "becc_multi_curve.sh" "becc_fixed.sh"; do
    echo "检查 $script 的导入:"
    grep -n "^source" "/home/donz/bECCsh/$script" | while IFS= read -r line; do
        check_source_path "/home/donz/bECCsh/$script" "$line" "$script"
    done
    echo
done

# 4. 检查库文件之间的相互引用
echo "4. 检查库文件相互引用..."
for lib_file in /home/donz/bECCsh/lib/*.sh; do
    if [[ -f "$lib_file" ]]; then
        echo "检查 $(basename "$lib_file"):"
        grep -n "source.*\.\." "$lib_file" 2>/dev/null | while IFS= read -r line; do
            echo -e "${YELLOW}⚠${NC} 发现相对路径引用: $line"
            WARNINGS=$((WARNINGS + 1))
        done
        
        # 检查source语句
        grep -n "^source" "$lib_file" 2>/dev/null | while IFS= read -r line; do
            check_source_path "$lib_file" "$line" "$(basename "$lib_file")"
        done
        echo
    fi
done

# 5. 检查核心加密文件
echo "5. 检查核心加密文件引用..."
for crypto_file in /home/donz/bECCsh/core/crypto/*.sh; do
    if [[ -f "$crypto_file" ]]; then
        echo "检查 $(basename "$crypto_file"):"
        grep -n "source.*\.\." "$crypto_file" 2>/dev/null | while IFS= read -r line; do
            echo -e "${YELLOW}⚠${NC} 发现相对路径引用: $line"
            WARNINGS=$((WARNINGS + 1))
        done
        echo
    fi
done

# 6. 检查测试脚本
echo "6. 检查测试脚本路径..."
find /home/donz/bECCsh -name "test_*.sh" -type f | head -20 | while read -r test_file; do
    echo "检查 $(basename "$test_file"):"
    grep -n "source" "$test_file" 2>/dev/null | grep -v "^#" | while IFS= read -r line; do
        if [[ "$line" =~ \.\. ]]; then
            echo -e "${YELLOW}⚠${NC} 发现相对路径引用: $line"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
    echo
done

# 7. 运行功能测试
echo "7. 运行基础功能测试..."
echo "测试 becc.sh --help:"
if /home/donz/bECCsh/becc.sh --help >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} becc.sh --help 成功"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗${NC} becc.sh --help 失败"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

echo "测试 becc_multi_curve.sh --help:"
if /home/donz/bECCsh/becc_multi_curve.sh --help >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} becc_multi_curve.sh --help 成功"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗${NC} becc_multi_curve.sh --help 失败"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

echo "测试 becc_fixed.sh --help:"
if /home/donz/bECCsh/becc_fixed.sh --help >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} becc_fixed.sh --help 成功"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗${NC} becc_fixed.sh --help 失败"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

# 8. 检查特定的source语句模式
echo "8. 检查危险的source模式..."
echo "检查硬编码路径..."
grep -r "source.*/home/" /home/donz/bECCsh --include="*.sh" 2>/dev/null | while IFS= read -r line; do
    echo -e "${YELLOW}⚠${NC} 发现硬编码路径: $line"
    WARNINGS=$((WARNINGS + 1))
done

echo "检查BASH_SOURCE用法..."
if grep -r "BASH_SOURCE" /home/donz/bECCsh/becc.sh /home/donz/bECCsh/becc_multi_curve.sh /home/donz/bECCsh/becc_fixed.sh >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} 主程序正确使用BASH_SOURCE"
else
    echo -e "${RED}✗${NC} 主程序未使用BASH_SOURCE"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# 总结报告
echo
echo "========================================="
echo "检查完成 - 总结报告"
echo "========================================="
echo -e "总检查项: $TOTAL_CHECKS"
echo -e "通过: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "失败: ${RED}$FAILED_CHECKS${NC}"
echo -e "警告: ${YELLOW}$WARNINGS${NC}"
echo

if [[ $FAILED_CHECKS -eq 0 ]]; then
    echo -e "${GREEN}✓ 路径完整性检查通过！${NC}"
    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}⚠ 存在 $WARNINGS 个警告，建议处理${NC}"
    fi
    exit 0
else
    echo -e "${RED}✗ 路径完整性检查失败！${NC}"
    echo -e "${RED}发现 $FAILED_CHECKS 个严重问题需要修复${NC}"
    exit 1
fi