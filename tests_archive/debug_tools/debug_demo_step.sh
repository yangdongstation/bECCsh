#!/bin/bash
# 逐步调试演示案例

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/core/crypto/ec_math_fixed_simple.sh"

echo "逐步调试ECDSA演示案例"
echo "====================="
echo

# 参数
p=23 a=1 b=1 gx=3 gy=10 n=29
private_key=7 message_hash=20 k=5

echo "参数:"
echo "  曲线: y² = x³ + ${a}x + ${b} mod ${p}"
echo "  基点G: ($gx, $gy)"
echo "  阶n: $n"
echo "  私钥: $private_key"
echo "  消息哈希: $message_hash"
echo "  k值: $k"
echo

# 1. 计算公钥
echo "1. 计算公钥 Q = d × G:"
Q=$(curve_scalar_mult_simple "$private_key" "$gx" "$gy" "$a" "$p")
qx=$(echo "$Q" | cut -d' ' -f1)
qy=$(echo "$Q" | cut -d' ' -f2)
echo "Q = ($qx, $qy)"
echo

# 2. 计算签名
echo "2. 计算签名:"

# 计算 P = kG
P=$(curve_scalar_mult_simple "$k" "$gx" "$gy" "$a" "$p")
px=$(echo "$P" | cut -d' ' -f1)
py=$(echo "$P" | cut -d' ' -f2)
echo "P = kG = ($px, $py)"

# r = xP mod n
r=$((px % n))
echo "r = xP mod n = $r"

# s = k⁻¹ * (message_hash + private_key * r) mod n
k_inv=$(mod_inverse_simple "$k" "$n")
echo "k⁻¹ = $k_inv"
s_temp=$((message_hash + private_key * r))
echo "s_temp = message_hash + private_key * r = $message_hash + $private_key * $r = $s_temp"
s=$(((k_inv * s_temp) % n))
echo "s = $s"
echo "签名: (r=$r, s=$s)"
echo

# 3. 验证签名 - 逐步计算
echo "3. 验证签名 - 逐步计算:"

# 计算 w = s⁻¹ mod n
w=$(mod_inverse_simple "$s" "$n")
echo "w = s⁻¹ mod n = $w"

# 计算 u₁ = message_hash × w mod n
u1=$((message_hash * w % n))
echo "u₁ = message_hash × w mod n = $u1"

# 计算 u₂ = r × w mod n
u2=$((r * w % n))
echo "u₂ = r × w mod n = $u2"

# 计算 P₁ = u₁ × G
echo "计算 P₁ = u₁ × G = $u1 × G:"
P1=$(curve_scalar_mult_simple "$u1" "$gx" "$gy" "$a" "$p")
P1_x=$(echo "$P1" | cut -d' ' -f1)
P1_y=$(echo "$P1" | cut -d' ' -f2)
echo "P₁ = ($P1_x, $P1_y)"

# 计算 P₂ = u₂ × Q
echo "计算 P₂ = u₂ × Q = $u2 × Q:"
P2=$(curve_scalar_mult_simple "$u2" "$qx" "$qy" "$a" "$p")
P2_x=$(echo "$P2" | cut -d' ' -f1)
P2_y=$(echo "$P2" | cut -d' ' -f2)
echo "P₂ = ($P2_x, $P2_y)"

# 计算 P = P₁ + P₂
echo "计算 P = P₁ + P₂:"
P_final=$(curve_point_add_correct "$P1_x" "$P1_y" "$P2_x" "$P2_y" "$a" "$p")
final_px=$(echo "$P_final" | cut -d' ' -f1)
final_py=$(echo "$P_final" | cut -d' ' -f2)
echo "P = ($final_px, $final_py)"

# 计算 v = xₚ mod n
v=$((final_px % n))
echo "v = xₚ mod n = $v"
echo

# 结果
echo "4. 结果:"
echo "v = $v, r = $r"

if [[ "$v" == "$r" ]]; then
    echo "✅ 签名验证成功!"
else
    echo "❌ 签名验证失败!"
    echo "差异: v - r = $((v - r))"
fi