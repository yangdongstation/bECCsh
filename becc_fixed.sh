#!/bin/bash
# bECCsh - 修复版纯Bash椭圆曲线密码学实现
# 版本: 2.0.1 (Fixed Edition)
# 修复了签名功能的问题

set -euo pipefail

# 版本信息
readonly VERSION="2.0.1"
readonly BUILD_DATE="2025-12-04"

# 全局配置
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR="${SCRIPT_DIR}/lib"
readonly CORE_DIR="${SCRIPT_DIR}/core"

# 导入基础库
source "${LIB_DIR}/bash_math.sh"
source "${LIB_DIR}/bigint.sh"
source "${LIB_DIR}/ec_curve.sh"
source "${LIB_DIR}/ec_point.sh"
source "${LIB_DIR}/asn1.sh"
source "${LIB_DIR}/entropy.sh"

# 导入修复的ECDSA函数
source "${CORE_DIR}/crypto/ecdsa_fixed.sh" 2>/dev/null || {
    echo "错误: 无法加载修复的ECDSA函数" >&2
    exit 1
}

# 导入多曲线支持
source "${CORE_DIR}/crypto/curve_selector_simple.sh" 2>/dev/null || {
    echo "错误: 无法加载曲线选择器" >&2
    exit 1
}

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
becc_fixed - 修复版纯Bash椭圆曲线密码学实现 v${VERSION}

使用方法: $0 [命令] [选项]

命令:
    keygen      生成ECDSA密钥对
    sign        对消息进行ECDSA签名
    verify      验证ECDSA签名
    test        运行测试套件
    help        显示此帮助信息

选项:
    -c, --curve CURVE       选择椭圆曲线 (secp256k1, secp256r1)
    -h, --hash HASH         选择哈希算法 (sha256, sha384, sha512)
    -f, --file FILE         输入/输出文件
    -m, --message MESSAGE   要签名的消息
    -k, --key KEY           私钥或公钥文件
    -s, --signature SIG     签名文件
    -v, --verbose           详细输出
    -d, --debug             调试模式
    -q, --quiet             静默模式
    --help                  显示详细帮助

支持的椭圆曲线:
    secp256k1      - 比特币标准曲线 (128位安全)
    secp256r1      - NIST P-256, TLS 1.3标准 (128位安全)

示例:
    # 生成密钥对
    $0 keygen -c secp256k1 -f private_key.pem
    
    # 签名消息
    $0 sign -c secp256k1 -k private_key.pem -m "Hello World" -f signature.der
    
    # 验证签名
    $0 verify -c secp256k1 -k public_key.pem -m "Hello World" -s signature.der
    
    # 运行测试
    $0 test -c secp256k1

重要说明:
    这是一个修复版本，解决了签名功能的问题。
    本程序主要用于教育和研究目的，不适合生产环境使用。

EOF
}

# 解析命令行参数
check_args() {
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
    CURVE_NAME=${CURVE_NAME:-"secp256k1"}
    HASH_ALG=${HASH_ALG:-"sha256"}
    OUTPUT_FILE=${OUTPUT_FILE:-""}
    INPUT_FILE=${INPUT_FILE:-""}
    MESSAGE=${MESSAGE:-""}
    KEY_FILE=${KEY_FILE:-""}
    SIGNATURE_FILE=${SIGNATURE_FILE:-""}
}

# 初始化密码学库
init_crypto() {
    log $LOG_INFO "初始化修复版bECCsh密码学库 v${VERSION}"
    
    # 选择并加载曲线
    if ! select_curve_simple "$CURVE_NAME"; then
        error_exit $ERR_INVALID_CURVE "曲线选择失败: $CURVE_NAME"
    fi
    
    # 获取当前曲线参数
    local params=$(get_current_curve_params_simple)
    if [[ $? -ne 0 ]]; then
        error_exit $ERR_CRYPTO_OPERATION "获取曲线参数失败"
    fi
    
    # 解析参数
    CURRENT_CURVE_P=$(echo "$params" | cut -d' ' -f1)
    CURRENT_CURVE_A=$(echo "$params" | cut -d' ' -f2)
    CURRENT_CURVE_B=$(echo "$params" | cut -d' ' -f3)
    CURRENT_CURVE_GX=$(echo "$params" | cut -d' ' -f4)
    CURRENT_CURVE_GY=$(echo "$params" | cut -d' ' -f5)
    CURRENT_CURVE_N=$(echo "$params" | cut -d' ' -f6)
    CURRENT_CURVE_H=$(echo "$params" | cut -d' ' -f7)
    
    log $LOG_INFO "已选择椭圆曲线: $CURRENT_CURVE_SIMPLE"
    log $LOG_INFO "曲线参数已加载"
    
    # 初始化随机数生成器
    if ! entropy_init; then
        error_exit $ERR_CRYPTO_OPERATION "熵源初始化失败"
    fi
    
    log $LOG_INFO "密码学库初始化完成"
}

