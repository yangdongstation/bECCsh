#!/bin/bash
# ecdsa.sh - ECDSA签名与验证
# 实现了完整的ECDSA算法，包括签名生成和验证

source ec_curve.sh
source ec_point.sh

# ECDSA签名生成
# 输入：消息哈希（十六进制），随机数k（十进制），私钥d（十进制）
# 输出：签名(r, s)（十六进制）
ecdsa_sign() {
    local hash_hex="$1" k="$2" d="$3"
    
    # 将哈希转换为十进制大数
    local hash_dec
    hash_dec=$(( 16#$hash_hex ))
    hash_dec=$(( hash_dec % CURVE_N ))
    
    # 1. 计算点 (x1, y1) = k * G
    echo "    计算 k*G..." >&2
    local x1 y1
    read -r x1 y1 < <(scalar_mult "$k" "$CURVE_GX" "$CURVE_GY")
    
    # 2. r = x1 mod n
    local r
    r=$(( x1 % CURVE_N ))
    
    if [ "$r" = "0" ]; then
        echo "错误：r=0，需要重新生成k值" >&2
        return 1
    fi
    
    # 3. s = k⁻¹ * (hash + r * d) mod n
    echo "    计算模逆元k⁻¹..." >&2
    local k_inv
    k_inv=$(bn_mod_inverse "$k" "$CURVE_N")
    
    echo "    计算 s..." >&2
    local s
    s=$(bn_mod_mul "$k_inv" $(bn_mod_add "$hash_dec" $(bn_mod_mul "$r" "$d" "$CURVE_N") "$CURVE_N") "$CURVE_N")
    
    if [ "$s" = "0" ]; then
        echo "错误：s=0，需要重新生成k值" >&2
        return 1
    fi
    
    # 转换为十六进制并格式化
    printf "%064x%064x\n" "$r" "$s"
}

# ECDSA签名验证
# 输入：消息哈希（十六进制），签名（十六进制），公钥(x,y坐标)
# 输出：0表示验证成功，1表示验证失败
ecdsa_verify() {
    local hash_hex="$1" signature="$2" pub_key_x="$3" pub_key_y="$4"
    
    # 检查签名长度
    if [ ${#signature} -ne 128 ]; then
        echo "错误：签名长度必须为128个十六进制字符" >&2
        return 1
    fi
    
    # 提取r和s
    local r_hex="${signature:0:64}"
    local s_hex="${signature:64:64}"
    
    # 转换为十进制
    local r_dec s_dec hash_dec
    r_dec=$(( 16#$r_hex ))
    s_dec=$(( 16#$s_hex ))
    hash_dec=$(( 16#$hash_hex ))
    hash_dec=$(( hash_dec % CURVE_N ))
    
    # 检查r和s的范围
    if [ "$r_dec" -le "0" ] || [ "$r_dec" -ge "$CURVE_N" ] || \
       [ "$s_dec" -le "0" ] || [ "$s_dec" -ge "$CURVE_N" ]; then
        echo "错误：签名值超出有效范围" >&2
        return 1
    fi
    
    echo "    验证签名..." >&2
    
    # 1. 计算 w = s⁻¹ mod n
    local w
    w=$(bn_mod_inverse "$s_dec" "$CURVE_N")
    
    # 2. 计算 u1 = hash * w mod n
    local u1
    u1=$(bn_mod_mul "$hash_dec" "$w" "$CURVE_N")
    
    # 3. 计算 u2 = r * w mod n
    local u2
    u2=$(bn_mod_mul "$r_dec" "$w" "$CURVE_N")
    
    # 4. 计算点 (x1, y1) = u1*G + u2*Q
    echo "    计算 u1*G..." >&2
    local x1_g y1_g
    read -r x1_g y1_g < <(scalar_mult "$u1" "$CURVE_GX" "$CURVE_GY")
    
    echo "    计算 u2*Q..." >&2
    local x1_q y1_q
    read -r x1_q y1_q < <(scalar_mult "$u2" "$pub_key_x" "$pub_key_y")
    
    echo "    计算点加法..." >&2
    local x1 y1
    read -r x1 y1 < <(point_add "$x1_g" "$y1_g" "$x1_q" "$y1_q")
    
    # 5. 验证 r ≡ x1 mod n
    local x1_mod
    x1_mod=$(( x1 % CURVE_N ))
    
    if [ "$x1_mod" = "$r_dec" ]; then
        echo "✓ 签名验证成功" >&2
        return 0
    else
        echo "✗ 签名验证失败" >&2
        return 1
    fi
}

# 辅助函数：从签名文件中读取签名
read_signature_from_file() {
    local sig_file="$1"
    if [ -f "$sig_file" ]; then
        tr -d '\n\r' < "$sig_file"
    else
        echo "错误：签名文件不存在: $sig_file" >&2
        return 1
    fi
}