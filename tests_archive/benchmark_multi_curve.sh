#!/bin/bash
# 多椭圆曲线性能基准测试脚本
# 对不同椭圆曲线进行性能比较和分析

set -euo pipefail

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
core_dir="$SCRIPT_DIR/core"

# 颜色输出
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# 测试配置
DEFAULT_ITERATIONS=100
ITERATIONS=${ITERATIONS:-$DEFAULT_ITERATIONS}
WARMUP_ITERATIONS=10

# 要测试的曲线列表
BENCHMARK_CURVES=(
    "secp192k1"
    "secp224k1"
    "secp256k1"
    "secp256r1"
    "secp384r1"
    "secp521r1"
    "brainpoolp256r1"
    "brainpoolp384r1"
    "brainpoolp512r1"
)

# 测试结果存储
declare -A KEYGEN_TIMES
declare -A SIGN_TIMES
declare -A VERIFY_TIMES
declare -A SIGN_SIZES
declare -A SUCCESS_RATES

# 打印标题
print_header() {
    echo -e "${CYAN}"
    echo "========================================"
    echo "bECCsh 多椭圆曲线性能基准测试"
    echo "========================================"
    echo -e "${NC}"
    echo "测试配置:"
    echo "  迭代次数: $ITERATIONS"
    echo "  预热次数: $WARMUP_ITERATIONS"
    echo "  测试曲线: ${BENCHMARK_CURVES[*]}"
    echo ""
}

# 获取当前时间（纳秒精度）
get_time_ns() {
    date +%s%N
}

# 计算时间差（毫秒）
calculate_duration_ms() {
    local start_ns=$1
    local end_ns=$2
    
    # 计算毫秒差值
    local duration_ns=$((end_ns - start_ns))
    local duration_ms=$((duration_ns / 1000000))
    
    echo "$duration_ms"
}

# 测试密钥生成性能
benchmark_keygen() {
    local curve=$1
    local iterations=$2
    
    echo -e "${YELLOW}测试 $curve 密钥生成性能...${NC}"
    
    # 预热
    for ((i=1; i<=WARMUP_ITERATIONS; i++)); do
        "$SCRIPT_DIR/becc.sh" keygen -c "$curve" -f "/tmp/bench_${curve}_warmup_${i}.pem" 2>/dev/null
        rm -f "/tmp/bench_${curve}_warmup_${i}.pem" "/tmp/bench_${curve}_warmup_${i}_public.pem"
    done
    
    # 正式测试
    local total_time_ms=0
    local success_count=0
    
    for ((i=1; i<=iterations; i++)); do
        local start_time end_time duration_ms
        
        start_time=$(get_time_ns)
        
        if "$SCRIPT_DIR/becc.sh" keygen -c "$curve" -f "/tmp/bench_${curve}_${i}.pem" 2>/dev/null; then
            end_time=$(get_time_ns)
            duration_ms=$(calculate_duration_ms $start_time $end_time)
            total_time_ms=$((total_time_ms + duration_ms))
            ((success_count++))
            
            # 清理生成的文件
            rm -f "/tmp/bench_${curve}_${i}.pem" "/tmp/bench_${curve}_${i}_public.pem"
        fi
        
        # 显示进度
        if [[ $((i % 10)) -eq 0 ]]; then
            printf "\r  进度: %d/%d (%.1f%%)" $i $iterations $((i * 100 / iterations))
        fi
    done
    
    echo -e "\r\033[K"  # 清除进度行
    
    # 计算平均时间
    if [[ $success_count -gt 0 ]]; then
        local avg_time_ms=$((total_time_ms / success_count))
        KEYGEN_TIMES["$curve"]=$avg_time_ms
        SUCCESS_RATES["${curve}_keygen"]=$((success_count * 100 / iterations))
        
        echo -e "  ${GREEN}✓${NC} 平均密钥生成时间: ${avg_time_ms}ms (成功率: ${SUCCESS_RATES["${curve}_keygen"]}%)"
    else
        echo -e "  ${RED}✗${NC} 密钥生成测试失败"
        KEYGEN_TIMES["$curve"]=999999
        SUCCESS_RATES["${curve}_keygen"]=0
    fi
}

