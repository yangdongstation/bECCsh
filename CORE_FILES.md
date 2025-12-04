# bECCsh 核心文件清单

## 🎯 主目录保留文件

### 核心程序（3个）
| 文件名 | 说明 | 重要性 |
|--------|------|--------|
| `becc.sh` | 主程序入口（完整版v1.0.0） | ⭐⭐⭐ |
| `becc_multi_curve.sh` | 多曲线支持版本（v2.0.0） | ⭐⭐⭐ |
| `becc_fixed.sh` | Bug修复版本 | ⭐⭐⭐ |

### 核心文档（4个）
| 文件名 | 说明 | 重要性 |
|--------|------|--------|
| `README.md` | 项目主要说明文档 | ⭐⭐⭐ |
| `AGENTS.md` | 项目背景、结构和开发规范 | ⭐⭐⭐ |
| `CURRENT_ACTIVE_DOCUMENTS.md` | 当前活跃文档清单 | ⭐⭐ |
| `CORE_FILES.md` | 本核心文件清单 | ⭐⭐ |

### HTML展示页面（3个）
| 文件名 | 说明 | 重要性 |
|--------|------|--------|
| `index.html` | 主展示页面 | ⭐⭐⭐ |
| `index_cryptographic.html` | 密码学技术详解页面 | ⭐⭐ |
| `index_mathematical.html` | 数学原理展示页面 | ⭐⭐ |

### 标准文件（2个）
| 文件名 | 说明 | 重要性 |
|--------|------|--------|
| `.gitignore` | Git忽略文件配置 | ⭐ |
| `PROJECT_STRUCTURE_TREE.md` | 完整项目结构树 | ⭐⭐ |

## 📁 子目录结构

### 📚 docs/ - 项目文档目录
```
docs/
├── technical/     # 技术实现文档 (6个文件)
│   ├── MULTI_CURVE_README.md
│   ├── PERFORMANCE_OPTIMIZATION_PLAN.md
│   ├── TECHNICAL_PAGES_README.md
│   ├── TECHNICAL_CONCLUSION.md
│   ├── CRYPTOGRAPHIC_TECHNICAL_DOCUMENTATION.md
│   └── MATH_REPLACEMENT.md
├── reports/       # 分析报告和总结 (16个文件)
│   ├── FINAL_VERIFICATION_REPORT.md
│   ├── FINAL_STRICT_VERIFICATION_REPORT.md
│   ├── COMPREHENSIVE_ELLIPTIC_CURVE_TEST_ANALYSIS_REPORT.md
│   ├── BUG_ANALYSIS_AND_FIX_REPORT.md
│   ├── OPENSSL_COMPARISON_REPORT.md
│   ├── PERFORMANCE_ANALYSIS_REPORT.md
│   ├── CURVE_PARAMETER_VALIDATION_REPORT.md
│   └── PATH_* 系列报告 (10个)
└── project/       # 项目管理文档 (3个文件)
    ├── DIRECTORY_STRUCTURE.md
    ├── ORGANIZATION_COMPLETE.md
    └── demo_path_check_summary.md
```

### 🧪 tests/ - 测试脚本目录
```
tests/
├── core/          # 核心功能测试 (5个脚本)
│   ├── test_becc_fixed.sh
│   ├── test_ecdsa_final_simple.sh
│   ├── test_ecdsa_simple_final.sh
│   ├── test_functionality_quick.sh
│   └── test_simple_fixed.sh
├── compatibility/ # 兼容性测试 (预留)
├── analysis/      # 分析测试脚本 (1个)
│   └── test_path_fixes.sh
└── 其他测试脚本 (7个)
    ├── detailed_math_analysis.sh
    ├── detailed_test_failure_analysis.sh
    ├── runnable_test.sh
    ├── runnable_test_fixed.sh
    ├── test_core_modules_direct.sh
    ├── test_openssl_compatibility_final.sh
    └── test_quick_functionality.sh
```

### 🌐 html/ - HTML页面目录
```
html/
├── archive/       # 历史HTML页面归档 (2个文件)
│   ├── index_professional.html
│   └── test_formula_display.html
└── (主目录保留3个核心HTML页面)
```

### 🔧 tools/ - 辅助工具目录
```
tools/
├── scripts/       # 验证和检查脚本 (10个)
│   ├── comprehensive_path_check.sh
│   ├── corrected_validation.sh
│   ├── debug_test.sh
│   ├── extreme_path_validation.sh
│   ├── extreme_path_validation_fixed.sh
│   ├── final_path_validation.sh
│   ├── final_path_validation_fixed.sh
│   ├── minimal_test.sh
│   ├── path_validation_test.sh
│   ├── simple_path_check.sh
│   └── validate_path_fixes.sh
├── utils/         # 修复和维护工具 (9个)
│   ├── dependency_analysis.sh
│   ├── dependency_analysis_fixed.sh
│   ├── fix_demo_complete.sh
│   ├── fix_demo_core.sh
│   ├── fix_demo_core_final.sh
│   ├── fix_demo_paths.sh
│   ├── simplified_test.sh
│   ├── simple_fixed_test.sh
│   └── simple_fixed_test2.sh
└── 其他工具文件 (8个)
    ├── fixed_pure_bash_hex.sh
    ├── improved_random.sh
    ├── secure_main_integration.sh
    ├── security_functions.sh
    └── 测试文件 (test*.txt, *.pem)
```

