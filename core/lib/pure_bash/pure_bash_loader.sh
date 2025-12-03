#!/bin/bash

# 纯Bash模块加载器
# 统一加载所有纯Bash密码学模块

# 获取当前脚本目录
PURE_BASH_DIR="${BASH_SOURCE%/*}"

# 加载纯Bash模块
echo "🔄 加载纯Bash模块..." >&2

# 基础编码模块
source "$PURE_BASH_DIR/pure_bash_encoding_final.sh"

# 随机数生成模块  
source "$PURE_BASH_DIR/pure_bash_random.sh"

# 哈希函数模块
source "$PURE_BASH_DIR/pure_bash_hash.sh"

# 综合密码学模块
source "$PURE_BASH_DIR/pure_bash_crypto.sh"

echo "✅ 纯Bash模块加载完成" >&2