#!/bin/bash
# 椭圆曲线选择器
# 提供统一的曲线选择接口和参数管理

set -euo pipefail

# 脚本目录
CURVE_SELECTOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CURVES_DIR="${CURVE_SELECTOR_DIR}/../curves"

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
CURVE_ALIASES=(
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

# 曲线安全级别映射
CURVE_SECURITY_LEVELS=(
    ["secp192k1"]="96"
    ["secp224k1"]="112"
    ["secp256k1"]="128"
    ["secp256r1"]="128"
    ["brainpoolp256r1"]="128"
    ["secp384r1"]="192"
    ["brainpoolp384r1"]="192"
    ["secp521r1"]="256"
    ["brainpoolp512r1"]="256"
)

# 曲线用途描述
CURVE_DESCRIPTIONS=(
    ["secp192k1"]="轻量级应用、物联网设备、资源受限环境"
    ["secp224k1"]="比特币早期使用、中等安全级别应用"
    ["secp256k1"]="比特币、以太坊等加密货币标准"
    ["secp256r1"]="TLS 1.3、JWT、政府标准、通用加密"
    ["secp384r1"]="高安全性应用、政府加密、企业级安全"
    ["secp521r1"]="最高安全级别、长期保密、政府顶级机密"
    ["brainpoolp256r1"]="欧洲标准、高透明度应用"
    ["brainpoolp384r1"]="高安全性欧洲标准应用"
    ["brainpoolp512r1"]="最高安全级别欧洲标准应用"
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

# 获取曲线的安全级别
get_curve_security_level() {
    local curve_name="$1"
    local normalized_name
    normalized_name=$(normalize_curve_name "$curve_name")
    
    echo "${CURVE_SECURITY_LEVELS[$normalized_name]:-"unknown"}"
}

# 获取曲线描述
get_curve_description() {
    local curve_name="$1"
    local normalized_name
    normalized_name=$(normalize_curve_name "$curve_name")
    
    echo "${CURVE_DESCRIPTIONS[$normalized_name]:-"未知曲线"}"
}

# 列出所有支持的曲线
list_supported_curves() {
    echo "支持的椭圆曲线:"
    echo "=================="
    
    for curve in "${SUPPORTED_CURVES[@]}"; do
        local security_level=$(get_curve_security_level "$curve")
        local description=$(get_curve_description "$curve")
        printf "  %-20s [安全级别: %s位] - %s\n" "$curve" "$security_level" "$description"
    done
    
    echo ""
    echo "曲线别名:"
    echo "=========="
    for alias in "${!CURVE_ALIASES[@]}"; do
        printf "  %-15s -> %s\n" "$alias" "${CURVE_ALIASES[$alias]}"
    done
}

# 根据安全级别推荐曲线
recommend_curve_by_security() {
    local security_level="$1"
    local performance_req="${2:-"balanced"}"  # fast, balanced, secure
    
    case "$security_level" in
        "96"|"low")
            echo "secp192k1"
            ;;
        "112"|"medium-low")
            echo "secp224k1"
            ;;
        "128"|"medium")
            case "$performance_req" in
                "fast")
                    echo "secp256k1"
                    ;;
                "secure")
                    echo "secp256r1"
                    ;;
                *)
                    echo "secp256r1"
                    ;;
            esac
            ;;
        "192"|"high")
            case "$performance_req" in
                "secure")
                    echo "brainpoolp384r1"
                    ;;
                *)
                    echo "secp384r1"
                    ;;
            esac
            ;;
        "256"|"maximum")
            case "$performance_req" in
                "secure")
                    echo "brainpoolp512r1"
                    ;;
                *)
                    echo "secp521r1"
                    ;;
            esac
            ;;
        *)
            echo "secp256r1"  # 默认推荐
            ;;
    esac
}

# 根据用例推荐曲线
recommend_curve_by_use_case() {
    local use_case="$1"
    
    case "$(echo "$use_case" | tr '[:upper:]' '[:lower:]')" in
        "mobile"|"iot"|"embedded")
            echo "secp192k1"
            ;;
        "bitcoin"|"ethereum"|"crypto")
            echo "secp256k1"
            ;;
        "web"|"tls"|"jwt")
            echo "secp256r1"
            ;;
        "government"|"enterprise")
            echo "secp384r1"
            ;;
        "long-term"|"archive"|"maximum")
            echo "secp521r1"
            ;;
        "european"|"brainpool")
            echo "brainpoolp256r1"
            ;;
        *)
            echo "secp256r1"  # 默认推荐
            ;;
    esac
}

# 选择并加载曲线参数
select_curve() {
    local curve_name="$1"
    local normalized_name
    normalized_name=$(normalize_curve_name "$curve_name")
    
    # 检查曲线是否受支持
    if ! is_curve_supported "$normalized_name"; then
        echo "错误: 不支持的椭圆曲线 '$curve_name'" >&2
        echo "支持的曲线: ${SUPPORTED_CURVES[*]}" >&2
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
    CURRENT_CURVE="$normalized_name"
    
    return 0
}

