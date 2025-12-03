#!/bin/bash

# 纯Bash性能测试
echo "⚡ 纯Bash性能测试"
echo "================"

SCRIPT_DIR="${BASH_SOURCE%/*}"
source "$SCRIPT_DIR/../pure_bash_tests/pure_bash_loader.sh"

echo "1. 随机数生成性能:"
start_time=$(date +%s%N)
for i in {1..100}; do
    purebash_random_simple 1000000 >/dev/null
done
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))
echo "  生成100个随机数耗时: ${duration}ms"

echo
echo "2. 哈希函数性能:"
start_time=$(date +%s%N)
for i in {1..50}; do
    purebash_sha256_simple "performance test $i" >/dev/null
done
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))
echo "  生成50个哈希耗时: ${duration}ms"

echo
echo "3. Base64编码性能:"
start_time=$(date +%s%N)
for i in {1..200}; do
    purebash_base64_encode "This is a test string for performance measurement" >/dev/null
done
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))
echo "  编码200个字符串耗时: ${duration}ms"

echo
echo "⚡ 性能测试完成！"
