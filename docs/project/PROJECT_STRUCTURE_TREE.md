# bECCsh项目完整目录结构树

## 📊 项目概览

**项目全称**: bECCsh (Bash Elliptic Curve Cryptography Shell)  
**项目描述**: 世界首个纯Bash椭圆曲线密码学实现  
**总文件数**: 780个  
**总目录数**: 270个  
**Shell脚本**: 226个  
**Markdown文档**: 107个  
**HTML文件**: 5个  

---

## 🏠 主目录结构

```
/home/donz/bECCsh/
├── 📄 核心脚本 (3个主要版本)
│   ├── becc.sh                    [15K] 主程序入口 (v1.0.0)
│   ├── becc_multi_curve.sh        [22K] 多曲线支持版本 (v2.0.0)
│   └── becc_fixed.sh              [16K] Bug修复版本
│
├── 📄 关键文档 (15+个核心文档)
│   ├── AGENTS.md                  [17K] 项目背景和用户偏好
│   ├── README.md                  [8.0K] 项目主要说明
│   ├── CRYPTOGRAPHIC_TECHNICAL_DOCUMENTATION.md [16K] 密码学技术细节
│   ├── COMPREHENSIVE_ELLIPTIC_CURVE_TEST_ANALYSIS_REPORT.md [23K] 综合测试分析
│   ├── PURE_BASH_MANIFESTO.md     [7.8K] 纯Bash编程哲学
│   └── CORE_FILES.md              [2.7K] 核心文件说明
│
├── 📁 archive/                    开发历史归档
├── 📁 beccsh/                     专业版本实现
├── 📁 core/                       纯Bash核心实现
├── 📁 demo/                       演示和测试
├── 📁 docs/                       项目文档
├── 📁 html/                       HTML文件
├── 📁 lib/                        共享库文件
├── 📁 tests/                      测试套件
├── 📁 tests_archive/              综合测试套件 (196个测试)
└── 📁 tools/                      工具和实用程序
```

---

## 📁 子目录详细结构

### 📁 core/ - 纯Bash核心实现
```
core/
├── lib/pure_bash/                 零依赖模块库
│   ├── pure_bash_loader.sh        统一模块加载器
│   ├── pure_bash_crypto.sh        密码学函数
│   ├── pure_bash_bigint_extended.sh 扩展大数运算
│   ├── pure_bash_hex.sh           十六进制操作
│   ├── pure_bash_random.sh        随机数生成
│   ├── bash_math.sh               [6.0K] 纯Bash数学函数
│   ├── bash_bigint.sh             [14K] 大整数运算
│   ├── bash_ec_math.sh            [11K] 椭圆曲线数学
│   ├── bash_simple_ec.sh          [7.5K] 简化椭圆曲线
│   ├── ec_point.sh                [13K] 椭圆曲线点运算
│   ├── asn1.sh                    [11K] ASN.1 DER编码
│   └── ec_curve.sh                [8.4K] 曲线参数管理
└── curves/                        曲线参数文件
    ├── secp256r1.params
    ├── secp256k1.params
    ├── secp384r1.params
    ├── secp521r1.params
    └── brainpool*.params
```

### 📁 lib/ - 共享库
```
lib/
├── asn1.sh                        [11K] ASN.1 DER编码
├── bigint.sh                      [18K] 大整数运算 (主要版本)
├── ec_curve.sh                    [8.4K] 椭圆曲线参数管理
├── ec_point.sh                    [13K] 椭圆曲线点运算
├── ecdsa.sh                       [14K] ECDSA签名实现
├── security.sh                    [11K] RFC 6979和安全功能
├── entropy.sh                     [11K] 8层熵源随机数生成
├── bash_math.sh                   [6.3K] 纯Bash数学函数
├── bash_bigint.sh                 [14K] 纯Bash大数运算
├── bash_ec_math.sh                [11K] 纯Bash椭圆曲线数学
├── bash_simple_ec.sh              [7.5K] 简化椭圆曲线演示
└── bash_concept_demo.sh           [8.4K] 概念演示
```

