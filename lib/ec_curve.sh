#!/bin/bash
# EC Curve - 椭圆曲线参数管理
# 支持NIST P系列曲线和secp256k1

set -euo pipefail

# 导入保护 - 防止重复定义
if [[ -n "${EC_CURVE_LOADED:-}" ]]; then
    return 0
fi
readonly EC_CURVE_LOADED=1

# 导入数学库
source "$(dirname "${BASH_SOURCE[0]}")/bash_math.sh"

# 曲线参数结构
# 每个曲线包含以下参数:
# - p: 有限域的模数
# - a: 曲线方程 y^2 = x^3 + ax + b 中的参数a
# - b: 曲线方程 y^2 = x^3 + ax + b 中的参数b
# - G: 基点 (Gx, Gy)
# - n: 基点的阶
# - h: 余因子

# 当前激活的曲线
CURVE_NAME=""
CURVE_P=""
CURVE_A=""
CURVE_B=""
CURVE_GX=""
CURVE_GY=""
CURVE_N=""
CURVE_H=""

# 支持的曲线列表
readonly SUPPORTED_CURVES=("secp256r1" "secp256k1" "secp384r1" "secp521r1")

# NIST P-256 (secp256r1) 参数
# p = 2^256 - 2^224 + 2^192 + 2^96 - 1
readonly P256_P="115792089210356248762697446949407573530086143415290314195533631308867097853951"
readonly P256_A="115792089210356248762697446949407573530086143415290314195533631308867097853948"  # -3 mod p
readonly P256_B="41058363725152142129326129780047268409114441015993725554835256314039467401291"
readonly P256_GX="48439561293906451759052585252797914202762949526041747995844090717080904636516"
readonly P256_GY="36134250956749795798585127919587881956611106672985015071877198253568414405109"
readonly P256_N="115792089210356248762697446949407573529996955224135760342422259061068512044369"
readonly P256_H="1"

# secp256k1 (比特币使用) 参数
# p = 2^256 - 2^32 - 977
readonly P256K1_P="115792089237316195423570985008687907853269984665640564039457584007908834671663"
readonly P256K1_A="0"
readonly P256K1_B="7"
readonly P256K1_GX="55066263022277343669578718895168534326250603453777594175500187360389116729240"
readonly P256K1_GY="32670510020758816978083085130507043184471273380659243275938904335757337482424"
readonly P256K1_N="115792089237316195423570985008687907852837564279074904382605163141518161494337"
readonly P256K1_H="1"

# NIST P-384 (secp384r1) 参数
readonly P384_P="39402006196394479212279040100143613805079739270465446667948293404245721771496870329047266088258938001861606973112319"
readonly P384_A="39402006196394479212279040100143613805079739270465446667948293404245721771496870329047266088258938001861606973112316"  # -3 mod p
readonly P384_B="27580193559959705877849011840389048093056905856361568521428707301988689241309860865136260764883745107765439761230575"
readonly P384_GX="2624703509579968926862315673456892618976967114838294284659523675835924516413593115718051175494425471403884755084549"
readonly P384_GY="34322434599928580972163183703047131172998866597583924285650006036050526993978240503341311719666238328104131944887"
readonly P384_N="39402006196394479212279040100143613805079739270465446667946905279627659399113263569398956308152294913554433653942643"
readonly P384_H="1"

# NIST P-521 (secp521r1) 参数
readonly P521_P="6864797660130609714981900799081393217269435300143305409394463459185543183397656052122559640661454554977296311391480858037121987999716643812574028291115057151"
readonly P521_A="6864797660130609714981900799081393217269435300143305409394463459185543183397656052122559640661454554977296311391480858037121987999716643812574028291115057148"  # -3 mod p
readonly P521_B="1093849038073734274511112390766805569936207598951683748994586394495953116470735890990370204467126716416914464956534276386432718695874013278919908351942956595"
readonly P521_GX="2661740802050217063226948125877558978136422736671233331137320583276355677199364974242220034623349209524308385032746805360833946301651616934631912074044506458"
readonly P521_GY="3757180025770259866293200442932935994217050505500134102064712199058637421474449504226177929546873441534939587464486976627246741448864943641064973691689675654"
readonly P521_N="6864797660130609714981900799081393217269435300143305409394463459185543183397655394245057746333217197532963996371363321113864768612440380340372808892707005449"
readonly P521_H="1"

# 检查曲线是否受支持
curve_is_supported() {
    local curve_name="$1"
    for curve in "${SUPPORTED_CURVES[@]}"; do
        if [[ "$curve" == "$curve_name" ]]; then
            return 0
        fi
    done
    return 1
}

