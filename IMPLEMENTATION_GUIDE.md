# bECCsh 实现指南 - 从数学到代码

**从理论到实践：如何在 Bash 中实现椭圆曲线密码学**

---

## 📚 目录

1. [概述](#概述)
2. [第一部分：大整数算术](#第一部分大整数算术)
3. [第二部分：有限域运算](#第二部分有限域运算)
4. [第三部分：椭圆曲线点操作](#第三部分椭圆曲线点操作)
5. [第四部分：标量乘法](#第四部分标量乘法)
6. [第五部分：ECDSA签名](#第五部分ecdsa签名)
7. [第六部分：ECDSA验证](#第六部分ecdsa验证)
8. [第七部分：密钥生成](#第七部分密钥生成)
9. [第八部分：文件格式](#第八部分文件格式)
10. [调试和性能优化](#调试和性能优化)

---

## 概述

### 架构层次

```
用户接口 (becc.sh)
    ↓
命令处理层 (keygen, sign, verify, export, import)
    ↓
ECDSA层 (ecdsa.sh) - 签名和验证逻辑
    ↓
点操作层 (ec_point.sh) - 点加法和倍增
    ↓
曲线参数层 (ec_curve.sh) - 曲线定义
    ↓
数学库层 (bash_math.sh, bigint.sh) - 基础运算
    ↓
熵收集层 (entropy.sh) - 随机数生成
```

### 文件对应关系

| 文件 | 职责 | 关键函数 |
|------|------|---------|
| becc.sh | 主程序和CLI | main() |
| beccsh/bash_math.sh | 基础算术和十六进制转换 | bashmath_* |
| beccsh/bigint.sh | 大整数加减乘除模运算 | bigint_* |
| beccsh/ec_curve.sh | 椭圆曲线参数管理 | curve_* |
| beccsh/ec_point.sh | 点加法、倍增、标量乘法 | ec_* |
| beccsh/ecdsa.sh | 签名和验证核心算法 | ecdsa_* |
| beccsh/entropy.sh | 安全随机数生成 | entropy_* |

---

## 第一部分：大整数算术

### 数学概念

在密码学中，我们需要处理极大的数字（256位 = 78位十进制）：

```
256 位数最大值：
115792089237316195423570985008687907853269984665640564039457584007913129639935
↑
普通 bash 整数最多 64 位（19位十进制）
```

### 实现策略：字符串逐位运算

Bash 本身无法处理这么大的数字。bECCsh 的解决方案是将大整数表示为**十进制字符串**，然后逐位执行运算。

#### 1.1 十六进制↔十进制转换

**数学原理**：

```
十六进制 ABC16 转十进制：
= A×16² + B×16¹ + C×16⁰
= 10×256 + 11×16 + 12×1
= 2560 + 176 + 12
= 2748
```

**代码实现** - bashmath.sh：

```bash
bashmath_hex_to_dec() {
    local hex="$1"
    local dec=0
    local i

    # 将十六进制字符串转为大写（便于处理）
    hex="${hex^^}"

    # 逐个字符处理，从左到右
    for ((i = 0; i < ${#hex}; i++)); do
        local char="${hex:$i:1}"
        local digit

        # 将十六进制字符转为数值 0-15
        case "$char" in
            [0-9]) digit=$((10#$char)) ;;
            A) digit=10 ;;
            B) digit=11 ;;
            C) digit=12 ;;
            D) digit=13 ;;
            E) digit=14 ;;
            F) digit=15 ;;
        esac

        # dec = dec * 16 + digit
        dec=$(bashmath_mult "$dec" 16)
        dec=$(bashmath_add "$dec" "$digit")
    done

    echo "$dec"
}
```

**关键点**：
- 逐位处理避免整数溢出
- `bashmath_mult` 和 `bashmath_add` 处理大整数
- 时间复杂度 O(n×m)，其中 n 是输入长度，m 是中间数字长度

#### 1.2 加法运算

**数学原理**（小学竖式加法）：

```
    12345
  +  6789
  --------
    19134

从右到左逐位：5+9=14→进位1
          4+8+1=13→进位1
          3+7+1=11→进位1
          2+6+1=9
          1=1
```

**代码实现** - bigint.sh：

```bash
bigint_add() {
    local a="$1"
    local b="$2"
    local result=""
    local carry=0
    local max_len

    # 处理空值
    a="${a:-0}"
    b="${b:-0}"

    # 补齐长度
    max_len=$((${#a} > ${#b} ? ${#a} : ${#b}))
    a=$(printf "%${max_len}s" "$a" | tr ' ' '0')
    b=$(printf "%${max_len}s" "$b" | tr ' ' '0')

    # 从右到左逐位相加
    for ((i = max_len - 1; i >= 0; i--)); do
        local digit_a="${a:$i:1}"
        local digit_b="${b:$i:1}"
        local sum=$((digit_a + digit_b + carry))

        result="$((sum % 10))${result}"
        carry=$((sum / 10))
    done

    # 处理最后的进位
    if [[ $carry -gt 0 ]]; then
        result="${carry}${result}"
    fi

    # 移除前导零
    result="${result##+(0)}"
    echo "${result:-0}"
}
```

**性能**：O(n)，其中 n 是数字长度

#### 1.3 乘法运算

**数学原理**（小学竖式乘法）：

```
     123
   ×  45
   -----
     615  (123 × 5)
    492   (123 × 4，向左移位1)
   -----
    5535
```

**代码实现** - bigint.sh（简化版）：

```bash
bigint_mult() {
    local a="$1"
    local b="$2"
    local result="0"
    local i

    a="${a:-0}"
    b="${b:-0}"

    # 如果有一个是0，直接返回0
    if [[ "$a" == "0" || "$b" == "0" ]]; then
        echo "0"
        return
    fi

    # b 的每一位乘以 a，然后加到结果中
    for ((i = 0; i < ${#b}; i++)); do
        local digit="${b:$((${#b} - i - 1)):1}"
        local partial=$(bigint_single_mult "$a" "$digit")

        # 乘以 10^i（向左移位）
        for ((j = 0; j < i; j++)); do
            partial="${partial}0"
        done

        result=$(bigint_add "$result" "$partial")
    done

    echo "$result"
}

# 一个数乘以单个数字（0-9）
bigint_single_mult() {
    local a="$1"
    local digit="$2"
    local result=""
    local carry=0
    local i

    for ((i = ${#a} - 1; i >= 0; i--)); do
        local prod=$((${a:$i:1} * digit + carry))
        result="$((prod % 10))${result}"
        carry=$((prod / 10))
    done

    if [[ $carry -gt 0 ]]; then
        result="${carry}${result}"
    fi

    echo "$result"
}
```

**性能**：O(n²)，较慢但足以满足需求

#### 1.4 取模运算

**数学原理**：

```
a mod n = a - (a ÷ n) × n

例如：23 mod 7
= 23 - (23 ÷ 7) × 7
= 23 - 3 × 7
= 23 - 21
= 2
```

**代码实现** - bigint.sh：

```bash
bigint_mod() {
    local a="$1"
    local n="$2"

    # 模0无意义
    if [[ -z "$n" || "$n" == "0" ]]; then
        echo "错误：模数为0"
        return 1
    fi

    # 如果 a < n，直接返回 a
    if [[ ${#a} -lt ${#n} ]] || \
       [[ ${#a} -eq ${#n} && "$a" < "$n" ]]; then
        echo "$a"
        return
    fi

    # 进行长除法
    local quotient
    local remainder="0"
    local i

    for ((i = 0; i < ${#a}; i++)); do
        # 余数向左移一位，加上 a 的下一位
        remainder="${remainder}${a:$i:1}"
        remainder="${remainder##+(0)}"  # 移除前导零
        remainder="${remainder:-0}"

        # 计算商的这一位
        local q=0
        while [[ $(bigint_compare "$remainder" "$n") -ge 0 ]]; do
            remainder=$(bigint_sub "$remainder" "$n")
            q=$((q + 1))
        done
    done

    echo "$remainder"
}
```

**性能**：O(n×m)，其中 n 是被除数长度，m 是除数长度

---

## 第二部分：有限域运算

### 数学概念

有限域运算 = 所有运算都在 mod p 下进行（p 是素数）

```
普通算术：a + b, a × b, a - b, ...
有限域算术：(a + b) mod p, (a × b) mod p, (a - b) mod p, ...
```

### 实现原则

**每个算术运算后立即取模**，确保数字始终在 0 到 p-1 范围内。

#### 2.1 有限域加法

```bash
fe_add() {
    local a="$1"
    local b="$2"
    local p="$3"  # 模数

    local sum=$(bigint_add "$a" "$b")
    local result=$(bigint_mod "$sum" "$p")
    echo "$result"
}
```

#### 2.2 有限域乘法

```bash
fe_mult() {
    local a="$1"
    local b="$2"
    local p="$3"

    local prod=$(bigint_mult "$a" "$b")
    local result=$(bigint_mod "$prod" "$p")
    echo "$result"
}
```

#### 2.3 有限域乘法逆元（最复杂）

**数学背景**：找到 x 使得 `a × x ≡ 1 (mod p)`

使用**扩展欧几里得算法**：

```
如果 p 是质数，对所有 1 ≤ a < p，都存在唯一的 x。

通过扩展欧几里得算法：
gcd(a, p) = 1
a × x + p × y = 1
→ a × x ≡ 1 (mod p)
→ x 就是 a 的逆元
```

**代码实现** - bash_math.sh：

```bash
bashmath_extended_gcd() {
    local a="$1"
    local b="$2"

    if [[ "$b" == "0" ]]; then
        echo "$a 1 0"
        return
    fi

    local result=$(bashmath_extended_gcd "$b" "$((a % b))")
    local gcd=$(echo "$result" | cut -d' ' -f1)
    local x1=$(echo "$result" | cut -d' ' -f2)
    local y1=$(echo "$result" | cut -d' ' -f3)

    local x=$y1
    local y=$((x1 - (a / b) * y1))

    echo "$gcd $x $y"
}

# 有限域乘法逆元
fe_inverse() {
    local a="$1"
    local p="$2"

    local result=$(bashmath_extended_gcd "$a" "$p")
    local x=$(echo "$result" | cut -d' ' -f2)

    # 确保 x 是正数
    x=$((x % p))
    if [[ $x -lt 0 ]]; then
        x=$((x + p))
    fi

    echo "$x"
}
```

**验证**：`(a × x) mod p = 1`

---

## 第三部分：椭圆曲线点操作

### 数学概念

椭圆曲线上的点满足方程：
```
y² ≡ x³ + ax + b (mod p)
```

两个点相加的规则：
```
P + Q = R（通过几何方法）
```

### 实现核心：点加法

#### 3.1 不同的两个点 P ≠ Q

**数学步骤**：

```
已知：P = (x₁, y₁), Q = (x₂, y₂)
求：R = P + Q = (x₃, y₃)

步骤1：计算斜率
λ = (y₂ - y₁) / (x₂ - x₁)  mod p
  = (y₂ - y₁) × (x₂ - x₁)⁻¹ mod p

步骤2：计算新点
x₃ = λ² - x₁ - x₂  mod p
y₃ = λ(x₁ - x₃) - y₁  mod p
```

**代码实现** - ec_point.sh：

```bash
ec_point_add() {
    local px="$1" py="$2"  # 点 P
    local qx="$3" qy="$4"  # 点 Q
    local a="$5"           # 曲线参数 a
    local p="$6"           # 素数 p

    # 无穷远点检查
    if [[ "$px" == "infinity" && "$py" == "infinity" ]]; then
        echo "$qx $qy"
        return
    fi
    if [[ "$qx" == "infinity" && "$qy" == "infinity" ]]; then
        echo "$px $py"
        return
    fi

    # 判断是否是同一个点
    if [[ "$px" == "$qx" && "$py" == "$qy" ]]; then
        # 同一个点，调用倍增
        ec_point_double "$px" "$py" "$a" "$p"
        return
    fi

    # 判断是否是互为镜像的点（x 相同，y 相反）
    local neg_qy=$(fe_sub "0" "$qy" "$p")
    if [[ "$px" == "$qx" && "$py" == "$neg_qy" ]]; then
        echo "infinity infinity"
        return
    fi

    # 计算斜率 λ = (qy - py) / (qx - px) mod p
    local dy=$(fe_sub "$qy" "$py" "$p")
    local dx=$(fe_sub "$qx" "$px" "$p")
    local dx_inv=$(fe_inverse "$dx" "$p")
    local lambda=$(fe_mult "$dy" "$dx_inv" "$p")

    # 计算 x₃ = λ² - x₁ - x₂ mod p
    local lambda_sq=$(fe_mult "$lambda" "$lambda" "$p")
    local x3=$(fe_sub "$lambda_sq" "$px" "$p")
    x3=$(fe_sub "$x3" "$qx" "$p")

    # 计算 y₃ = λ(x₁ - x₃) - y₁ mod p
    local x1_minus_x3=$(fe_sub "$px" "$x3" "$p")
    local y3=$(fe_mult "$lambda" "$x1_minus_x3" "$p")
    y3=$(fe_sub "$y3" "$py" "$p")

    echo "$x3 $y3"
}
```

#### 3.2 同一个点：点倍增 P + P

**数学步骤**：

```
已知：P = (x₁, y₁)
求：R = P + P = (x₃, y₃)

步骤1：计算切线斜率（使用微积分）
λ = (3x₁² + a) / (2y₁)  mod p

步骤2：计算新点（公式相同）
x₃ = λ² - 2x₁  mod p
y₃ = λ(x₁ - x₃) - y₁  mod p
```

**代码实现** - ec_point.sh：

```bash
ec_point_double() {
    local px="$1" py="$2"
    local a="$3"
    local p="$4"

    # 无穷远点
    if [[ "$py" == "0" ]]; then
        echo "infinity infinity"
        return
    fi

    # 计算斜率 λ = (3x₁² + a) / (2y₁) mod p
    local px_sq=$(fe_mult "$px" "$px" "$p")
    local numerator=$(fe_mult "3" "$px_sq" "$p")
    numerator=$(fe_add "$numerator" "$a" "$p")

    local denominator=$(fe_mult "2" "$py" "$p")
    local denom_inv=$(fe_inverse "$denominator" "$p")
    local lambda=$(fe_mult "$numerator" "$denom_inv" "$p")

    # 计算 x₃ = λ² - 2x₁ mod p
    local lambda_sq=$(fe_mult "$lambda" "$lambda" "$p")
    local x3=$(fe_sub "$lambda_sq" "$px" "$p")
    x3=$(fe_sub "$x3" "$px" "$p")

    # 计算 y₃ = λ(x₁ - x₃) - y₁ mod p
    local x1_minus_x3=$(fe_sub "$px" "$x3" "$p")
    local y3=$(fe_mult "$lambda" "$x1_minus_x3" "$p")
    y3=$(fe_sub "$y3" "$py" "$p")

    echo "$x3 $y3"
}
```

---

## 第四部分：标量乘法

### 数学概念

计算 `k × P`（k 倍的点 P），其中 k 可能非常大（256位）

**朴素方法**：P + P + P + ... + P（k 次）
- 对 k = 2^256 来说，需要 10^77 次加法 ❌

**聪明方法**：二进制展开（Double-and-Add）
- 只需约 2 × 256 = 512 次操作 ✓

### 实现：二进制方法

**数学原理**：

```
k = 5 = 0b101₂ = 1×2² + 0×2¹ + 1×2⁰

5×P = (1×4 + 0×2 + 1×1) × P
    = 4P + P
    = (P + P) + (P + P) + P

计算步骤：
P → 2P → 4P
          4P + P = 5P ✓
```

**代码实现** - ec_point.sh：

```bash
ec_scalar_mult() {
    local k="$1"           # 标量
    local px="$2" py="$3"  # 点 P
    local a="$4"
    local p="$5"

    # 处理特殊情况
    if [[ "$k" == "0" ]]; then
        echo "infinity infinity"
        return
    fi

    # 初始化：result = O（无穷远点）
    local result_x="infinity"
    local result_y="infinity"

    # 当前点：Q = P
    local cur_x="$px"
    local cur_y="$py"

    # 对 k 的每一位处理（从最低位到最高位）
    while [[ "$k" != "0" ]]; do
        # 如果当前位是 1，加上当前点
        if [[ $((k % 2)) -eq 1 ]]; then
            if [[ "$result_x" == "infinity" && "$result_y" == "infinity" ]]; then
                result_x="$cur_x"
                result_y="$cur_y"
            else
                local temp=$(ec_point_add "$result_x" "$result_y" \
                                          "$cur_x" "$cur_y" \
                                          "$a" "$p")
                result_x=$(echo "$temp" | cut -d' ' -f1)
                result_y=$(echo "$temp" | cut -d' ' -f2)
            fi
        fi

        # 倍增当前点：Q = 2Q
        local temp=$(ec_point_double "$cur_x" "$cur_y" "$a" "$p")
        cur_x=$(echo "$temp" | cut -d' ' -f1)
        cur_y=$(echo "$temp" | cut -d' ' -f2)

        # k 右移一位（整数除以2）
        k=$((k / 2))
    done

    echo "$result_x $result_y"
}
```

**时间复杂度**：O(log k)，其中 k 是标量

---

## 第五部分：ECDSA 签名

### 数学流程

```
消息 m
  ↓
1. 哈希：h = SHA256(m)
  ↓
2. 生成随机 k（1 到 n-1 之间）
   实际使用 RFC 6979：k = HMAC 推导
  ↓
3. 计算点：(x₁, y₁) = k × G
  ↓
4. 提取第一部分：r = x₁ mod n
  ↓
5. 计算第二部分：s = k⁻¹ × (h + d × r) mod n
     其中 d 是私钥，n 是曲线阶
  ↓
签名 = (r, s)
```

### 代码实现 - ecdsa.sh：

```bash
ecdsa_sign() {
    local message="$1"
    local private_key="$2"
    local curve="$3"

    # 步骤1：加载曲线参数
    source "beccsh/ec_curve.sh"
    local -n params="${curve}_params"
    local p="${params[p]}"
    local n="${params[n]}"
    local a="${params[a]}"
    local Gx="${params[Gx]}"
    local Gy="${params[Gy]}"

    # 步骤2：计算消息哈希
    local h=$(sha256sum <<<"$message" | cut -d' ' -f1)
    h=$(bashmath_hex_to_dec "$h")
    h=$(bigint_mod "$h" "$n")

    # 步骤3：生成（或推导）随机数 k
    local k
    if [[ -n "${RFC_6979_MODE:-}" ]]; then
        # RFC 6979：确定性 k
        k=$(rfc6979_derive_k "$h" "$private_key" "$n")
    else
        # 从熵源生成随机 k
        k=$(entropy_random_in_range "1" "$n")
    fi

    # 步骤4：计算 (x₁, y₁) = k × G
    local kG=$(ec_scalar_mult "$k" "$Gx" "$Gy" "$a" "$p")
    local x1=$(echo "$kG" | cut -d' ' -f1)
    local y1=$(echo "$kG" | cut -d' ' -f2)

    # 步骤5：提取 r = x₁ mod n
    local r=$(bigint_mod "$x1" "$n")

    # 如果 r = 0，重新生成 k（极其罕见）
    if [[ "$r" == "0" ]]; then
        # 递归调用
        ecdsa_sign "$message" "$private_key" "$curve"
        return
    fi

    # 步骤6：计算 s = k⁻¹ × (h + d × r) mod n
    local k_inv=$(fe_inverse "$k" "$n")

    local d_times_r=$(bigint_mult "$private_key" "$r")
    d_times_r=$(bigint_mod "$d_times_r" "$n")

    local h_plus_dr=$(bigint_add "$h" "$d_times_r")
    h_plus_dr=$(bigint_mod "$h_plus_dr" "$n")

    local s=$(bigint_mult "$k_inv" "$h_plus_dr")
    s=$(bigint_mod "$s" "$n")

    # 如果 s = 0，重新生成 k（极其罕见）
    if [[ "$s" == "0" ]]; then
        ecdsa_sign "$message" "$private_key" "$curve"
        return
    fi

    # 返回签名 (r, s)
    echo "$r $s"
}
```

### RFC 6979：确定性 k 生成

**为什么需要**：随机 k 的泄露会导致私钥破解

**解决方案**：从消息和私钥推导 k

```bash
rfc6979_derive_k() {
    local h="$1"           # 消息哈希
    local d="$2"           # 私钥
    local n="$3"           # 曲线阶

    # 初始化
    local V=$(printf '\x01%.0s' {1..32})
    local K=$(printf '\x00%.0s' {1..32})

    # 步骤1：更新 K 和 V
    local input="${V}${d}${h}"
    K=$(echo -n "$K" | xxd -r -p | \
        openssl dgst -sha256 -hmac <(echo -n "$K" | xxd -r -p) -binary | \
        xxd -p)

    V=$(echo -n "$V" | xxd -r -p | \
        openssl dgst -sha256 -hmac <(echo -n "$K" | xxd -r -p) -binary | \
        xxd -p)

    # 步骤2：重复直到生成有效的 k
    local T
    while true; do
        T=""
        while [[ $(echo -n "$T" | wc -c) -lt 32 ]]; do
            V=$(echo -n "$V" | xxd -r -p | \
                openssl dgst -sha256 -hmac <(echo -n "$K" | xxd -r -p) -binary | \
                xxd -p)
            T="${T}${V}"
        done

        local k=$(echo "${T:0:64}" | bashmath_hex_to_dec)

        # 检查 k 是否在有效范围内
        if [[ $k -gt 0 && $(bigint_compare "$k" "$n") -lt 0 ]]; then
            echo "$k"
            return
        fi

        # 否则重新推导
        K=$(echo -n "$K${V}" | xxd -r -p | \
            openssl dgst -sha256 -hmac <(echo -n "$K" | xxd -r -p) -binary | \
            xxd -p)

        V=$(echo -n "$V" | xxd -r -p | \
            openssl dgst -sha256 -hmac <(echo -n "$K" | xxd -r -p) -binary | \
            xxd -p)
    done
}
```

---

## 第六部分：ECDSA 验证

### 数学流程

```
接收：消息 m，签名 (r, s)，公钥 Q = d×G
  ↓
1. 哈希消息：h = SHA256(m)
  ↓
2. 计算 w = s⁻¹ mod n
  ↓
3. 计算 u₁ = h × w mod n
         u₂ = r × w mod n
  ↓
4. 计算点：(x₁, y₁) = u₁ × G + u₂ × Q
         使用点加法
  ↓
5. 验证：if (x₁ mod n == r)
            VALID ✓
         else
            INVALID ✗
```

### 代码实现 - ecdsa.sh：

```bash
ecdsa_verify() {
    local message="$1"
    local r="$2" s="$3"           # 签名
    local public_key_x="$4"
    local public_key_y="$5"        # 公钥 Q
    local curve="$6"

    # 步骤1：加载曲线参数
    source "beccsh/ec_curve.sh"
    local -n params="${curve}_params"
    local p="${params[p]}"
    local n="${params[n]}"
    local a="${params[a]}"
    local Gx="${params[Gx]}"
    local Gy="${params[Gy]}"

    # 步骤2：验证签名值的范围
    if [[ $r -le 0 || $r -ge $n ]] || [[ $s -le 0 || $s -ge $n ]]; then
        echo "INVALID"
        return
    fi

    # 步骤3：计算消息哈希
    local h=$(sha256sum <<<"$message" | cut -d' ' -f1)
    h=$(bashmath_hex_to_dec "$h")
    h=$(bigint_mod "$h" "$n")

    # 步骤4：计算 w = s⁻¹ mod n
    local w=$(fe_inverse "$s" "$n")

    # 步骤5：计算 u₁ = h × w mod n
    local u1=$(bigint_mult "$h" "$w")
    u1=$(bigint_mod "$u1" "$n")

    # 步骤6：计算 u₂ = r × w mod n
    local u2=$(bigint_mult "$r" "$w")
    u2=$(bigint_mod "$u2" "$n")

    # 步骤7：计算 u₁ × G
    local u1G=$(ec_scalar_mult "$u1" "$Gx" "$Gy" "$a" "$p")
    local u1Gx=$(echo "$u1G" | cut -d' ' -f1)
    local u1Gy=$(echo "$u1G" | cut -d' ' -f2)

    # 步骤8：计算 u₂ × Q
    local u2Q=$(ec_scalar_mult "$u2" "$public_key_x" "$public_key_y" "$a" "$p")
    local u2Qx=$(echo "$u2Q" | cut -d' ' -f1)
    local u2Qy=$(echo "$u2Q" | cut -d' ' -f2)

    # 步骤9：计算 R = u₁×G + u₂×Q
    local R=$(ec_point_add "$u1Gx" "$u1Gy" "$u2Qx" "$u2Qy" "$a" "$p")
    local Rx=$(echo "$R" | cut -d' ' -f1)
    local Ry=$(echo "$R" | cut -d' ' -f2)

    # 步骤10：检查是否是无穷远点
    if [[ "$Rx" == "infinity" && "$Ry" == "infinity" ]]; then
        echo "INVALID"
        return
    fi

    # 步骤11：验证 Rx ≡ r (mod n)
    local rx_mod=$(bigint_mod "$Rx" "$n")

    if [[ "$rx_mod" == "$r" ]]; then
        echo "VALID"
    else
        echo "INVALID"
    fi
}
```

### 为什么验证有效？（数学证明）

如果签名生成正确：

```
s = k⁻¹(h + dr) mod n

两边乘以 k：
ks = h + dr mod n

在验证中：
u₁×G + u₂×Q
= (hw)×G + (rw)×Q
= (hw)×G + (rw)×d×G     （Q = d×G）
= (hw + rwd)×G
= w(h + rd)×G
= w(ks)×G
= (w×s⁻¹)×k×G
= 1×k×G
= k×G

所以验证点的 x 坐标确实等于 r！✓
```

---

## 第七部分：密钥生成

### 数学流程

```
1. 生成随机私钥 d
   1 ≤ d < n

2. 计算公钥 Q = d × G
   使用标量乘法

3. 返回：
   私钥：d（需要保密）
   公钥：Q = (Qx, Qy)（可以公开）
```

### 代码实现 - becc.sh：

```bash
cmd_keygen() {
    local curve="${curve_name:-secp256r1}"
    local output_file="${output_file:-}"

    # 验证曲线
    if ! is_valid_curve "$curve"; then
        echo "错误：不支持的曲线：$curve"
        exit 1
    fi

    echo "生成 $curve 密钥对..."
    echo "这可能需要 2 分钟左右..."

    # 步骤1：从熵源生成随机私钥
    source "beccsh/ec_curve.sh"
    local -n params="${curve}_params"
    local n="${params[n]}"

    local private_key=$(entropy_random_in_range "1" "$n")

    echo "✓ 私钥已生成"

    # 步骤2：计算公钥
    local Gx="${params[Gx]}"
    local Gy="${params[Gy]}"
    local a="${params[a]}"
    local p="${params[p]}"

    echo "计算公钥（这需要一些时间）..."

    local Q=$(ec_scalar_mult "$private_key" "$Gx" "$Gy" "$a" "$p")
    local Qx=$(echo "$Q" | cut -d' ' -f1)
    local Qy=$(echo "$Q" | cut -d' ' -f2)

    echo "✓ 公钥已生成"

    # 步骤3：保存密钥
    if [[ -n "$output_file" ]]; then
        # 保存为 PEM 格式
        export_key_to_pem "$curve" "$private_key" "$Qx" "$Qy" "$output_file"
        export_public_key_to_pem "$curve" "$Qx" "$Qy" "${output_file%.pem}_public.pem"
    else
        # 显示密钥
        echo ""
        echo "========== 密钥信息 =========="
        echo "曲线：$curve"
        echo "私钥：$private_key"
        echo "公钥 X：$Qx"
        echo "公钥 Y：$Qy"
    fi

    echo ""
    echo "✓ 密钥生成完成！"
}
```

### 随机数生成 - entropy.sh：

```bash
entropy_random_in_range() {
    local min="$1"
    local max="$2"

    # 计算范围大小
    local range=$(bigint_sub "$max" "$min")
    local range_len=${#range}

    # 从 /dev/urandom 读取足够的字节
    local bytes_needed=$((range_len / 2 + 1))
    local random_bytes=$(dd if=/dev/urandom bs=1 count=$bytes_needed 2>/dev/null | \
                        xxd -p)

    # 转换为十进制
    local random_num=$(bashmath_hex_to_dec "$random_bytes")

    # 限制在范围内
    random_num=$(bigint_mod "$random_num" "$range")
    random_num=$(bigint_add "$random_num" "$min")

    echo "$random_num"
}
```

---

## 第八部分：文件格式

### PEM 格式（私钥）

```
-----BEGIN EC PRIVATE KEY-----
[Base64 编码的 DER 数据]
-----END EC PRIVATE KEY-----
```

### DER 编码（ASN.1）

DER 是二进制编码格式，结构为：

```
SEQUENCE {
  version: INTEGER = 1
  privateKey: OCTET STRING (私钥字节)
  parameters: [0] EXPLICIT OBJECT IDENTIFIER (曲线OID)
  publicKey: [1] EXPLICIT BIT STRING (公钥字节)
}
```

### 代码实现 - becc.sh：

```bash
export_key_to_pem() {
    local curve="$1"
    local private_key="$2"
    local public_x="$3"
    local public_y="$4"
    local output_file="$5"

    # 获取曲线 OID
    local oid=$(get_curve_oid "$curve")

    # 步骤1：构建 DER 编码
    local der=$(build_ec_der_private_key "$private_key" "$public_x" "$public_y" "$oid")

    # 步骤2：转换为 Base64
    local b64=$(echo -n "$der" | base64 -w 64)

    # 步骤3：写入 PEM 文件
    {
        echo "-----BEGIN EC PRIVATE KEY-----"
        echo "$b64"
        echo "-----END EC PRIVATE KEY-----"
    } > "$output_file"

    chmod 600 "$output_file"
    echo "✓ 私钥已保存到：$output_file"
}
```

---

## 调试和性能优化

### 调试技巧

#### 1. 启用追踪模式

```bash
# 在 becc.sh 顶部添加
set -x  # 显示所有执行的命令
set -v  # 显示所有读取的行

# 或只调试特定函数
debug_ec_scalar_mult() {
    local k="$1" px="$2" py="$3" a="$4" p="$5"
    echo "[DEBUG] 计算 $k × ($px, $py)"
    echo "[DEBUG] 曲线参数：a=$a, p=$p"

    # 调用原函数
    ec_scalar_mult "$k" "$px" "$py" "$a" "$p"
}
```

#### 2. 中间值检查

```bash
# 在关键点添加输出
verify_point_on_curve() {
    local x="$1" y="$2" a="$3" b="$4" p="$5"

    # 计算 y²
    local y_sq=$(fe_mult "$y" "$y" "$p")

    # 计算 x³ + ax + b
    local x_cu=$(fe_mult "$x" "$x" "$p")
    x_cu=$(fe_mult "$x_cu" "$x" "$p")

    local ax=$(fe_mult "$a" "$x" "$p")

    local right=$(fe_add "$x_cu" "$ax" "$p")
    right=$(fe_add "$right" "$b" "$p")

    # 验证
    if [[ "$y_sq" == "$right" ]]; then
        echo "[✓] 点 ($x, $y) 在曲线上"
        return 0
    else
        echo "[✗] 点 ($x, $y) 不在曲线上！"
        echo "    y² = $y_sq"
        echo "    x³ + ax + b = $right"
        return 1
    fi
}
```

### 性能优化

#### 1. 缓存计算结果

```bash
# 缓存 Gx², Gx³ 等常用值
declare -A point_cache

cache_point_powers() {
    local x="$1" a="$2" p="$3"

    point_cache["x²"]=$(fe_mult "$x" "$x" "$p")
    point_cache["x³"]=$(fe_mult "$x" "${point_cache[x²]}" "$p")
    point_cache["3x²"]=$(fe_mult "3" "${point_cache[x²]}" "$p")
    point_cache["3x²+a"]=$(fe_add "${point_cache[3x²]}" "$a" "$p")
}
```

#### 2. 避免重复的 mod p 操作

```bash
# 不好的做法
result=$(fe_add "$a" "$b" "$p")
result=$(fe_add "$result" "$c" "$p")
result=$(fe_add "$result" "$d" "$p")
# 每次都 mod p，共3次

# 好的做法
result=$(bigint_add "$a" "$b")
result=$(bigint_add "$result" "$c")
result=$(bigint_add "$result" "$d")
result=$(bigint_mod "$result" "$p")
# 只在最后 mod p 一次
```

#### 3. 使用字符串长度优化

```bash
# 快速比较两个大整数的大小
bigint_compare_fast() {
    local a="$1" b="$2"

    # 先比较长度
    if [[ ${#a} -lt ${#b} ]]; then
        echo "-1"  # a < b
        return
    elif [[ ${#a} -gt ${#b} ]]; then
        echo "1"   # a > b
        return
    fi

    # 长度相同时再做字符串比较
    if [[ "$a" < "$b" ]]; then
        echo "-1"
    elif [[ "$a" > "$b" ]]; then
        echo "1"
    else
        echo "0"
    fi
}
```

### 性能基准

| 操作 | 时间 | vs OpenSSL |
|------|------|-----------|
| 密钥生成 | 120 秒 | 6000× |
| 签名 | 380 秒 | 38000× |
| 验证 | 450 秒 | 45000× |

---

## 总结

### 知识映射

```
数学概念          →    代码实现          →    文件位置
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
模运算             →    bigint_mod        →    bigint.sh
乘法逆元           →    fe_inverse        →    bash_math.sh
点加法             →    ec_point_add      →    ec_point.sh
点倍增             →    ec_point_double   →    ec_point.sh
标量乘法           →    ec_scalar_mult    →    ec_point.sh
ECDSA签名          →    ecdsa_sign        →    ecdsa.sh
ECDSA验证          →    ecdsa_verify      →    ecdsa.sh
RFC 6979推导       →    rfc6979_derive_k  →    ecdsa.sh
密钥生成           →    cmd_keygen        →    becc.sh
```

### 学习路径建议

1. **理论基础** → MATH_CRYPTOGRAPHY_GUIDE.md
2. **知识演进** → MATHEMATICS_DEEP_FOUNDATIONS.md
3. **代码级实现** → 本文档（IMPLEMENTATION_GUIDE.md）
4. **实际应用** → 运行 `./becc.sh` 命令

---

*本指南旨在帮助开发者理解 bECCsh 的实现细节。通过连接数学和代码，我们可以更深入地理解椭圆曲线密码学的工作原理。*
