#!/bin/bash
# 路径完整性验证测试

echo "🔍 bECCsh 路径完整性验证测试"
echo "================================"
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"
CORE_DIR="${SCRIPT_DIR}/core"
TOOLS_DIR="${SCRIPT_DIR}/tools"

errors=0
warnings=0

check_file() {
    local file="$1"
    local description="$2"
    
    if [[ -f "$file" ]]; then
        echo "✅ $description: 存在"
        return 0
    else
        echo "❌ $description: 缺失 ($file)"
        ((errors++))
        return 1
    fi
}

check_dir() {
    local dir="$1"
    local description="$2"
    
    if [[ -d "$dir" ]]; then
        echo "✅ $description: 存在"
        return 0
    else
        echo "❌ $description: 缺失 ($dir)"
        ((errors++))
        return 1
    fi
}

check_source_path() {
    local file="$1"
    local line="$2"
    local source_path="$3"
    
    # 解析source路径
    if [[ "$source_path" =~ ^"\$\{[^}]+\}" ]]; then
        # 相对路径，需要解析
        local base_dir
        if [[ "$source_path" == *"SCRIPT_DIR"* ]]; then
            base_dir="$SCRIPT_DIR"
        elif [[ "$source_path" == *"LIB_DIR"* ]]; then
            base_dir="$LIB_DIR"
        elif [[ "$source_path" == *"CORE_DIR"* ]]; then
            base_dir="$CORE_DIR"
        else
            base_dir="$(dirname "$file")"
        fi
        
        # 提取路径部分
        local path_part=$(echo "$source_path" | sed 's/.*}"\([^"]*\)".*/\1/')
        local full_path="${base_dir}${path_part}"
        
        if [[ -f "$full_path" ]]; then
            echo "  ✅ $source_path -> $full_path"
        else
            echo "  ❌ $source_path -> $full_path (缺失)"
            ((errors++))
        fi
    elif [[ "$source_path" =~ ^"\$\(dirname.*\)" ]]; then
        # 使用dirname的相对路径
        local dir_path=$(dirname "$file")
        local path_part=$(echo "$source_path" | sed 's/.*}"\([^"]*\)".*/\1/')
        local full_path="${dir_path}${path_part}"
        
        if [[ -f "$full_path" ]]; then
            echo "  ✅ $source_path -> $full_path"
        else
            echo "  ❌ $source_path -> $full_path (缺失)"
            ((errors++))
        fi
    fi
}

echo "1. 检查主程序文件..."
check_file "$SCRIPT_DIR/becc.sh" "主程序 becc.sh"
check_file "$SCRIPT_DIR/becc_multi_curve.sh" "多曲线版本 becc_multi_curve.sh"
check_file "$SCRIPT_DIR/becc_fixed.sh" "修复版本 becc_fixed.sh"

echo
echo "2. 检查关键目录..."
check_dir "$LIB_DIR" "库目录 lib/"
check_dir "$CORE_DIR" "核心目录 core/"
check_dir "$TOOLS_DIR" "工具目录 tools/"

echo
echo "3. 检查核心库文件..."
check_file "$LIB_DIR/bash_math.sh" "Bash数学库"
check_file "$LIB_DIR/bigint.sh" "大数运算库"
check_file "$LIB_DIR/ec_curve.sh" "椭圆曲线库"
check_file "$LIB_DIR/ec_point.sh" "椭圆曲线点库"
check_file "$LIB_DIR/ecdsa.sh" "ECDSA库"
check_file "$LIB_DIR/security.sh" "安全库"
check_file "$LIB_DIR/asn1.sh" "ASN.1编码库"
check_file "$LIB_DIR/entropy.sh" "熵源库"

echo
echo "4. 检查核心模块..."
check_file "$CORE_DIR/crypto/curve_selector.sh" "曲线选择器"
check_file "$CORE_DIR/crypto/curve_selector_simple.sh" "简化曲线选择器"
check_file "$CORE_DIR/crypto/ecdsa_fixed.sh" "修复的ECDSA"

echo
echo "5. 检查曲线参数..."
check_file "$CORE_DIR/curves/secp256k1_params.sh" "SECP256K1参数"
check_file "$CORE_DIR/curves/secp256r1_params.sh" "SECP256R1参数"
check_file "$CORE_DIR/curves/secp384r1_params.sh" "SECP384R1参数"

echo
echo "6. 检查工具文件..."
check_file "$TOOLS_DIR/security_functions.sh" "安全功能模块"

echo
echo "7. 检查source路径..."
echo "   分析主程序的source语句:"
grep -n "source.*\.sh" "$SCRIPT_DIR/becc.sh" | while read -r line; do
    file=$(echo "$line" | cut -d: -f1)
    line_num=$(echo "$line" | cut -d: -f2)
    source_path=$(echo "$line" | cut -d: -f3- | sed 's/.*source //')
    echo "   第$line_num行: $source_path"
    check_source_path "$file" "$line_num" "$source_path"
done

echo
echo "8. 检查测试脚本路径..."
if [[ -f "$SCRIPT_DIR/test_becc_fixed.sh" ]]; then
    echo "✅ 测试脚本 test_becc_fixed.sh 存在"
else
    echo "❌ 测试脚本 test_becc_fixed.sh 缺失"
    ((errors++))
fi

echo
echo "9. 检查演示脚本..."
for demo in "$SCRIPT_DIR"/demo/*.sh; do
    if [[ -f "$demo" ]]; then
        demo_name=$(basename "$demo")
        if bash -n "$demo" 2>/dev/null; then
            echo "✅ 演示脚本 $demo_name: 语法正确"
        else
            echo "❌ 演示脚本 $demo_name: 语法错误"
            ((errors++))
        fi
    fi
done

echo
echo "10. 检查HTML文件..."
for html in "$SCRIPT_DIR"/*.html; do
    if [[ -f "$html" ]]; then
        html_name=$(basename "$html")
        echo "✅ HTML文件 $html_name: 存在"
    fi
done

echo
echo "================================"
echo "🏁 路径完整性验证完成"
echo "错误数量: $errors"
echo "警告数量: $warnings"

if [[ $errors -eq 0 ]]; then
    echo "🎉 所有路径检查通过！"
    exit 0
else
    echo "⚠️  发现 $errors 个路径问题，需要修复"
    exit 1
fi