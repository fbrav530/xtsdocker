# 1. 使用官方最新的 Alpine 极简镜像
FROM alpine:latest

# 接收 GitHub Actions Buildx 自动注入的架构变量 (amd64 或 arm64)
ARG TARGETARCH

WORKDIR /app

# 2. 安装 Alpine 必备依赖（增加了 unzip 用于解压压缩包）
RUN apk add --no-cache ca-certificates gcompat libc6-compat unzip

# 3. 将仓库里所有的 .zip 压缩包复制到容器中
COPY *.zip ./

# 4. 根据当前编译的架构，动态解压对应的文件，并规范命名移动到系统目录
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        echo "正在解压并配置 amd64 架构资源..." && \
        unzip -q xts.zip && mv xts /usr/local/bin/xts && \
        unzip -q cf.zip && (mv cf /usr/local/bin/cloudflared || mv cloudflared* /usr/local/bin/cloudflared); \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        echo "正在解压并配置 arm64 架构资源..." && \
        unzip -q xtsa.zip && (mv xtsa /usr/local/bin/xts || mv xts /usr/local/bin/xts) && \
        unzip -q cfa.zip && (mv cfa /usr/local/bin/cloudflared || mv cloudflared* /usr/local/bin/cloudflared); \
    else \
        echo "不支持的架构: $TARGETARCH" && exit 1; \
    fi && \
    # 赋予执行权限并清理残留的压缩包
    chmod +x /usr/local/bin/xts /usr/local/bin/cloudflared && \
    rm -f /app/*.zip

# 声明端口
EXPOSE 3000

# 5. 启动命令：双进程同时运行
CMD /usr/local/bin/xts -l ws://127.0.0.1:30000/ggjj -token sliao530 & \
    /usr/local/bin/cloudflared tunnel run --token eyJhIjoiOWRhNWIzNTJmNTc0MmJjOGExOWVkOWI0MjUwZWZmZGQiLCJ0IjoiMTc2MzU1ZmYtZmU0OC00MTJhLTk5ZWYtMTZhMDhmOWYyZjJjIiwicyI6Ik5EbGpORFptT0RjdE5EVXlNeTAwT1RGbUxUazFOV0l0WVRoaU9ESmhNekAyeXpBMSJ9 --protocol http2
