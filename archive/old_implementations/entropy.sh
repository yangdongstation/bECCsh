#!/bin/bash
# entropy.sh - 专业级熵收集系统
# 实现了多层熵收集，确保密钥生成的随机性

# 全局变量，将被curves.sh设置
CURVE_N=""

# 高级熵收集函数 - 支持多种熵源
collect_entropy() {
    local pool="" layer=0
    local entropy_sources="${BECCSH_ENTROPY_SRC:-all}"
    
    echo "  使用熵源: $entropy_sources" >&2
    
    # 层1：键盘输入（如果可用）
    if [[ "$entropy_sources" == *"keyboard"* ]] || [[ "$entropy_sources" == "all" ]]; then
        ((layer++))
        echo "  [${layer}/8] 收集键盘熵（30秒）..." >&2
        local key_entropy=$(collect_keyboard_entropy)
        pool+="$key_entropy"
    fi
    
    # 层2：CPU时序抖动
    if [[ "$entropy_sources" == *"cpu"* ]] || [[ "$entropy_sources" == "all" ]]; then
        ((layer++))
        echo "  [${layer}/8] 收集CPU抖动熵..." >&2
        local cpu_entropy=$(collect_cpu_entropy)
        pool+="$cpu_entropy"
    fi
    
    # 层3：系统状态
    if [[ "$entropy_sources" == *"system"* ]] || [[ "$entropy_sources" == "all" ]]; then
        ((layer++))
        echo "  [${layer}/8] 收集系统熵..." >&2
        local system_entropy=$(collect_system_entropy)
        pool+="$system_entropy"
    fi
    
    # 层4：网络状态
    if [[ "$entropy_sources" == *"network"* ]] || [[ "$entropy_sources" == "all" ]]; then
        ((layer++))
        echo "  [${layer}/8] 收集网络熵..." >&2
        local network_entropy=$(collect_network_entropy)
        pool+="$network_entropy"
    fi
    
    # 层5：硬件信息
    if [[ "$entropy_sources" == *"hardware"* ]] || [[ "$entropy_sources" == "all" ]]; then
        ((layer++))
        echo "  [${layer}/8] 收集硬件熵..." >&2
        local hw_entropy=$(collect_hardware_entropy)
        pool+="$hw_entropy"
    fi
    
    # 层6：进程信息
    if [[ "$entropy_sources" == *"process"* ]] || [[ "$entropy_sources" == "all" ]]; then
        ((layer++))
        echo "  [${layer}/8] 收集进程熵..." >&2
        local proc_entropy=$(collect_process_entropy)
        pool+="$proc_entropy"
    fi
    
    # 层7：时间熵
    ((layer++))
    echo "  [${layer}/8] 收集时间熵..." >&2
    local time_entropy=$(collect_time_entropy)
    pool+="$time_entropy"
    
    # 层8：哈希链混合（增强版）
    ((layer++))
    echo "  [${layer}/8] 混合熵池（256次迭代）..." >&2
    local final="$pool"
    for i in {1..256}; do
        final="$(printf "%s%s%s%s" "$final" "$i" "$(date +%s%N)" "$RANDOM" | sha256sum | cut -d' ' -f1)"
        if [ $(( i % 32 )) -eq 0 ]; then
            printf "%d%% " $(( i * 100 / 256 )) >&2
        fi
    done
    echo >&2
    
    # 转换为数值并确保 k < CURVE_N
    local k_dec
    k_dec=$(printf "%d" "0x${final:0:64}")
    echo "$(( k_dec % CURVE_N ))"
}

# 收集键盘熵
collect_keyboard_entropy() {
    local key_input="" key_timestamps=""
    local start_time=$(date +%s%N)
    local char_count=0
    
    # 读取用户输入，带时序信息
    while [ $char_count -lt 50 ]; do
        read -rs -N 1 -t 0.1 char 2>/dev/null || true
        if [ -n "$char" ]; then
            key_input+="$char"
            key_timestamps+="$(date +%s%N) "
            printf "*" >&2
            ((char_count++))
        fi
        
        # 超时检查（30秒）
        if [ $(( $(date +%s%N) - start_time )) -gt 30000000000 ]; then
            break
        fi
    done
    echo >&2
    
    # 混合输入和时序信息
    printf "%s%s" "$key_input" "$key_timestamps" | sha256sum | cut -d' ' -f1
}

