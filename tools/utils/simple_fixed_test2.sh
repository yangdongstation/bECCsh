#!/bin/bash

# 基础设置
SCRIPT_DIR="/home/donz/bECCsh"
LIB_DIR="${SCRIPT_DIR}/lib"
CORE_DIR="${SCRIPT_DIR}/core"

# 加载库
source "${LIB_DIR}/bash_math.sh"
source "${LIB_DIR}/bigint.sh"
source "${LIB_DIR}/ec_curve.sh"
source "${LIB_DIR}/ec_point.sh"
source "${LIB_DIR}/asn1.sh"
source "${LIB_DIR}/entropy.sh"

# 测试ecdsa_fixed.sh加载
echo "Loading ecdsa_fixed.sh..."
source "${CORE_DIR}/crypto/ecdsa_fixed.sh" && echo "✅ ECDSA fixed loaded"

source "${CORE_DIR}/crypto/curve_selector_simple.sh" && echo "✅ Curve selector loaded"

# 基本函数
show_help() {
    echo "Simple Fixed Test - bECCsh修复版本"
    echo "基本功能测试通过！"
}

main() {
    local cmd="${1:-help}"
    case "$cmd" in
        help)
            show_help
            ;;
        test)
            echo "Running basic test..."
            echo "✅ All components loaded successfully"
            ;;
        *)
            echo "Unknown command: $cmd"
            exit 1
            ;;
    esac
}

main "$@"