# 测试签名性能
benchmark_sign() {
    local curve=$1
    local iterations=$2
    local test_message="bECCsh Performance Benchmark Test Message"
    
    echo -e "${YELLOW}测试 $curve 签名性能...${NC}"
    
    # 首先生成测试密钥对
    local test_key="/tmp/bench_${curve}_sign_key.pem"
    if ! "$SCRIPT_DIR/becc.sh" keygen -c "$curve" -f "$test_key" 2>/dev/null; then
        echo -e "  ${RED}✗${NC} 测试密钥生成失败"
        SIGN_TIMES["$curve"]=999999
        SUCCESS_RATES["${curve}_sign"]=0
        return 1
    fi
    
    # 预热
    for ((i=1; i<=WARMUP_ITERATIONS; i++)); do
        "$SCRIPT_DIR/becc.sh" sign -c "$curve" -k "$test_key" -m "$test_message" 2>/dev/null
    done
    
    # 正式测试
    local total_time_ms=0
    local success_count=0
    local signature_size=0
    
    for ((i=1; i<=iterations; i++)); do
        local start_time end_time duration_ms
        
        start_time=$(get_time_ns)
        
        local signature_file="/tmp/bench_${curve}_sign_${i}.sig"
        if "$SCRIPT_DIR/becc.sh" sign -c "$curve" -k "$test_key" -m "$test_message" -f "$signature_file" 2>/dev/null; then
            end_time=$(get_time_ns)
            duration_ms=$(calculate_duration_ms $start_time $end_time)
            total_time_ms=$((total_time_ms + duration_ms))
            ((success_count++))
            
            # 记录签名大小（仅第一次成功）
            if [[ $success_count -eq 1 ]] && [[ -f "$signature_file" ]]; then
                signature_size=$(stat -f%z "$signature_file" 2>/dev/null || stat -c%s "$signature_file" 2>/dev/null || echo "0")
            fi
            
            # 清理签名文件
            rm -f "$signature_file"
        fi
        
        # 显示进度
        if [[ $((i % 10)) -eq 0 ]]; then
            printf "\r  进度: %d/%d (%.1f%%)" $i $iterations $((i * 100 / iterations))
        fi
    done
    
    echo -e "\r\033[K"  # 清除进度行
    
    # 计算平均时间
    if [[ $success_count -gt 0 ]]; then
        local avg_time_ms=$((total_time_ms / success_count))
        SIGN_TIMES["$curve"]=$avg_time_ms
        SIGN_SIZES["$curve"]=$signature_size
        SUCCESS_RATES["${curve}_sign"]=$((success_count * 100 / iterations))
        
        echo -e "  ${GREEN}✓${NC} 平均签名时间: ${avg_time_ms}ms (成功率: ${SUCCESS_RATES["${curve}_sign"]}%, 签名大小: ${signature_size}字节)"
    else
        echo -e "  ${RED}✗${NC} 签名测试失败"
        SIGN_TIMES["$curve"]=999999
        SUCCESS_RATES["${curve}_sign"]=0
    fi
    
    # 清理测试密钥
    rm -f "$test_key" "${test_key%.pem}_public.pem"
}