### 📁 tests_archive/ - 综合测试套件 (196个测试脚本)
```
tests_archive/
├── comprehensive_runnable_test.sh   [8.4K] 主测试运行器
├── benchmark_multi_curve.sh       [15K] 性能基准测试
├── simple_runnable_test.sh        [2.3K] 简化测试
├── verify_normal_error_handling.sh [3.1K] 错误处理验证
│
├── core/                          核心功能测试
│   ├── test_bash_math.sh
│   ├── test_bigint_operations.sh
│   ├── test_hex_conversions.sh
│   └── test_*.sh (15+个测试)
│
├── elliptic_curves/               曲线相关测试
│   ├── test_curve_parameters.sh
│   ├── test_point_operations.sh
│   ├── test_secp256r1.sh
│   └── test_*.sh (20+个测试)
│
├── ecdsa/                         签名算法测试
│   ├── test_ecdsa_sign_verify.sh
│   ├── test_rfc6979.sh
│   ├── test_signature_formats.sh
│   └── test_*.sh (25+个测试)
│
├── openssl_comparison/            标准兼容性测试
│   ├── test_openssl_compatibility.sh
│   ├── test_openssl_signatures.sh
│   ├── verify_against_openssl.sh
│   └── test_*.sh (30+个测试)
│
├── extreme_tests/                 边界条件测试
│   ├── test_large_numbers.sh
│   ├── test_edge_cases.sh
│   ├── test_performance_limits.sh
│   └── test_*.sh (20+个测试)
│
├── debug_tools/                   开发调试工具
│   ├── debug_math_operations.sh
│   ├── debug_curve_params.sh
│   ├── performance_profiler.sh
│   └── debug_*.sh (15+个工具)
│
├── math_modules/                  数学模块测试
├── environmental/                 环境兼容性测试
└── final_versions/                最终版本验证
```

### 📁 demo/ - 演示和测试
```
demo/
├── bash_pure_demo.sh              [8.3K] 纯Bash概念演示
├── bash_concept_demo.sh           [8.5K] 概念验证演示
├── demo.sh                        [2.0K] 基础演示
├── final_verification.sh          [3.8K] 最终验证
├── pure_bash_demo.sh              [980] 纯Bash演示
├── pure_bash_complete_demo.sh     [4.5K] 完整纯Bash演示
├── pure_bash_final_demo.sh        [5.8K] 最终纯Bash演示
├── quick_demo.sh                  [828] 快速演示
│
├── pure_bash_core/                纯Bash核心测试
├── pure_bash_tests/               纯Bash功能测试
├── quick_tests/                   快速测试套件
├── comparison/                    对比测试
├── examples/                      使用示例
├── reports/                       测试报告
├── tests/                         测试文件
├── validation/                    验证测试
└── verification/                  验证文件
```

### 📁 tools/ - 工具和实用程序
```
tools/
├── security_functions.sh          [6.3K] 安全功能
├── secure_main_integration.sh     [1.7K] 主程序集成
├── improved_random.sh             [4.3K] 改进随机数
├── fixed_pure_bash_hex.sh         [2.4K] 修复的十六进制函数
├── test1.txt                      测试文件1
├── test2.txt                      测试文件2
├── openssl_test_key.pem           OpenSSL测试密钥
│
├── scripts/                       脚本工具集合
│   ├── error_handling_*.sh
│   ├── logging_*.sh
│   ├── optimization_*.sh
│   └── utility_*.sh
│
└── utils/                         实用工具
    ├── performance_*.sh
    ├── debugging_*.sh
    └── helper_*.sh
```

### 📁 docs/ - 项目文档
```
docs/
├── project/                       项目相关文档
├── reports/                       报告和总结
└── technical/                     技术文档
```

### 📁 html/ - HTML文件
```
html/
└── archive/                       HTML归档文件
```

### 📁 archive/ - 开发历史归档
```
archive/
├── old_implementations/           旧版本实现
├── test_files/                    历史测试文件
└── backup_*.sh                    备份文件
```

