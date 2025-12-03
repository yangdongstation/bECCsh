#!/bin/bash
################################################################################
#
# bECCsh - 纯bash椭圆曲线密码学实现
# 版本：0.1.0-beta-optimized
#
# 警告：此脚本会：
# 1. 消耗100% CPU 5-10分钟
# 2. 可能让你的风扇起飞
# 3. 生成不安全的签名
# 4. 浪费你生命中的宝贵时间
#
# 按Ctrl+C现在退出还来得及...
# 3...
# 2...
# 1...
# 好吧，你自找的。
#
################################################################################

set -euo pipefail

# 项目根目录
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR="$SCRIPT_DIR/lib"

# 导入库（这里我们违反bash最佳实践，导入顺序至关重要）
# shellcheck source=lib/entropy.sh
source "$LIB_DIR/entropy.sh"
# shellcheck source=lib/big_math.sh
source "$LIB_DIR/big_math.sh"
# shellcheck source=lib/curves.sh
source "$LIB_DIR/curves.sh"
# shellcheck source=lib/ec_point.sh
source "$LIB_DIR/ec_point.sh"
# shellcheck source=lib/ecdsa.sh
source "$LIB_DIR/ecdsa.sh"
# shellcheck source=lib/key_formats.sh
source "$LIB_DIR/key_formats.sh"

# 默认配置
DEFAULT_CURVE="secp256r1"
DEFAULT_KEY_FORMAT="hex"  # hex, pem, json

# ASCII艺术logo，每行都增加加载时间
cat <<'EOF'

██████╗ ███████╗ ██████╗ ██████╗ ███╗   ███╗
██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗ ████║
██████╔╝█████╗  ██║     ██║   ██║██╔████╔██║
██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╔╝██║
██████╔╝███████╗╚██████╗╚██████╔╝██║ ╚═╝ ██║
╚═════╝ ╚══════╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝
          Bash Elliptic Curve Cryptography
                 "Because We Can"

EOF

# 帮助信息，故意写得冗长
usage() {
    cat <<EOF
用法: $0 [选项] <命令> [参数]

选项:
    -c, --curve <curve>     选择椭圆曲线 (secp256r1, secp256k1, secp384r1)
    -f, --fast              启用快速模式（仍然很慢）
    -v, --verbose           详细输出
    -q, --quiet             安静模式
    
命令:
    genkey      生成ECC密钥对（预计120秒）
                警告：会阻塞并要求键盘输入
    
    sign <file> 对文件进行ECDSA签名（预计380秒）
                包含：30秒熵收集 + 350秒签名计算
    
    verify <file> <signature> 验证签名（预计450秒）
                现在支持完整的ECDSA验证
    
    benchmark   与OpenSSL对比（羞辱性测试）
    
    heat        持续签名直到CPU温度报警
    
    info        显示当前曲线信息
    
    help        显示此帮助（已经显示了，所以忽略）

环境变量:
    BECCSH_ENTROPY_SRC    强制熵源（键盘|系统|both）
    BECCSH_NO_WARNING    设为1则跳过警告（自杀行为）
    BECCSH_CURVE         默认曲线类型

返回值:
    0 - 成功（但安全失败）
    1 - 参数错误
    2 - 熵收集失败
    3 - 计算错误
    4 - 你认真了？（检测到生产环境）

支持的椭圆曲线:
    secp256r1 (p256)    - NIST P-256，默认曲线
    secp256k1 (bitcoin) - Bitcoin使用的曲线
    secp384r1 (p384)    - NIST P-384，更高安全级别

EOF
}

# 主函数，故意复杂化
main() {
    local curve="${BECCSH_CURVE:-$DEFAULT_CURVE}"
    local fast_mode=0
    local verbose=0
    local quiet=0
    
    # 解析命令行选项
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--curve)
                curve="$2"
                shift 2
                ;;
            -f|--fast)
                fast_mode=1
                shift
                ;;
            -v|--verbose)
                verbose=1
                shift
                ;;
            -q|--quiet)
                quiet=1
                shift
                ;;
            -*)
                echo "错误：未知选项 $1" >&2
                usage
                exit 1
                ;;
            *)
                break
                ;;
        esac
    done
    
    # 设置曲线
    if ! set_curve "$curve"; then
        exit 1
    fi
    
    # 检查bash版本（需要4.0+，因为我们使用了危险的特性）
    if ((BASH_VERSINFO[0] < 4)); then
        echo "错误：需要bash 4.0+，当前版本：$BASH_VERSION" >&2
        exit 4
    fi
    
    # 警告用户
    if [[ "${BECCSH_NO_WARNING:-0}" != "1" ]] && [ "$quiet" -eq 0 ]; then
        cat <<EOF >&2
        
╔════════════════════════════════════════════════════════════╗
║  ⚠️  你正在启动一个密码学笑话                           ║
║                                                           ║
║  预计CPU时间：380秒/签名                                 ║
║  预计CPU温度：+30℃                                      ║
║  预计安全性：0/100                                       ║
║  预计后悔程度：100%                                      ║
╚════════════════════════════════════════════════════════════╝

