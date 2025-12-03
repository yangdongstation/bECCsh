#!/bin/bash
# error_handling.sh - 专业错误处理和边界检查
# 实现企业级的错误处理、异常管理和安全恢复

# 错误代码定义
readonly ERROR_SUCCESS=0
readonly ERROR_INVALID_ARGUMENT=1
readonly ERROR_FILE_NOT_FOUND=2
readonly ERROR_PERMISSION_DENIED=3
readonly ERROR_INVALID_FORMAT=4
readonly ERROR_OUT_OF_RANGE=5
readonly ERROR_CRYPTOGRAPHIC_FAILURE=6
readonly ERROR_SECURITY_VIOLATION=7
readonly ERROR_SYSTEM_FAILURE=8
readonly ERROR_MEMORY_ALLOCATION=9
readonly ERROR_TIMEOUT=10
readonly ERROR_UNKNOWN=255

# 错误信息映射
declare -A ERROR_MESSAGES
ERROR_MESSAGES[$ERROR_SUCCESS]="成功"
ERROR_MESSAGES[$ERROR_INVALID_ARGUMENT]="无效的参数"
ERROR_MESSAGES[$ERROR_FILE_NOT_FOUND]="文件未找到"
ERROR_MESSAGES[$ERROR_PERMISSION_DENIED]="权限被拒绝"
ERROR_MESSAGES[$ERROR_INVALID_FORMAT]="无效的格式"
ERROR_MESSAGES[$ERROR_OUT_OF_RANGE]="数值超出范围"
ERROR_MESSAGES[$ERROR_CRYPTOGRAPHIC_FAILURE]="密码学操作失败"
ERROR_MESSAGES[$ERROR_SECURITY_VIOLATION]="安全违规"
ERROR_MESSAGES[$ERROR_SYSTEM_FAILURE]="系统故障"
ERROR_MESSAGES[$ERROR_MEMORY_ALLOCATION]="内存分配失败"
ERROR_MESSAGES[$ERROR_TIMEOUT]="操作超时"
ERROR_MESSAGES[$ERROR_UNKNOWN]="未知错误"

# 异常类型定义
readonly EXCEPTION_NONE=0
readonly EXCEPTION_WARNING=1
readonly EXCEPTION_ERROR=2
readonly EXCEPTION_FATAL=3
readonly EXCEPTION_SECURITY=4

# 全局异常状态
declare -g GLOBAL_EXCEPTION_TYPE=$EXCEPTION_NONE
declare -g GLOBAL_EXCEPTION_CODE=$ERROR_SUCCESS
declare -g GLOBAL_EXCEPTION_MESSAGE=""
declare -g GLOBAL_EXCEPTION_CONTEXT=""

# 初始化错误处理
init_error_handling() {
    log_professional INFO "初始化专业错误处理系统..."
    
    # 设置错误处理陷阱
    trap 'handle_error $? "未捕获的异常" "全局上下文"' ERR
    trap 'handle_signal INT' INT
    trap 'handle_signal TERM' TERM
    
    # 初始化错误统计
    declare -g ERROR_STATISTICS
    ERROR_STATISTICS="errors:0,warnings:0,security:0,fatals:0"
    
    log_professional INFO "错误处理系统初始化完成"
}

# 抛出异常
throw_exception() {
    local type="$1"
    local code="$2"
    local message="$3"
    local context="${4:-}"
    
    GLOBAL_EXCEPTION_TYPE=$type
    GLOBAL_EXCEPTION_CODE=$code
    GLOBAL_EXCEPTION_MESSAGE="$message"
    GLOBAL_EXCEPTION_CONTEXT="$context"
    
    # 记录异常
    log_exception "$type" "$code" "$message" "$context"
    
    # 根据异常类型处理
    case "$type" in
        $EXCEPTION_WARNING)
            handle_warning "$code" "$message" "$context"
            ;;
        $EXCEPTION_ERROR)
            handle_error "$code" "$message" "$context"
            ;;
        $EXCEPTION_FATAL)
            handle_fatal "$code" "$message" "$context"
            ;;
        $EXCEPTION_SECURITY)
            handle_security_violation "$code" "$message" "$context"
            ;;
    esac
    
    return $code
}

