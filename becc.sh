#!/bin/bash
# bECCsh - 纯Bash椭圆曲线密码学实现
# 版本: 1.0.0 (Professional Edition)
# 作者: AI Assistant
# 许可证: MIT
# 
# 这是一个完全用Bash实现的椭圆曲线密码学库，支持ECDSA签名和验证。
# 虽然这是一个"密码学傲慢笑话"项目，但实现是严肃和专业的。
#
# 特性:
# - 纯Bash实现，无外部依赖
# - 支持secp256r1, secp256k1, secp384r1曲线
# - 完整的ECDSA签名和验证
# - RFC 6979确定性k值生成
# - 侧信道攻击防护
# - ASN.1 DER编码
# - 企业级错误处理

set -euo pipefail

# 版本信息
readonly VERSION="1.0.0"
readonly BUILD_DATE="2025-12-03"

# 全局配置
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR="${SCRIPT_DIR}/lib"

# 导入库
source "${LIB_DIR}/bash_math.sh"
source "${LIB_DIR}/bigint.sh"
source "${LIB_DIR}/ec_curve.sh"
source "${LIB_DIR}/ec_point.sh"
source "${LIB_DIR}/ecdsa.sh"
source "${LIB_DIR}/security.sh"
source "${LIB_DIR}/asn1.sh"
source "${LIB_DIR}/entropy.sh"
# 导入安全功能
source "${SCRIPT_DIR}/security_functions.sh"

# 错误代码
readonly ERR_INVALID_INPUT=1
readonly ERR_CRYPTO_OPERATION=2
readonly ERR_MEMORY=3
readonly ERR_INVALID_CURVE=4
readonly ERR_SIGNATURE_INVALID=5

# 日志级别
readonly LOG_DEBUG=0
readonly LOG_INFO=1
readonly LOG_WARN=2
readonly LOG_ERROR=3

# 当前日志级别
LOG_LEVEL=${LOG_INFO}

# 日志函数
log() {
    local level=$1
    shift
    local message="$*"
    
    if [[ $level -ge $LOG_LEVEL ]]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        case $level in
            $LOG_DEBUG) echo "[DEBUG] $timestamp - $message" >&2 ;;
            $LOG_INFO) echo "[INFO] $timestamp - $message" >&2 ;;
            $LOG_WARN) echo "[WARN] $timestamp - $message" >&2 ;;
            $LOG_ERROR) echo "[ERROR] $timestamp - $message" >&2 ;;
        esac
    fi
}

# 错误处理函数
error_exit() {
    local code=$1
    shift
    local message="$*"
    log $LOG_ERROR "$message"
    exit $code
}

# 显示使用帮助
show_help() {
    cat << EOF
bECCsh - 纯Bash椭圆曲线密码学实现 v${VERSION}

使用方法: $0 [命令] [选项]

命令:
    keygen      生成ECDSA密钥对
    sign        对消息进行ECDSA签名
    verify      验证ECDSA签名
    test        运行测试套件
    benchmark   性能基准测试
    help        显示此帮助信息

选项:
    -c, --curve CURVE       选择椭圆曲线 (secp256r1, secp256k1, secp384r1)
    -h, --hash HASH         选择哈希算法 (sha256, sha384, sha512)
    -f, --file FILE         输入/输出文件
    -m, --message MESSAGE   要签名的消息
    -k, --key KEY           私钥或公钥文件
    -s, --signature SIG     签名文件
    -v, --verbose           详细输出
    -d, --debug             调试模式
    -q, --quiet             静默模式
    --help                  显示详细帮助

示例:
    # 生成密钥对
    $0 keygen -c secp256r1 -f private_key.pem
    
    # 签名消息
    $0 sign -c secp256r1 -k private_key.pem -m "Hello World" -f signature.der
    
    # 验证签名
    $0 verify -c secp256r1 -k public_key.pem -m "Hello World" -s signature.der
    
    # 运行测试
    $0 test -c secp256r1
    
    # 性能测试
    $0 benchmark -c secp256r1 -n 100

安全警告:
    这是一个纯Bash实现的密码学库，主要用于教育和研究目的。
    在生产环境中，请使用经过充分测试的密码学库。

EOF
}