# 获取当前曲线的参数
get_current_curve_params() {
    if [[ -z "${CURRENT_CURVE:-}" ]]; then
        echo "错误: 未选择任何椭圆曲线" >&2
        return 1
    fi
    
    case "$CURRENT_CURVE" in
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
            echo "错误: 未知的曲线 '$CURRENT_CURVE'" >&2
            return 1
            ;;
    esac
}

# 获取当前曲线的十六进制参数
get_current_curve_params_hex() {
    if [[ -z "${CURRENT_CURVE:-}" ]]; then
        echo "错误: 未选择任何椭圆曲线" >&2
        return 1
    fi
    
    case "$CURRENT_CURVE" in
        "secp256k1")
            get_secp256k1_params_hex
            ;;
        "secp256r1")
            get_secp256r1_params_hex
            ;;
        "secp384r1")
            get_secp384r1_params_hex
            ;;
        "secp521r1")
            get_secp521r1_params_hex
            ;;
        "secp224k1")
            get_secp224k1_params_hex
            ;;
        "secp192k1")
            get_secp192k1_params_hex
            ;;
        "brainpoolp256r1")
            get_brainpoolp256r1_params_hex
            ;;
        "brainpoolp384r1")
            get_brainpoolp384r1_params_hex
            ;;
        "brainpoolp512r1")
            get_brainpoolp512r1_params_hex
            ;;
        *)
            echo "错误: 未知的曲线 '$CURRENT_CURVE'" >&2
            return 1
            ;;
    esac
}

# 获取当前曲线的信息
get_current_curve_info() {
    if [[ -z "${CURRENT_CURVE:-}" ]]; then
        echo "错误: 未选择任何椭圆曲线" >&2
        return 1
    fi
    
    case "$CURRENT_CURVE" in
        "secp256k1")
            get_secp256k1_info
            ;;
        "secp256r1")
            get_secp256r1_info
            ;;
        "secp384r1")
            get_secp384r1_info
            ;;
        "secp521r1")
            get_secp521r1_info
            ;;
        "secp224k1")
            get_secp224k1_info
            ;;
        "secp192k1")
            get_secp192k1_info
            ;;
        "brainpoolp256r1"|"brainpoolp384r1"|"brainpoolp512r1")
            get_brainpool_info "$CURRENT_CURVE"
            ;;
        *)
            echo "错误: 未知的曲线 '$CURRENT_CURVE'" >&2
            return 1
            ;;
    esac
}

# 验证当前曲线参数
validate_current_curve() {
    if [[ -z "${CURRENT_CURVE:-}" ]]; then
        echo "错误: 未选择任何椭圆曲线" >&2
        return 1
    fi
    
    case "$CURRENT_CURVE" in
        "secp256k1")
            validate_secp256k1_params
            ;;
        "secp256r1")
            validate_secp256r1_params
            ;;
        "secp384r1")
            validate_secp384r1_params
            ;;
        "secp521r1")
            validate_secp521r1_params
            ;;
        "secp224k1")
            validate_secp224k1_params
            ;;
        "secp192k1")
            validate_secp192k1_params
            ;;
        *)
            echo "警告: 曲线 '$CURRENT_CURVE' 验证函数未实现" >&2
            return 0
            ;;
    esac
}

# 曲线选择器演示函数
demo_curve_selector() {
    echo "椭圆曲线选择器演示"
    echo "===================="
    echo ""
    
    # 列出所有支持的曲线
    list_supported_curves
    echo ""
    
    # 演示曲线选择
    local test_curves=("secp256k1" "secp256r1" "p-256" "bitcoin" "secp384r1")
    
    for curve in "${test_curves[@]}"; do
        echo "测试曲线选择: $curve"
        if select_curve "$curve"; then
            echo "✓ 成功选择曲线: $CURRENT_CURVE"
            echo "  安全级别: $(get_curve_security_level "$CURRENT_CURVE")位"
            echo "  描述: $(get_curve_description "$CURRENT_CURVE")"
            echo ""
        else
            echo "✗ 选择曲线失败: $curve"
            echo ""
        fi
    done
    
    # 演示推荐功能
    echo "智能曲线推荐演示:"
    echo "==================="
    
    local security_levels=("96" "128" "192" "256")
    for level in "${security_levels[@]}"; do
        echo "安全级别 $level 位推荐: $(recommend_curve_by_security "$level")"
    done
    
    echo ""
    local use_cases=("mobile" "bitcoin" "web" "government" "long-term")
    for use_case in "${use_cases[@]}"; do
        echo "用例 '$use_case' 推荐: $(recommend_curve_by_use_case "$use_case")"
    done
}

# 如果直接运行此脚本，执行演示
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    demo_curve_selector
fi