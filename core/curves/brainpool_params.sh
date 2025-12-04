#!/bin/bash
# Brainpool椭圆曲线参数定义
# 欧洲标准曲线系列，提供额外的安全性和透明度

set -euo pipefail

# 导入保护 - 防止重复定义
if [[ -n "${BRAINPOOL_PARAMS_LOADED:-}" ]]; then
    return 0
fi
readonly BRAINPOOL_PARAMS_LOADED=1

# BrainpoolP256r1 参数 (十六进制表示)
# 素数p
readonly BRAINPOOLP256R1_P_HEX="a9fb57dba1eea9bc3e660a909d838d726e3bf623d52620282013481d1f6e5377"

# 系数a
readonly BRAINPOOLP256R1_A_HEX="7d5a0975fc2c3057eef67530417affe7fb8055c126dc5c6ce94a4b44f330b5d9"

# 系数b
readonly BRAINPOOLP256R1_B_HEX="26dc5c6ce94a4b44f330b5d9bbd77cbf958416295cf7e1ce6bccdc18ff8c07b6"

# 基点G的x坐标
readonly BRAINPOOLP256R1_GX_HEX="8bd2aeb9cb7e57cb2c4b482ffc81b7afb9de27e1e3bd23c23a4453bd9ace3262"

# 基点G的y坐标
readonly BRAINPOOLP256R1_GY_HEX="547ef835c3dac4fd97f8461a14611dc9c27745132ded8e545c1d54c72f046997"

# 基点G的阶n
readonly BRAINPOOLP256R1_N_HEX="a9fb57dba1eea9bc3e660a909d838d718c397aa3b561a6f7901e0e82974856a7"

# BrainpoolP384r1 参数 (十六进制表示)
# 素数p
readonly BRAINPOOLP384R1_P_HEX="8cb91e82a3386d280f5d6f7e50e641df152f7109ed5456b412b1da197fb71123acd3a729901d1a71874700133107ec53"

# 系数a
readonly BRAINPOOLP384R1_A_HEX="7bc382c63d8c150c3c72080ace05afa0c2bea28e4fb22787139165efba91f90f8aa5814a503ad4eb04a8c7dd22ce2826"

# 系数b
readonly BRAINPOOLP384R1_B_HEX="04a8c7dd22ce28268b39b55416f0447ba2d929106c97508e58c72e2b326a429f5e875576f1b4f69e2704f5e6a775f0b"

# 基点G的x坐标
readonly BRAINPOOLP384R1_GX_HEX="1d1c64f068cf45ffa2a63a81b7c13f6b8847a3e77ab14fe3db7fcafe0cbd10e8e826e03436d646aaef87b2e247d4af1e"

# 基点G的y坐标
readonly BRAINPOOLP384R1_GY_HEX="8abe1d7520f9c2a45cb1eb8e95cfd55262b70b29feec5864e19c054ff99129280e4646217791811142820341263c5315"

# 基点G的阶n
readonly BRAINPOOLP384R1_N_HEX="8cb91e82a3386d280f5d6f7e50e641df152f7109ed5456b31f166e6cac0425a7cf3ab6af6b7fc3103b883202e9046565"

# BrainpoolP512r1 参数 (十六进制表示)
# 素数p
readonly BRAINPOOLP512R1_P_HEX="aadd9db8dbe9c48b3fd4e6ae33c9fc07cb308db3b3c9d20ed6639cca703308717d4d9b009bc66842aecda12ae6f3800dd08c90d97e5dd43bfe7f59f1c800d77"

# 系数a
readonly BRAINPOOLP512R1_A_HEX="7830a3318B603B89E2327145AC234CC594CBDD8D3DF91610A83441CAEA9863BC2DED5D5AA8253AA10A2EF1C98B9AC8B57F1117A72BF2C7B9E7C1AC4D77FC94CA"

# 系数b
readonly BRAINPOOLP512R1_B_HEX="3df91610a83441caea9863bc2ded5d5aa8253aa10a2ef1c98b9ac8b57f1117a72bf2c7b9e7c1ac4d77fc94cadc083e67984050b75ebae5dd2809bd638016f723"

# 基点G的x坐标
readonly BRAINPOOLP512R1_GX_HEX="81aee4bdd82ed9645a21322e9c4c6a9385ed9f70b5d916c1b43b62eef4d3778d2ff7200661e24080bd28b808cf7902fabdc9d6f69aa7e602d2b6d1b9b8f3e4f"

# 基点G的y坐标
readonly BRAINPOOLP512R1_GY_HEX="7d51cac7f974a9cb6237d82a8b9a87b7b7b4e3ea1018c9d8b702881a8b0168cc3a91e34e1e4a1b1a1237e78a0ee1f8940f0ec5812c4e3b5b8f2d6f8e3a8b8f"

# 基点G的阶n
readonly BRAINPOOLP512R1_N_HEX="aadd9db8dbe9c48b3fd4e6ae33c9fc07cb308db3b3c9d20ed6639cca70330870553e5c414ca92619418661197fac10471db1d381085ddaddb58796829ca90069"