# 测试签名验证性能
benchmark_verify() {
    local curve=$1
    local iterations=$2
    local test_message="bECCsh Performance Benchmark Test Message"
    
    echo -e "${YELLOW}测试 $curve 签名验证性能...${NC}"
    
    # 首先生成测试密钥对和签名
    local test_key="/tmp/bench_${curve}_verify_key.pem"
    local test_sig="/tmp/bench_${curve}_verify.sig"
    
    if ! "$SCRIPT_DIR/becc.sh" keygen -c "$curve" -f "$test_key" 2>/dev/null; then
        echo -e "  ${RED}✗${NC} 测试密钥生成失败"
        VERIFY_TIMES["$curve"]=999999
        SUCCESS_RATES["${curve}_verify"]=0
        return 1
    fi
    
    if ! "$SCRIPT_DIR/becc.sh" sign -c "$curve" -k "$test_key" -m "$test_message" -f "$test_sig" 2>/dev/null; then
        echo -e "  ${RED}✗${NC} 测试签名生成失败"
        VERIFY_TIMES["$curve"]=999999
        SUCCESS_RATES["${curve}_verify"]=0
        rm -f "$test_key" "${test_key%.pem}_public.pem"
        return 1
    fi
    
    # 预热
    for ((i=1; i<=WARMUP_ITERATIONS; i++)); do
        "$SCRIPT_DIR/becc.sh" verify -c "$curve" -k "${test_key%.pem}_public.pem" -m "$test_message" -s "$test_sig" 2>/dev/null
    done
    
    # 正式测试
    local total_time_ms=0
    local success_count=0
    
    for ((i=1; i<=iterations; i++)); do
        local start_time end_time duration_ms
        
        start_time=$(get_time_ns)
        
        if "$SCRIPT_DIR/becc.sh" verify -c "$curve" -k "${test_key%.pem}_public.pem" -m "$test_message" -s "$test_sig" 2>/dev/null | grep -q "VALID"; then
            end_time=$(get_time_ns)
            duration_ms=$(calculate_duration_ms $start_time $end_time)
            total_time_ms=$((total_time_ms + duration_ms))
            ((success_count++))
        fi
        
        # 显示进度
        if [[ $((i % 10)) -eq 0 ]]; then
            printf "\r  进度: %d/%d (%.1f%%)" $i $iterations $((i * 100 / iterations))
        fi
    done
    
    echo -e "\r\033[K"  # 清除进度行
    
    # 计算平均时间
    if [[ $success_count -gt 0 ]]; then
        local avg_time_ms=$((total_time_ms / success_count))
        VERIFY_TIMES["$curve"]=$avg_time_ms
        SUCCESS_RATES["${curve}_verify"]=$((success_count * 100 / iterations))
        
        echo -e "  ${GREEN}✓${NC} 平均验证时间: ${avg_time_ms}ms (成功率: ${SUCCESS_RATES["${curve}_verify"]}%)"
    else
        echo -e "  ${RED}✗${NC} 签名验证测试失败"
        VERIFY_TIMES["$curve"]=999999
        SUCCESS_RATES["${curve}_verify"]=0
    fi
    
    # 清理测试文件
    rm -f "$test_key" "${test_key%.pem}_public.pem" "$test_sig"
}

# 运行完整的基准测试
run_benchmark() {
    local curve=$1
    local iterations=$2
    
    echo -e "${BLUE}开始测试 $curve ...${NC}"
    
    benchmark_keygen "$curve" "$iterations"
    benchmark_sign "$curve" "$iterations"
    benchmark_verify "$curve" "$iterations"
    
    echo ""
}

# 生成性能报告
generate_report() {
    echo -e "${CYAN}"
    echo "========================================"
    echo "性能基准测试报告"
    echo "========================================"
    echo -e "${NC}"
    
    # 创建表格格式输出
    printf "${WHITE}%-20s %15s %15s %15s %12s %10s${NC}\n" \
        "曲线" "密钥生成(ms)" "签名(ms)" "验证(ms)" "签名大小(B)" "成功率(%)"
    
    echo "-----------------------------------------------------------------------------------------"
    
    for curve in "${BENCHMARK_CURVES[@]}"; do
        local keygen_time=${KEYGEN_TIMES["$curve"]:-999}
        local sign_time=${SIGN_TIMES["$curve"]:-999}
        local verify_time=${VERIFY_TIMES["$curve"]:-999}
        local sign_size=${SIGN_SIZES["$curve"]:-0}
        local keygen_rate=${SUCCESS_RATES["${curve}_keygen"]:-0}
        local sign_rate=${SUCCESS_RATES["${curve}_sign"]:-0}
        local verify_rate=${SUCCESS_RATES["${curve}_verify"]:-0}
        local avg_rate=$(( (keygen_rate + sign_rate + verify_rate) / 3 ))
        
        # 根据性能设置颜色
        local color="${GREEN}"
        if [[ $avg_rate -lt 80 ]]; then
            color="${RED}"
        elif [[ $avg_rate -lt 95 ]]; then
            color="${YELLOW}"
        fi
        
        printf "${color}%-20s %15d %15d %15d %12d %10d${NC}\n" \
            "$curve" "$keygen_time" "$sign_time" "$verify_time" "$sign_size" "$avg_rate"
    done
    
    echo ""
    echo "性能分析:"
    echo "---------"
    
    # 找出最快和最慢的曲线
    local fastest_keygen="" fastest_sign="" fastest_verify=""
    local slowest_keygen="" slowest_sign="" slowest_verify=""
    local min_keygen=999999 min_sign=999999 min_verify=999999
    local max_keygen=0 max_sign=0 max_verify=0
    
    for curve in "${BENCHMARK_CURVES[@]}"; do
        local keygen_time=${KEYGEN_TIMES["$curve"]:-999}
        local sign_time=${SIGN_TIMES["$curve"]:-999}
        local verify_time=${VERIFY_TIMES["$curve"]:-999}
        
        # 密钥生成
        if [[ $keygen_time -lt $min_keygen ]]; then
            min_keygen=$keygen_time
            fastest_keygen=$curve
        fi
        if [[ $keygen_time -gt $max_keygen ]]; then
            max_keygen=$keygen_time
            slowest_keygen=$curve
        fi
        
        # 签名
        if [[ $sign_time -lt $min_sign ]]; then
            min_sign=$sign_time
            fastest_sign=$curve
        fi
        if [[ $sign_time -gt $max_sign ]]; then
            max_sign=$sign_time
            slowest_sign=$curve
        fi
        
        # 验证
        if [[ $verify_time -lt $min_verify ]]; then
            min_verify=$verify_time
            fastest_verify=$curve
        fi
        if [[ $verify_time -gt $max_verify ]]; then
            max_verify=$verify_time
            slowest_verify=$curve
        fi
    done
    
    echo "最快密钥生成: $fastest_keygen (${min_keygen}ms)"
    echo "最快签名: $fastest_sign (${min_sign}ms)"
    echo "最快验证: $fastest_verify (${min_verify}ms)"
    echo ""
    echo "最慢密钥生成: $slowest_keygen (${max_keygen}ms)"
    echo "最慢签名: $slowest_sign (${max_sign}ms)"
    echo "最慢验证: $slowest_verify (${max_verify}ms)"
    
    echo ""
    echo "推荐:"
    echo "------"
    echo "性能优先: $fastest_sign (签名), $fastest_verify (验证)"
    echo "安全性优先: secp521r1 (256位安全级别)"
    echo "平衡选择: secp256r1 (128位安全级别，良好性能)"
    echo "移动/IoT: secp192k1 (轻量级，低功耗)"
    echo "加密货币: secp256k1 (比特币/以太坊标准)"
}