### 📁 beccsh/ - 专业版本
```
beccsh/
├── becc_professional.sh           [17K] 专业版主程序
├── lib/                           专业版库文件
│   ├── log_professional.sh        [2.8K] 专业日志
│   ├── ecdsa_prof.sh              [2.0K] 专业ECDSA
│   ├── curves_prof.sh             [12K] 专业曲线
│   ├── error_handling.sh          [16K] 错误处理
│   ├── keymgmt.sh                 [18K] 密钥管理
│   └── optimizations.sh           [5.3K] 性能优化
│
├── CRYPTOGRAPHIC_SECURITY_ANALYSIS.md [8.3K]
├── FINAL_REPORT.md                [7.7K]
├── MATH_DOCUMENTATION.md          [5.4K]
├── PROJECT_FINAL_SUMMARY.md       [7.7K]
├── PROJECT_SUMMARY.md             [4.0K]
├── README_PROFESSIONAL.md         [9.1K]
└── README.md                      [5.8K]
```

---

## 🎯 核心文件突出显示

### 🔴 主程序入口 (3个版本)
- **`becc.sh`** - 主程序入口 (v1.0.0) - 最近更新: 2025-12-04 23:11
- **`becc_multi_curve.sh`** - 多曲线支持版本 (v2.0.0) - 22KB
- **`becc_fixed.sh`** - Bug修复版本 - 最近更新: 2025-12-04 23:11

### 📚 关键文档
- **`AGENTS.md`** - 项目背景和编码规范 - 17KB
- **`README.md`** - 项目主要说明 - 8.0KB
- **`CRYPTOGRAPHIC_TECHNICAL_DOCUMENTATION.md`** - 技术文档 - 16KB
- **`COMPREHENSIVE_ELLIPTIC_CURVE_TEST_ANALYSIS_REPORT.md`** - 测试分析 - 23KB

### 🔧 核心库文件
- **`lib/bigint.sh`** - 大整数运算 - 18KB
- **`lib/ecdsa.sh`** - ECDSA签名实现 - 14KB
- **`lib/ec_point.sh`** - 椭圆曲线点运算 - 13KB
- **`lib/security.sh`** - 安全功能 - 11KB

### 🧪 测试套件
- **`tests_archive/comprehensive_runnable_test.sh`** - 主测试运行器 - 8.4KB
- **`tests_archive/benchmark_multi_curve.sh`** - 性能基准测试 - 15KB

### 🎪 演示文件
- **`demo/bash_pure_demo.sh`** - 纯Bash概念演示 - 8.3KB
- **`demo/pure_bash_final_demo.sh`** - 最终纯Bash演示 - 5.8KB

---

## 📈 项目规模统计

| 类别 | 数量 | 说明 |
|------|------|------|
| 总文件数 | 780 | 包含所有文件 |
| Shell脚本 | 226 | 可执行脚本文件 |
| Markdown文档 | 107 | 项目文档 |
| HTML文件 | 5 | 网页文件 |
| 测试脚本 | 196 | tests_archive目录 |
| 核心库文件 | 30+ | lib和core目录 |
| 主要版本 | 3 | becc.sh系列 |

---

## 🕐 最近更新记录

### 最近24小时更新的核心文件:
1. `becc.sh` - 主程序入口 (2025-12-04 23:11)
2. `becc_fixed.sh` - Bug修复版本 (2025-12-04 23:11)
3. `README.md` - 项目文档 (2025-12-04 16:20)
4. `beccsh/lib/log_professional.sh` - 专业版日志 (2025-12-04 13:01)

---

## 🔍 文件大小分布

### 大文件 (>10KB)
- `index.html` - 44KB (主页面)
- `COMPREHENSIVE_ELLIPTIC_CURVE_TEST_ANALYSIS_REPORT.md` - 23KB
- `becc_multi_curve.sh` - 22KB
- `lib/bigint.sh` - 18KB
- `AGENTS.md` - 17KB
- `becc_fixed.sh` - 16KB

### 中等文件 (5-10KB)
- 大部分核心库文件和文档
- 测试脚本和演示文件

### 小文件 (<5KB)
- 工具脚本和辅助文件
- 简单的测试和演示

---

**最后更新时间**: 2025-12-05 00:51  
**结构完整性**: ✅ 完整  
**核心文件状态**: ✅ 全部存在  
**测试覆盖率**: ✅ 196个测试脚本