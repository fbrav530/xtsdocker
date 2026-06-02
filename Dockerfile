# 1. 使用官方最新的 Alpine 极简镜像
FROM alpine:latest

# 接收 GitHub Actions Buildx 自动注入的架构变量 (amd64 或 arm64)
ARG TARGETARCH

WORKDIR /app

# 2. 安装 Alpine 必备依赖（增加了 wget 用于下载 cloudflared）
RUN apk add --no-cache ca-certificates gcompat libc6-compat wget

# 3. 处理你手动上传的 xts 二进制文件
COPY xts xtsa ./
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

# 4. 自动识别架构并下载 Cloudflare 官方最新版 cloudflared 二进制文件
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        echo "正在下载 Linux amd64 版 cloudflared..." && \
        wget -O /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        echo "正在下载 Linux arm64 版 cloudflared..." && \
        wget -O /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64; \
    fi && \
    chmod +x /usr/local/bin/cloudflared

# 容器内监听 3000 端口
EXPOSE 3000

# 5. 同时启动两个程序：
# - xts 放在后台运行 (&) 监听本地 3000 端口
# - cloudflared 在前台运行，负责建立隧道并保持容器不退出
CMD /usr/local/bin/xts -l ws://127.0.0.1:3000/ggjj -token sliao530 & \
    /usr/local/bin/cloudflared tunnel run --token eyJhIjoiOWRhNWIzNTJmNTc0MmJjOGExOWVkOWI0MjUwZWZmZGQiLCJ0IjoiMTc2MzU1ZmYtZmU0OC00MTJhLTk5ZWYtMTZhMDhmOWYyZjJjIiwicyI6Ik5EbGpORFptT0RjdE5EVXlNeTAwT1RGbUxUazFOV0l0WVRoaU9ESmhNekAyeXpBMSJ9