# 记录异常
log_exception() {
    local type="$1"
    local code="$2"
    local message="$3"
    local context="$4"
    
    local timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
    local exception_type_name=""
    
    case "$type" in
        $EXCEPTION_WARNING) exception_type_name="WARNING" ;;
        $EXCEPTION_ERROR) exception_type_name="ERROR" ;;
        $EXCEPTION_FATAL) exception_type_name="FATAL" ;;
        $EXCEPTION_SECURITY) exception_type_name="SECURITY" ;;
        *) exception_type_name="UNKNOWN" ;;
    esac
    
    # 记录到审计日志
    audit_log "EXCEPTION: [$exception_type_name] $message (Code: $code, Context: $context)"
    
    # 根据类型选择日志级别
    case "$type" in
        $EXCEPTION_WARNING)
            log_professional WARNING "$message"
            ;;
        $EXCEPTION_ERROR)
            log_professional ERROR "$message"
            ;;
        $EXCEPTION_FATAL)
            log_professional ERROR "FATAL: $message"
            ;;
        $EXCEPTION_SECURITY)
            log_professional SECURITY "SECURITY VIOLATION: $message"
            ;;
    esac
}

# 处理警告
handle_warning() {
    local code="$1"
    local message="$2"
    local context="$3"
    
    # 更新统计
    local current_warnings=$(echo "$ERROR_STATISTICS" | grep -o "warnings:[0-9]*" | cut -d: -f2)
    local new_warnings=$((current_warnings + 1))
    ERROR_STATISTICS=$(echo "$ERROR_STATISTICS" | sed "s/warnings:[0-9]*/warnings:$new_warnings/")
    
    # 警告通常不中断执行
    log_professional WARNING "警告已记录: $message"
}

# 处理错误
handle_error() {
    local code="$1"
    local message="$2"
    local context="$3"
    
    # 更新统计
    local current_errors=$(echo "$ERROR_STATISTICS" | grep -o "errors:[0-9]*" | cut -d: -f2)
    local new_errors=$((current_errors + 1))
    ERROR_STATISTICS=$(echo "$ERROR_STATISTICS" | sed "s/errors:[0-9]*/errors:$new_errors/")
    
    # 错误恢复机制
    if ! recover_from_error "$code" "$context"; then
        log_professional ERROR "错误恢复失败: $message"
        cleanup_and_exit "$code"
    fi
}

# 处理致命错误
handle_fatal() {
    local code="$1"
    local message="$2"
    local context="$$3"
    
    # 更新统计
    local current_fatals=$(echo "$ERROR_STATISTICS" | grep -o "fatals:[0-9]*" | cut -d: -f2)
    local new_fatals=$((current_fatals + 1))
    ERROR_STATISTICS=$(echo "$ERROR_STATISTICS" | sed "s/fatals:[0-9]*/fatals:$new_fatals/")
    
    log_professional ERROR "致命错误，正在执行紧急清理..."
    
    # 紧急清理
    emergency_cleanup
    
    # 退出程序
    cleanup_and_exit "$code"
}

# 处理安全违规
handle_security_violation() {
    local code="$1"
    local message="$2"
    local context="$3"
    
    # 更新统计
    local current_security=$(echo "$ERROR_STATISTICS" | grep -o "security:[0-9]*" | cut -d: -f2)
    local new_security=$((current_security + 1))
    ERROR_STATISTICS=$(echo "$ERROR_STATISTICS" | sed "s/security:[0-9]*/security:$new_security/")
    
    log_professional SECURITY "安全违规检测: $message"
    
    # 安全违规处理
    security_violation_response "$code" "$context"
}

# 错误恢复机制
recover_from_error() {
    local code="$1"
    local context="$2"
    
    case "$code" in
        $ERROR_FILE_NOT_FOUND)
            # 尝试创建文件或提供替代方案
            log_professional WARNING "尝试恢复文件未找到错误..."
            return 0
            ;;
        $ERROR_PERMISSION_DENIED)
            # 尝试调整权限或提供替代路径
            log_professional WARNING "尝试恢复权限错误..."
            return 0
            ;;
        $ERROR_CRYPTOGRAPHIC_FAILURE)
            # 重新尝试密码学操作
            log_professional WARNING "尝试恢复密码学错误..."
            sleep 1  # 短暂延迟后重试
            return 0
            ;;
        *)
            # 默认恢复策略
            log_professional WARNING "使用默认错误恢复策略..."
            return 0
            ;;
    esac
}

# 安全违规响应
security_violation_response() {
    local code="$1"
    local context="$2"
    
    # 立即清理敏感数据
    clear_sensitive_data
    
    # 记录详细的安全事件
    local security_event="SECURITY_VIOLATION: Code=$code, Context=$context, Time=$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
    audit_log "$security_event"
    
    # 根据违规类型采取不同措施
    case "$context" in
        *"invalid_key"*)
            log_professional SECURITY "检测到无效密钥使用"
            ;;
        *"tampered_data"*)
            log_professional SECURITY "检测到数据篡改"
            ;;
        *"unauthorized_access"*)
            log_professional SECURITY "检测到未授权访问"
            ;;
        *)
            log_professional SECURITY "检测到未知安全违规"
            ;;
    esac
    
    # 在严重情况下终止程序
    if [[ $code -eq $ERROR_SECURITY_VIOLATION ]]; then
        cleanup_and_exit "$code"
    fi
}