# 解析命令行参数
parse_args() {
    local args=()
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--curve)
                CURVE_NAME="$2"
                shift 2
                ;;
            -h|--hash)
                HASH_ALG="$2"
                shift 2
                ;;
            -f|--file)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -m|--message)
                MESSAGE="$2"
                shift 2
                ;;
            -k|--key)
                KEY_FILE="$2"
                shift 2
                ;;
            -s|--signature)
                SIGNATURE_FILE="$2"
                shift 2
                ;;
            -v|--verbose)
                LOG_LEVEL=$LOG_INFO
                shift
                ;;
            -d|--debug)
                LOG_LEVEL=$LOG_DEBUG
                set -x
                shift
                ;;
            -q|--quiet)
                LOG_LEVEL=$LOG_ERROR
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            -*)
                error_exit $ERR_INVALID_INPUT "未知选项: $1"
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done
    
    # 恢复位置参数
    set -- "${args[@]}"
    
    # 设置默认值
    CURVE_NAME=${CURVE_NAME:-"secp256r1"}
    HASH_ALG=${HASH_ALG:-"sha256"}
    OUTPUT_FILE=${OUTPUT_FILE:-""}
    MESSAGE=${MESSAGE:-""}
    KEY_FILE=${KEY_FILE:-""}
    SIGNATURE_FILE=${SIGNATURE_FILE:-""}
}

# 初始化密码学库
init_crypto() {
    log $LOG_INFO "初始化bECCsh密码学库 v${VERSION}"
    
    # 验证曲线支持
    if ! curve_is_supported "$CURVE_NAME"; then
        error_exit $ERR_INVALID_CURVE "不支持的曲线: $CURVE_NAME"
    fi
    
    # 初始化曲线参数
    if ! curve_init "$CURVE_NAME"; then
        error_exit $ERR_CRYPTO_OPERATION "曲线初始化失败"
    fi
    
    # 初始化随机数生成器
    if ! entropy_init; then
        error_exit $ERR_CRYPTO_OPERATION "熵源初始化失败"
    fi
    
    log $LOG_INFO "密码学库初始化完成"
}

# 生成密钥对
cmd_keygen() {
    log $LOG_INFO "生成ECDSA密钥对 (曲线: $CURVE_NAME)"
    
    # 生成私钥
    local private_key
    private_key=$(ecdsa_generate_private_key)
    if [[ $? -ne 0 ]]; then
        error_exit $ERR_CRYPTO_OPERATION "私钥生成失败"
    fi
    
    # 计算公钥
    local public_key
    public_key=$(ecdsa_get_public_key "$private_key")
    if [[ $? -ne 0 ]]; then
        error_exit $ERR_CRYPTO_OPERATION "公钥计算失败"
    fi
    
    # 保存密钥
    if [[ -n "$OUTPUT_FILE" ]]; then
        # 保存私钥
        if ! save_private_key "$private_key" "$OUTPUT_FILE"; then
            error_exit $ERR_CRYPTO_OPERATION "私钥保存失败"
        fi
        
        # 保存公钥
        local pub_file="${OUTPUT_FILE%.pem}_public.pem"
        if ! save_public_key "$public_key" "$pub_file"; then
            error_exit $ERR_CRYPTO_OPERATION "公钥保存失败"
        fi
        
        log $LOG_INFO "密钥对已保存到: $OUTPUT_FILE 和 $pub_file"
    else
        # 输出到标准输出
        echo "=== PRIVATE KEY ==="
        echo "$private_key"
        echo "=== PUBLIC KEY ==="
        echo "$public_key"
    fi
}

