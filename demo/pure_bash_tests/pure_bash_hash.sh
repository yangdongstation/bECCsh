#!/bin/bash

# 纯Bash哈希函数实现
# 完全摆脱外部依赖，仅使用Bash内置功能

# SHA-256常量定义
readonly SHA256_K=(
    0x428a2f98 0x71374491 0xb5c0fbcf 0xe9b5dba5 0x3956c25b 0x59f111f1 0x923f82a4 0xab1c5ed5
    0xd807aa98 0x12835b01 0x243185be 0x550c7dc3 0x72be5d74 0x80deb1fe 0x9bdc06a7 0xc19bf174
    0xe49b69c1 0xefbe4786 0x0fc19dc6 0x240ca1cc 0x2de92c6f 0x4a7484aa 0x5cb0a9dc 0x76f988da
    0x983e5152 0xa831c66d 0xb00327c8 0xbf597fc7 0xc6e00bf3 0xd5a79147 0x06ca6351 0x14292967
    0x27b70a85 0x2e1b2138 0x4d2c6dfc 0x53380d13 0x650a7354 0x766a0abb 0x81c2c92e 0x92722c85
    0xa2bfe8a1 0xa81a664b 0xc24b8b70 0xc76c51a3 0xd192e819 0xd6990624 0xf40e3585 0x106aa070
    0x19a4c116 0x1e376c08 0x2748774c 0x34b0bcb5 0x391c0cb3 0x4ed8aa4a 0x5b9cca4f 0x682e6ff3
    0x748f82ee 0x78a5636f 0x84c87814 0x8cc70208 0x90befffa 0xa4506ceb 0xbef9a3f7 0xc67178f2
)

# 右移函数（逻辑右移）
purebash_rshift() {
    local num=$1
    local shift=$2
    echo $((num >> shift))
}

# 无符号右移函数
purebash_urshift() {
    local num=$1
    local shift=$2
    local mask=0xFFFFFFFF
    local result=$(((num & mask) >> shift))
    echo $result
}

# 循环右移函数
purebash_rotr() {
    local num=$1
    local shift=$2
    local bits=${3:-32}
    local mask=$(( (1 << bits) - 1 ))
    
    local shifted=$(( (num >> shift) & mask ))
    local rotated=$(( (num << (bits - shift)) & mask ))
    
    echo $(( shifted | rotated ))
}

# SHA-256的Σ0函数
purebash_sigma0() {
    local x=$1
    local rotr2=$(purebash_rotr $x 2)
    local rotr13=$(purebash_rotr $x 13)
    local rotr22=$(purebash_rotr $x 22)
    echo $(( rotr2 ^ rotr13 ^ rotr22 ))
}

# SHA-256的Σ1函数
purebash_sigma1() {
    local x=$1
    local rotr6=$(purebash_rotr $x 6)
    local rotr11=$(purebash_rotr $x 11)
    local rotr25=$(purebash_rotr $x 25)
    echo $(( rotr6 ^ rotr11 ^ rotr25 ))
}

# SHA-256的σ0函数
purebash_sigma_small0() {
    local x=$1
    local rotr7=$(purebash_rotr $x 7)
    local rotr18=$(purebash_rotr $x 18)
    local shr3=$(purebash_rshift $x 3)
    echo $(( rotr7 ^ rotr18 ^ shr3 ))
}

# SHA-256的σ1函数
purebash_sigma_small1() {
    local x=$1
    local rotr17=$(purebash_rotr $x 17)
    local rotr19=$(purebash_rotr $x 19)
    local shr10=$(purebash_rshift $x 10)
    echo $(( rotr17 ^ rotr19 ^ shr10 ))
}

# 选择函数Ch(x,y,z) = (x AND y) XOR (NOT x AND z)
purebash_ch() {
    local x=$1 y=$2 z=$3
    echo $(( (x & y) ^ (~x & z) ))
}

# 主函数Maj(x,y,z) = (x AND y) XOR (x AND z) XOR (y AND z)
purebash_maj() {
    local x=$1 y=$2 z=$3
    echo $(( (x & y) ^ (x & z) ^ (y & z) ))
}

# 32位加法（处理溢出）
purebash_add32() {
    local sum=$1
    shift
    for num in "$@"; do
        sum=$((sum + num))
    done
    echo $((sum & 0xFFFFFFFF))
}

