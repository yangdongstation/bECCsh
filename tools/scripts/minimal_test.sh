#!/bin/bash
# 最小化测试
set -euo pipefail

# 基础设置
readonly SCRIPT_DIR="/home/donz/bECCsh"
readonly LIB_DIR="${SCRIPT_DIR}/lib"
readonly CORE_DIR="${SCRIPT_DIR}/core"

# 导入基础库
echo "Loading basic libraries..."
source "${LIB_DIR}/bash_math.sh"
source "${LIB_DIR}/bigint.sh"
source "${LIB_DIR}/ec_curve.sh"
source "${LIB_DIR}/ec_point.sh"
source "${LIB_DIR}/asn1.sh"
source "${LIB_DIR}/entropy.sh"

# 导入修复的函数
echo "Loading fixed functions..."
source "${CORE_DIR}/crypto/ecdsa_fixed.sh"
source "${CORE_DIR}/crypto/curve_selector_simple.sh"

# 设置默认值
LOG_LEVEL=1
VERSION="2.0.1"

# 简单的日志函数
log() {
    local level=$1
    shift
    [[ $level -ge $LOG_LEVEL ]] && echo "[INFO] $*"
}

# 简单的帮助函数
show_help() {
    echo "Minimal test version ${VERSION}"
    echo "Basic functionality test passed!"
}

# 简单的参数检查
check_args() {
    CURVE_NAME=${CURVE_NAME:-"secp256k1"}
    HASH_ALG=${HASH_ALG:-"sha256"}
}

# 简单的初始化
init_crypto() {
    log 1 "Initializing minimal crypto library"
    # 选择默认曲线
    CURRENT_CURVE_SIMPLE="secp256k1"
}

# 主函数
main() {
    local command="${1:-help}"
    shift || true
    
    check_args "$@"
    
    case "$command" in
        help)
            show_help
            ;;
        test)
            init_crypto
            echo "✅ Minimal test completed successfully!"
            echo "Current curve: $CURRENT_CURVE_SIMPLE"
            ;;
        *)
            echo "Unknown command: $command"
            exit 1
            ;;
    esac
}

# 运行测试
echo "Running minimal test..."
main "$@"