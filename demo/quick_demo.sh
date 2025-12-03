#!/bin/bash

# 快速演示纯Bash功能
echo "🚀 bECCsh 纯Bash快速演示"
echo "========================"

# 运行核心演示
echo "运行核心纯Bash演示..."
cd core
./becc_pure.sh | head -20

echo
echo "运行独立功能演示..."
cd lib/pure_bash
bash pure_bash_random.sh | head -5

echo
echo "✅ 快速演示完成！"
echo "📚 更多测试请查看 demo/ 目录"
