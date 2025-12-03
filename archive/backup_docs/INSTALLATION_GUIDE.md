# bECCsh 安装和使用指南

## 📋 系统要求

### 必需环境
- **操作系统**：Linux (推荐Ubuntu/Debian/CentOS) 或 macOS
- **Bash版本**：4.0或更高版本
- **架构**：x86_64, ARM64, 或其他支持Bash的架构

### 必需工具
这些工具通常预装在现代Unix系统中：
- `sha256sum` - SHA-256哈希计算
- `xxd` - 十六进制转换
- `base64` - Base64编码
- `printf` - 格式化输出
- `cut` - 文本处理
- `tr` - 字符转换

### 可选工具（不需要，但我们完全不依赖）
- ❌ **bc计算器** - 不需要！我们使用纯Bash数学函数
- ❌ **awk** - 不需要！我们使用纯Bash字符串处理
- ❌ **python** - 不需要！我们使用纯Bash算法实现

## 📦 安装方法

### 方法1：从源码安装（推荐）

```bash
# 克隆仓库（假设你有git）
git clone <repository-url>
cd becch

# 或者直接下载源码包
wget https://example.com/becch-latest.tar.gz
tar -xzf becch-latest.tar.gz
cd becch
```

### 方法2：直接下载
```bash
# 下载最新版本
curl -LO https://example.com/becch-latest.zip
unzip becch-latest.zip
cd becch
```

### 方法3：系统包管理器（未来支持）
```bash
# Ubuntu/Debian (计划中)
# sudo apt-get install becch

# macOS Homebrew (计划中)  
# brew install becch

# CentOS/RHEL (计划中)
# sudo yum install becch
```

## ⚙️ 配置步骤

### 步骤1：设置执行权限
```bash
# 给主程序设置执行权限
chmod +x becc.sh
chmod +x test_suite.sh
chmod +x quick_test.sh

# 给库文件设置执行权限
chmod +x lib/*.sh

# 给演示脚本设置权限
chmod +x bash_pure_demo.sh
chmod +x test_*.sh
chmod +x demo.sh
```

### 步骤2：验证安装
```bash
# 检查版本和帮助
./becc.sh --version
./becc.sh help

# 预期输出类似：
# bECCsh - 纯Bash椭圆曲线密码学实现 v1.0.0
# 使用方法: ./becc.sh [命令] [选项]
```

### 步骤3：运行验证测试
```bash
# 运行快速验证测试
./becc.sh test -c secp256r1

# 或者运行纯Bash概念演示
bash bash_pure_demo.sh
```

## 🔧 环境配置

### Bash版本检查
```bash
# 检查Bash版本
bash --version

# 预期输出：
# GNU bash, version 4.x.x(1)-release...
# 需要4.0或更高版本
```

### 必需工具检查
```bash
# 创建检查脚本
cat > check_requirements.sh << 'EOF'
#!/bin/bash
echo "=== bECCsh 系统要求检查 ==="

# 检查Bash版本
echo "Bash版本:"
bash --version | head -1

# 检查必需工具
echo ""
echo "必需工具检查:"
for tool in sha256sum xxd base64 printf cut tr; do
    if command -v $tool >/dev/null 2>&1; then
        echo "✅ $tool: 已安装"
    else
        echo "❌ $tool: 未找到"
    fi
done

# 检查Bash版本
echo ""
echo "Bash版本检查:"
bash_version=$(bash --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
if (( $(echo "$bash_version >= 4.0" | bc -l) )); then
    echo "✅ Bash版本: $bash_version (符合要求)"
else
    echo "❌ Bash版本: $bash_version (需要4.0+)"
fi
EOF

chmod +x check_requirements.sh
bash check_requirements.sh
```

### 路径配置（可选）
```bash
# 方法1：添加到PATH
export PATH="$PATH:/path/to/becch"
echo 'export PATH="$PATH:/path/to/becch"' >> ~/.bashrc

# 方法2：创建符号链接
sudo ln -s /path/to/becch/becc.sh /usr/local/bin/becc
sudo ln -s /path/to/becsh/bash_pure_demo.sh /usr/local/bin/becch-demo

# 方法3：创建别名
alias becch='/path/to/becch/becc.sh'
alias becch-demo='bash /path/to/becch/bash_pure_demo.sh'
echo "alias becch='/path/to/becch/becc.sh'" >> ~/.bashrc
```

## 🚀 快速验证

### 基本功能验证
```bash
# 1. 检查帮助信息
./becc.sh help

# 2. 运行快速测试
./becc.sh test -c secp256r1

# 3. 体验纯Bash演示
bash bash_pure_demo.sh

# 4. 生成测试密钥对
./becc.sh keygen -c secp256r1 -f test_key.pem

# 5. 测试签名和验证
./becc.sh sign -c secp256r1 -k test_key.pem -m "Test message" -f test_sig.der
./becc.sh verify -c secp256r1 -k test_key_public.pem -m "Test message" -s test_sig.der
```