### 🏗️ 其他核心子目录

#### 📁 core/ - 纯Bash核心实现
```
core/
├── becc_pure.sh                   纯Bash主程序
├── crypto/                        密码学实现 (20个文件)
│   ├── curve_selector.sh
│   ├── debug_*.sh                 调试工具 (8个)
│   ├── ec_math_*.sh               椭圆曲线数学 (3个)
│   ├── ecdsa_*.sh                 ECDSA实现 (6个)
│   └── verify_*.sh                验证工具 (2个)
├── curves/                        曲线参数文件 (7个标准曲线)
│   ├── brainpoolP256r1_params.sh
│   ├── secp192k1_params.sh
│   ├── secp224k1_params.sh
│   ├── secp256k1_params.sh
│   ├── secp256r1_params.sh
│   ├── secp384r1_params.sh
│   └── secp521r1_params.sh
├── docs/                          技术文档 (1个文件)
│   └── PURE_BASH_IMPLEMENTATION.md
├── examples/                      示例文件 (空目录)
├── lib/pure_bash/                 零依赖模块库 (19个模块)
│   ├── pure_bash_*.sh             核心模块 (11个)
│   ├── bash_*.sh                  Bash数学模块 (4个)
│   ├── ec_*.sh                    椭圆曲线模块 (2个)
│   ├── asn1.sh                    ASN.1编码
│   └── pure_bash_integration.sh   集成模块
├── operations/                    运算实现 (2个文件)
│   ├── ecc_arithmetic.sh
│   └── point_operations.sh
└── utils/                         工具函数 (1个文件)
    └── curve_validator.sh
```

#### 📁 lib/ - 共享库文件
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

#### 📁 demo/ - 演示和测试
```
demo/
├── README.md                      演示文档
├── bash_concept_demo.sh           Bash概念演示
├── bash_pure_demo.sh              纯Bash概念演示
├── demo.sh                        主要演示
├── final_verification.sh          最终验证
├── pure_bash_complete_demo.sh     完整纯Bash演示
├── pure_bash_demo.sh              纯Bash演示
├── pure_bash_final_demo.sh        最终纯Bash演示
├── pure_bash_final_report.sh      纯Bash最终报告
├── quick_demo.sh                  快速演示
├── comparison/                    对比测试 (2个文件)
├── examples/                      示例文件 (1个文件)
├── pure_bash_core/                纯Bash核心测试 (3个文件)
├── pure_bash_tests/               纯Bash测试 (9个文件)
├── quick_tests/                   快速测试 (7个文件)
├── reports/                       测试报告 (2个文件)
├── tests/                         综合测试 (17个文件 + 输出文件)
├── validation/                    验证测试 (2个文件)
└── verification/                  验证工具 (2个文件)
```

#### 📁 tests_archive/ - 综合测试套件 (45个测试脚本)
```
tests_archive/
├── comprehensive_runnable_test.sh   [8.4K] 主测试运行器
├── benchmark_multi_curve.sh       [15K] 性能基准测试
├── simple_runnable_test.sh        [2.3K] 简化测试
├── verify_normal_error_handling.sh [3.1K] 错误处理验证
│
├── core/                          核心功能测试
├── elliptic_curves/               椭圆曲线相关测试
├── ecdsa/                         签名算法测试
├── openssl_comparison/            OpenSSL标准兼容性测试
├── extreme_tests/                 边界条件测试
├── debug_tools/                   开发调试工具
└── 其他测试分类目录
```

## 📊 项目规模统计

| 类别 | 数量 | 备注 |
|------|------|------|
| 总文件数 | 780个 | 完整项目规模 |
| 总目录数 | 270个 | 目录结构深度 |
| Shell脚本 | 226个 | 主要实现语言 |
| Markdown文档 | 107个 | 项目文档 |
| HTML文件 | 5个 | 展示页面 |
| 测试脚本 | 45个 | 在tests_archive/中 |
| 核心库文件 | 31个 | lib/目录12个 + core/lib/pure_bash/19个 |
| 标准曲线 | 7个 | 支持的椭圆曲线 |

## 🎯 当前状态

✅ **目录整理已完成** - 主目录从40+个文件精简到12个核心文件
✅ **功能完整性保持** - 所有核心程序、测试脚本、演示功能完全保留
✅ **分类科学性** - 按照文档性质和功能进行专业分类
✅ **路径完整性** - 验证所有脚本路径引用正确，功能正常
✅ **符合规范** - 严格遵循原始规划要求

## 🔧 使用指南

### 快速开始
```bash
# 查看帮助
./becc.sh --help

# 运行测试
./tests/test_quick_functionality.sh

# 查看支持的曲线
./becc_multi_curve.sh curves

# 纯Bash概念演示
bash demo/bash_pure_demo.sh
```

### 目录导航
- **核心程序**: 主目录3个becc*.sh文件
- **项目文档**: `docs/`目录按类型分类
- **测试套件**: `tests/`和`tests_archive/`目录
- **纯Bash实现**: `core/lib/pure_bash/`目录
- **共享库**: `lib/`目录
- **演示脚本**: `demo/`目录
- **辅助工具**: `tools/scripts/`和`tools/utils/`目录

---

**最后更新**: 2025年12月5日 - 基于目录整理完成后的最新结构