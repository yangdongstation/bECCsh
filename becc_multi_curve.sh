#!/bin/bash
# bECCsh - 纯Bash椭圆曲线密码学实现 (多曲线支持版)
# 版本: 2.0.0 (Multi-Curve Edition)
# 作者: AI Assistant
# 许可证: MIT
# 
# 这是一个完全用Bash实现的椭圆曲线密码学库，支持ECDSA签名和验证。
# 支持多种椭圆曲线算法，包括NIST标准、Koblitz曲线和Brainpool系列。
#
# 特性:
# - 纯Bash实现，无外部依赖
# - 支持9种标准椭圆曲线
# - 智能曲线选择和推荐
# - 完整的ECDSA签名和验证
# - RFC 6979确定性k值生成
# - 侧信道攻击防护
# - ASN.1 DER编码
# - 企业级错误处理

set -euo pipefail

# 版本信息
readonly VERSION="2.0.0"
readonly BUILD_DATE="2025-12-04"

# 全局配置
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR="${SCRIPT_DIR}/lib"
readonly CORE_DIR="${SCRIPT_DIR}/core"

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
source "${SCRIPT_DIR}/tools/security_functions.sh" 2>/dev/null || {
    echo "警告: 无法加载安全功能模块" >&2
}

# 导入多曲线支持
source "${CORE_DIR}/crypto/curve_selector.sh"

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

# 全局曲线配置
CURRENT_CURVE=""

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
bECCsh - 纯Bash椭圆曲线密码学实现 v${VERSION} (多曲线支持版)

使用方法: $0 [命令] [选项]

命令:
    keygen      生成ECDSA密钥对
    sign        对消息进行ECDSA签名
    verify      验证ECDSA签名
    test        运行测试套件
    benchmark   性能基准测试
    curves      显示支持的曲线信息
    recommend   智能曲线推荐
    help        显示此帮助信息

选项:
    -c, --curve CURVE       选择椭圆曲线 (支持9种标准曲线)
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
    secp384r1      - NIST P-384, 高安全性 (192位安全)
    secp521r1      - NIST P-521, 最高安全性 (256位安全)
    secp224k1      - Koblitz曲线, 中等安全 (112位安全)
    secp192k1      - Koblitz曲线, 轻量级应用 (96位安全)
    brainpoolp256r1 - 欧洲标准, 高透明度 (128位安全)
    brainpoolp384r1 - 欧洲标准, 高安全性 (192位安全)
    brainpoolp512r1 - 欧洲标准, 最高安全 (256位安全)

曲线别名:
    p-256, prime256v1 -> secp256r1
    p-384, prime384v1 -> secp384r1
    p-521, prime521v1 -> secp521r1
    btc, bitcoin      -> secp256k1
    ethereum          -> secp256k1

示例:
    # 生成密钥对 (默认使用secp256r1)
    $0 keygen -f private_key.pem
    
    # 使用比特币曲线生成密钥对
    $0 keygen -c secp256k1 -f bitcoin_key.pem
    
    # 使用高安全性曲线
    $0 keygen -c secp521r1 -f high_security_key.pem
    
    # 签名消息
    $0 sign -c secp256r1 -k private_key.pem -m "Hello World" -f signature.der
    
    # 验证签名
    $0 verify -c secp256r1 -k public_key.pem -m "Hello World" -s signature.der
    
    # 显示所有支持的曲线
    $0 curves
    
    # 智能曲线推荐
    $0 recommend --security 128 --performance balanced
    
    # 运行多曲线测试
    $0 test
    
    # 性能基准测试
    $0 benchmark -c secp256r1 -n 100

安全警告:
    这是一个纯Bash实现的密码学库，主要用于教育和研究目的。
    在生产环境中，请使用经过充分测试的密码学库。

EOF
}

# 显示详细的曲线信息
show_curves_info() {
    cat << EOF
bECCsh 支持的椭圆曲线详细信息
=====================================

EOF
    
    # 列出所有支持的曲线
    list_supported_curves
    
    echo ""
    echo "安全级别分类:"
    echo "=============="
    echo "96位  - 轻量级安全 (物联网、移动设备)"
    echo "112位 - 中等安全 (传统应用兼容)"
    echo "128位 - 标准安全 (现代应用推荐)"
    echo "192位 - 高安全级别 (企业、政府)"
    echo "256位 - 最高安全级别 (长期保密、顶级机密)"
    
    echo ""
    echo "性能特征:"
    echo "=========="
    echo "Koblitz曲线 (secp192k1, secp224k1, secp256k1): 计算效率高"
    echo "NIST曲线 (secp256r1, secp384r1, secp521r1): 广泛支持，标准兼容"
    echo "Brainpool曲线: 参数生成透明，欧洲标准"
    
    echo ""
    echo "用例推荐:"
    echo "=========="
    echo "加密货币: secp256k1 (比特币、以太坊标准)"
    echo "Web/TLS:  secp256r1 (TLS 1.3、JWT标准)"
    echo "移动/IoT: secp192k1 (轻量级、低功耗)"
    echo "企业应用: secp384r1 (高安全性、政府标准)"
    echo "长期存档: secp521r1 (最高安全级别)"
    echo "欧洲标准: brainpoolp256r1 (透明度要求高)"
}

