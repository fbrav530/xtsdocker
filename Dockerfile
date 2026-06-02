# 1. 使用 Debian 瘦身版作为基础镜像
FROM debian:bookworm-slim

# 接收 GitHub Buildx 自动注入的目标架构变量 (amd64 或 arm64)
ARG TARGETARCH

WORKDIR /app

# 2. 安装基础系统证书（运行网络程序必备，无需安装 wget）
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 3. 将仓库里的二进制文件复制到容器的工作目录
COPY xts xtsa ./

# 4. 根据当前编译的架构，把正确的二进制文件移动到系统目录，并重命名为 xts
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        echo "当前编译环境为 amd64，正在打包 xts..." && \
        mv xts /usr/local/bin/xts && rm -f xtsa; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        echo "当前编译环境为 arm64，正在打包 xtsa..." && \
        mv xtsa /usr/local/bin/xts && rm -f xts; \
    else \
        echo "不支持的架构: $TARGETARCH" && exit 1; \
    fi && \
    chmod +x /usr/local/bin/xts

# 5. 声明暴露 3000 端口
EXPOSE 3000/tcp

# 6. 启动命令：锁定 3000 端口、ws 协议、前台死守运行
CMD ["/usr/local/bin/xts", "-l", "ws://0.0.0.0:3000/ggjj", "-token", "sliao530"]