# 保存测试结果到文件
save_results() {
    local output_file="${1:-benchmark_results.txt}"
    
    {
        echo "bECCsh 多椭圆曲线性能基准测试结果"
        echo "======================================"
        echo "测试时间: $(date)"
        echo "迭代次数: $ITERATIONS"
        echo ""
        
        echo "详细结果:"
        echo "---------"
        for curve in "${BENCHMARK_CURVES[@]}"; do
            echo "曲线: $curve"
            echo "  密钥生成时间: ${KEYGEN_TIMES["$curve"]:-N/A}ms"
            echo "  签名时间: ${SIGN_TIMES["$curve"]:-N/A}ms"
            echo "  验证时间: ${VERIFY_TIMES["$curve"]:-N/A}ms"
            echo "  签名大小: ${SIGN_SIZES["$curve"]:-N/A}字节"
            echo "  成功率: ${SUCCESS_RATES["${curve}_keygen"]:-0}%/${SUCCESS_RATES["${curve}_sign"]:-0}%/${SUCCESS_RATES["${curve}_verify"]:-0}%"
            echo ""
        done
    } > "$output_file"
    
    echo -e "${GREEN}测试结果已保存到: $output_file${NC}"
}

# 主函数
main() {
    local specific_curve=""
    local output_file=""
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--curve)
                specific_curve="$2"
                shift 2
                ;;
            -n|--iterations)
                ITERATIONS="$2"
                shift 2
                ;;
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -h|--help)
                echo "用法: $0 [选项]"
                echo "选项:"
                echo "  -c, --curve CURVE     测试特定曲线"
                echo "  -n, --iterations N    设置迭代次数 (默认: $DEFAULT_ITERATIONS)"
                echo "  -o, --output FILE     保存结果到文件"
                echo "  -h, --help           显示帮助信息"
                exit 0
                ;;
            *)
                echo "未知选项: $1"
                exit 1
                ;;
        esac
    done
    
    # 打印标题
    print_header
    
    # 确定要测试的曲线
    local test_curves=()
    if [[ -n "$specific_curve" ]]; then
        test_curves=("$specific_curve")
    else
        test_curves=("${BENCHMARK_CURVES[@]}")
    fi
    
    # 运行基准测试
    for curve in "${test_curves[@]}"; do
        run_benchmark "$curve" "$ITERATIONS"
    done
    
    # 生成报告
    generate_report
    
    # 保存结果（如果需要）
    if [[ -n "$output_file" ]]; then
        save_results "$output_file"
    fi
    
    echo -e "\n${GREEN}基准测试完成!${NC}"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi