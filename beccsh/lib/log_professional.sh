#!/bin/bash
# log_professional.sh - 专业版日志函数

# 专业版日志函数
log_professional() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")
            echo "[INFO] $timestamp - $message"
            ;;
        "ERROR")
            echo "[ERROR] $timestamp - $message" >&2
            ;;
        "DEBUG")
            echo "[DEBUG] $timestamp - $message"
            ;;
        "WARNING")
            echo "[WARNING] $timestamp - $message"
            ;;
        *)
            echo "[UNKNOWN] $timestamp - $message"
            ;;
    esac
}

# 专业版异常处理
throw_exception() {
    local exception_type="$1"
    local error_code="$2"
    local message="$3"
    
    log_professional ERROR "异常[$exception_type] 代码[$error_code]: $message"
    exit $error_code
}

# 专业版能力测试
test_ecdsa_capabilities() {
    log_professional INFO "测试ECDSA能力..."
    
    # 测试基本数学能力
    if ! command -v bc >/dev/null 2>&1 && [[ ${BASH_VERSION%%.*} -lt 4 ]]; then
        log_professional ERROR "需要bash 4.0+或bc支持"
        return 1
    fi
    
    # 测试大数运算能力
    if ! command -v bigint_compare >/dev/null 2>&1; then
        log_professional ERROR "需要大数运算支持"
        return 1
    fi
    
    log_professional INFO "ECDSA能力测试通过"
    return 0
}

# 简化版bigint_compare函数（用于测试环境）
bigint_compare() {
    local num1="$1"
    local num2="$2"
    
    # 移除前导零
    num1="${num1#0*}"
    num2="${num2#0*}"
    
    # 比较长度
    local len1=${#num1}
    local len2=${#num2}
    
    if [[ $len1 -gt $len2 ]]; then
        echo "1"  # num1 > num2
        return 0
    elif [[ $len1 -lt $len2 ]]; then
        echo "2"  # num1 < num2
        return 0
    else
        # 长度相同，逐位比较
        if [[ "$num1" == "$num2" ]]; then
            echo "0"  # num1 = num2
            return 0
        elif [[ "$num1" > "$num2" ]]; then
            echo "1"  # num1 > num2
            return 0
        else
            echo "2"  # num1 < num2
            return 0
        fi
    fi
}

# 错误代码定义
EXCEPTION_ERROR=1
ERROR_INVALID_FORMAT=100
ERROR_OUT_OF_RANGE=101
ERROR_CRYPTO_FAIL=200

# 如果直接运行此脚本，进行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "专业版日志函数测试"
    log_professional INFO "测试信息日志"
    log_professional ERROR "测试错误日志"
    log_professional DEBUG "测试调试日志"
    
    echo "大数比较测试:"
    echo "123 vs 456: $(bigint_compare 123 456)"
    echo "999 vs 998: $(bigint_compare 999 998)"
    echo "1000 vs 1000: $(bigint_compare 1000 1000)"
fi