# 字符串转换为32位字数组
purebash_str_to_words() {
    local input="$1"
    local len=${#input}
    local words=()
    
    # 填充和长度处理
    local padded_len=$(((len + 9 + 63) / 64 * 64))
    local bit_len=$((len * 8))
    
    # 转换为十六进制并填充
    local hex_str=""
    for ((i=0; i<len; i++)); do
        local char="${input:$i:1}"
        local ord=$(printf "%d" "'$char")
        hex_str+=$(printf "%02x" $ord)
    done
    
    # 添加填充位
    hex_str+="80"
    
    # 填充零到合适长度
    while ((${#hex_str} < $((padded_len * 2 - 8)))); do
        hex_str+="00"
    done
    
    # 添加原始长度（64位大端）
    for ((i=56; i>=0; i-=8)); do
        hex_str+=$(printf "%02x" $((bit_len >> i)))
    done
    
    # 转换为32位字
    for ((i=0; i<${#hex_str}; i+=8)); do
        local word_hex="${hex_str:$i:8}"
        local word_dec=0
        for ((j=0; j<8; j+=2)); do
            local byte_hex="${word_hex:$j:2}"
            local byte_dec=$((16#$byte_hex))
            word_dec=$((word_dec | (byte_dec << (24 - j * 4))))
        done
        words+=($word_dec)
    done
    
    echo "${words[@]}"
}

# 纯Bash SHA-256实现
purebash_sha256() {
    local input="$1"
    
    # 初始哈希值
    local h0=0x6a09e667 h1=0xbb67ae85 h2=0x3c6ef372 h3=0xa54ff53a
    local h4=0x510e527f h5=0x9b05688c h6=0x1f83d9ab h7=0x5be0cd19
    
    # 转换为字数组
    local words=($(purebash_str_to_words "$input"))
    
    # 处理每个消息块
    local w=()
    for ((block=0; block<${#words[@]}/16; block++)); do
        # 初始化消息调度数组
        for ((i=0; i<16; i++)); do
            w[i]=${words[$((block * 16 + i))]}
        done
        
        # 扩展消息调度数组
        for ((i=16; i<64; i++)); do
            local s0=$(purebash_sigma_small0 ${w[$((i-15))]})
            local s1=$(purebash_sigma_small1 ${w[$((i-2))]})
            w[i]=$(purebash_add32 ${w[$((i-16))]} $s0 ${w[$((i-7))]} $s1)
        done
        
        # 初始化工作变量
        local a=$h0 b=$h1 c=$h2 d=$h3 e=$h4 f=$h5 g=$h6 h=$h7
        
        # 主循环
        for ((i=0; i<64; i++)); do
            local s1=$(purebash_sigma1 $e)
            local ch=$(purebash_ch $e $f $g)
            local temp1=$(purebash_add32 $h $s1 $ch ${SHA256_K[i]} ${w[i]})
            local s0=$(purebash_sigma0 $a)
            local maj=$(purebash_maj $a $b $c)
            local temp2=$(purebash_add32 $s0 $maj)
            
            h=$g
            g=$f
            f=$e
            e=$(purebash_add32 $d $temp1)
            d=$c
            c=$b
            b=$a
            a=$(purebash_add32 $temp1 $temp2)
        done
        
        # 计算中间哈希值
        h0=$(purebash_add32 $h0 $a)
        h1=$(purebash_add32 $h1 $b)
        h2=$(purebash_add32 $h2 $c)
        h3=$(purebash_add32 $h3 $d)
        h4=$(purebash_add32 $h4 $e)
        h5=$(purebash_add32 $h5 $f)
        h6=$(purebash_add32 $h6 $g)
        h7=$(purebash_add32 $h7 $h)
    done
    
    # 输出最终哈希值
    printf "%08x%08x%08x%08x%08x%08x%08x%08x" $h0 $h1 $h2 $h3 $h4 $h5 $h6 $h7
}

# 测试函数
purebash_test_hash() {
    echo "=== 纯Bash哈希函数测试 ==="
    
    local test_vectors=(
        ""
        "abc"
        "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
    )
    
    for input in "${test_vectors[@]}"; do
        echo "输入: '$input'"
        local hash=$(purebash_sha256 "$input")
        echo "SHA-256: $hash"
        echo
    done
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    purebash_test_hash
fi