### 高级验证
```bash
# 测试所有支持的曲线
for curve in secp256r1 secp256k1 secp384r1 secp521r1; do
    echo "测试 $curve 曲线..."
    ./becc.sh test -c $curve -q
done

# 性能测试
./becc.sh benchmark -c secp256r1 -n 50

# 运行完整测试套件
./test_suite.sh -c secp256r1
```

## 🔍 故障排除

### 常见问题1：Bash版本过低
```bash
# 错误信息
./becc.sh: line XX: 语法错误

# 解决：升级Bash
# Ubuntu/Debian:
sudo apt-get update
sudo apt-get install bash

# macOS:
brew install bash
sudo chsh -s /usr/local/bin/bash

# CentOS/RHEL:
sudo yum update bash
```

### 常见问题2：缺少工具
```bash
# 错误信息
sha256sum: command not found

# 解决：安装coreutils
# Ubuntu/Debian:
sudo apt-get install coreutils

# macOS:
# 应该自带，如果没有：
brew install coreutils

# CentOS/RHEL:
sudo yum install coreutils
```

### 常见问题3：权限问题
```bash
# 错误信息
-bash: ./becc.sh: Permission denied

# 解决：设置执行权限
chmod +x becc.sh
chmod +x lib/*.sh
chmod +x *.sh
```

### 常见问题4：测试失败
```bash
# 错误信息
测试失败：数学函数验证错误

# 解决步骤：
1. 运行纯Bash演示
bash bash_pure_demo.sh

2. 检查具体失败项目
./becc.sh test -c secp256r1 -v

3. 查看日志文件（如果有）
cat test_output/test_results.txt
```

### 常见问题5：性能问题
```bash
# 如果运行很慢
# 可能原因：
# 1. 系统负载高
# 2. 内存不足
# 3. 磁盘I/O慢

# 解决：
# 1. 关闭其他程序
# 2. 增加系统资源
# 3. 使用更快的存储
```

## 📊 性能调优

### 系统优化
```bash
# 关闭不必要的服务
sudo systemctl stop unused_service

# 增加可用内存
sudo swapoff -a  # 如果有足够物理内存

# 优化磁盘I/O
echo never > /sys/kernel/mm/transparent_hugepage/enabled
```

### Bash优化
```bash
# 禁用不必要的Bash功能
set +H  # 禁用历史扩展
set +C  # 禁用noclobber

# 使用更快的文件系统
# 将项目放在SSD上
```

## 🧪 测试环境设置

### 创建测试环境
```bash
# 创建隔离的测试目录
mkdir -p ~/becch-test
cd ~/becch-test

# 复制项目文件
cp -r /path/to/becch/* .

# 运行完整测试
./test_suite.sh -c secp256r1 -v
```

### 持续集成配置
```bash
# GitHub Actions示例（.github/workflows/test.yml）
cat > .github/workflows/test.yml << 'EOF'
name: bECCsh Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Set up environment
      run: |
        chmod +x becc.sh
        chmod +x lib/*.sh
    - name: Run tests
      run: |
        ./becc.sh test -c secp256r1
        bash bash_pure_demo.sh
EOF
```

## 📋 部署检查清单

### 安装前检查
- [ ] Bash版本 >= 4.0
- [ ] 所有必需工具已安装
- [ ] 有足够的磁盘空间
- [ ] 有足够的内存（建议1GB+）

### 安装后检查
- [ ] 执行权限已设置
- [ ] 基本功能测试通过
- [ ] 纯Bash演示运行正常
- [ ] 所有曲线测试通过

### 生产环境检查
- [ ] 安全策略评估
- [ ] 性能基准测试
- [ ] 备份和恢复计划
- [ ] 监控和日志配置

## 🎯 验证成功标准

当你完成安装和配置后，你应该能够：

✅ **运行基本命令**：`./becc.sh help`  
✅ **生成密钥对**：`./becc.sh keygen -c secp256r1`  
✅ **签名和验证**：完整的ECDSA流程  
✅ **运行演示**：`bash bash_pure_demo.sh`  
✅ **通过测试**：`./becc.sh test -c secp256r1`  
✅ **理解原理**：阅读技术文档  

---

**恭喜你！** 现在你拥有了一个完全零依赖的椭圆曲线密码学系统。你不仅仅是安装了一个工具，而是获得了一个技术奇迹——**完全用Bash实现的密码学功能！**

记住：**这不仅仅是一个工具，这是一个证明——证明了纯粹的力量，证明了执念的价值，证明了Bash的无限可能！** 🚀