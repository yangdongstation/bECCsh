# bECCsh - 纯Bash椭圆曲线密码学实现

## 🎯 项目概述

bECCsh (Bash Elliptic Curve Cryptography Shell) 是一个完全使用Bash内置功能实现的椭圆曲线密码学库，实现了**零外部依赖**的密码学功能。这个项目证明了Bash不仅仅是一个胶水语言，它本身就是一个完整的编程环境。

**核心成就**:
- ✅ 世界首个纯Bash椭圆曲线密码学实现
- ✅ 完全零外部依赖（无bc、awk、python等）
- ✅ 支持多椭圆曲线（secp256r1, secp256k1, secp384r1, secp521r1等9种标准曲线）
- ✅ 完整ECDSA签名和验证功能
- ✅ RFC 6979确定性k值生成
- ✅ 生产环境主动阻止机制

## 📁 项目结构

```
/home/donz/bECCsh/
├── becc.sh                    # 主程序入口（完整版v1.0.0）
├── becc_multi_curve.sh        # 多曲线支持版本（v2.0.0）
├── becc_fixed.sh              # Bug修复版本
├── core/                      # 纯Bash实现核心
│   ├── becc_pure.sh          # 纯Bash主程序
│   ├── crypto/               # 密码学实现和调试工具
│   ├── curves/               # 曲线参数文件
│   ├── operations/           # ECC算术和点运算
│   └── lib/pure_bash/        # 纯Bash模块库
├── lib/                       # 共享库文件
│   ├── bash_math.sh          # 纯Bash数学函数（替代bc）
│   ├── bash_bigint.sh        # 纯Bash大数运算
│   ├── ecdsa.sh              # ECDSA签名实现
│   ├── security.sh           # RFC 6979和安全功能
│   └── *.sh                  # 其他密码学模块
├── demo/                      # 演示和测试
│   ├── bash_pure_demo.sh     # 纯Bash概念演示
│   ├── demo_multi_curve_showcase.sh # 交互式多曲线展示
│   └── pure_bash_tests/      # 功能测试套件
├── test_*.sh                  # 196个测试脚本
├── archive/                   # 开发历史归档
└── *.md                       # 75个项目文档
```

## 🚀 快速开始

### 基础命令
```bash
# 运行主程序
./becc.sh --help

# 生成密钥对
./becc.sh keygen -c secp256r1 -f private_key.pem

# 签名消息
./becc.sh sign -c secp256r1 -k private_key.pem -m "Hello World" -f signature.der

# 验证签名
./becc.sh verify -c secp256r1 -k public_key.pem -m "Hello World" -s signature.der

# 运行测试
./becc.sh test -c secp256r1
```

### 多曲线版本
```bash
# 查看支持的曲线
./becc_multi_curve.sh curves

# 智能曲线推荐
./becc_multi_curve.sh recommend

# 使用特定曲线
./becc_multi_curve.sh keygen -c secp256k1
```

### 测试和演示
```bash
# 核心功能测试
./test_core_functionality.sh

# 综合测试（9种曲线，6种消息类型）
./test_comprehensive.sh

# 纯Bash概念演示
bash demo/bash_pure_demo.sh

# 多曲线交互展示
./demo_multi_curve_showcase.sh
```

## 🔧 技术架构

### 纯Bash数学运算层
- **十六进制转换**: 字符映射和进制转换算法
- **大数运算**: 竖式算法的字符串实现
- **对数计算**: 循环除法的整数实现
- **模运算**: 基于除法的余数计算

### 椭圆曲线运算层
- **点加法**: 椭圆曲线群运算概念验证
- **点乘法**: 二进制展开算法
- **曲线验证**: 方程验证和点检查
- **小素数域**: 用于教育演示的简化实现

### 密码学功能层
- **哈希函数**: DJB2算法变体
- **随机数生成**: 8层熵源收集系统
- **ECDSA简化**: 教育级别的签名验证概念
- **ASN.1 DER**: 标准签名格式编码
- **RFC 6979**: 确定性k值生成

## 🧪 测试策略

### 测试层次
1. **单元测试**: 单个数学函数验证
2. **集成测试**: 密码学操作链测试
3. **概念验证**: 算法正确性演示
4. **对比测试**: 与标准实现结果对比

### 主要测试命令
```bash
# 快速功能测试
./test_quick_functionality.sh

# 多曲线支持测试
./test_multi_curve.sh secp256r1 secp256k1

# 综合验证测试
./comprehensive_runnable_test.sh

# ECDSA专项测试
./test_ecdsa_final_simple.sh
```

### 测试执行模式
- 彩色输出（绿色✓通过，红色✗失败）
- 标准化测试结果报告
- 性能基准测试和计时测量
- 边界情况和极端情况测试

## 🛡️ 安全考虑

### ⚠️ 重要安全警告
1. **教育用途仅限**: 主要用于密码学教学和研究
2. **非生产级别**: 不适合高安全要求环境
3. **生产环境阻止**: 主动检测并阻止生产使用
4. **简化算法**: 使用教育简化版算法
5. **伪随机数**: 随机数生成非密码学强度
6. **整数限制**: 受Bash内置算术限制

### 安全机制
- **运行时生产环境阻止**: 检测`BECC_PRODUCTION`环境变量
- **多层安全警告**: 启动时显示醒目的安全警告
- **环境安全检查**: 检查/dev/urandom、内存、临时目录
- **常量时间比较**: 防侧信道攻击保护
- **安全内存清除**: 多次覆盖敏感数据