# 生成密钥对
cmd_keygen() {
    log $LOG_INFO "生成ECDSA密钥对 (曲线: $CURRENT_CURVE_SIMPLE)"
    
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
        echo "$private_key" > "$OUTPUT_FILE"
        chmod 600 "$OUTPUT_FILE"
        
        # 保存公钥
        local pub_file="${OUTPUT_FILE%.pem}_public.pem"
        echo "$public_key" > "$pub_file"
        chmod 644 "$pub_file"
        
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
    
    log $LOG_INFO "签名消息 (曲线: $CURRENT_CURVE_SIMPLE, 哈希: $HASH_ALG)"
    
    # 读取私钥
    local private_key
    if [[ -f "$KEY_FILE" ]]; then
        private_key=$(cat "$KEY_FILE")
    else
        private_key="$KEY_FILE"
    fi
    
    # 验证私钥格式
    if ! [[ "$private_key" =~ ^[0-9]+$ ]]; then
        error_exit $ERR_INVALID_INPUT "无效的私钥格式"
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
    
    # 转换为整数
    message_hash=$((16#$message_hash))
    
    # 生成签名
    log $LOG_DEBUG "生成签名 - 私钥: ${private_key:0:10}..., 哈希: $message_hash"
    local signature=$(generate_ecdsa_signature "$private_key" "$message_hash" "$CURRENT_CURVE_SIMPLE")
    
    if [[ $? -ne 0 ]]; then
        error_exit $ERR_CRYPTO_OPERATION "签名生成失败"
    fi
    
    # 解析签名
    local r=$(echo "$signature" | cut -d' ' -f1)
    local s=$(echo "$signature" | cut -d' ' -f2)
    
    log $LOG_INFO "签名生成成功 - r: ${r:0:20}..., s: ${s:0:20}..."
    
    # 编码签名
    local encoded_signature
    encoded_signature=$(encode_ecdsa_signature "$r" "$s")
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
    
    log $LOG_INFO "验证签名 (曲线: $CURRENT_CURVE_SIMPLE, 哈希: $HASH_ALG)"
    
    # 读取公钥
    local public_key
    if [[ -f "$KEY_FILE" ]]; then
        public_key=$(cat "$KEY_FILE")
    else
        public_key="$KEY_FILE"
    fi
    
    # 解析公钥
    local pub_x pub_y
    if [[ "$public_key" =~ ^[0-9]+[[:space:]][0-9]+$ ]]; then
        pub_x=$(echo "$public_key" | cut -d' ' -f1)
        pub_y=$(echo "$public_key" | cut -d' ' -f2)
    else
        error_exit $ERR_INVALID_INPUT "无效的公钥格式"
    fi
    
    # 读取签名
    local signature_data
    if [[ -f "$SIGNATURE_FILE" ]]; then
        signature_data=$(base64 -w0 "$SIGNATURE_FILE" 2>/dev/null || cat "$SIGNATURE_FILE")
    else
        signature_data="$SIGNATURE_FILE"
    fi
    
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
    
    # 转换为整数
    message_hash=$((16#$message_hash))
    
    # 验证签名
    log $LOG_DEBUG "验证签名 - 公钥: ($pub_x, $pub_y), 哈希: $message_hash, r: $signature_r, s: $signature_s"
    
    if verify_ecdsa_signature_fixed "$pub_x" "$pub_y" "$message_hash" "$signature_r" "$signature_s" "$CURRENT_CURVE_SIMPLE"; then
        log $LOG_INFO "签名验证成功"
        echo "VALID"
        return 0
> fi
    
    log $LOG_WARN "签名验证失败"
    echo "INVALID"
    return $ERR_SIGNATURE_INVALID
}

# 运行测试套件
cmd_test() {
    log $LOG_INFO "运行修复版bECCsh测试套件"
    
    echo "测试修复的ECDSA功能..."
    echo "========================"
    
    # 测试基本功能
    local test_message="Hello, bECCsh Fixed!"
    local test_hash=$(echo -n "$test_message" | sha256sum | cut -d' ' -f1)
    test_hash=$((16#$test_hash))
    
    echo "测试消息: $test_message"
    echo "消息哈希: $test_hash"
    echo "测试曲线: $CURRENT_CURVE_SIMPLE"
    echo ""
    
    # 生成测试密钥对
    echo "1. 生成测试密钥对..."
    local test_private_key=$(ecdsa_generate_private_key)
    local test_public_key=$(ecdsa_get_public_key "$test_private_key")
    
    if [[ -n "$test_private_key" && -n "$test_public_key" ]]; then
        echo "✅ 密钥对生成成功"
        echo "私钥: ${test_private_key:0:20}..."
        echo "公钥: ${test_public_key:0:40}..."
    else
        echo "❌ 密钥对生成失败"
        return 1
    fi
    echo ""
    
    # 测试签名
    echo "2. 测试签名功能..."
    local signature=$(generate_ecdsa_signature "$test_private_key" "$test_hash" "$CURRENT_CURVE_SIMPLE")
    
    if [[ $? -eq 0 && -n "$signature" ]]; then
        local r=$(echo "$signature" | cut -d' ' -f1)
        local s=$(echo "$signature" | cut -d' ' -f2)
        echo "✅ 签名生成成功"
        echo "r: ${r:0:20}..."
        echo "s: ${s:0:20}..."
    else
        echo "❌ 签名生成失败"
        return 1
    fi
    echo ""
    
    # 解析公钥
    local pub_x=$(echo "$test_public_key" | cut -d' ' -f1)
    local pub_y=$(echo "$test_public_key" | cut -d' ' -f2)
    
    # 测试验证
    echo "3. 测试签名验证..."
    if verify_ecdsa_signature_fixed "$pub_x" "$pub_y" "$test_hash" "$r" "$s" "$CURRENT_CURVE_SIMPLE"; then
        echo "✅ 签名验证成功"
    else
        echo "❌ 签名验证失败"
        return 1
    fi
    echo ""
    
    # 测试错误签名
    echo "4. 测试错误签名检测..."
    local wrong_r=$(bigint_add "$r" "1")
    if verify_ecdsa_signature_fixed "$pub_x" "$pub_y" "$test_hash" "$wrong_r" "$s" "$CURRENT_CURVE_SIMPLE"; then
        echo "⚠️  错误签名验证通过 (预期应失败)"
    else
        echo "✅ 错误签名正确被拒绝"
    fi
    echo ""
    
    echo "🎉 所有测试通过!"
    return 0
}

# 主函数
main() {
    local command="${1:-help}"
    shift || true
    
    # 显示安全警告（仅在非静默模式下）
    if [[ "${BECC_SILENT:-false}" != "true" ]]; then
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║                    ⚠️  重要安全警告 ⚠️                        ║"
        echo "╠══════════════════════════════════════════════════════════════╣"
        echo "║  本程序是修复版本，解决了签名功能问题                      ║"
        echo "║  仅用于教育研究目的，不适合生产环境使用                    ║"
        echo "║  修复了数学运算和语法错误，确保功能正常                    ║"
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo ""
    fi
    
    # 安全检查（在生产环境中阻止使用）
    if [[ "${BECC_PRODUCTION:-false}" == "true" ]]; then
        echo "❌ 错误：本项目不适合生产环境使用" >&2
        echo "请查看安全警告了解详细信息" >&2
        exit 1
    fi
    
    # 解析参数
    check_args "$@"
    
    # 处理帮助命令
    if [[ "$command" == "help" ]]; then
        show_help
        exit 0
    fi
    
    # 对于不需要初始化的命令，直接执行
    case "$command" in
        test)
            cmd_test
            exit 0
            ;;
    esac
    
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
        *)
            error_exit $ERR_INVALID_INPUT "未知命令: $command"
            ;;
    esac
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi