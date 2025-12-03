#!/bin/bash

# 纯Bash功能综合测试
echo "🎯 纯Bash功能综合测试"
echo "====================="

# 获取脚本目录
SCRIPT_DIR="${BASH_SOURCE%/*}"

# 加载纯Bash模块
source "$SCRIPT_DIR/pure_bash_loader.sh"

echo "1. 随机数生成测试:"
for i in {1..5}; do
    echo "  随机数 $i: $(purebash_random_simple 1000)"
done

echo
echo "2. 哈希函数测试:"
for text in "hello" "world" "purebash" "2024"; do
    hash=$(purebash_sha256_simple "$text")
    echo "  '$text' -> $hash"
done

echo
echo "3. Base64编码测试:"
for text in "test" "bash" "crypto" "pure"; do
    encoded=$(purebash_base64_encode "$text")
    decoded=$(purebash_base64_decode "$encoded")
    echo "  '$text' -> '$encoded' -> '$decoded'"
    if [[ "$text" == "$decoded" ]]; then
        echo "    ✅ 编解码正确"
    else
        echo "    ❌ 编解码错误"
    fi
    echo
done

echo
echo "4. ECDSA测试:"
echo "  生成密钥对..."
key_data=$(purebash_ecdsa_keygen_simple "secp256r1")
echo "  $key_data"

echo
echo "  签名测试..."
message="test message"
sign_data=$(purebash_ecdsa_sign_simple "12345" "$message")
echo "  $sign_data"

echo
echo "✅ 纯Bash功能测试完成！"
