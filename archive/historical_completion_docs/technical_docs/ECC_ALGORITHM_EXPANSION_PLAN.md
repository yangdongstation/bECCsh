# 🚀 bECCsh ECC算法扩展计划

## 🎯 扩展目标

在现有SECP256K1基础上，增加对更多标准椭圆曲线算法的支持，将bECCsh打造成完整的纯Bash椭圆曲线密码学库。

## 📋 支持的椭圆曲线算法

### 🔴 高优先级（核心扩展）

#### 1. SECP256R1 (P-256) - NIST标准
- **别名**：PRIME256V1, P-256
- **用途**：TLS 1.3, JWT, 政府标准
- **参数**：
  - 素数p: 2^256 - 2^224 + 2^192 + 2^96 - 1
  - 阶n: 0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551
  - 系数a: -3 (0xffffffff00000001000000000000000000000000fffffffffffffffffffffffc)
  - 系数b: 0x5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b
  - 基点Gx: 0x6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296
  - 基点Gy: 0x4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5

#### 2. SECP384R1 (P-384) - NIST标准
- **别名**：PRIME384V1
- **用途**：高安全性应用，政府加密
- **参数**：更大的密钥长度(384位)

#### 3. SECP521R1 (P-521) - NIST标准
- **别名**：PRIME521V1
- **用途**：最高安全级别，长期保密
- **参数**：521位密钥长度

### 🟡 中优先级（标准扩展）

#### 4. SECP224K1
- **用途**：比特币早期使用，中等安全级别
- **特点**：Koblitz曲线，计算效率高

#### 5. SECP192K1
- **用途**：轻量级应用，物联网设备
- **特点**：较小密钥尺寸，适合资源受限环境

### 🟢 低优先级（高级扩展）

#### 6. Brainpool曲线系列
- **BrainpoolP256r1**：欧洲标准
- **BrainpoolP384r1**：高安全性欧洲标准
- **BrainpoolP512r1**：最高安全级别

#### 7. Curve25519相关
- **Curve25519**：Daniel J. Bernstein设计
- **Ed25519**：Edwards形式，高性能签名

## 🔧 技术实现计划

### 第一阶段：核心NIST曲线（1-2周）

#### 1. 参数定义模块
```bash
# core/curves/secp256r1_params.sh
#!/bin/bash
# SECP256R1 (P-256) 参数定义

SECP256R1_P="ffffffff00000001000000000000000000000000ffffffffffffffffffffffff"
SECP256R1_A="ffffffff00000001000000000000000000000000fffffffffffffffffffffffc"
SECP256R1_B="5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b"
SECP256R1_N="ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551"
SECP256R1_GX="6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296"
SECP256R1_GY="4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5"
```

#### 2. 曲线选择接口
```bash
# core/curve_selector.sh
#!/bin/bash
# 椭圆曲线选择器

select_curve() {
    local curve_name="$1"
    case "$curve_name" in
        "secp256k1")
            source "${SCRIPT_DIR}/curves/secp256k1_params.sh"
            ;;
        "secp256r1"|"p-256"|"prime256v1")
            source "${SCRIPT_DIR}/curves/secp256r1_params.sh"
            ;;
        "secp384r1"|"p-384"|"prime384v1")
            source "${SCRIPT_DIR}/curves/secp384r1_params.sh"
            ;;
        "secp521r1"|"p-521"|"prime521v1")
            source "${SCRIPT_DIR}/curves/secp521r1_params.sh"
            ;;
        *)
            echo "错误：不支持的椭圆曲线 $curve_name"
            return 1
            ;;
    esac
}
```

#### 3. 通用ECC运算核心
```bash
# core/ecc_generic.sh
#!/bin/bash
# 通用椭圆曲线运算

# 模运算（适用于不同曲线）
mod_reduce() {
    local value="$1"
    local modulus="$2"
    # 实现适用于大数的模约简
}

# 点加法（通用算法）
ec_point_add() {
    local x1="$1" y1="$2" x2="$3" y2="$4" a="$5" p="$6"
    # 实现通用椭圆曲线点加法
}

# 点乘法（通用算法）
ec_point_multiply() {
    local k="$1" gx="$2" gy="$3" a="$4" p="$5"
    # 实现通用椭圆曲线点乘法
}
```