# 签名消息
cmd_sign() {
    if [[ -z "$MESSAGE" && -z "$INPUT_FILE" ]]; then
        error_exit $ERR_INVALID_INPUT "必须提供要签名的消息或文件"
    fi
    
    if [[ -z "$KEY_FILE" ]]; then
        error_exit $ERR_INVALID_INPUT "必须提供私钥文件"
    fi
    
    log $LOG_INFO "签名消息 (曲线: $CURVE_NAME, 哈希: $HASH_ALG)"
    
    # 读取私钥
    local private_key
    private_key=$(load_private_key "$KEY_FILE")
    if [[ $? -ne 0 ]]; then
        error_exit $ERR_CRYPTO_OPERATION "私钥加载失败"
    fi
    
    # 准备消息
    local message_to_sign
    if [[ -n "$INPUT_FILE" ]]; then
        message_to_sign=$(cat "$INPUT_FILE")
    else
        message_to_sign="$MESSAGE"
    fi
    
    # 计算消息哈希
    local message_hash
    message_hash=$(hash_message "$message_to_sign" "$HASH_ALG")
    if [[ $? -ne 0 ]]; then
        error_exit $ERR_CRYPTO_OPERATION "消息哈希计算失败"
    fi
    
    # 生成签名
    local signature_r signature_s
    if ! ecdsa_sign "$private_key" "$message_hash" "$CURVE_NAME" "$HASH_ALG"; then
        error_exit $ERR_CRYPTO_OPERATION "签名生成失败"
    fi
    
    # 获取签名结果
    signature_r=${ECDSA_SIGNATURE_R:-}
    signature_s=${ECDSA_SIGNATURE_S:-}
    
    if [[ -z "$signature_r" || -z "$signature_s" ]]; then
        error_exit $ERR_CRYPTO_OPERATION "签名结果无效"
    fi
    
    # 编码签名
    local encoded_signature
    encoded_signature=$(encode_ecdsa_signature "$signature_r" "$signature_s")
    if [[ $? -ne 0 ]]; then
        error_exit $ERR_CRYPTO_OPERATION "签名编码失败"
    fi
    
    # 保存签名
    if [[ -n "$OUTPUT_FILE" ]]; then
        echo -n "$encoded_signature" | base64 -d > "$OUTPUT_FILE"
        log $LOG_INFO "签名已保存到: $OUTPUT_FILE"
    else
        echo "$encoded_signature"
    fi
}

# 验证签名
cmd_verify() {
    if [[ -z "$MESSAGE" && -z "$INPUT_FILE" ]]; then
        error_exit $ERR_INVALID_INPUT "必须提供要验证的消息或文件"
    fi
    
    if [[ -z "$KEY_FILE" ]]; then
        error_exit $ERR_INVALID_INPUT "必须提供公钥文件"
    fi
    
    if [[ -z "$SIGNATURE_FILE" ]]; then
        error_exit $ERR_INVALID_INPUT "必须提供签名文件"
    fi
    
    log $LOG_INFO "验证签名 (曲线: $CURVE_NAME, 哈希: $HASH_ALG)"
    
    # 读取公钥
    local public_key
    public_key=$(load_public_key "$KEY_FILE")
    if [[ $? -ne 0 ]]; then
        error_exit $ERR_CRYPTO_OPERATION "公钥加载失败"
    fi
    
    # 读取签名
    local signature_data
    signature_data=$(base64 -w0 "$SIGNATURE_FILE" 2>/dev/null || cat "$SIGNATURE_FILE")
    
    # 解码签名
    local signature_r signature_s
    if ! decode_ecdsa_signature "$signature_data" signature_r signature_s; then
        error_exit $ERR_CRYPTO_OPERATION "签名解码失败"
    fi
    
    # 准备消息
    local message_to_verify
    if [[ -n "$INPUT_FILE" ]]; then
        message_to_verify=$(cat "$INPUT_FILE")
    else
        message_to_verify="$MESSAGE"
    fi
    
    # 计算消息哈希
    local message_hash
    message_hash=$(hash_message "$message_to_verify" "$HASH_ALG")
    if [[ $? -ne 0 ]]; then
        error_exit $ERR_CRYPTO_OPERATION "消息哈希计算失败"
    fi
    
    # 验证签名
    if ecdsa_verify "$public_key" "$message_hash" "$signature_r" "$signature_s" "$CURVE_NAME" "$HASH_ALG"; then
        log $LOG_INFO "签名验证成功"
        echo "VALID"
        return 0
    else
        log $LOG_WARN "签名验证失败"
        echo "INVALID"
        return $ERR_SIGNATURE_INVALID
    fi
}