# 余因子h
readonly BRAINPOOL_H="1"

# 转换为十进制数的辅助函数
hex_to_decimal() {
    local hex_value="$1"
    # 移除空格并转换为大写
    hex_value=$(echo "$hex_value" | tr -d ' ' | tr '[:lower:]' '[:upper:]')
    
    # 使用python进行大数十六进制到十进制转换（如果可用）
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "print(int('$hex_value', 16))"
    elif command -v python >/dev/null 2>&1; then
        python -c "print(int('$hex_value', 16))"
    elif command -v bc >/dev/null 2>&1; then
        # 使用bc进行转换
        echo "ibase=16; $hex_value" | BC_LINE_LENGTH=0 bc
    else
        echo "错误: 需要python或bc进行大数转换" >&2
        return 1
    fi
}

# BrainpoolP256r1 十进制参数（缓存以提高性能）
if [[ -z "${BRAINPOOLP256R1_P:-}" ]]; then
    readonly BRAINPOOLP256R1_P="$(hex_to_decimal "$BRAINPOOLP256R1_P_HEX")"
fi

if [[ -z "${BRAINPOOLP256R1_A:-}" ]]; then
    readonly BRAINPOOLP256R1_A="$(hex_to_decimal "$BRAINPOOLP256R1_A_HEX")"
fi

if [[ -z "${BRAINPOOLP256R1_B:-}" ]]; then
    readonly BRAINPOOLP256R1_B="$(hex_to_decimal "$BRAINPOOLP256R1_B_HEX")"
fi

if [[ -z "${BRAINPOOLP256R1_GX:-}" ]]; then
    readonly BRAINPOOLP256R1_GX="$(hex_to_decimal "$BRAINPOOLP256R1_GX_HEX")"
fi

if [[ -z "${BRAINPOOLP256R1_GY:-}" ]]; then
    readonly BRAINPOOLP256R1_GY="$(hex_to_decimal "$BRAINPOOLP256R1_GY_HEX")"
fi

if [[ -z "${BRAINPOOLP256R1_N:-}" ]]; then
    readonly BRAINPOOLP256R1_N="$(hex_to_decimal "$BRAINPOOLP256R1_N_HEX")"
fi

# BrainpoolP384r1 十进制参数
if [[ -z "${BRAINPOOLP384R1_P:-}" ]]; then
    readonly BRAINPOOLP384R1_P="$(hex_to_decimal "$BRAINPOOLP384R1_P_HEX")"
fi

if [[ -z "${BRAINPOOLP384R1_A:-}" ]]; then
    readonly BRAINPOOLP384R1_A="$(hex_to_decimal "$BRAINPOOLP384R1_A_HEX")"
fi

if [[ -z "${BRAINPOOLP384R1_B:-}" ]]; then
    readonly BRAINPOOLP384R1_B="$(hex_to_decimal "$BRAINPOOLP384R1_B_HEX")"
fi

if [[ -z "${BRAINPOOLP384R1_GX:-}" ]]; then
    readonly BRAINPOOLP384R1_GX="$(hex_to_decimal "$BRAINPOOLP384R1_GX_HEX")"
fi

if [[ -z "${BRAINPOOLP384R1_GY:-}" ]]; then
    readonly BRAINPOOLP384R1_GY="$(hex_to_decimal "$BRAINPOOLP384R1_GY_HEX")"
fi

if [[ -z "${BRAINPOOLP384R1_N:-}" ]]; then
    readonly BRAINPOOLP384R1_N="$(hex_to_decimal "$BRAINPOOLP384R1_N_HEX")"
fi

# BrainpoolP512r1 十进制参数
if [[ -z "${BRAINPOOLP512R1_P:-}" ]]; then
    readonly BRAINPOOLP512R1_P="$(hex_to_decimal "$BRAINPOOLP512R1_P_HEX")"
fi

if [[ -z "${BRAINPOOLP512R1_A:-}" ]]; then
    readonly BRAINPOOLP512R1_A="$(hex_to_decimal "$BRAINPOOLP512R1_A_HEX")"
fi

if [[ -z "${BRAINPOOLP512R1_B:-}" ]]; then
    readonly BRAINPOOLP512R1_B="$(hex_to_decimal "$BRAINPOOLP512R1_B_HEX")"
fi

if [[ -z "${BRAINPOOLP512R1_GX:-}" ]]; then
    readonly BRAINPOOLP512R1_GX="$(hex_to_decimal "$BRAINPOOLP512R1_GX_HEX")"
fi

if [[ -z "${BRAINPOOLP512R1_GY:-}" ]]; then
    readonly BRAINPOOLP512R1_GY="$(hex_to_decimal "$BRAINPOOLP512R1_GY_HEX")"
fi

if [[ -z "${BRAINPOOLP512R1_N:-}" ]]; then
    readonly BRAINPOOLP512R1_N="$(hex_to_decimal "$BRAINPOOLP512R1_N_HEX")"
fi