### 第二阶段：多曲线支持（2-3周）

#### 1. 曲线验证测试
```bash
# demo/tests/multi_curve_validation.sh
#!/bin/bash
# 多曲线验证测试

test_curve() {
    local curve_name="$1"
    echo "测试椭圆曲线: $curve_name"
    
    # 加载曲线参数
    select_curve "$curve_name"
    
    # 执行标准测试向量
    run_known_answer_tests "$curve_name"
    
    # 验证OpenSSL兼容性
    compare_with_openssl "$curve_name"
}

# 测试所有支持的曲线
curves=("secp256k1" "secp256r1" "secp384r1" "secp521r1")
for curve in "${curves[@]}"; do
    test_curve "$curve"
done
```

#### 2. 性能基准测试
```bash
# demo/benchmarks/curve_performance.sh
#!/bin/bash
# 椭圆曲线性能基准测试

benchmark_curve() {
    local curve_name="$1"
    echo "性能测试: $curve_name"
    
    # 密钥生成性能
    time_key_generation "$curve_name"
    
    # 签名性能
    time_signature_generation "$curve_name"
    
    # 验证性能
    time_signature_verification "$curve_name"
}
```

### 第三阶段：高级功能（3-4周）

#### 1. 自动曲线选择
```bash
# core/smart_curve_selector.sh
#!/bin/bash
# 智能曲线选择器

select_optimal_curve() {
    local security_level="$1"  # 安全级别：low, medium, high, maximum
    local performance_req="$2" # 性能要求：fast, balanced, secure
    local use_case="$3"        # 用例：mobile, web, government, iot
    
    case "$security_level" in
        "low")
            echo "secp192k1"
            ;;
        "medium")
            [[ "$performance_req" == "fast" ]] && echo "secp256k1" || echo "secp256r1"
            ;;
        "high")
            echo "secp384r1"
            ;;
        "maximum")
            echo "secp521r1"
            ;;
    esac
}
```

#### 2. 混合曲线操作
```bash
# core/hybrid_curve_crypto.sh
#!/bin/bash
# 混合曲线密码学操作

# 多曲线签名（增强安全性）
multi_curve_sign() {
    local message="$1"
    local primary_curve="$2"
    local secondary_curve="$3"
    
    # 主曲线签名
    local primary_sig=$(sign_with_curve "$message" "$primary_curve")
    
    # 副曲线签名（对主签名进行签名）
    local secondary_sig=$(sign_with_curve "$primary_sig" "$secondary_curve")
    
    echo "$primary_curve:$primary_sig|$secondary_curve:$secondary_sig"
}
```

## 📁 目录结构扩展

```
core/
├── curves/                    # 椭圆曲线参数定义
│   ├── secp256k1_params.sh   # 比特币曲线（现有）
│   ├── secp256r1_params.sh   # NIST P-256
│   ├── secp384r1_params.sh   # NIST P-384
│   ├── secp521r1_params.sh   # NIST P-521
│   ├── secp224k1_params.sh   # Koblitz 224
│   ├── secp192k1_params.sh   # Koblitz 192
│   └── brainpool_params.sh   # Brainpool系列
├── operations/               # 通用ECC运算
│   ├── ecc_arithmetic.sh    # 椭圆曲线算术运算
│   ├── point_operations.sh  # 点运算通用实现
│   └── modular_math.sh      # 模运算通用库
├── crypto/                   # 密码学操作
│   ├── ecc_signatures.sh    # ECC签名通用实现
│   ├── key_generation.sh    # 密钥生成通用实现
│   └── curve_selector.sh    # 曲线选择器
└── utils/                    # 工具函数
    ├── curve_validator.sh   # 曲线参数验证
    └── performance_tester.sh # 性能测试工具

demo/
├── multi_curve/             # 多曲线演示
│   ├── curve_comparison.sh  # 曲线对比演示
│   ├── performance_demo.sh  # 性能展示
│   └── security_levels.sh   # 安全级别演示
├── tests/
│   ├── curve_validation.sh  # 多曲线验证测试
│   ├── openssl_multi.sh     # OpenSSL多曲线对比
│   └── known_answers.sh     # 已知答案测试
└── benchmarks/
    ├── speed_comparison.sh  # 速度基准测试
    └── security_analysis.sh # 安全性分析
```