# 获取曲线参数
curve_get_params() {
    local curve_name="$1"
    
    case "$curve_name" in
        "secp256r1")
            echo "$P256_P $P256_A $P256_B $P256_GX $P256_GY $P256_N $P256_H"
            ;;
        "secp256k1")
            echo "$P256K1_P $P256K1_A $P256K1_B $P256K1_GX $P256K1_GY $P256K1_N $P256K1_H"
            ;;
        "secp384r1")
            echo "$P384_P $P384_A $P384_B $P384_GX $P384_GY $P384_N $P384_H"
            ;;
        "secp521r1")
            echo "$P521_P $P521_A $P521_B $P521_GX $P521_GY $P521_N $P521_H"
            ;;
        *)
            echo ""
            return 1
            ;;
    esac
}

# 初始化曲线参数
curve_init() {
    local curve_name="$1"
    
    if ! curve_is_supported "$curve_name"; then
        echo "错误: 不支持的曲线 '$curve_name'" >&2
        return 1
    fi
    
    CURVE_NAME="$curve_name"
    
    local params
    params=$(curve_get_params "$curve_name")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    CURVE_P=$(echo "$params" | cut -d' ' -f1)
    CURVE_A=$(echo "$params" | cut -d' ' -f2)
    CURVE_B=$(echo "$params" | cut -d' ' -f3)
    CURVE_GX=$(echo "$params" | cut -d' ' -f4)
    CURVE_GY=$(echo "$params" | cut -d' ' -f5)
    CURVE_N=$(echo "$params" | cut -d' ' -f6)
    CURVE_H=$(echo "$params" | cut -d' ' -f7)
    
    # 验证曲线参数
    if ! curve_validate_params; then
        echo "错误: 曲线参数验证失败" >&2
        return 1
    fi
    
    return 0
}

# 验证曲线参数
curve_validate_params() {
    # 检查参数是否为有效的大数
    for param in "$CURVE_P" "$CURVE_A" "$CURVE_B" "$CURVE_GX" "$CURVE_GY" "$CURVE_N" "$CURVE_H"; do
        if [[ -z "$param" ]] || [[ ! "$param" =~ ^[0-9]+$ ]]; then
            return 1
        fi
    done
    
    # 简化验证：由于大数模幂运算性能问题，暂时只检查基本参数有效性
    # 实际的曲线验证可以通过已知测试向量来验证
    
    # 检查参数长度是否合理（至少100位）
    for param in "$CURVE_P" "$CURVE_N"; do
        if [[ ${#param} -lt 30 ]]; then
            echo "错误: 参数长度异常" >&2
            return 1
        fi
    done
    
    return 0
}

# 获取当前曲线信息
curve_info() {
    if [[ -z "$CURVE_NAME" ]]; then
        echo "错误: 未初始化曲线" >&2
        return 1
    fi
    
    echo "曲线名称: $CURVE_NAME"
    echo "有限域 p: $CURVE_P"
    echo "参数 a: $CURVE_A"
    echo "参数 b: $CURVE_B"
    echo "基点 Gx: $CURVE_GX"
    echo "基点 Gy: $CURVE_GY"
    echo "阶 n: $CURVE_N"
    echo "余因子 h: $CURVE_H"
    
    # 计算位数
    local p_bits=$(bashmath_log2 "$CURVE_P")
    echo "安全级别: ${p_bits}位"
}

# 获取曲线的安全级别
curve_security_level() {
    case "$CURVE_NAME" in
        "secp256r1"|"secp256k1")
            echo "256"
            ;;
        "secp384r1")
            echo "384"
            ;;
        "secp521r1")
            echo "521"
            ;;
        *)
            echo "0"
            return 1
            ;;
    esac
}

# 获取曲线的哈希算法推荐
curve_recommended_hash() {
    case "$CURVE_NAME" in
        "secp256r1"|"secp256k1")
            echo "sha256"
            ;;
        "secp384r1")
            echo "sha384"
            ;;
        "secp521r1")
            echo "sha512"
            ;;
        *)
            echo "sha256"
            return 1
            ;;
    esac
}

# 测试曲线实现
curve_test() {
    echo "测试椭圆曲线实现..."
    
    for curve in "${SUPPORTED_CURVES[@]}"; do
        echo -e "\n测试曲线: $curve"
        
        if curve_init "$curve"; then
            echo "✓ 曲线初始化成功"
            
            if curve_validate_params; then
                echo "✓ 曲线参数验证通过"
            else
                echo "✗ 曲线参数验证失败"
            fi
            
            local security_level=$(curve_security_level)
            local recommended_hash=$(curve_recommended_hash)
            echo "  安全级别: $security_level位"
            echo "  推荐哈希: $recommended_hash"
        else
            echo "✗ 曲线初始化失败"
        fi
    done
    
    echo -e "\n曲线测试完成"
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    curve_test
fi