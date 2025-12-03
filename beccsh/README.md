# bECCsh 🔥⚡️🛡️

**Professional ECC Implementation in Pure Bash**

> "我们证明了bash是图灵完备的，包括制造密码学灾难" —— 项目座右铭

## ⚠️ 安全声明

**此软件具有以下特性：**
- **专业级**：完整的ECDSA实现，支持多种曲线
- **多功能**：密钥生成、签名、验证、格式转换
- **可配置**：多种曲线选择，密钥格式支持
- **教育性**：完整的数学文档和测试套件
- **娱乐性**：仍然比OpenSSL慢38000倍

**适用场景：**
- ✅ 密码学学习和研究
- ✅ ECC算法实现参考
- ✅ 椭圆曲线数学教学
- ✅ 向老板证明"bash能做任何事情"
- ✅ 冬季键盘加热设备

**禁止场景（违者后果自负）：**
- ❌ 生产环境
- ❌ 真实数据签名
- ❌ 加密货币钱包
- ❌ 任何涉及金钱、隐私、生命的场景

## 🚀 新功能

### 1. 完整的ECDSA实现
- ✅ **签名生成**：完整的ECDSA签名算法
- ✅ **签名验证**：完整的ECDSA验证算法
- ✅ **多种曲线**：secp256r1, secp256k1, secp384r1
- ✅ **密钥格式**：HEX, PEM, JSON格式支持

### 2. 增强的熵收集
- ✅ **八层熵源**：键盘、CPU、系统、网络、硬件、进程、时间、随机
- ✅ **可配置**：支持选择特定熵源
- ✅ **专业级**：比原来多2层熵收集

### 3. 性能优化
- ✅ **快速模式**：比标准模式快2倍（仍然很慢）
- ✅ **窗口方法**：2位窗口优化点乘
- ✅ **预计算**：加速常用操作

### 4. 专业测试套件
- ✅ **单元测试**：数学运算、点运算、ECDSA测试
- ✅ **集成测试**：完整流程验证
- ✅ **性能测试**：基准测试和性能分析
- ✅ **边界测试**：异常情况和错误处理

### 5. 完整文档
- ✅ **数学文档**：详细的椭圆曲线数学理论
- ✅ **API文档**：函数说明和使用指南
- ✅ **安全分析**：安全性考虑和限制

## 性能基准（在Intel i7-8550U上）

| 操作 | OpenSSL | bECCsh | 速度差 |
|------|---------|--------|--------|
| 生成密钥 | 0.02s | **120s** | 6000× |
| 签名 | 0.01s | **380s** | 38000× |
| 验证 | 0.01s | **450s** | 45000× |

*注：测试数据为1KB消息，签名耗时的380秒中包含30秒键盘熵收集*

## 安装与使用

```bash
# 方式1：直接运行（不推荐，但很有趣）
git clone https://github.com/yourusername/bECCsh.git 
cd bECCsh
./becc.sh genkey
./becc.sh sign message.txt
./becc.sh verify message.txt.sig

# 方式2：Docker隔离（推荐）
docker build -t beccsh .
docker run -it --rm beccsh genkey

# 方式3：专业测试
./test_suite.sh all
```

## 高级用法

### 选择椭圆曲线
```bash
# 使用Bitcoin曲线secp256k1
./becc.sh -c secp256k1 genkey

# 使用高安全级别的secp384r1
./becc.sh -c secp384r1 genkey

# 查看支持的曲线
./becc.sh info
```

### 密钥格式
```bash
# 生成PEM格式密钥
BECCSH_KEY_FORMAT=pem ./becc.sh genkey

# 生成JSON格式密钥信息
BECCSH_KEY_FORMAT=json ./becc.sh genkey
```

### 熵源配置
```bash
# 仅使用系统熵源
BECCSH_ENTROPY_SRC=system ./becc.sh genkey

# 使用键盘和CPU熵源
BECCSH_ENTROPY_SRC=keyboard,cpu ./becc.sh genkey
```

### 快速模式
```bash
# 启用快速模式（仍然很慢）
./becc.sh -f sign message.txt
```

## 技术架构

```
专业ECC实现：
├── 多层熵收集（8层）
├── 大数运算（bc辅助）
├── 椭圆曲线运算（点加、倍点、标量乘）
├── ECDSA协议（签名、验证）
├── 密钥格式（HEX、PEM、JSON）
├── 性能优化（窗口方法、预计算）
└── 专业测试（单元、集成、性能）
```

## 数学理论

项目包含完整的数学文档 `MATH_DOCUMENTATION.md`，涵盖：
- 椭圆曲线定义和性质
- 点运算算法
- ECDSA算法详解
- 安全性分析
- 测试向量和边界条件

## 测试套件

```bash
# 运行所有测试
./test_suite.sh all

# 只运行单元测试
./test_suite.sh unit

# 只运行集成测试
./test_suite.sh integration

# 性能基准测试
./test_suite.sh performance
```

## 项目结构

```
bECCsh/
├── becc.sh              # 主脚本（增强版）
├── test_suite.sh        # 专业测试套件
├── MATH_DOCUMENTATION.md # 数学文档
├── README.md            # 项目文档
├── lib/
│   ├── entropy.sh       # 八层熵收集
│   ├── big_math.sh      # 大数运算
│   ├── curves.sh        # 多种曲线支持
│   ├── ec_point.sh      # 椭圆曲线点运算
│   ├── ecdsa.sh         # 完整ECDSA实现
│   ├── key_formats.sh   # 密钥格式支持
│   └── optimizations.sh # 性能优化
└── examples/
    └── demo.sh          # 演示脚本
```

## 安全性分析

### 已解决的安全问题
- ✅ 完整的ECDSA验证实现
- ✅ 多种曲线选择
- ✅ 密钥格式标准化
- ✅ 专业级熵收集
- ✅ 完整的测试覆盖

### 仍然存在的限制
- ⚠️ 性能仍然很慢（教育目的）
- ⚠️ 依赖bc进行大数运算
- ⚠️ 时序攻击风险（bash实现限制）
- ⚠️ 侧信道攻击风险

## 贡献指南

我们接受以下类型的贡献：
- ✅ 数学算法的正确性改进
- ✅ 测试用例的增加
- ✅ 文档的完善
- ✅ 代码可读性的提升
- ❌ 性能优化（违背项目初衷）
- ❌ 生产环境适配

## 许可证

**WTFPL**（Do What The F*ck You Want To Public License）

但请记住：**任何使用都视为同意"后果自负"条款**。

## 致谢

感谢密码学界的先驱们，特别是：
- Neal Koblitz 和 Victor Miller（椭圆曲线密码学发明者）
- NIST（标准化工作）
- SECG（SECG标准）
- 所有为密码学安全做出贡献的研究者

---

*"最快的签名方式就是不签名，但我们选择了最慢且最完整的实现"*