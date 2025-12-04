#!/bin/bash

# bECCsh HTML文件中的.md链接最终验证脚本
# 验证所有.md链接修复结果

echo "🔍 bECCsh HTML文件中的.md链接最终验证报告"
echo "=============================================="
echo

# 要验证的HTML文件列表
html_files=(
    "index.html"
    "index_cryptographic.html" 
    "index_mathematical.html"
    "html/archive/index_professional.html"
)

# 统计变量
total_links=0
valid_links=0
invalid_links=0
broken_paths=()

echo "📋 验证HTML文件中的.md链接:"
echo

for html_file in "${html_files[@]}"; do
    if [[ -f "$html_file" ]]; then
        echo "📄 检查文件: $html_file"
        
        # 提取所有.md链接
        md_links=$(grep -oE 'href="[^"]*\.md"' "$html_file" 2>/dev/null | sed 's/href="\([^"]*\)"/\1/' | sort -u)
        
        if [[ -n "$md_links" ]]; then
            file_links=$(echo "$md_links" | wc -l)
            total_links=$((total_links + file_links))
            
            echo "   发现 $file_links 个.md链接:"
            
            while IFS= read -r link; do
                if [[ -n "$link" ]]; then
                    # 移除开头的./如果存在
                    clean_link=${link#./}
                    
                    echo -n "   🔗 $clean_link - "
                    
                    if [[ -f "$clean_link" ]]; then
                        echo "✅ 存在"
                        valid_links=$((valid_links + 1))
                    else
                        echo "❌ 不存在"
                        invalid_links=$((invalid_links + 1))
                        broken_paths+=("$html_file -> $clean_link")
                    fi
                fi
            done <<< "$md_links"
        else
            echo "   ℹ️  无.md链接"
        fi
        echo
    else
        echo "⚠️  文件不存在: $html_file"
        echo
    fi
done

echo "=============================================="
echo "📊 最终验证统计:"
echo "   总链接数: $total_links"
echo "   有效链接: $valid_links"
echo "   无效链接: $invalid_links"
echo

if [[ $invalid_links -eq 0 ]]; then
    echo "🎉 恭喜！所有.md链接都已修复并可访问！"
    echo "   修复完成度: 100%"
    exit_code=0
else
    echo "❌ 发现 $invalid_links 个无效链接:"
    for broken in "${broken_paths[@]}"; do
        echo "   - $broken"
    done
    echo
    echo "🔗 修复完成度: $(( (valid_links * 100) / total_links ))%"
    exit_code=1
fi

echo
echo "🔍 特别验证我们修复的关键链接:"
echo "=============================================="

key_links=(
    "docs/technical/CRYPTOGRAPHIC_TECHNICAL_DOCUMENTATION.md"
    "docs/reports/COMPREHENSIVE_ELLIPTIC_CURVE_TEST_ANALYSIS_REPORT.md"
    "docs/project/PURE_BASH_MANIFESTO.md"
    "docs/reports/COMPREHENSIVE_OPENSSL_COMPARISON_REPORT.md"
    "archive/historical_completion_docs/technical_docs/MATH_REPLACEMENT.md"
)

all_key_valid=true
for link in "${key_links[@]}"; do
    echo -n "🔑 $link - "
    if [[ -f "$link" ]]; then
        echo "✅ 存在 ($(wc -c < "$link" | awk '{print $1}') 字节)"
    else
        echo "❌ 不存在"
        all_key_valid=false
    fi
done

echo
if $all_key_valid; then
    echo "✅ 所有关键修复链接都已验证通过！"
else
    echo "❌ 部分关键链接仍有问题！"
    exit_code=1
fi

echo
echo "🎯 最终状态总结:"
echo "=============================================="
if [[ $exit_code -eq 0 ]]; then
    echo "🎊 完美！所有HTML文件中的.md链接修复完成！"
    echo "📈 修复完成度: 100%"
    echo "✨ 所有目标文件都存在且可访问"
else
    echo "⚠️  仍有部分链接需要修复"
    echo "📈 当前修复完成度: $(( (valid_links * 100) / total_links ))%"
fi

exit $exit_code