# 获取BrainpoolP256r1参数函数
get_brainpoolp256r1_params() {
    echo "$BRAINPOOLP256R1_P $BRAINPOOLP256R1_A $BRAINPOOLP256R1_B $BRAINPOOLP256R1_GX $BRAINPOOLP256R1_GY $BRAINPOOLP256R1_N $BRAINPOOL_H"
}

# 获取BrainpoolP256r1参数（十六进制）
get_brainpoolp256r1_params_hex() {
    echo "$BRAINPOOLP256R1_P_HEX $BRAINPOOLP256R1_A_HEX $BRAINPOOLP256R1_B_HEX $BRAINPOOLP256R1_GX_HEX $BRAINPOOLP256R1_GY_HEX $BRAINPOOLP256R1_N_HEX $BRAINPOOL_H"
}

# 获取BrainpoolP384r1参数函数
get_brainpoolp384r1_params() {
    echo "$BRAINPOOLP384R1_P $BRAINPOOLP384R1_A $BRAINPOOLP384R1_B $BRAINPOOLP384R1_GX $BRAINPOOLP384R1_GY $BRAINPOOLP384R1_N $BRAINPOOL_H"
}

# 获取BrainpoolP384r1参数（十六进制）
get_brainpoolp384r1_params_hex() {
    echo "$BRAINPOOLP384R1_P_HEX $BRAINPOOLP384R1_A_HEX $BRAINPOOLP384R1_B_HEX $BRAINPOOLP384R1_GX_HEX $BRAINPOOLP384R1_GY_HEX $BRAINPOOLP384R1_N_HEX $BRAINPOOL_H"
}

# 获取BrainpoolP512r1参数函数
get_brainpoolp512r1_params() {
    echo "$BRAINPOOLP512R1_P $BRAINPOOLP512R1_A $BRAINPOOLP512R1_B $BRAINPOOLP512R1_GX $BRAINPOOLP512R1_GY $BRAINPOOLP512R1_N $BRAINPOOL_H"
}

# 获取BrainpoolP512r1参数（十六进制）
get_brainpoolp512r1_params_hex() {
    echo "$BRAINPOOLP512R1_P_HEX $BRAINPOOLP512R1_A_HEX $BRAINPOOLP512R1_B_HEX $BRAINPOOLP512R1_GX_HEX $BRAINPOOLP512R1_GY_HEX $BRAINPOOLP512R1_N_HEX $BRAINPOOL_H"
}

# 获取Brainpool曲线信息
get_brainpool_info() {
    local curve_type="$1"
    
    case "$curve_type" in
        "brainpoolp256r1")
            cat << EOF
BrainpoolP256r1 椭圆曲线信息:
  标准: RFC 5639, 欧洲标准
  用途: 欧洲密码学标准、高透明度应用
  安全级别: 128位
  密钥长度: 256位
  特点: 基于素数域，参数生成具有可验证的随机性
  素数p: $BRAINPOOLP256R1_P_HEX
  系数a: $BRAINPOOLP256R1_A_HEX
  系数b: $BRAINPOOLP256R1_B_HEX
  基点Gx: $BRAINPOOLP256R1_GX_HEX
  基点Gy: $BRAINPOOLP256R1_GY_HEX
  阶n: $BRAINPOOLP256R1_N_HEX
  余因子h: $BRAINPOOL_H
EOF
            ;;
        "brainpoolp384r1")
            cat << EOF
BrainpoolP384r1 椭圆曲线信息:
  标准: RFC 5639, 欧洲标准
  用途: 高安全性欧洲标准应用
  安全级别: 192位
  密钥长度: 384位
  特点: 基于素数域，参数生成具有可验证的随机性
  素数p: $BRAINPOOLP384R1_P_HEX
  系数a: $BRAINPOOLP384R1_A_HEX
  系数b: $BRAINPOOLP384R1_B_HEX
  基点Gx: $BRAINPOOLP384R1_GX_HEX
  基点Gy: $BRAINPOOLP384R1_GY_HEX
  阶n: $BRAINPOOLP384R1_N_HEX
  余因子h: $BRAINPOOL_H
EOF
            ;;
        "brainpoolp512r1")
            cat << EOF
BrainpoolP512r1 椭圆曲线信息:
  标准: RFC 5639, 欧洲标准
  用途: 最高安全级别欧洲标准应用
  安全级别: 256位
  密钥长度: 512位
  特点: 基于素数域，参数生成具有可验证的随机性
  素数p: $BRAINPOOLP512R1_P_HEX
  系数a: $BRAINPOOLP512R1_A_HEX
  系数b: $BRAINPOOLP512R1_B_HEX
  基点Gx: $BRAINPOOLP512R1_GX_HEX
  基点Gy: $BRAINPOOLP512R1_GY_HEX
  阶n: $BRAINPOOLP512R1_N_HEX
  余因子h: $BRAINPOOL_H
EOF
            ;;
        *)
            echo "错误: 不支持的Brainpool曲线类型: $curve_type" >&2
            return 1
            ;;
    esac
}