# 智能曲线推荐
show_recommendations() {
    local security_level="${1:-""}"
    local performance="${2:-"balanced"}"
    local use_case="${3:-""}"
    
    cat << EOF
智能椭圆曲线推荐
==================

EOF
    
    if [[ -n "$security_level" ]]; then
        echo "基于安全级别推荐 (${security_level}位):"
        local recommended_curve=$(recommend_curve_by_security "$security_level" "$performance")
        echo "  推荐曲线: $recommended_curve"
        echo "  描述: $(get_curve_description "$recommended_curve")"
        echo ""
    fi
    
    if [[ -n "$use_case" ]]; then
        echo "基于用例推荐 (${use_case}):"
        local recommended_curve=$(recommend_curve_by_use_case "$use_case")
        echo "  推荐曲线: $recommended_curve"
        echo "  描述: $(get_curve_description "$recommended_curve")"
        echo ""
    fi
    
    if [[ -z "$security_level" && -z "$use_case" ]]; then
        echo "通用推荐方案:"
        echo "=============="
        
        echo ""
        echo "现代Web应用:"
        echo "  推荐: secp256r1"
        echo "  原因: TLS 1.3标准，广泛支持"
        
        echo ""
        echo "加密货币:"
        echo "  推荐: secp256k1"
        echo "  原因: 比特币、以太坊标准"
        
        echo ""
        echo "移动/物联网:"
        echo "  推荐: secp192k1"
        echo "  原因: 轻量级，计算效率高"
        
        echo ""
        echo "企业级应用:"
        echo "  推荐: secp384r1"
        echo "  原因: 高安全性，政府标准"
        
        echo ""
        echo "长期存档:"
        echo "  推荐: secp521r1"
        echo "  原因: 最高安全级别"
        
        echo ""
        echo "欧洲标准应用:"
        echo "  推荐: brainpoolp256r1"
        echo "  原因: 参数透明，符合欧洲标准"
    fi
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
            --security)
                SECURITY_LEVEL="$2"
                shift 2
                ;;
            --performance)
                PERFORMANCE_REQ="$2"
                shift 2
                ;;
            --use-case)
                USE_CASE="$2"
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
    SECURITY_LEVEL=${SECURITY_LEVEL:-""}
    PERFORMANCE_REQ=${PERFORMANCE_REQ:-"balanced"}
    USE_CASE=${USE_CASE:-""}
}

# 初始化密码学库
init_crypto() {
    log $LOG_INFO "初始化bECCsh多曲线密码学库 v${VERSION}"
    
    # 选择并加载曲线
    if ! select_curve "$CURVE_NAME"; then
        error_exit $ERR_INVALID_CURVE "曲线选择失败: $CURVE_NAME"
    fi
    
    # 验证当前曲线参数
    if ! validate_current_curve; then
        error_exit $ERR_CRYPTO_OPERATION "曲线参数验证失败"
    fi
    
    # 显示当前曲线信息
    log $LOG_INFO "已选择椭圆曲线: $CURRENT_CURVE"
    log $LOG_INFO "安全级别: $(get_curve_security_level "$CURRENT_CURVE")位"
    log $LOG_INFO "描述: $(get_curve_description "$CURRENT_CURVE")"
    
    # 初始化随机数生成器
    if ! entropy_init; then
        error_exit $ERR_CRYPTO_OPERATION "熵源初始化失败"
    fi
    
    log $LOG_INFO "密码学库初始化完成"
}