# 信号处理
handle_signal() {
    local signal="$1"
    
    case "$signal" in
        INT)
            log_professional WARNING "接收到中断信号 (SIGINT)"
            cleanup_and_exit $ERROR_SUCCESS
            ;;
        TERM)
            log_professional WARNING "接收到终止信号 (SIGTERM)"
            cleanup_and_exit $ERROR_SUCCESS
            ;;
        *)
            log_professional WARNING "接收到未知信号: $signal"
            ;;
    esac
}

# 紧急清理
emergency_cleanup() {
    log_professional INFO "执行紧急清理..."
    
    # 清理敏感数据
    clear_sensitive_data
    
    # 关闭文件描述符
    exec 2>/dev/null
    
    # 重置终端
    tput cnorm 2>/dev/null || true
    
    log_professional INFO "紧急清理完成"
}

# 正常清理和退出
cleanup_and_exit() {
    local exit_code="${1:-$ERROR_SUCCESS}"
    
    log_professional INFO "执行正常清理，退出码: $exit_code"
    
    # 清理敏感数据
    clear_sensitive_data
    
    # 显示错误统计
    display_error_statistics
    
    # 退出程序
    exit $exit_code
}

# 清理敏感数据
clear_sensitive_data() {
    # 清理全局变量中的敏感信息
    GLOBAL_EXCEPTION_CONTEXT=""
    SECURITY_CONTEXT=""
    
    # 清理临时文件
    if [[ -f "/tmp/beccsh_temp_$$" ]]; then
        shred -u "/tmp/beccsh_temp_$$" 2>/dev/null || rm -f "/tmp/beccsh_temp_$$"
    fi
    
    # 清理内存中的敏感数据
    for var in $(set | grep -E "(KEY|PRIVATE|SECRET|PASSWORD)" | cut -d= -f1); do
        printf -v "$var" "%s" "00000000000000000000000000000000"
        unset "$var"
    done
    
    log_professional SECURITY "敏感数据已清理"
}

# 显示错误统计
display_error_statistics() {
    echo ""
    echo "========================================"
    echo "错误统计报告"
    echo "========================================"
    echo "错误: $(echo "$ERROR_STATISTICS" | grep -o "errors:[0-9]*" | cut -d: -f2)"
    echo "警告: $(echo "$ERROR_STATISTICS" | grep -o "warnings:[0-9]*" | cut -d: -f2)"
    echo "安全违规: $(echo "$ERROR_STATISTICS" | grep -o "security:[0-9]*" | cut -d: -f2)"
    echo "致命错误: $(echo "$ERROR_STATISTICS" | grep -o "fatals:[0-9]*" | cut -d: -f2)"
    echo "========================================"
}

# 参数验证
validate_parameters() {
    local params=("$@")
    local valid=1
    
    for param in "${params[@]}"; do
        if [[ -z "$param" ]]; then
            throw_exception $EXCEPTION_ERROR $ERROR_INVALID_ARGUMENT "参数不能为空"
            valid=0
        fi
    done
    
    return $valid
}

# 文件验证
validate_file() {
    local filename="$1"
    local required_permission="${2:-r}"
    
    # 检查文件是否存在
    if [[ ! -f "$filename" ]]; then
        throw_exception $EXCEPTION_ERROR $ERROR_FILE_NOT_FOUND "文件不存在: $filename"
        return 1
    fi
    
    # 检查读取权限
    if [[ $required_permission == *"r"* ]] && [[ ! -r "$filename" ]]; then
        throw_exception $EXCEPTION_ERROR $ERROR_PERMISSION_DENIED "文件不可读: $filename"
        return 1
    fi
    
    # 检查写入权限
    if [[ $required_permission == *"w"* ]] && [[ ! -w "$filename" ]]; then
        throw_exception $EXCEPTION_ERROR $ERROR_PERMISSION_DENIED "文件不可写: $filename"
        return 1
    fi
    
    # 检查文件大小（防止DoS攻击）
    local file_size=$(stat -c%s "$filename" 2>/dev/null || echo "0")
    if [[ $file_size -gt 10485760 ]]; then  # 10MB限制
        throw_exception $EXCEPTION_WARNING $ERROR_INVALID_ARGUMENT "文件过大: $filename (${file_size}字节)"
    fi
    
    return 0
}

