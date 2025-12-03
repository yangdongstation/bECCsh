#!/bin/bash
# 纯Bash示例演示

source ../lib/pure_bash/pure_bash_crypto.sh

echo "🎯 纯Bash密码学演示"
echo "===================="

# 测试哈希
echo "1. 哈希测试:"
message="Hello, Pure Bash!"
hash=$(purebash_sha256_simple "$message")
echo "  消息: '$message'"
echo "  哈希: $hash"

# 测试随机数
echo
echo "2. 随机数测试:"
for i in {1..5}; do
    rand=$(purebash_random_simple 1000)
    echo "  随机数 $i: $rand"
done

# 测试编码
echo
echo "3. 编码测试:"
text="PureBash2024"
encoded=$(purebash_base64_encode "$text")
decoded=$(purebash_base64_decode "$encoded")
echo "  原文: '$text'"
echo "  Base64: '$encoded'"
echo "  解码: '$decoded'"

# 测试ECDSA
echo
echo "4. ECDSA测试:"
key_data=$(purebash_ecdsa_keygen_simple "secp256r1")
echo "  $key_data"

echo
echo "✅ 纯Bash密码学演示完成！"
