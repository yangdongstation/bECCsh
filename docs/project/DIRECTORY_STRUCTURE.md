# bECCsh 项目目录结构

经过系统整理，项目目录结构更加清晰和专业。以下是完整的目录结构说明：

## 🏠 主目录（核心文件）

```
/home/donz/bECCsh/
├── becc.sh                           # 主程序入口（完整版v1.0.0）⭐
├── becc_multi_curve.sh              # 多曲线支持版本（v2.0.0）⭐
├── becc_fixed.sh                    # Bug修复版本⭐
├── README.md                        # 项目主要说明文档⭐
├── AGENTS.md                        # 项目背景和开发规范⭐
├── CURRENT_ACTIVE_DOCUMENTS.md      # 当前活跃文档清单⭐
├── CORE_FILES.md                    # 核心文件清单⭐
├── TECHNICAL_PAGES_README.md        # 技术页面使用指南⭐
├── index.html                       # 主展示页面⭐
├── .gitignore                       # Git忽略文件⭐
└── [核心子目录]                    # 功能明确的子目录
```

**总计：11个核心文件，保持主目录清爽专注**

## 📁 子目录结构

### docs/ - 文档目录
```
docs/
├── technical/          # 技术实现文档
│   ├── MULTI_CURVE_README.md                    # 多曲线功能说明
│   ├── MULTI_CURVE_IMPLEMENTATION_COMPLETE.md   # 多曲线实现完成报告
│   ├── GITHUB_LINKS_GUIDE.md                    # GitHub链接指南
│   └── FIX_SUMMARY.md                           # 修复总结
│
├── reports/            # 分析报告和总结
│   ├── FINAL_2_PERCENT_FAILURE_ANALYSIS.md      # 2%失败率分析
│   ├── ORGANIZATION_SUMMARY.md                  # 目录整理总结
│   ├── PROJECT_COMPLETION_SUMMARY.md            # 项目完成总结
│   ├── PUSH_INSTRUCTIONS.md                     # Git推送说明
│   ├── GIT_SUMMARY.md                           # Git仓库总结
│   └── COMMIT_MESSAGE.md                        # 提交信息模板
│
└── [归档文档]         # 历史完成文档（在archive/中）
```

### tests/ - 测试脚本目录
```
tests/
├── test_quick_functionality.sh           # 快速功能测试
├── test_openssl_compatibility_final.sh   # OpenSSL兼容性测试
├── test_core_modules_direct.sh          # 核心模块直接测试
├── runnable_test.sh                     # 可运行测试
├── detailed_math_analysis.sh            # 详细数学分析
└── detailed_test_failure_analysis.sh    # 详细测试失败分析
```

### html/ - HTML页面目录
```
html/
├── index_cryptographic.html    # 密码学技术详解页面
├── index_mathematical.html     # 数学原理展示页面
├── index_professional.html     # 专业版本页面
└── test_formula_display.html   # 公式显示测试页面
```

### tools/ - 辅助工具目录
```
tools/
├── security_functions.sh        # 安全功能模块
├── secure_main_integration.sh   # 安全集成脚本
├── improved_random.sh          # 改进随机数生成
├── fixed_pure_bash_hex.sh      # 纯Bash十六进制修复
├── openssl_test_key.pem        # OpenSSL测试密钥
├── test1.txt                   # 测试文件1
└── test2.txt                   # 测试文件2
```

### 现有核心子目录（功能明确，保持不变）
```
core/                    # 纯Bash实现核心
├── becc_pure.sh        # 纯Bash主程序
├── crypto/             # 密码学实现
├── curves/             # 曲线参数
├── operations/         # ECC算术运算
└── lib/pure_bash/      # 纯Bash模块库

demo/                    # 演示和测试
├── bash_pure_demo.sh   # 纯Bash概念演示
├── demo_multi_curve_showcase.sh # 多曲线展示
├── pure_bash_tests/    # 功能测试套件
├── quick_tests/        # 快速测试
├── comparison/         # 对比测试
├── examples/           # 使用示例
├── validation/         # 验证测试
└── verification/       # 验证报告

lib/                     # 共享库文件
├── bash_math.sh        # 纯Bash数学函数
├── bash_bigint.sh      # 纯Bash大数运算
├── ecdsa.sh            # ECDSA签名实现
├── security.sh         # RFC 6979和安全功能
├── elliptic_curve.sh   # 椭圆曲线核心
├── key_management.sh   # 密钥管理
├── signature_formatting.sh # 签名格式处理
├── random_generator.sh # 随机数生成
├── validation.sh       # 输入验证
├── error_handling.sh   # 错误处理
└── constants.sh        # 常量定义

archive/                 # 开发历史归档
├── backup_docs/        # 文档备份
├── old_implementations/ # 历史实现版本
├── test_files/         # 历史测试文件
└── [历史归档文件]

tests_archive/           # 测试归档
├── core/               # 核心功能测试历史
├── elliptic_curves/    # 椭圆曲线测试历史
├── ecdsa/             # ECDSA测试历史
├── openssl_comparison/ # OpenSSL对比测试历史
├── extreme_tests/      # 极限条件测试历史
├── debug_tools/        # 调试工具测试历史
├── demos/              # 演示测试历史
├── final_versions/     # 最终版本测试历史
├── environmental/      # 环境测试历史
└── math_modules/       # 数学模块测试历史
```

## 📊 统计信息

### 文件分布
- **主目录**：11个核心文件
- **docs/technical/**：4个技术文档
- **docs/reports/**：6个分析报告
- **tests/**：6个测试脚本
- **html/**：4个HTML页面
- **tools/**：8个辅助工具
- **现有子目录**：保持原有功能结构

### 整理效果
- **主目录清爽**：从40+个文件减少到11个核心文件
- **分类清晰**：每个子目录都有明确的功能定位
- **逻辑完整**：程序运行和文档逻辑完全不受影响
- **易于维护**：文件组织结构更加专业和系统化

## 🎯 设计原则

### 1. 核心聚焦原则
主目录只保留最核心、最常用的文件，让用户一眼就能看到项目的关键内容。

### 2. 功能分类原则
按照文件功能和用途进行分类，每个子目录都有明确的职责范围。

### 3. 逻辑完整原则
确保文件移动不影响程序运行和文档逻辑，所有链接和引用都保持有效。

### 4. 专业美观原则
目录结构清晰专业，符合开源项目的标准组织结构。

## 🚀 使用指南

### 快速开始
```bash
# 查看项目核心
ls -la /home/donz/bECCsh/

# 运行主程序
./becc.sh --help

# 查看技术文档
cat docs/technical/MULTI_CURVE_README.md

# 运行测试
./tests/test_quick_functionality.sh

# 查看展示页面
open index.html
```

### 深入探索
```bash
# 探索纯Bash核心实现
cd core/ && ls -la

# 查看详细技术文档
cat docs/technical/CRYPTOGRAPHIC_TECHNICAL_DOCUMENTATION.md

# 运行专业演示
cd demo/ && ./demo_multi_curve_showcase.sh

# 查看数学原理
open html/index_mathematical.html
```

## 📋 维护建议

1. **定期清理** - 定期检查主目录，避免非核心文件堆积
2. **分类存放** - 新文件按照功能分类放入相应子目录
3. **文档同步** - 保持文档与实际文件结构同步
4. **版本管理** - 使用Git跟踪目录结构变化
5. **用户反馈** - 根据用户反馈优化目录结构

---

**整理完成时间：** 2025年12月4日
**整理效果：** 主目录从40+个文件精简到11个核心文件，项目结构更加专业清晰