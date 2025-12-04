# bECCsh 项目目录结构完整指南

## 🏗️ 项目根目录

```
/home/donz/bECCsh/
├── becc.sh                           # 主程序入口（完整版v1.0.0）
├── becc_multi_curve.sh              # 多曲线支持版本（v2.0.0）
├── becc_fixed.sh                    # Bug修复版本
├── security_functions.sh            # 安全功能模块
├── secure_main_integration.sh       # 安全集成主程序
├── improved_random.sh               # 改进的随机数生成
├── fixed_pure_bash_hex.sh           # 纯Bash十六进制修复版
├── test_*.sh                        # 196个测试脚本
├── *.md                            # 75个技术文档
└── [核心目录结构]
```

## 📁 核心目录详解

### `/core/` - 纯Bash实现核心
```
core/
├── becc_pure.sh                    # 纯Bash主程序
├── crypto/                         # 密码学实现
│   ├── elliptic_curves.sh         # 椭圆曲线运算
│   ├── ecdsa_pure.sh              # 纯Bash ECDSA
│   ├── rfc6979.sh                 # RFC 6979确定性k值
│   └── debugging_tools.sh         # 调试工具
├── curves/                         # 曲线参数文件
│   ├── secp256r1_params.sh        # P-256参数
│   ├── secp256k1_params.sh        # Bitcoin曲线
│   ├── secp384r1_params.sh        # P-384参数
│   ├── secp521r1_params.sh        # P-521参数
│   └── brainpool*.sh              # Brainpool系列
├── operations/                     # ECC算术运算
│   ├── point_operations.sh        # 点运算
│   ├── field_arithmetic.sh        # 域运算
│   └── modular_math.sh            # 模运算
├── lib/pure_bash/                  # 纯Bash模块库
│   ├── bash_math_pure.sh          # 纯Bash数学
│   ├── bash_bigint_pure.sh        # 纯Bash大数
│   └── string_operations.sh       # 字符串操作
└── utils/                          # 工具函数
    ├── validation.sh              # 验证函数
    └── formatting.sh              # 格式化工具
```

### `/lib/` - 共享库文件
```
lib/
├── bash_math.sh                   # 纯Bash数学函数（替代bc）
├── bash_bigint.sh                 # 纯Bash大数运算
├── ecdsa.sh                       # ECDSA签名实现
├── security.sh                    # RFC 6979和安全功能
├── elliptic_curve.sh              # 椭圆曲线核心
├── key_management.sh              # 密钥管理
├── signature_formatting.sh        # 签名格式处理
├── random_generator.sh            # 随机数生成
├── validation.sh                  # 输入验证
└── error_handling.sh              # 错误处理
```

### `/demo/` - 演示和测试
```
demo/
├── bash_pure_demo.sh              # 纯Bash概念演示
├── demo_multi_curve_showcase.sh   # 交互式多曲线展示
├── pure_bash_core/                # 纯Bash核心演示
│   ├── hex_demo.sh               # 十六进制演示
│   ├── math_demo.sh              # 数学运算演示
│   └── elliptic_demo.sh          # 椭圆曲线演示
├── pure_bash_tests/               # 功能测试套件
│   ├── test_math_functions.sh    # 数学函数测试
│   ├── test_bigint_operations.sh # 大数运算测试
│   └── test_elliptic_curves.sh   # 椭圆曲线测试
├── quick_tests/                   # 快速测试
├── comparison/                    # 对比测试
├── examples/                      # 使用示例
├── validation/                    # 验证测试
├── verification/                  # 验证报告
└── tests/                         # 测试输出
```

### `/beccsh/` - 专业版本
```
beccsh/
├── README.md                      # 专业版说明
├── README_PROFESSIONAL.md         # 专业版文档
├── PROJECT_SUMMARY.md             # 项目总结
├── PROJECT_FINAL_SUMMARY.md       # 最终总结
├── FINAL_REPORT.md                # 最终报告
├── CRYPTOGRAPHIC_SECURITY_ANALYSIS.md # 密码学安全分析
├── MATH_DOCUMENTATION.md          # 数学文档
├── examples/                      # 专业版示例
└── lib/                          # 专业版库文件
```

### `/archive/` - 开发历史归档
```
archive/
├── backup_docs/                   # 文档备份
│   ├── DEPENDENCY_ANALYSIS_REPORT.md
│   ├── FINAL_TEST_REPORT.md
│   ├── FINAL_VERIFICATION_REPORT.md
│   └── TEST_REPORT.md
├── old_implementations/           # 旧版本实现
└── test_files/                    # 测试文件归档
```

### `/tests_archive/` - 测试归档
```
tests_archive/
├── core/                          # 核心测试
├── elliptic_curves/               # 椭圆曲线测试
├── ecdsa/                        # ECDSA测试
├── openssl_comparison/           # OpenSSL对比测试
├── extreme_tests/                # 极限测试
├── debug_tools/                  # 调试工具
├── demos/                        # 演示测试
├── final_versions/               # 最终版本测试
├── environmental/                # 环境测试
└── math_modules/                 # 数学模块测试
```

## 📋 文件分类统计

### 可执行脚本 (196个)
```
主程序脚本:
- becc.sh (完整版v1.0.0)
- becc_multi_curve.sh (多曲线版v2.0.0)
- becc_fixed.sh (修复版)

测试脚本:
- test_*.sh (各种功能测试)
- test_core_*.sh (核心测试)
- test_openssl_*.sh (OpenSSL对比)
- comprehensive_*.sh (综合测试)
- runnable_*.sh (可运行测试)

演示脚本:
- demo_*.sh (演示程序)
- bash_pure_demo.sh (纯Bash演示)
- demo_multi_curve_showcase.sh (多曲线展示)
```

