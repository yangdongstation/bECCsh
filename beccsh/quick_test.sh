#!/bin/bash
# quick_test.sh - 快速验证项目是否能"运行"

set -e

echo "🔥 bECCsh - 快速测试套件"

# 检查依赖
echo "1. 检查依赖..."
for cmd in sha256sum bc; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "✗ 缺少必需命令: $cmd"
        exit 1
    fi
done
echo "✓ 依赖检查通过"

# 检查文件结构
echo "2. 检查文件结构..."
required_files=(
    "lib/entropy.sh"
    "lib/big_math.sh"
    "lib/ec_curve.sh"
    "lib/ec_point.sh"
    "lib/ecdsa.sh"
)
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "✗ 缺少文件: $file"
        exit 1
    fi
done
echo "✓ 文件结构检查通过"

# 测试大数运算
echo "3. 测试大数运算..."
source lib/big_math.sh

# 简单测试
result=$(bn_mod_add "5" "3" "17")
if [ "$result" = "8" ]; then
    echo "✓ 模加法测试通过"
else
    echo "✗ 模加法失败: 5+3 mod 17 = $result (期望8)"
    exit 1
fi

inverse=$(bn_mod_inverse "3" "17")
if [ "$inverse" = "6" ]; then
    echo "✓ 模逆元测试通过 (3⁻¹ mod 17 = $inverse)"
else
    echo "✗ 模逆元失败: 3⁻¹ mod 17 = $inverse (期望6)"
    exit 1
fi
echo "✓ 基础密码学测试通过"

# 测试熵收集（快速模式）
echo "4. 测试熵收集（5秒）..."
source lib/entropy.sh
BECCSH_QUICK_ENTROPY=1  # 快速模式
if entropy=$(collect_entropy); then
    echo "✓ 熵收集成功（k值长度: ${#entropy}位十进制）"
else
    echo "✗ 熵收集失败"
    exit 1
fi

# 最终测试：生成密钥对（可选，很慢）
echo "5. 完整测试（很慢，跳过请按Ctrl+C）..."
cat <<EOF

这将运行完整流程：
- 生成密钥对（约120秒）
- 签名测试文件（约380秒）
- 总计：8分钟生命

是否继续？(y/N)
EOF
read -r -n 1 -t 10 response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "运行中..."
    ./becc.sh genkey
    echo "测试数据" > test.txt
    ./becc.sh sign test.txt
    echo "✓ 完整测试通过"
else
    echo "跳过完整测试"
fi

echo "🎉 所有测试通过！项目可以运行（但不保证安全）"
echo "接下来可以运行: ./becc.sh benchmark"