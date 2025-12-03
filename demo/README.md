# bECCsh 演示和测试

这个目录包含bECCsh纯Bash实现的各种演示和测试文件。

## 📁 目录结构

```
demo/
├── pure_bash_tests/          # 纯Bash功能测试
│   ├── test_all_functions.sh # 综合功能测试
│   └── pure_bash_*.sh       # 各个模块的独立测试
├── examples/                 # 示例演示
│   └── pure_bash_demo.sh    # 纯Bash演示脚本
├── validation/               # 验证测试
│   ├── performance_test.sh  # 性能测试
│   └── compatibility_test.sh # 兼容性测试
└── quick_demo.sh            # 快速演示入口
```

## 🚀 快速开始

```bash
# 快速演示
./quick_demo.sh

# 综合功能测试
./pure_bash_tests/test_all_functions.sh

# 性能测试
./validation/performance_test.sh

# 兼容性验证
./validation/compatibility_test.sh
```

## 🧪 测试内容

### 功能测试
- 随机数生成质量
- 哈希函数正确性
- Base64编解码完整性
- ECDSA简化算法

### 性能测试
- 随机数生成速度
- 哈希计算性能
- Base64编码效率

### 兼容性验证
- Bash版本检查
- 外部依赖验证
- 系统功能可用性

## 📊 测试结果说明

### ✅ 通过指标
- 功能正常执行
- 结果符合预期
- 无错误输出

### ⚠️ 注意指标  
- 性能相对较低（纯Bash正常）
- 整数大小限制（Bash固有限制）
- 随机数质量（教育级别）

## 🎯 使用建议

1. **教学演示** - 使用quick_demo.sh
2. **功能验证** - 使用test_all_functions.sh
3. **性能评估** - 使用performance_test.sh
4. **环境检查** - 使用compatibility_test.sh

## 🔍 故障排除

如果测试失败：
1. 检查Bash版本（需要4.0+）
2. 验证文件权限
3. 查看具体错误信息
4. 确保模块加载正确

---

**这些测试文件帮助验证纯Bash实现的功能完整性，不影响主程序的整洁性。**