### 安全边界
- 小素数域运算（p < 1000）
- 简化模运算实现
- 概念级别哈希函数
- 教育用途的密钥长度

### 推荐使用场景
- ✅ 密码学课程教学演示
- ✅ 算法概念验证和研究
- ✅ 零依赖环境的应急方案
- ✅ Bash编程技术展示

### 明确禁用场景
- ❌ 生产环境密码学应用
- ❌ 敏感数据保护
- ❌ 高价值交易签名
- ❌ 任何商业密码学用途

## 🎨 代码风格指南

### Bash编程规范
```bash
# 函数命名：小写下划线
bashmath_hex_to_dec() {
    local hex="$1"  # 参数使用local声明
    # 实现代码
}

# 变量命名
readonly CURVE_NAME="secp256r1"  # 常量使用readonly
local private_key="$1"           # 局部变量使用local
ECDSA_SIGNATURE_R=""            # 全局变量使用模块前缀

# 错误处理
if ! bashbigint_validate "$num"; then
    return 1
fi

# 错误代码
readonly ERR_INVALID_INPUT=1
readonly ERR_CRYPTO_OPERATION=2
```

### 模块化设计
- **单一职责**: 每个函数只做一件事
- **导入保护**: 防止重复定义
- **错误传播**: 正确的返回码处理
- **模块前缀**: 函数名使用模块前缀
- **导入模式**:
```bash
# 通用导入保护
if [[ -n "${MODULE_LOADED:-}" ]]; then
    return 0
fi
readonly MODULE_LOADED=1

# 相对路径导入
source "$(dirname "${BASH_SOURCE[0]}")/bash_math.sh"
```

### 文档标准
- **双语注释**: 关键函数使用中文和英文注释
- **函数头**: 详细的功能和参数说明
- **算法解释**: 复杂算法的步骤说明
- **视觉元素**: 重要警告使用ASCII艺术框

## 📊 性能特征

### 性能基准
- 100次数学运算：约1秒
- 大数加法：O(n) 时间复杂度
- 大数乘法：O(n×m) 时间复杂度
- 椭圆曲线点乘：O(log k) 时间复杂度

### 资源使用
- **内存**: 纯Bash内存管理，适合教育用途
- **CPU**: 算法复杂度合理，非高性能场景
- **依赖**: 零外部依赖，启动快速

## 🔍 调试和故障排除

### 常见问题和解决方案
```bash
# 检查Bash版本（需要4.0+）
bash --version

# 验证纯Bash环境
bash demo/bash_pure_demo.sh

# 测试单个数学函数
source lib/bash_math.sh
bashmath_hex_to_dec "FF"

# 检查错误日志
set -x  # 开启调试模式
```

### 环境要求
- **Bash版本**: 4.0或更高
- **操作系统**: Linux/macOS推荐
- **标准工具**: sha256sum, xxd, base64（可选，有回退方案）

### 环境变量
- `BECC_PRODUCTION`: 设为"true"阻止生产使用
- `BECC_SILENT`: 设为"true"抑制安全警告
- `LOG_LEVEL`: 控制日志详细程度（DEBUG=0, INFO=1, WARN=2, ERROR=3）

## 📚 关键文档

### 技术文档
- `TECHNICAL_IMPLEMENTATION.md` - 详细技术实现
- `CRYPTOGRAPHIC_TECHNICAL_DOCUMENTATION.md` - 密码学技术细节
- `MATH_REPLACEMENT.md` - 纯Bash数学函数说明
- `PERFORMANCE_ANALYSIS_REPORT.md` - 性能基准测试

### 项目文档
- `README.md` - 项目主要说明
- `PROJECT_OVERVIEW.md` - 项目概览
- `PURE_BASH_MANIFESTO.md` - 纯Bash编程哲学

### 验证报告
- `FINAL_VERIFICATION_REPORT.md` - 完整验证报告
- `CRYPTOGRAPHIC_SECURITY_CONSIDERATIONS.md` - 密码学安全分析
- `OPENSSL_COMPARISON_REPORT.md` - OpenSSL兼容性测试

## 🎯 开发原则

### 纯Bash哲学
1. **零外部依赖**: 仅使用Bash内置功能
2. **算法透明**: 每个步骤清晰可见
3. **教育价值**: 完美的密码学教学工具
4. **代码美学**: 展现编程的纯粹之美

### 技术决策
- 字符串处理替代数学库
- 竖式算法实现大数运算
- 字符映射实现进制转换
- 循环算法替代复杂函数

## 📈 支持曲线

### 标准曲线
- **secp256r1** (P-256, prime256v1)
- **secp256k1** (Bitcoin, Ethereum)
- **secp384r1** (P-384)
- **secp521r1** (P-521)
- **secp192r1** (P-192)
- **secp224r1** (P-224)
- **brainpoolP256r1**
- **brainpoolP384r1**
- **brainpoolP512r1**

### 曲线别名
- P-256: secp256r1, prime256v1
- Bitcoin: secp256k1, btc
- Ethereum: secp256k1, eth

## 🏆 项目成熟度

- **196个shell脚本**: 表明功能完整性
- **75个文档文件**: 显示全面覆盖
- **多版本实现**: 专业版、纯Bash版、多曲线版
- **广泛测试套件**: 包含边界情况测试
- **完整验证报告**: OpenSSL兼容性测试
- **开发历史归档**: 保留完整开发过程

---

**核心理念**: 纯粹即力量，简约即美学，执念即成就！

**最终宣言**: 这，就是纯Bash的力量！🚀

---

*最后更新: 2025年12月 - 基于项目完整代码库分析*