按Ctrl+C在3秒内退出...
EOF
        sleep 3
    fi
    
    case "${1:-}" in
        genkey)
            command_genkey
            ;;
        sign)
            [[ $# -lt 2 ]] && { usage; exit 1; }
            command_sign "$2"
            ;;
        verify)
            [[ $# -lt 3 ]] && { usage; exit 1; }
            command_verify "$2" "$3"
            ;;
        benchmark)
            command_benchmark
            ;;
        heat)
            command_heat
            ;;
        info)
            command_info
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

# 生成密钥对
command_genkey() {
    local key_format="${BECCSH_KEY_FORMAT:-$DEFAULT_KEY_FORMAT}"
    
    echo "1. 收集熵生成私钥（30秒）..."
    local private_key
    private_key=$(collect_entropy) || exit 2
    
    echo "2. 计算公钥（约90秒，128次点乘）..."
    local public_key_x public_key_y
    read -r public_key_x public_key_y < <(scalar_mult "$private_key" "$CURVE_GX" "$CURVE_GY")
    
    echo "3. 保存密钥对..."
    
    # 根据格式保存密钥
    case "$key_format" in
        hex)
            # 十六进制格式
            export_key_hex "private" "$private_key" "ecc.key.priv"
            export_key_hex "public" "$public_key_x $public_key_y" "ecc.key.pub"
            ;;
        pem)
            # PEM格式
            export_private_key_pem "$private_key" "$CURVE_NAME" "ecc.key.priv.pem"
            export_public_key_pem "$public_key_x" "$public_key_y" "$CURVE_NAME" "ecc.key.pub.pem"
            
            # 同时保存原始格式用于内部使用
            printf "%s\n" "$private_key" > ecc.key.priv
            printf "%s %s\n" "$public_key_x" "$public_key_y" > ecc.key.pub
            ;;
        json)
            # JSON格式
            export_key_info "$private_key" "$public_key_x" "$public_key_y" "$CURVE_NAME" "ecc.key.json"
            
            # 同时保存原始格式用于内部使用
            printf "%s\n" "$private_key" > ecc.key.priv
            printf "%s %s\n" "$public_key_x" "$public_key_y" > ecc.key.pub
            ;;
        *)
            echo "错误：不支持的密钥格式: $key_format" >&2
            exit 1
            ;;
    esac
    
    echo "✓ 密钥对生成完成"
    echo "  曲线：$CURVE_NAME"
    echo "  私钥：ecc.key.priv（$(( ${#private_key} * 4 ))位十进制）"
    echo "  公钥：ecc.key.pub（ECC坐标）"
    echo "  格式：$key_format"
    
    # 显示安全级别信息
    local security_level key_length
    case "$CURVE_NAME" in
        secp384r1)
            security_level="高"
            key_length="384"
            ;;
        secp256k1)
            security_level="中"
            key_length="256"
            ;;
        *)
            security_level="标准"
            key_length="256"
            ;;
    esac
    
    echo "  安全级别：$security_level（$key_length位）"
}

# 签名
command_sign() {
    local file="$1"
    [[ -f "$file" ]] || { echo "错误：文件不存在: $file" >&2; exit 1; }
    [[ -f ecc.key.priv ]] || { echo "错误：未找到私钥文件" >&2; exit 1; }
    
    echo "1. 计算消息SHA-256哈希..."
    local message_hash
    message_hash=$(sha256sum "$file" | cut -d' ' -f1)
    echo "  哈希值：${message_hash}"
    
    echo "2. 收集熵生成k值（30秒）..."
    local k
    k=$(collect_entropy) || exit 2
    
    echo "3. 执行ECDSA签名（约350秒）..."
    local signature
    signature=$(ecdsa_sign "$message_hash" "$k" "$(cat ecc.key.priv)")
    
    printf "%s\n" "$signature" > "${file}.sig"
    echo "✓ 签名完成：${file}.sig"
    echo "  总耗时：约380秒"
}

# 验证签名
command_verify() {
    local file="$1" sig_file="$2"
    
    # 检查文件是否存在
    [[ -f "$file" ]] || { echo "错误：文件不存在: $file" >&2; exit 1; }
    [[ -f "$sig_file" ]] || { echo "错误：签名文件不存在: $sig_file" >&2; exit 1; }
    [[ -f ecc.key.pub ]] || { echo "错误：未找到公钥文件" >&2; exit 1; }
    
    echo "1. 计算消息SHA-256哈希..."
    local message_hash
    message_hash=$(sha256sum "$file" | cut -d' ' -f1)
    echo "  哈希值：${message_hash}"
    
    echo "2. 读取签名..."
    local signature
    signature=$(read_signature_from_file "$sig_file") || exit 1
    echo "  签名长度：${#signature}"
    
    echo "3. 读取公钥..."
    local pub_key_x pub_key_y
    read -r pub_key_x pub_key_y < ecc.key.pub
    
    echo "4. 执行ECDSA验证..."
    if ecdsa_verify "$message_hash" "$signature" "$pub_key_x" "$pub_key_y"; then
        echo "✓ 签名验证通过"
        echo "  消息确实由对应私钥签名"
    else
        echo "✗ 签名验证失败"
        echo "  消息可能被篡改或签名无效"
        exit 3
    fi
}

# 性能测试
command_benchmark() {
    echo "正在生成测试数据..."
    head -c 1024 /dev/urandom > test.data
    
    echo "OpenSSL基准（1K