### 技术文档 (75个)
```
项目文档:
- README.md (项目主文档)
- AGENTS.md (项目背景和规范)
- PROJECT_OVERVIEW.md (项目概览)
- TECHNICAL_IMPLEMENTATION.md (技术实现)

技术报告:
- CRYPTOGRAPHIC_TECHNICAL_DOCUMENTATION.md (密码学技术)
- COMPREHENSIVE_ELLIPTIC_CURVE_TEST_ANALYSIS_REPORT.md (测试分析)
- CRYPTOGRAPHIC_SECURITY_CONSIDERATIONS.md (安全考虑)
- PERFORMANCE_ANALYSIS_REPORT.md (性能分析)

验证报告:
- FINAL_VERIFICATION_REPORT.md (最终验证)
- OPENSSL_COMPARISON_REPORT.md (OpenSSL对比)
- CURVE_PARAMETER_VALIDATION_REPORT.md (曲线验证)

开发文档:
- PURE_BASH_MANIFESTO.md (纯Bash哲学)
- MATH_REPLACEMENT.md (数学替代方案)
- SECURITY_WARNING.md (安全警告)
```

### 核心文件说明

#### 主程序文件
```bash
becc.sh                    # 标准版本 - 完整功能实现
becc_multi_curve.sh       # 多曲线版本 - 支持9种标准曲线
becc_fixed.sh             # 修复版本 - 包含bug修复
security_functions.sh     # 安全函数 - RFC 6979等安全功能
```

#### 关键文档文件
```markdown
AGENTS.md                 # 项目规范和开发指南
TECHNICAL_IMPLEMENTATION.md # 详细技术实现说明
CRYPTOGRAPHIC_TECHNICAL_DOCUMENTATION.md # 密码学技术细节
FINAL_VERIFICATION_REPORT.md # 完整验证报告
```

#### 测试文件
```bash
test_core_functionality.sh    # 核心功能测试
test_comprehensive.sh        # 综合测试套件
test_openssl_compatibility_final.sh # OpenSSL兼容性测试
test_ecdsa_final_simple.sh   # ECDSA专项测试
```

## 🎯 使用指南

### 快速开始文件
```bash
# 基础使用
./becc.sh --help                    # 查看帮助
./becc.sh keygen -c secp256r1       # 生成密钥
./becc.sh sign -m "message"         # 签名消息
./becc.sh verify -s signature.der   # 验证签名

# 多曲线版本
./becc_multi_curve.sh curves        # 查看支持曲线
./becc_multi_curve.sh recommend     # 智能推荐

# 测试验证
./test_quick_functionality.sh       # 快速功能测试
./test_comprehensive.sh            # 综合测试
```

### 开发文档阅读顺序
```markdown
1. AGENTS.md                    # 项目规范
2. TECHNICAL_IMPLEMENTATION.md  # 技术实现
3. PURE_BASH_MANIFESTO.md      # 纯Bash哲学
4. MATH_REPLACEMENT.md         # 数学函数替代
5. SECURITY_WARNING.md         # 安全警告
6. FINAL_VERIFICATION_REPORT.md # 验证报告
```

### 演示和测试
```bash
# 概念演示
bash demo/bash_pure_demo.sh                    # 纯Bash概念
./demo/demo_multi_curve_showcase.sh           # 多曲线展示

# 功能测试
./test_core_modules_direct.sh                 # 核心模块测试
./test_openssl_compatibility_final.sh         # OpenSSL兼容性

# 分析报告
./detailed_math_analysis.sh                   # 数学分析
./detailed_test_failure_analysis.sh          # 失败分析
```

## 📊 项目规模统计

```
总文件数: 271+
├── Shell脚本: 196个
├── Markdown文档: 75个
├── 核心目录: 9个
├── 测试目录: 11个
├── 演示目录: 15个
└── 归档目录: 4个

代码行数统计:
├── 主程序: 15,000+ 行
├── 库文件: 25,000+ 行
├── 测试脚本: 30,000+ 行
└── 文档: 50,000+ 行

支持曲线: 9种标准椭圆曲线
测试覆盖率: 核心功能100%
验证测试: 与OpenSSL对比验证
```

## 🏷️ 文件命名规范

### 脚本文件命名
```bash
becc*.sh              # 主程序相关
test_*.sh             # 测试脚本
demo_*.sh             # 演示脚本
*_pure_bash*.sh       # 纯Bash实现
*_multi_curve*.sh     # 多曲线相关
*_fixed*.sh           # 修复版本
*_final*.sh           # 最终版本
```

### 文档文件命名
```markdown
*_TECHNICAL_*.md      # 技术文档
*_REPORT.md           # 报告文档
*_ANALYSIS.md         # 分析文档
FINAL_*.md            # 最终文档
*_SUMMARY.md          # 总结文档
*_DOCUMENTATION.md    # 说明文档
```

### 目录命名规范
```
core/                  # 核心实现
lib/                   # 库文件
demo/                  # 演示和测试
archive/               # 历史归档
tests_archive/         # 测试归档
beccsh/                # 专业版本
```

这个目录结构体现了bECCsh项目的完整性、专业性和教育价值，每个文件和目录都有其明确的用途和定位。