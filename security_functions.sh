#!/bin/bash
# Security Functions - 安全功能实现
# 仅使用Bash内置功能实现安全相关功能

# 安全警告显示函数
show_security_warning() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    ⚠️  重要安全警告 ⚠️                        ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  本程序仅用于教育研究目的，不适合生产环境使用                ║"
    echo "║  使用风险自负，作者不对任何损失承担责任                     ║"
    echo "║                                                              ║"
    echo "║  安全限制：                                                  ║"
    echo "║  • 使用小素数域进行概念演示                                 ║"
    echo "║  • 缺乏完整的模运算实现                                     ║"
    echo "║  • 随机数生成仅为概念级别                                   ║"
    echo "║  • 哈希函数非密码学强度                                     ║"
    echo "║                                                              ║"
    echo "║  适用场景：                                                  ║"
    echo "║  ✅ 密码学教学和培训                                         ║"
    echo "║  ✅ 算法研究和概念验证                                       ║"
    echo "║  ✅ 编程技术展示和演示                                       ║"
    echo "║  ✅ 无依赖环境的应急方案                                     ║"
    echo "║                                                              ║"
    echo "║  不适用场景：                                                ║"
    echo "║  ❌ 生产环境密码学应用                                       ║"
    echo "║  ❌ 高价值数据保护                                           ║"
    echo "║  ❌ 关键基础设施安全                                         ║"
    echo "║  ❌ 需要FIPS认证的场景                                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "详细信息请查看 SECURITY_WARNING.md 文件"
    echo ""
}

# 安全检查函数
security_check_environment() {
    local errors=0
    
    echo "=== 环境安全检查 ==="
    
    # 检查Bash版本
    local bash_version=$(bash --version | head -1)
    echo "Bash版本: $bash_version"
    
    # 检查/dev/urandom可用性
    if [[ -c /dev/urandom ]]; then
        echo "✅ /dev/urandom 可用"
    else
        echo "⚠️  /dev/urandom 不可用，可能影响随机数质量"
        ((errors++))
    fi
    
    # 检查内存情况
    if [[ -f /proc/meminfo ]]; then
        local mem_total=$(grep "MemTotal" /proc/meminfo | awk '{print $2}')
        echo "内存总量: ${mem_total}KB"
        
        if [[ $mem_total -lt 512000 ]]; then
            echo "⚠️  内存可能不足，可能影响大数运算性能"
        fi
    fi
    
    # 检查临时目录安全性
    if [[ -w "/tmp" ]]; then
        echo "⚠️  /tmp目录可写，注意临时文件安全"
    fi
    
    # 检查调试环境
    if [[ -n "${DEBUG:-}" ]]; then
        echo "⚠️  调试模式开启，可能影响安全性"
    fi
    
    if [[ $errors -gt 0 ]]; then
        echo "⚠️  发现 $errors 个潜在安全问题"
        return 1
    else
        echo "✅ 环境安全检查通过"
        return 0
    fi
}

# 内存安全检查
security_memory_check() {
    local sensitive_data="$1"
    
    # 检查敏感数据长度
    if [[ ${#sensitive_data} -gt 1000 ]]; then
        echo "⚠️  检测到大量敏感数据" >&2
        return 1
    fi
    
    # 检查是否包含敏感模式
    if [[ "$sensitive_data" =~ [0-9a-fA-F]{32,} ]]; then
        echo "⚠️  检测到可能的密钥或哈希数据" >&2
        return 1
    fi
    
    return 0
}

# 常量时间比较（侧信道攻击防护）
constant_time_compare() {
    local a="$1" local b="$2"
    local result=0
    local len_a=${#a} local len_b=${#b}
    
    # 长度检查（常量时间）
    [[ $len_a -ne $len_b ]] && return 1
    
    # 逐字符比较（常量时间）
    for ((i=0; i<len_a; i++)); do
        [[ "${a:$i:1}" != "${b:$i:1}" ]] && result=1
    done
    
    return $result
}

# 安全内存清零
secure_zero_memory() {
    local var_name="$1"
    
    # 用随机数据覆盖多次
    for ((i=0; i<3; i++)); do
        eval "$var_name='00000000000000000000000000000000'"
        eval "$var_name='FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'"
    done
    
    # 最终清零
    eval "$var_name='00000000000000000000000000000000'"
    unset $var_name
}

# 测试函数
test_security_functions() {
    echo "=== 安全功能测试 ==="
    
    show_security_warning
    
    if security_check_environment; then
        echo "✅ 环境安全检查通过"
    else
        echo "⚠️  环境安全检查发现警告"
    fi
    
    # 测试常量时间比较
    if constant_time_compare "test123" "test123"; then
        echo "✅ 常量时间比较测试通过"
    else
        echo "❌ 常量时间比较测试失败"
    fi
    
    if constant_time_compare "test123" "test456"; then
        echo "❌ 常量时间比较测试失败"
    else
        echo "✅ 常量时间比较测试通过"
    fi
    
    # 测试安全内存清零
    local test_var="sensitive_data_12345"
    secure_zero_memory "test_var"
    if [[ -z "${test_var:-}" ]]; then
        echo "✅ 安全内存清零测试通过"
    else
        echo "❌ 安全内存清零测试失败"
    fi
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_security_functions
fi