#!/bin/bash
# 极端严格的路径完整性检查脚本 - 修复版
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

extract_source_path() {
    local line="$1"
    # 更robust的source路径提取
    if [[ "$line" =~ source[[:space:]]+\"([^\"]+)\" ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$line" =~ source[[:space:]]+\'([^\']+)\' ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$line" =~ source[[:space:]]+([^[:space:];]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo ""
    fi
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
    script_path="/home/donz/bECCsh/$script"
    script_dir=$(dirname "$script_path")
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^source ]]; then
            source_path=$(extract_source_path "$line")
            if [[ -n "$source_path" ]]; then
                # 解析变量引用
                source_path=$(echo "$source_path" | sed "s|\${SCRIPT_DIR}|$script_dir|g" | sed "s|\${LIB_DIR}|$script_dir/lib|g" | sed "s|\${CORE_DIR}|$script_dir/core|g")
                
                if [[ "$source_path" == /* ]]; then
                    check_file_exists "$source_path" "$script"
                else
                    full_path="$script_dir/$source_path"
                    check_file_exists "$full_path" "$script"
                fi
            fi
        fi
    done < "$script_path"
    echo
done

# 4. 检查库文件之间的相互引用
echo "4. 检查库文件相互引用..."
for lib_file in /home/donz/bECCsh/lib/*.sh; do
    if [[ -f "$lib_file" ]]; then
        echo "检查 $(basename "$lib_file"):"
        lib_dir=$(dirname "$lib_file")
        
        # 检查相对路径引用
        if grep -n "\.\." "$lib_file" >/dev/null 2>&1; then
            echo -e "${YELLOW}⚠${NC} 发现相对路径引用:"
            grep -n "\.\." "$lib_file" | head -5
            WARNINGS=$((WARNINGS + 1))
        fi
        
        # 检查source语句
        while IFS= read -r line; do
            if [[ "$line" =~ ^source ]]; then
                source_path=$(extract_source_path "$line")
                if [[ -n "$source_path" ]]; then
                    # 解析相对路径
                    if [[ "$source_path" == \$\(dirname* ]]; then
                        # 动态路径，跳过检查
                        continue
                    elif [[ "$source_path" != /* ]]; then
                        full_path="$lib_dir/$source_path"
                        if [[ ! -f "$full_path" ]]; then
                            echo -e "${RED}✗${NC} 找不到引用的文件: $source_path"
                            FAILED_CHECKS=$((FAILED_CHECKS + 1))
                        fi
                    fi
                fi
            fi
        done < "$lib_file"
        echo
    fi
done

# 5. 检查核心加密文件
echo "5. 检查核心加密文件引用..."
for crypto_file in /home/donz/bECCsh/core/crypto/*.sh; do
    if [[ -f "$crypto_file" ]]; then
        echo "检查 $(basename "$crypto_file"):"
        crypto_dir=$(dirname "$crypto_file")
        
        # 检查相对路径引用
        if grep -n "\.\." "$crypto_file" >/dev/null 2>&1; then
            echo -e "${YELLOW}⚠${NC} 发现相对路径引用:"
            grep -n "\.\." "$crypto_file" | head -3
            WARNINGS=$((WARNINGS + 1))
        fi
        echo
    fi
done

# 6. 运行功能测试
echo "6. 运行基础功能测试..."
echo "测试 becc.sh --help:"
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if /home/donz/bECCsh/becc.sh --help >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} becc.sh --help 成功"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗${NC} becc.sh --help 失败"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

echo "测试 becc_multi_curve.sh --help:"
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if /home/donz/bECCsh/becc_multi_curve.sh --help >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} becc_multi_curve.sh --help 成功"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗${NC} becc_multi_curve.sh --help 失败"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

echo "测试 becc_fixed.sh --help:"
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if /home/donz/bECCsh/becc_fixed.sh --help >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} becc_fixed.sh --help 成功"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗${NC} becc_fixed.sh --help 失败"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# 7. 检查特定的source语句模式
echo "7. 检查危险的source模式..."
echo "检查硬编码路径..."
if grep -r "source.*/home/" /home/donz/bECCsh --include="*.sh" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠${NC} 发现硬编码路径:"
    grep -r "source.*/home/" /home/donz/bECCsh --include="*.sh" | head -3
    WARNINGS=$((WARNINGS + 1))
fi

echo "检查BASH_SOURCE用法..."
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if grep -q "BASH_SOURCE" /home/donz/bECCsh/becc.sh /home/donz/bECCsh/becc_multi_curve.sh /home/donz/bECCsh/becc_fixed.sh >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} 主程序正确使用BASH_SOURCE"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗${NC} 主程序未使用BASH_SOURCE"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# 8. 检查关键库文件是否存在
echo "8. 检查关键库文件..."
check_file_exists "/home/donz/bECCsh/lib/bash_math.sh" "基础数学库"
check_file_exists "/home/donz/bECCsh/lib/bigint.sh" "大数运算库"
check_file_exists "/home/donz/bECCsh/lib/ec_curve.sh" "椭圆曲线库"
check_file_exists "/home/donz/bECCsh/lib/ec_point.sh" "椭圆点库"
check_file_exists "/home/donz/bECCsh/lib/ecdsa.sh" "ECDSA库"
check_file_exists "/home/donz/bECCsh/lib/security.sh" "安全库"
check_file_exists "/home/donz/bECCsh/lib/asn1.sh" "ASN.1库"
check_file_exists "/home/donz/bECCsh/lib/entropy.sh" "熵库"
check_file_exists "/home/donz/bECCsh/core/crypto/curve_selector.sh" "曲线选择器"
check_file_exists "/home/donz/bECCsh/core/crypto/ecdsa_fixed.sh" "修复的ECDSA"
check_file_exists "/home/donz/bECCsh/core/crypto/curve_selector_simple.sh" "简化曲线选择器"

# 9. 运行简单的功能测试
echo "9. 运行简单功能测试..."
echo "测试数学函数加载:"
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if bash -c 'source /home/donz/bECCsh/lib/bash_math.sh && bashmath_add 2 3' >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} 数学函数加载成功"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗${NC} 数学函数加载失败"
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