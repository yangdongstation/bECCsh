#!/bin/bash
# 简化的椭圆曲线选择器
# 避免变量冲突的版本

set -euo pipefail

# 脚本目录
CURVE_SELECTOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURVES_DIR="${CURVE_SELECTOR_DIR}/../curves"

# 支持的椭圆曲线列表
SUPPORTED_CURVES=(
    "secp256k1"
    "secp256r1"
    "secp384r1"
    "secp521r1"
    "secp224k1"
    "secp192k1"
    "brainpoolp256r1"
    "brainpoolp384r1"
    "brainpoolp512r1"
)

# 曲线别名映射
declare -A CURVE_ALIASES=(
    ["p-256"]="secp256r1"
    ["prime256v1"]="secp256r1"
    ["p-384"]="secp384r1"
    ["prime384v1"]="secp384r1"
    ["p-521"]="secp521r1"
    ["prime521v1"]="secp521r1"
    ["btc"]="secp256k1"
    ["bitcoin"]="secp256k1"
    ["ethereum"]="secp256k1"
)

# 标准化曲线名称
normalize_curve_name() {
    local curve_name="$1"
    local normalized_name
    
    # 转换为小写
    normalized_name=$(echo "$curve_name" | tr '[:upper:]' '[:lower:]')
    
    # 检查是否有别名映射
    if [[ -n "${CURVE_ALIASES[$normalized_name]:-}" ]]; then
        echo "${CURVE_ALIASES[$normalized_name]}"
    else
        echo "$normalized_name"
    fi
}

# 检查曲线是否受支持
is_curve_supported() {
    local curve_name="$1"
    local normalized_name
    normalized_name=$(normalize_curve_name "$curve_name")
    
    for supported_curve in "${SUPPORTED_CURVES[@]}"; do
        if [[ "$supported_curve" == "$normalized_name" ]]; then
            return 0
        fi
    done
    
    return 1
}

# 选择并加载曲线参数
select_curve_simple() {
    local curve_name="$1"
    local normalized_name
    normalized_name=$(normalize_curve_name "$curve_name")
    
    # 检查曲线是否受支持
    if ! is_curve_supported "$normalized_name"; then
        echo "错误: 不支持的椭圆曲线 '$curve_name'" >&2
        return 1
    fi
    
    # 加载对应的参数文件
    case "$normalized_name" in
        "secp256k1")
            source "${CURVES_DIR}/secp256k1_params.sh"
            ;;
        "secp256r1")
            source "${CURVES_DIR}/secp256r1_params.sh"
            ;;
        "secp384r1")
            source "${CURVES_DIR}/secp384r1_params.sh"
            ;;
        "secp521r1")
            source "${CURVES_DIR}/secp521r1_params.sh"
            ;;
        "secp224k1")
            source "${CURVES_DIR}/secp224k1_params.sh"
            ;;
        "secp192k1")
            source "${CURVES_DIR}/secp192k1_params.sh"
            ;;
        "brainpoolp256r1")
            source "${CURVES_DIR}/brainpool_params.sh"
            ;;
        "brainpoolp384r1")
            source "${CURVES_DIR}/brainpool_params.sh"
            ;;
        "brainpoolp512r1")
            source "${CURVES_DIR}/brainpool_params.sh"
            ;;
        *)
            echo "错误: 曲线 '$normalized_name' 参数文件未实现" >&2
            return 1
            ;;
    esac
    
    # 设置当前曲线名称
    CURRENT_CURVE_SIMPLE="$normalized_name"
    
    return 0
}

# 获取当前曲线的参数
get_current_curve_params_simple() {
    if [[ -z "${CURRENT_CURVE_SIMPLE:-}" ]]; then
        echo "错误: 未选择任何椭圆曲线" >&2
        return 1
    fi
    
    case "$CURRENT_CURVE_SIMPLE" in
        "secp256k1")
            get_secp256k1_params
            ;;
        "secp256r1")
            get_secp256r1_params
            ;;
        "secp384r1")
            get_secp384r1_params
            ;;
        "secp521r1")
            get_secp521r1_params
            ;;
        "secp224k1")
            get_secp224k1_params
            ;;
        "secp192k1")
            get_secp192k1_params
            ;;
        "brainpoolp256r1")
            get_brainpoolp256r1_params
            ;;
        "brainpoolp384r1")
            get_brainpoolp384r1_params
            ;;
        "brainpoolp512r1")
            get_brainpoolp512r1_params
            ;;
        *)
            echo "错误: 未知的曲线 '$CURRENT_CURVE_SIMPLE'" >&2
            return 1
            ;;
    esac
}

# 简单的演示函数
demo_curve_selector_simple() {
    echo "简化椭圆曲线选择器演示"
    echo "======================="
    echo ""
    
    echo "支持的曲线: ${SUPPORTED_CURVES[*]}"
    echo ""
    
    # 测试几个曲线
    local test_curves=("secp256k1" "secp256r1" "p-256" "bitcoin")
    
    for curve in "${test_curves[@]}"; do
        echo "测试曲线: $curve"
        if select_curve_simple "$curve"; then
            echo "✓ 成功选择曲线: $CURRENT_CURVE_SIMPLE"
            local params=$(get_current_curve_params_simple)
            echo "  参数: $params"
        else
            echo "✗ 选择曲线失败: $curve"
        fi
        echo ""
    done
}

# 如果直接运行此脚本，执行演示
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    demo_curve_selector_simple
fi