# 生成密钥对
cmd_keygen() {
    log $LOG_INFO "生成ECDSA密钥对 (曲线: $CURRENT_CURVE)"
    
    # 获取当前曲线参数
    local curve_params
    curve_params=$(get_current_curve_params)
    if [[ $? -ne 0 ]]; then
        error_exit $ERR_CRYPTO_OPERATION "获取曲线参数失败"
    fi
    
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
    
    log $LOG_INFO "签名消息 (曲线: $CURRENT_CURVE, 哈希: $HASH_ALG)"
    
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
    if ! ecdsa_sign "$private_key" "$message_hash" "$CURRENT_CURVE" "$HASH_ALG"; then
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
    
    log $LOG_INFO "验证签名 (曲线: $CURRENT_CURVE, 哈希: $HASH_ALG)"
    
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
    if ecdsa_verify "$public_key" "$message_hash" "$signature_r" "$signature_s" "$CURRENT_CURVE" "$HASH_ALG"; then
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
    log $LOG_INFO "运行bECCsh多曲线测试套件"
    
    local test_script="${SCRIPT_DIR}/test_multi_curve.sh"
    if [[ -f "$test_script" ]]; then
        bash "$test_script" -v
    else
        log $LOG_WARN "多曲线测试套件未找到，运行基本测试"
        
        # 基本功能测试
        local test_curves=("secp256r1" "secp256k1" "secp384r1")
        local test_passed=0
        local test_failed=0
        
        for curve in "${test_curves[@]}"; do
            log $LOG_INFO "测试曲线: $curve"
            
            # 选择曲线
            if ! select_curve "$curve"; then
                log $LOG_ERROR "曲线选择失败: $curve"
                ((test_failed++))
                continue
            fi
            
            # 生成测试密钥
            local test_private_key test_public_key
            test_private_key=$(ecdsa_generate_private_key)
            test_public_key=$(ecdsa_get_public_key "$test_private_key")
            
            # 测试消息
            local test_message="Hello, bECCsh Multi-Curve!"
            
            # 计算哈希
            local test_hash
            test_hash=$(hash_message "$test_message" "$HASH_ALG")
            
            # 签名
            if ecdsa_sign "$test_private_key" "$test_hash" "$curve" "$HASH_ALG"; then
                local test_signature_r=${ECDSA_SIGNATURE_R:-}
                local test_signature_s=${ECDSA_SIGNATURE_S:-}
                
                # 验证
                if ecdsa_verify "$test_public_key" "$test_hash" "$test_signature_r" "$test_signature_s" "$curve" "$HASH_ALG"; then
                    log $LOG_INFO "曲线 $curve 测试通过"
                    ((test_passed++))
                else
                    log $LOG_ERROR "曲线 $curve 签名验证失败"
                    ((test_failed++))
                fi
            else
                log $LOG_ERROR "曲线 $curve 签名生成失败"
                ((test_failed++))
            fi
        done
        
        log $LOG_INFO "测试完成: 通过 $test_passed, 失败 $test_failed"
        
        if [[ $test_failed -eq 0 ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# 性能基准测试
cmd_benchmark() {
    local iterations=${1:-100}
    
    log $LOG_INFO "运行性能基准测试 (迭代次数: $iterations, 曲线: $CURRENT_CURVE)"
    
    local start_time end_time duration
    local i success_count=0
    
    start_time=$(date +%s.%N)
    
    for ((i=1; i<=iterations; i++)); do
        # 生成密钥对
        local private_key public_key
        private_key=$(ecdsa_generate_private_key)
        public_key=$(ecdsa_get_public_key "$private_key")
        
        # 签名
        local message="Multi-curve benchmark test $i"
        local message_hash
        message_hash=$(hash_message "$message" "$HASH_ALG")
        
        if ecdsa_sign "$private_key" "$message_hash" "$CURRENT_CURVE" "$HASH_ALG"; then
            local sig_r=${ECDSA_SIGNATURE_R:-}
            local sig_s=${ECDSA_SIGNATURE_S:-}
            
            # 验证
            if ecdsa_verify "$public_key" "$message_hash" "$sig_r" "$sig_s" "$CURRENT_CURVE" "$HASH_ALG"; then
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
    log $LOG_INFO "多曲线基准测试完成"
    echo "曲线: $CURRENT_CURVE"
    echo "总时间: ${duration}s"
    echo "操作次数: $iterations"
    echo "成功次数: $success_count"
    echo "平均时间: $(bashmath_divide_float "$duration" "$iterations" 6)s"
    echo "操作/秒: $(bashmath_divide_float "$iterations" "$duration" 6)"
}

# 显示曲线信息
cmd_curves() {
    show_curves_info
}

# 智能推荐
cmd_recommend() {
    show_recommendations "$SECURITY_LEVEL" "$PERFORMANCE_REQ" "$USE_CASE"
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
    check_args "$@"
    
    # 处理帮助命令
    if [[ "$command" == "help" ]]; then
        show_help
        exit 0
    fi
    
    # 对于不需要初始化的命令，直接执行
    case "$command" in
        curves)
            cmd_curves
            exit 0
            ;;
        recommend)
            cmd_recommend
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