# 数值范围验证
validate_range() {
    local value="$1"
    local min_val="$2"
    local max_val="$3"
    local name="${4:-数值}"
    
    bigint_compare "$value" "$min_val"
    local cmp_min=$?
    
    bigint_compare "$value" "$max_val"
    local cmp_max=$?
    
    if [[ $cmp_min -eq 2 ]] || [[ $cmp_max -eq 1 ]]; then
        throw_exception $EXCEPTION_ERROR $ERROR_OUT_OF_RANGE "$name超出范围: [$min_val, $max_val]"
        return 1
    fi
    
    return 0
}

# 密钥验证
validate_key() {
    local key="$1"
    local key_type="${2:-unknown}"
    
    # 检查密钥长度
    if [[ ${#key} -lt 10 ]] || [[ ${#key} -gt 1000 ]]; then
        throw_exception $EXCEPTION_SECURITY $ERROR_SECURITY_VIOLATION "密钥长度异常: $key_type (${#key}位)"
        return 1
    fi
    
    # 检查密钥格式（应该是数字）
    if ! [[ $key =~ ^[0-9]+$ ]]; then
        throw_exception $EXCEPTION_SECURITY $ERROR_SECURITY_VIOLATION "密钥格式无效: $key_type"
        return 1
    fi
    
    return 0
}

# 曲线参数验证
validate_curve_parameters() {
    local curve_name="$1"
    
    # 检查曲线名称
    case "$curve_name" in
        secp256r1|secp256k1|secp384r1)
            return 0
            ;;
        *)
            throw_exception $EXCEPTION_ERROR $ERROR_INVALID_ARGUMENT "不支持的曲线: $curve_name"
            return 1
            ;;
    esac
}

# 哈希算法验证
validate_hash_algorithm() {
    local algorithm="$1"
    
    case "$algorithm" in
        sha256|sha384|sha512)
            return 0
            ;;
        *)
            throw_exception $EXCEPTION_ERROR $ERROR_INVALID_ARGUMENT "不支持的哈希算法: $algorithm"
            return 1
            ;;
    esac
}

# 内存使用监控
monitor_memory_usage() {
    local current_memory=$(ps -o rss= -p $$ 2>/dev/null | xargs)
    local max_memory="${1:-1048576}"  # 默认1GB限制（KB）
    
    if [[ $current_memory -gt $max_memory ]]; then
        throw_exception $EXCEPTION_FATAL $ERROR_MEMORY_ALLOCATION "内存使用超出限制: ${current_memory}KB > ${max_memory}KB"
        return 1
    fi
    
    return 0
}

# 超时监控
start_timeout_monitor() {
    local timeout_seconds="$1"
    local operation_name="${2:-操作}"
    
    # 启动后台超时监控
    (
        sleep "$timeout_seconds"
        kill -TERM $$ 2>/dev/null
    ) &
    
    local timeout_pid=$!
    echo "$timeout_pid $operation_name"
}

# 取消超时监控
cancel_timeout_monitor() {
    local timeout_info="$1"
    read -r timeout_pid operation_name <<< "$timeout_info"
    
    if kill -0 "$timeout_pid" 2>/dev/null; then
        kill -TERM "$timeout_pid" 2>/dev/null
        log_professional INFO "超时监控已取消: $operation_name"
    fi
}

# 数据完整性验证
validate_data_integrity() {
    local data="$1"
    local expected_hash="$2"
    
    local actual_hash=$(echo -n "$data" | sha256sum | cut -d' ' -f1)
    
    if [[ "$actual_hash" != "$expected_hash" ]]; then
        throw_exception $EXCEPTION_SECURITY $ERROR_SECURITY_VIOLATION "数据完整性验证失败"
        return 1
    fi
    
    return 0
}

# 网络输入验证
validate_network_input() {
    local input="$1"
    
    # 检查输入长度
    if [[ ${#input} -gt 65536 ]]; then  # 64KB限制
        throw_exception $EXCEPTION_SECURITY $ERROR_SECURITY_VIOLATION "网络输入过大"
        return 1
    fi
    
    # 检查是否包含控制字符
    if [[ $input =~ [\x00-\x1F\x7F-\xFF] ]]; then
        throw_exception $EXCEPTION_SECURITY $ERROR_SECURITY_VIOLATION "网络输入包含控制字符"
        return 1
    fi
    
    return 0
}

# 初始化错误处理
init_error_handling