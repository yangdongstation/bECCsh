#!/bin/bash
# demo.sh - 演示bECCsh的基本用法

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🎭 bECCsh 演示脚本"
echo "=================="
echo ""
echo "这个演示将展示："
echo "1. 生成密钥对（约120秒）"
echo "2. 创建测试文件"
echo "3. 签名文件（约380秒）"
echo "4. 尝试验证（会失败，因为我们还没实现）"
echo ""
echo "总耗时：约8分钟的生命"
echo ""
echo "按回车开始演示，或按Ctrl+C退出..."
read

# 检查主程序是否存在
if [ ! -f "${PROJECT_ROOT}/becc.sh" ]; then
    echo "错误：无法找到bECCsh主程序: ${PROJECT_ROOT}/becc.sh"
    exit 1
fi

echo "1. 生成密钥对..."
"${PROJECT_ROOT}/becc.sh" genkey

echo ""
echo "2. 创建测试文件..."
echo "这是bECCsh的测试文件，用于演示ECC签名过程。" > test_message.txt
echo "此文件包含一些示例文本，将被签名。" >> test_message.txt
echo "生成的签名将证明：" >> test_message.txt
echo "1. bECCsh确实能工作（某种程度上）" >> test_message.txt
echo "2. 签名过程确实很慢（确实如此）" >> test_message.txt
echo "3. 安全性确实堪忧（绝对如此）" >> test_message.txt
echo "✓ 测试文件已创建"

echo ""
echo "3. 签名文件..."
"${PROJECT_ROOT}/becc.sh" sign test_message.txt

echo ""
echo "4. 尝试验证签名..."
echo "注意：验证功能尚未实现，所以会显示失败消息"
"${PROJECT_ROOT}/becc.sh" verify test_message.txt test_message.txt.sig || true

echo ""
echo "演示完成！"
echo "="
echo "生成的文件："
echo "- ecc.key.priv: 私钥文件（请妥善保管，虽然不安全）"
echo "- ecc.key.pub: 公钥文件"
echo "- test_message.txt: 测试文件"
echo "- test_message.txt.sig: 签名文件"
echo ""
echo "您现在可以尝试："
echo "1. ./becc.sh benchmark    # 性能对比测试"
echo "2. ./becc.sh heat         # CPU加热模式"
echo ""
echo "警告：请勿在生产环境中使用此软件！"