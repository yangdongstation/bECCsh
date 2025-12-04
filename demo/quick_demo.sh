#!/bin/bash

# 快速演示纯Bash功能
echo "🚀 bECCsh 纯Bash快速演示"
echo "========================"

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 运行核心演示
echo "运行核心纯Bash演示..."
if [[ -f "$PROJECT_ROOT/core/becc_pure.sh" ]]; then
    cd "$PROJECT_ROOT/core"
    ./becc_pure.sh | head -20
else
    echo "❌ 无法找到核心纯Bash程序: $PROJECT_ROOT/core/becc_pure.sh"
fi

echo
echo "运行独立功能演示..."
if [[ -f "$PROJECT_ROOT/core/lib/pure_bash/pure_bash_random.sh" ]]; then
    cd "$PROJECT_ROOT/core/lib/pure_bash"
    bash pure_bash_random.sh | head -5
else
    echo "❌ 无法找到纯Bash随机数模块"
fi

echo
echo "✅ 快速演示完成！"
echo "📚 更多测试请查看 demo/ 目录"
