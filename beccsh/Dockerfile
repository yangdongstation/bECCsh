FROM ubuntu:22.04

# 安装必要的bash和工具（虽然我们不依赖它们）
RUN apt-get update && apt-get install -y \
    bash \
    bc \
    coreutils \
    procps \
    iproute2 \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# 创建项目目录
WORKDIR /opt/beccsh

# 复制项目文件
COPY . .

# 设置权限
RUN chmod +x becc.sh quick_test.sh lib/*.sh

# 创建专用用户（不推荐以root运行）
RUN useradd -m -s /bin/bash beccuser
USER beccuser

# 默认命令：显示警告并运行测试
CMD ["bash", "-c", "./quick_test.sh"]