# 收集CPU时序熵
collect_cpu_entropy() {
    local jitter=""
    local iterations=200  # 增加迭代次数
    
    for i in $(seq 1 $iterations); do
        # 执行一些计算来增加CPU负载
        local dummy=$((i * i * i))
        jitter+="$(date +%s%N)"
        printf "." >&2
        
        # 每50次换行
        if [ $((i % 50)) -eq 0 ]; then
            echo >&2
        fi
    done
    echo >&2
    
    printf "%s" "$jitter" | sha256sum | cut -d' ' -f1
}

# 收集系统熵
collect_system_entropy() {
    local system_data=""
    
    # 系统内存信息
    if [ -f /proc/meminfo ]; then
        system_data+="$(cat /proc/meminfo)"
    fi
    
    # CPU统计信息
    if [ -f /proc/stat ]; then
        system_data+="$(cat /proc/stat)"
    fi
    
    # 负载平均值
    if [ -f /proc/loadavg ]; then
        system_data+="$(cat /proc/loadavg)"
    fi
    
    # 系统运行时间
    if [ -f /proc/uptime ]; then
        system_data+="$(cat /proc/uptime)"
    fi
    
    # 系统版本信息
    if [ -f /proc/version ]; then
        system_data+="$(cat /proc/version)"
    fi
    
    # 如果以上文件都不存在，使用vmstat
    if [ -z "$system_data" ] && command -v vmstat &>/dev/null; then
        system_data="$(vmstat 1 1)"
    fi
    
    printf "%s" "$system_data" | sha256sum | cut -d' ' -f1
}

# 收集网络熵
collect_network_entropy() {
    local network_data=""
    
    # 网络连接状态
    if command -v ss &>/dev/null; then
        network_data+="$(ss -tuln 2>/dev/null)"
    elif command -v netstat &>/dev/null; then
        network_data+="$(netstat -tuln 2>/dev/null)"
    fi
    
    # 网络接口统计
    if [ -f /proc/net/dev ]; then
        network_data+="$(cat /proc/net/dev)"
    fi
    
    # ARP缓存
    if [ -f /proc/net/arp ]; then
        network_data+="$(cat /proc/net/arp)"
    fi
    
    printf "%s" "$network_data" | sha256sum | cut -d' ' -f1
}

# 收集硬件熵
collect_hardware_entropy() {
    local hw_data=""
    
    # CPU信息
    if [ -f /proc/cpuinfo ]; then
        hw_data+="$(grep -E "(processor|model name|cpu MHz)" /proc/cpuinfo)"
    fi
    
    # 块设备信息
    if [ -f /proc/partitions ]; then
        hw_data+="$(cat /proc/partitions)"
    fi
    
    # 设备中断信息
    if [ -f /proc/interrupts ]; then
        hw_data+="$(cat /proc/interrupts)"
    fi
    
    # 设备IO端口
    if [ -f /proc/ioports ]; then
        hw_data+="$(cat /proc/ioports)"
    fi
    
    printf "%s" "$hw_data" | sha256sum | cut -d' ' -f1
}

# 收集进程熵
collect_process_entropy() {
    local proc_data=""
    
    # 进程树
    if command -v pstree &>/dev/null; then
        proc_data+="$(pstree -p $$)"
    fi
    
    # 进程列表
    if command -v ps &>/dev/null; then
        proc_data+="$(ps aux)"
    fi
    
    # 当前进程的文件描述符
    if [ -d /proc/$$/fd ]; then
        proc_data+="$(ls -la /proc/$$/fd)"
    fi
    
    printf "%s" "$proc_data" | sha256sum | cut -d' ' -f1
}

# 收集时间熵
collect_time_entropy() {
    local time_data=""
    
    # 高精度时间
    time_data+="$(date +%s%N)"
    
    # 系统时钟信息
    if command -v hwclock &>/dev/null; then
        time_data+="$(hwclock --show 2>/dev/null || true)"
    fi
    
    # 随机数（如果可用）
    if [ -f /dev/urandom ]; then
        time_data+="$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')"
    fi
    
    printf "%s" "$time_data" | sha256sum | cut -d' ' -f1
}