#!/bin/bash

# 修复版纯Bash模块加载器
# 确保所有模块正确加载

# 获取当前脚本目录
LOADER_DIR="${BASH_SOURCE%/*}"

# 确保LOADER_DIR不为空
if [[ -z "$LOADER_DIR" ]]; then
    LOADER_DIR="$(dirname "$0")"
fi

echo "🔄 加载纯Bash模块..." >&2
echo "📁 模块目录: $LOADER_DIR" >&2

# 基础模块
echo "  📦 加载基础模块..." >&2
source "$LOADER_DIR/pure_bash_encoding_final.sh" || {
    echo "❌ 无法加载编码模块" >&2
    return 1
}

echo "  📦 加载随机数模块..." >&2
source "$LOADER_DIR/pure_bash_random.sh" || {
    echo "❌ 无法加载随机数模块" >&2
    return 1
}

echo "  📦 加载哈希模块..." >&2
source "$LOADER_DIR/pure_bash_hash.sh" || {
    echo "❌ 无法加载哈希模块" >&2
    return 1
}

# 扩展模块（可选）
echo "  📦 加载扩展大数模块..." >&2
if source "$LOADER_DIR/pure_bash_bigint_extended.sh" 2>/dev/null; then
    echo "  ✅ 扩展大数模块加载成功" >&2
    
    echo "  📦 加载扩展密码学模块..." >&2
    if source "$LOADER_DIR/pure_bash_extended_crypto.sh" 2>/dev/null; then
        echo "  ✅ 扩展密码学模块加载成功" >&2
        
        echo "  📦 加载完整实现模块..." >&2
        if source "$LOADER_DIR/pure_bash_complete.sh" 2>/dev/null; then
            echo "  ✅ 完整实现模块加载成功" >&2
            export PUREBASH_EXTENDED_AVAILABLE=true
        else
            echo "  ℹ️  完整实现模块不可用" >&2
            export PUREBASH_EXTENDED_AVAILABLE=false
        fi
    else
        echo "  ℹ️  扩展密码学模块不可用" >&2
        export PUREBASH_EXTENDED_AVAILABLE=false
    fi
else
    echo "  ℹ️  扩展大数模块不可用" >&2
    export PUREBASH_EXTENDED_AVAILABLE=false
fi

echo "✅ 纯Bash模块加载完成" >&2

# 提供兼容性函数
if [[ "${PUREBASH_EXTENDED_AVAILABLE:-false}" == "true" ]]; then
    echo "  🚀 扩展功能可用" >&2
else
    echo "  🎯 使用基础功能" >&2
fi