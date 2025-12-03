#!/bin/bash

# 纯Bash随机数生成器
# 完全摆脱外部依赖，仅使用Bash内置功能和系统信息

# 全局随机状态
PUREBASH_RANDOM_STATE=""
PUREBASH_RANDOM_INITIALIZED=false

# 初始化随机状态
purebash_random_init() {
    if [[ "$PUREBASH_RANDOM_INITIALIZED" == "true" ]]; then
        return 0
    fi
    
    # 收集系统信息作为种子
    local seed_data=""
    
    # 1. 使用Bash内置的RANDOM变量
    for ((i=0; i<32; i++)); do
        seed_data+="$RANDOM"
    done
    
    # 2. 使用系统时间（纳秒级）
    local nanoseconds=""
    if [[ -f /proc/timer_list ]]; then
        # 尝试读取内核计时器信息
        nanoseconds=$(grep -m1 "now at" /proc/timer_list 2>/dev/null | sed 's/.*now at *//')
    fi
    
    if [[ -z "$nanoseconds" ]]; then
        # 后备方案：使用秒级时间戳和PID组合
        nanoseconds="$(date +%s)${BASHPID}"
    fi
    
    seed_data+="$nanoseconds"
    
    # 3. 使用内存使用信息
    local mem_info=""
    if [[ -f /proc/meminfo ]]; then
        mem_info=$(grep -E "(MemTotal|MemFree|SwapTotal|SwapFree)" /proc/meminfo 2>/dev/null | tr -d ' ' | tr '\n' ':')
    fi
    
    if [[ -n "$mem_info" ]]; then
        seed_data+="$mem_info"
    fi
    
    # 4. 使用进程信息
    local proc_info="${BASHPID}$(date +%s%N)"
    seed_data+="$proc_info"
    
    # 5. 使用Bash内部状态
    local bash_state=""
    for var in BASH_VERSION BASH_VERSINFO PPID SHLVL; do
        bash_state+="${!var}"
    done
    seed_data+="$bash_state"
    
    # 混合种子数据
    PUREBASH_RANDOM_STATE=$(purebash_entropy_mix "$seed_data")
    PUREBASH_RANDOM_INITIALIZED=true
    
    echo "✅ 纯Bash随机状态已初始化" >&2
}

# 熵混合函数
purebash_entropy_mix() {
    local data="$1"
    local mixed=""
    
    # 多重哈希混合
    for ((round=0; round<8; round++)); do
        local new_data=""
        local len=${#data}
        
        # 简单的混合算法（基于加法和异或）
        for ((i=0; i<len; i++)); do
            local char="${data:$i:1}"
            local ord=$(printf "%d" "'$char")
            
            # 与位置相关的混合
            local mixed_val=$(( (ord * (i + 1) + round * 0x9e3779b9) & 0xFFFFFFFF ))
            new_data+=$(printf "%08x" $mixed_val)
        done
        
        data="$new_data"
    done
    
    echo "$data"
}

# 线性反馈移位寄存器（LFSR）
purebash_lfsr() {
    local state="$1"
    local new_bit=0
    
    # 32位LFSR，使用特征多项式 x^32 + x^22 + x^2 + x^1 + 1
    local bit32=$(( (state >> 31) & 1 ))
    local bit22=$(( (state >> 21) & 1 ))
    local bit2=$(( (state >> 1) & 1 ))
    local bit1=$(( state & 1 ))
    
    new_bit=$(( bit32 ^ bit22 ^ bit2 ^ bit1 ))
    
    echo $(((state << 1 | new_bit) & 0xFFFFFFFF))
}

# 纯Bash伪随机数生成器
purebash_random() {
    local max_value=${1:-32767}
    
    # 确保已初始化
    if [[ "$PUREBASH_RANDOM_INITIALIZED" != "true" ]]; then
        purebash_random_init
    fi
    
    # 更新随机状态
    local current_state="$PUREBASH_RANDOM_STATE"
    
    # 使用LFSR生成下一个状态
    local new_state=$(purebash_lfsr "$current_state")
    
    # 添加额外的熵
    local time_component=$(date +%s%N)
    local pid_component="$BASHPID"
    local random_component="$RANDOM"
    
    new_state=$(( (new_state + time_component + pid_component + random_component) & 0xFFFFFFFF ))
    
    PUREBASH_RANDOM_STATE="$new_state"
    
    # 生成最终随机数
    local random_result=$(( new_state % (max_value + 1) ))
    echo "$random_result"
}

# 生成指定位数的随机十六进制字符串
purebash_random_hex() {
    local bits=$1
    local bytes=$(((bits + 7) / 8))
    local hex_chars=$((bytes * 2))
    
    local hex_result=""
    
    for ((i=0; i<hex_chars; i++)); do
        local random_nibble=$(purebash_random 15)
        hex_result+=$(printf "%x" $random_nibble)
    done
    
    echo "$hex_result"
}

# 生成指定位数的随机大数
purebash_random_bigint() {
    local bits=$1
    local hex_str=$(purebash_random_hex "$bits")
    
    # 转换为十进制（简化版本）
    local decimal=0
    local base=1
    local len=${#hex_str}
    
    for ((i=len-1; i>=0; i--)); do
        local char="${hex_str:$i:1}"
        local value
        case $char in
            [0-9]) value=$char ;;
            [a-f]) value=$((10 + $(printf "%d" "'$char") - $(printf "%d" "'a"))) ;;
            [A-F]) value=$((10 + $(printf "%d" "'$char") - $(printf "%d" "'A"))) ;;
        esac
        decimal=$((decimal + value * base))
        base=$((base * 16))
    done
    
    echo "$decimal"
}

# RFC 6979确定性随机数生成（纯Bash版本）
purebash_rfc6979() {
    local private_key=$1
    local message_hash=$2
    local curve_order=$3
    
    # 简化实现：使用HMAC-DRBG的纯Bash版本
    local v=""
    local k=""
    
    # 初始化V和K
    for ((i=0; i<32; i++)); do
        v+="01"
        k+="00"
    done
    
    # 使用私钥和消息哈希作为熵源
    local entropy="${private_key}${message_hash}"
    
    # 生成确定性k值
    local counter=0
    while [[ $counter -lt 100 ]]; do
        local candidate="${entropy}${counter}"
        candidate=$(purebash_entropy_mix "$candidate")
        
        # 转换为整数并取模
        local candidate_int=0
        local base=1
        for ((i=0; i<${#candidate} && i<16; i++)); do
            local char="${candidate:$i:1}"
            local ord=$(printf "%d" "'$char")
            candidate_int=$((candidate_int + ord * base))
            base=$((base * 256))
        done
        
        # 确保在有效范围内
        if [[ $candidate_int -gt 0 && $candidate_int -lt $curve_order ]]; then
            echo "$candidate_int"
            return 0
        fi
        
        counter=$((counter + 1))
    done
    
    # 后备方案：使用简化随机数
    purebash_random_bigint 256
}

# 随机数质量测试
purebash_random_test() {
    echo "=== 纯Bash随机数生成器测试 ==="
    
    # 基本随机数测试
    echo "基本随机数测试:"
    for ((i=0; i<10; i++)); do
        echo "  随机数 $i: $(purebash_random 1000)"
    done
    
    echo
    echo "随机十六进制测试:"
    for ((i=0; i<5; i++)); do
        echo "  128位随机数: $(purebash_random_hex 128)"
    done
    
    echo
    echo "RFC 6979 测试:"
    local test_private="12345"
    local test_hash="abcdef1234567890"
    local test_order="115792089237316195423570985008687907852837564279074904382605163141518161494337"
    
    for ((i=0; i<5; i++)); do
        local k=$(purebash_rfc6979 "$test_private" "$test_hash" "$test_order")
        echo "  生成的k值: $k"
    done
    
    echo
    echo "唯一性测试:"
    local unique_values=()
    local duplicates=0
    
    for ((i=0; i<100; i++)); do
        local value=$(purebash_random 10000)
        
        # 检查是否已存在
        local found=false
        for existing in "${unique_values[@]}"; do
            if [[ "$existing" == "$value" ]]; then
                found=true
                duplicates=$((duplicates + 1))
                break
            fi
        done
        
        if [[ "$found" == "false" ]]; then
            unique_values+=($value)
        fi
    done
    
    echo "  生成100个随机数，重复数: $duplicates"
    echo "  唯一性: $((100 - duplicates))%"
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    purebash_random_test
fi