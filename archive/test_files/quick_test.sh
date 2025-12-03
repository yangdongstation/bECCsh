#!/bin/bash
# bECCsh快速测试脚本
# 验证基本功能是否正常工作

set -euo pipefail

# 颜色定义
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
NC='\\033[0m' # No Color

# 测试状态
TESTS_PASSED=0
TESTS_FAILED=0

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $*"
    ((TESTS_FAILED++))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

# 检查依赖
check_dependencies() {
    log_info "检查系统依赖..."
    
    local deps=("sha256sum" "bc" "xxd" "base64" "openssl")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            log_pass "找到命令: $dep"
        else
            log_fail "缺少命令: $dep"
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_warn "缺少以下命令: ${missing_deps[*]}"
        log_warn "某些功能可能受限"
        return 1
    fi
    
    return 0
}

# 测试基本功能
test_basic_functionality() {
    log_info "测试基本功能..."
    
    # 测试脚本执行权限
    if [[ -x "becc.sh" ]]; then
        log_pass "主脚本可执行"
    else
        log_fail "主脚本不可执行"
        chmod +x becc.sh
    fi
    
    # 测试库文件
    for lib_file in lib/*.sh; do
        if [[ -r "$lib_file" ]]; then
            log_pass "库文件可读: $lib_file"
        else
            log_fail "库文件不可读: $lib_file"
        fi
    done
    
    # 测试帮助功能
    if ./becc.sh help >/dev/null 2>&1; then
        log_pass "帮助功能正常"
    else
        log_fail "帮助功能异常"
    fi
    
    return 0
}

# 测试ECDSA完整流程
test_ecdsa_flow() {
    log_info "测试ECDSA完整流程..."
    
    local curve="secp256r1"
    local test_message="Hello, bECCsh Quick Test!"
    local private_key_file="test_private.pem"
    local public_key_file="test_public.pem"
    local signature_file="test_signature.der"
    
    # 清理旧文件
    rm -f "$private_key_file" "$public_key_file" "$signature_file"
    
    # 1. 生成密钥对
    log_info "生成密钥对..."
    if ./becc.sh keygen -c "$curve" -f "$private_key_file" >/dev/null 2>&1; then
        log_pass "密钥对生成成功"
    else
        log_fail "密钥对生成失败"
        return 1
    fi
    
    # 检查密钥文件
    if [[ -f "$private_key_file" && -f "${private_key_file%.pem}_public.pem" ]]; then
        log_pass "密钥文件创建成功"
        mv "${private_key_file%.pem}_public.pem" "$public_key_file"
    else
        log_fail "密钥文件未创建"
        return 1
    fi
    
    # 2. 签名消息
    log_info "签名消息..."
    if ./becc.sh sign -c "$curve" -k "$private_key_file" -m "$test_message" -f "$signature_file" >/dev/null 2>&1; then
        log_pass "签名生成成功"
    else
        log_fail "签名生成失败"
        return 1
    fi
    
    # 检查签名文件
    if [[ -f "$signature_file" ]]; then
        log_pass "签名文件创建成功"
    else
        log_fail "签名文件未创建"
        return 1
    fi
    
    # 3. 验证签名
    log_info "验证签名..."
    local verify_result
    verify_result=$(./becc.sh verify -c "$curve" -k "$public_key_file" -m "$test_message" -s "$signature_file" 2>/dev/null || echo "INVALID")
    
    if [[ "$verify_result" == "VALID" ]]; then
        log_pass "签名验证成功"
    else
        log_fail "签名验证失败: $verify_result"
        return 1
    fi
    
    # 4. 测试错误情况
    log_info "测试错误情况..."
    local wrong_message="Wrong message"
    local wrong_result
    wrong_result=$(./becc.sh verify -c "$curve" -k "$public_key_file" -m "$wrong_message" -s "$signature_file" 2>/dev/null || echo "INVALID")
    
    if [[ "$wrong_result" == "INVALID" ]]; then
        log_pass "错误消息正确拒绝"
    else
        log_fail "错误消息未被拒绝: $wrong_result"
    fi
    
    # 清理测试文件
    rm -f "$private_key_file" "$public_key_file" "$signature_file"
    
    return 0
}

# 测试不同曲线
test_curves() {
    log_info "测试不同曲线..."
    
    local curves=("secp256r1" "secp256k1")
    local test_message="Curve test message"
    
    for curve in "${curves[@]}"; do
        log_info "测试曲线: $curve"
        
        # 快速测试该曲线
        local private_key="test_${curve}_private.pem"
        local public_key="test_${curve}_public.pem"
        local signature="test_${curve}_signature.der"
        
        rm -f "$private_key" "$public_key" "$signature"
        
        # 生成密钥对
        if ./becc.sh keygen -c "$curve" -f "$private_key" >/dev/null 2>&1; then
            mv "${private_key%.pem}_public.pem" "$public_key"
            
            # 签名
            if ./becc.sh sign -c "$curve" -k "$private_key" -m "$test_message" -f "$signature" >/dev/null 2>&1; then
                # 验证
                if ./becc.sh verify -c "$curve" -k "$public_key" -m "$test_message" -s "$signature" >/dev/null 2>&1; then
                    log_pass "$curve 曲线测试通过"
                else
                    log_fail "$curve 曲线验证失败"
                fi
            else
                log_fail "$curve 曲线签名失败"
            fi
        else
            log_fail "$curve 曲线密钥生成失败"
        fi
        
        # 清理
        rm -f "$private_key" "$public_key" "$signature"
    done
}

# 测试大数运算
test_bigint() {
    log_info "测试大数运算..."
    
    # 导入bigint库
    source lib/bigint.sh
    
    # 测试基本运算
    local sum=$(bigint_add "123456789" "987654321")
    if [[ "$sum" == "1111111110" ]]; then
        log_pass "大数加法正确"
    else
        log_fail "大数加法错误: $sum"
    fi
    
    local product=$(bigint_multiply "12345" "67890")
    if [[ "$product" == "838102050" ]]; then
        log_pass "大数乘法正确"
    else
        log_fail "大数乘法错误: $product"
    fi
    
    local remainder=$(bigint_mod "987654321" "12345")
    if [[ "$remainder" == "10101" ]]; then
        log_pass "大数模运算正确"
    else
        log_fail "大数模运算错误: $remainder"
    fi
}

# 测试安全功能
test_security() {
    log_info "测试安全功能..."
    
    # 导入安全库
    source lib/security.sh
    
    # 测试常量时间比较
    if constant_time_compare "test123" "test123"; then
        log_pass "常量时间比较(相同)正确"
    else
        log_fail "常量时间比较(相同)错误"
    fi
    
    if ! constant_time_compare "test123" "test124"; then
        log_pass "常量时间比较(不同)正确"
    else
        log_fail "常量时间比较(不同)错误"
    fi
    
    # 测试RFC 6979
    local test_private="1234567890123456789012345678901234567890123456789012345678901234"
    local test_hash="1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
    
    if rfc6979_generate_k "$test_private" "$test_hash" "secp256r1" >/dev/null 2>&1; then
        log_pass "RFC 6979实现可用"
    else
        log_fail "RFC 6979实现有问题"
    fi
}

# 显示测试结果
show_results() {
    echo -e "\\n${BLUE}===============================${NC}"
    echo -e "${BLUE}快速测试结果${NC}"
    echo -e "${BLUE}===============================${NC}"
    echo -e "总测试数: $((TESTS_PASSED + TESTS_FAILED))"
    echo -e "通过: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "失败: ${RED}$TESTS_FAILED${NC}"
    echo -e "${BLUE}===============================${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}所有测试通过! bECCsh基本功能正常。${NC}"
        return 0
    else
        echo -e "${RED}部分测试失败，请检查环境配置。${NC}"
        return 1
    fi
}

# 主函数
main() {
    log_info "开始bECCsh快速测试..."
    log_info "测试时间: $(date)"
    
    # 检查依赖
    check_dependencies
    
    # 测试基本功能
    test_basic_functionality
    
    # 测试ECDSA流程
    test_ecdsa_flow
    
    # 测试不同曲线
    test_curves
    
    # 测试大数运算
    test_bigint
    
    # 测试安全功能
    test_security
    
    # 显示结果
    show_results
    
    log_info "快速测试完成!"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi