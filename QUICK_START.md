# bECCsh 快速入门指南

## 🚀 5分钟上手

### 步骤1：验证系统要求
```bash
# 检查Bash版本
bash --version  # 需要4.0+

# 检查必需工具
which sha256sum xxd base64  # 应该都有

# 可选：检查bc（不需要，但我们已经完全不依赖它）
# which bc  # 不需要！
```

### 步骤2：获取项目
```bash
# 克隆项目（假设你有git）
git clone <repository-url>
cd becch

# 或者直接下载源码包并解压
# tar -xzf becch-latest.tar.gz
# cd becch
```

### 步骤3：设置执行权限
```bash
# 给主程序设置执行权限
chmod +x becc.sh
chmod +x test_suite.sh
chmod +x lib/*.sh

# 给演示脚本设置权限
chmod +x bash_pure_demo.sh
chmod +x test_*.sh
```

### 步骤4：验证安装
```bash
# 检查帮助信息
./becc.sh help

# 预期输出：
# bECCsh - 纯Bash椭圆曲线密码学实现 v1.0.0
# 使用方法: ./becc.sh [命令] [选项]
```

### 步骤5：运行快速测试
```bash
# 运行基础功能测试
./becc.sh test -c secp256r1

# 或者运行纯Bash演示
bash bash_pure_demo.sh
```

## 📋 基本使用

### 生成密钥对
```bash
# 生成secp256r1密钥对
./becc.sh keygen -c secp256r1 -f my_key.pem

# 输出：
# my_key.pem (私钥)
# my_key_public.pem (公钥)
```

### 签名消息
```bash
# 对消息进行签名
./becc.sh sign -c secp256r1 -k my_key.pem -m "Hello, World!" -f signature.der

# 或者签名文件内容
./becc.sh sign -c secp256r1 -k my_key.pem -f message.txt -s signature.der
```

### 验证签名
```bash
# 验证签名
./becc.sh verify -c secp256r1 -k my_key_public.pem -m "Hello, World!" -s signature.der

# 预期输出：VALID 或 INVALID
```

## 🎮 体验纯Bash演示

### 运行概念演示
```bash
# 体验完全无依赖的密码学演示
bash bash_pure_demo.sh
```

这个演示将展示：
- ✅ 纯Bash十六进制转换
- ✅ 纯Bash大数加法和乘法
- ✅ 椭圆曲线点运算概念
- ✅ 纯Bash哈希函数
- ✅ 纯Bash随机数生成
- ✅ 密钥生成和签名概念

### 预期输出
```
=== 纯Bash密码学概念演示 ===
十六进制转换测试:
  FF -> 255 (期望: 255)
  255 -> FF (期望: FF)
大数加法测试:
  123 + 456 = 579 (期望: 579)
...
🎉 纯Bash密码学概念演示完成！
✅ 成功演示了所有功能！
🚀 重要结论:
  完全使用Bash实现密码学功能是完全可能的！
```

## 🔧 高级用法

### 选择不同曲线
```bash
# 使用secp256k1 (比特币曲线)
./becc.sh keygen -c secp256k1 -f bitcoin_key.pem

# 使用secp384r1 (高安全级别)
./becc.sh keygen -c secp384r1 -f high_security_key.pem

# 使用secp521r1 (最高安全级别)
./becc.sh keygen -c secp521r1 -f maximum_security_key.pem
```

### 性能测试
```bash
# 运行性能基准测试
./becc.sh benchmark -c secp256r1 -n 100

# 预期结果：
# 数学函数性能: 100 次操作耗时约1秒
# 适合教育和小型应用，不适合高频操作
```

### 调试模式
```bash
# 启用调试模式（详细输出）
./becc.sh -d keygen -c secp256r1 -f debug_key.pem

# 查看详细日志
./becc.sh keygen -c secp256r1 -f key.pem -v
```

## 🎓 学习路径

### 初学者路径（30分钟）
1. ✅ 运行快速测试（5分钟）
2. ✅ 体验纯Bash演示（10分钟）
3. ✅ 生成和验证密钥对（10分钟）
4. ✅ 阅读README主要部分（5分钟）

### 进阶路径（2小时）
1. ✅ 完成初学者路径
2. ✅ 阅读MATH_REPLACEMENT.md（30分钟）
3. ✅ 研究bash_bigint.sh实现（30分钟）
4. ✅ 理解椭圆曲线运算（30分钟）
5. ✅ 尝试修改和扩展（30分钟）

### 专家路径（1天）
1. ✅ 完成进阶路径
2. ✅ 阅读PURE_BASH_MANIFESTO.md（1小时）
3. ✅ 研究所有库文件的实现（2小时）
4. ✅ 理解RFC 6979实现（1小时）
5. ✅ 尝试添加新功能（3小时）

## 🔍 故障排除

### 常见问题1：Bash版本太低
```bash
# 错误：需要Bash 4.0+
# 解决：升级Bash或更换系统
bash --version
```

### 常见问题2：缺少工具
```bash
# 错误：找不到sha256sum
# 解决：安装coreutils包
# Ubuntu/Debian: sudo apt-get install coreutils
# macOS: 应该自带
# CentOS: sudo yum install coreutils
```

### 常见问题3：权限问题
```bash
# 错误：权限拒绝
# 解决：设置执行权限
chmod +x becc.sh
chmod +x lib/*.sh
```

### 常见问题4：测试失败
```bash
# 如果测试失败，先运行简单的概念演示
bash bash_pure_demo.sh

# 检查具体是哪个功能失败
./becc.sh test -c secp256r1 -v  # 详细输出
```

## 📚 下一步阅读

完成快速入门后，建议阅读：

1. **[README.md](README.md)** - 完整项目文档
2. **[MATH_REPLACEMENT.md](MATH_REPLACEMENT.md)** - 纯Bash数学函数详解
3. **[bash_pure_demo.sh](bash_pure_demo.sh)** - 概念演示源码
4. **[PURE_BASH_MANIFESTO.md](PURE_BASH_MANIFESTO.md)** - 纯Bash编程哲学

## 🎯 目标达成

恭喜你完成了bECCsh的快速入门！你现在可以：

✅ **生成和验证ECDSA签名**  
✅ **理解纯Bash密码学概念**  
✅ **体验零依赖的编程美学**  
✅ **探索完全透明的算法实现**  

**记住**：你不仅仅是在使用一个密码学工具，你是在见证一个技术奇迹——**完全用Bash实现的椭圆曲线密码学！**

---

*"有时候，最不合理的执念，会带来最美丽的结果。"* 🚀