## 🧪 测试策略

### 1. 已知答案测试 (KAT)
```bash
# 使用NIST提供的测试向量
# core/test_vectors/secp256r1_kat.txt
TestVector1:
PrivateKey: 6140fcac5a8c1df6b2b3f3e2e9a8f7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1
PublicKeyX: 1894550a9d5c5a530ea7309c9f337e769e2a86c1e5e69b1f9c3a7d0e2f4c6b8a
PublicKeyY: 3f46a9b8c7d6e5f4a3b2c1d0e9f8a7b6c5d4e3f2a1b9c8d7e6f5a4b3c2d1e0f
Message: "test message"
SignatureR: 8c15e2d1f3b4a5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c
SignatureS: 1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2
```

### 2. OpenSSL交叉验证
```bash
# 与OpenSSL进行逐曲线对比
for curve in secp256r1 secp384r1 secp521r1; do
    echo "测试曲线: $curve"
    
    # 生成测试密钥对
    openssl ecparam -name "$curve" -genkey -out openssl_key.pem
    
    # 提取参数进行对比
    openssl ec -in openssl_key.pem -text -noout
    
    # 签名对比
    echo "test message" | openssl dgst -sha256 -sign openssl_key.pem -out openssl.sig
    
    # 使用我们的实现进行验证
    ./becc.sh verify --curve "$curve" --message "test message" --signature openssl.sig
    
done
```

### 3. 边界条件测试
```bash
# 测试各种边界条件
test_boundary_conditions() {
    local curve="$1"
    
    # 测试零点
    test_point_at_infinity "$curve"
    
    # 测试阶的边界
    test_order_boundaries "$curve"
    
    # 测试大数运算
    test_large_number_arithmetic "$curve"
    
    # 测试模运算
    test_modular_reduction "$curve"
}
```

## 📊 性能优化计划

### 1. 算法优化
- **窗口NAF方法**：优化点乘算法
- **预计算表**：加速固定点乘法
- **Montgomery约简**：优化模运算
- **并行计算**：利用Bash后台进程

### 2. 内存优化
- **大数表示优化**：减少内存占用
- **缓存机制**：避免重复计算
- **流式处理**：处理大数据块

### 3. 代码优化
- **函数内联**：减少函数调用开销
- **条件优化**：减少分支判断
- **字符串优化**：高效的大数表示

## 🎯 里程碑计划

### 第1周：基础框架
- [ ] SECP256R1参数定义
- [ ] 通用ECC运算核心
- [ ] 曲线选择接口
- [ ] 基础测试框架

### 第2周：核心实现
- [ ] SECP384R1支持
- [ ] SECP521R1支持
- [ ] 多曲线验证测试
- [ ] OpenSSL交叉验证

### 第3周：高级功能
- [ ] 自动曲线选择
- [ ] 性能基准测试
- [ ] 安全级别分类
- [ ] 优化算法实现

### 第4周：完善发布
- [ ] 完整文档编写
- [ ] 性能调优
- [ ] 边界条件测试
- [ ] 最终发布准备

## 🚀 最终目标

**短期目标（1个月）：**
- 支持4条主要NIST曲线
- 达到90%+ OpenSSL兼容性
- 完整测试覆盖

**中期目标（2-3个月）：**
- 支持8+条标准曲线
- 实现智能曲线选择
- 性能优化达到实用级别

**长期目标（6个月）：**
- 成为最完整的纯Bash ECC库
- 支持所有主流椭圆曲线
- 达到生产环境质量标准

---

**🎯 让我们将bECCsh打造成世界最完整的纯Bash椭圆曲线密码学库！**