# 运行测试套件
cmd_test() {
    log $LOG_INFO "运行bECCsh测试套件"
    
    local test_script="${SCRIPT_DIR}/test_suite.sh"
    if [[ -f "$test_script" ]]; then
        bash "$test_script" -c "$CURVE_NAME" -v
    else
        log $LOG_WARN "测试套件未找到，运行基本测试"
        
        # 基本功能测试
        local test_private_key test_public_key test_message test_signature_r test_signature_s
        
        # 生成测试密钥
        test_private_key=$(ecdsa_generate_private_key)
        test_public_key=$(ecdsa_get_public_key "$test_private_key")
        
        # 测试消息
        test_message="Hello, bECCsh!"
        
        # 计算哈希
        local test_hash
        test_hash=$(hash_message "$test_message" "$HASH_ALG")
        
        # 签名
        if ecdsa_sign "$test_private_key" "$test_hash" "$CURVE_NAME" "$HASH_ALG"; then
            test_signature_r=${ECDSA_SIGNATURE_R:-}
            test_signature_s=${ECDSA_SIGNATURE_S:-}
            
            # 验证
            if ecdsa_verify "$test_public_key" "$test_hash" "$test_signature_r" "$test_signature_s" "$CURVE_NAME" "$HASH_ALG"; then
                log $LOG_INFO "基本测试通过"
                return 0
            else
                log $LOG_ERROR "签名验证失败"
                return 1
            fi
        else
            log $LOG_ERROR "签名生成失败"
            return 1
        fi
    fi
}

# 性能基准测试
cmd_benchmark() {
    local iterations=${1:-100}
    
    log $LOG_INFO "运行性能基准测试 (迭代次数: $iterations, 曲线: $CURVE_NAME)"
    
    local start_time end_time duration
    local i success_count=0
    
    start_time=$(date +%s.%N)
    
    for ((i=1; i<=iterations; i++)); do
        # 生成密钥对
        local private_key public_key
        private_key=$(ecdsa_generate_private_key)
        public_key=$(ecdsa_get_public_key "$private_key")
        
        # 签名
        local message="Benchmark test $i"
        local message_hash
        message_hash=$(hash_message "$message" "$HASH_ALG")
        
        if ecdsa_sign "$private_key" "$message_hash" "$CURVE_NAME" "$HASH_ALG"; then
            local sig_r=${ECDSA_SIGNATURE_R:-}
            local sig_s=${ECDSA_SIGNATURE_S:-}
            
            # 验证
            if ecdsa_verify "$public_key" "$message_hash" "$sig_r" "$sig_s" "$CURVE_NAME" "$HASH_ALG"; then
                ((success_count++))
            fi
        fi
        
        # 显示进度
        if [[ $((i % 10)) -eq 0 ]]; then
            printf "\r进度: %d/%d (%.1f%%)" $i $iterations $((i * 100 / iterations))
        fi
    done
    
    end_time=$(date +%s.%N)
    # 计算持续时间（纳秒转秒）
    local start_sec=${start_time%.*}
    local start_nsec=${start_time#*.}
    local end_sec=${end_time%.*}
    local end_nsec=${end_time#*.}
    
    local total_nsec=$(( (end_sec - start_sec) * 1000000000 + (end_nsec - start_nsec) ))
    duration=$(bashmath_divide_float "$total_nsec" "1000000000" 6)
    
    echo -e "\n"
    log $LOG_INFO "基准测试完成"
    echo "总时间: ${duration}s"
    echo "操作次数: $iterations"
    echo "成功次数: $success_count"
    echo "平均时间: $(bashmath_divide_float "$duration" "$iterations" 6)s"
    echo "操作/秒: $(bashmath_divide_float "$iterations" "$duration" 6)"
}

# 主函数
main() {
    local command="${1:-help}"
    shift || true
    
    # 显示安全警告（仅在非静默模式下）
    if [[ "${BECC_SILENT:-false}" != "true" ]]; then
        show_security_warning
    fi
    
    # 安全检查（在生产环境中阻止使用）
    if [[ "${BECC_PRODUCTION:-false}" == "true" ]]; then
        echo "❌ 错误：本项目不适合生产环境使用" >&2
        echo "请查看 SECURITY_WARNING.md 了解详细信息" >&2
        exit 1
    fi
    
    # 基础安全检查
    if ! security_check_environment; then
        echo "⚠️  环境安全检查发现警告，继续运行..." >&2
    fi
    
    # 解析参数
    parse_args "$@"
    
    # 处理帮助命令
    if [[ "$command" == "help" ]]; then
        show_help
        exit 0
    fi
    
    # 初始化密码学库
    init_crypto
    
    # 执行命令
    case "$command" in
        keygen)
            cmd_keygen
            ;;
        sign)
            cmd_sign
            ;;
        verify)
            cmd_verify
            ;;
        test)
            cmd_test
            ;;
        benchmark)
            cmd_benchmark "$@"
            ;;
        *)
            error_exit $ERR_INVALID_INPUT "未知命令: $command"
            ;;
    esac
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi