# 演示脚本路径问题分析报告

## 🔍 问题概述

经过全面检查，发现演示脚本存在以下路径引用问题：

## 📋 发现的问题

### 1. 缺失的演示脚本
- **问题**: `demo/demo_multi_curve_showcase.sh` 文件不存在
- **位置**: 文档中多次引用，但实际文件位于 `tests_archive/demos/`
- **影响**: 用户按照文档指示无法找到演示脚本

### 2. 路径引用错误

#### 2.1 相对路径问题
**文件**: `demo/quick_tests/quick_test.sh`
- **问题**: 使用 `source lib/big_math.sh` 和 `source lib/entropy.sh`
- **实际位置**: `lib/big_math.sh` 不存在，正确路径是 `beccsh/lib/big_math.sh`
- **影响**: 演示脚本无法加载必要的库文件

#### 2.2 库文件缺失
**文件**: `demo/tests/test_suite.sh`
- **问题**: 使用 `source lib/big_math.sh` 等相对路径
- **实际位置**: 需要引用正确的库文件路径
- **影响**: 测试套件无法运行

### 3. 纯Bash模块路径问题

#### 3.1 不一致的模块路径
**文件**: `demo/pure_bash_demo.sh`
- **问题**: `source "${SCRIPT_DIR}/../core/lib/pure_bash/pure_bash_crypto.sh"`
- **状态**: 路径正确，但依赖的模块文件存在多个版本

#### 3.2 循环依赖风险
多个演示脚本尝试加载相同的纯Bash模块，但模块间存在交叉引用

## 🛠️ 修复方案

### 1. 修复缺失的演示脚本
```bash
# 创建符号链接或复制文件
ln -s ../../tests_archive/demos/demo_multi_curve_showcase.sh demo/demo_multi_curve_showcase.sh
```

### 2. 修复路径引用

#### 2.1 修复 quick_test.sh
```bash
# 修改前
source lib/big_math.sh
source lib/entropy.sh

# 修改后  
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$PROJECT_ROOT/lib/big_math.sh" 2>/dev/null || \
    source "$PROJECT_ROOT/beccsh/lib/big_math.sh" 2>/dev/null || {
        echo "错误: 无法加载 big_math.sh"
        exit 1
    }
source "$PROJECT_ROOT/lib/entropy.sh" 2>/dev/null || \
    source "$PROJECT_ROOT/beccsh/lib/entropy.sh" 2>/dev/null || {
        echo "错误: 无法加载 entropy.sh"
        exit 1
    }
```

#### 2.2 修复 test_suite.sh
```bash
# 添加项目根目录检测
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# 然后使用绝对路径引用
source "$PROJECT_ROOT/lib/big_math.sh"
# 或其他可能的路径
source "$PROJECT_ROOT/beccsh/lib/big_math.sh" 2>/dev/null || \
    source "$PROJECT_ROOT/lib/big_math.sh" 2>/dev/null || {
        echo "错误: 无法加载数学库"
        exit 1
    }
```

### 3. 统一纯Bash模块加载

#### 3.1 创建统一的模块加载器
创建 `demo/pure_bash_loader.sh`:
```bash
#!/bin/bash
# 统一的纯Bash模块加载器

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# 尝试多个可能的路径
load_pure_bash_module() {
    local module="$1"
    local paths=(
        "$PROJECT_ROOT/core/lib/pure_bash/$module"
        "$PROJECT_ROOT/demo/pure_bash_tests/$module"
        "$SCRIPT_DIR/pure_bash_tests/$module"
    )
    
    for path in "${paths[@]}"; do
        if [[ -f "$path" ]]; then
            source "$path"
            return 0
        fi
    done
    
    echo "错误: 无法加载纯Bash模块: $module" >&2
    return 1
}

# 加载核心模块
load_pure_bash_module "pure_bash_encoding_final.sh"
load_pure_bash_module "pure_bash_random.sh"
load_pure_bash_module "pure_bash_hash.sh"
load_pure_bash_module "pure_bash_crypto.sh"
```

#### 3.2 更新演示脚本
修改所有纯Bash演示脚本，使用统一的加载器。

## 📊 修复优先级

1. **高优先级** (立即修复)
   - 修复缺失的 demo_multi_curve_showcase.sh
   - 修复 quick_test.sh 中的路径问题
   - 修复 test_suite.sh 中的路径问题

2. **中优先级** (后续修复)
   - 统一纯Bash模块加载机制
   - 优化路径检测逻辑

3. **低优先级** (可选改进)
   - 添加路径验证和错误处理
   - 创建路径配置常量

## ✅ 验证方法

修复后应验证：
1. 所有演示脚本能够正确找到依赖文件
2. 纯Bash模块能够正常加载
3. 功能测试能够通过
4. 多曲线展示脚本能够正常运行

## 📝 建议

1. **建立路径标准**: 统一使用项目根目录作为基准
2. **添加路径验证**: 在脚本开始时验证关键文件是否存在
3. **创建加载器**: 为不同类型的模块创建统一的加载机制
4. **文档同步**: 确保文档中的路径引用与实际文件结构一致