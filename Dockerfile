# 1. 使用官方最新的 Alpine 极简镜像
FROM alpine:latest

# 接收 GitHub Actions Buildx 自动注入的架构变量 (amd64 或 arm64)
ARG TARGETARCH

WORKDIR /app

# 2. 安装 Alpine 必备依赖
# ca-certificates: 用于网络证书校验
# gcompat & libc6-compat: 核心兼容层，确保非静态编译的 glibc 二进制文件能在 Alpine 下正常运行
RUN apk add --no-cache ca-certificates gcompat libc6-compat

# 3. 复制你手动上传到仓库的二进制文件
COPY xts xtsa ./

# 4. 根据当前编译的架构，把正确的二进制文件移动到系统目录
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

# 声明端口
EXPOSE 3000

# 5. 使用 Shell 形式启动：
# - 自动适配云平台分配的 $PORT 变量（若无则默认 3000）
# - 保持 ws://:${PORT}/ggjj 的格式，允许外部任意域名和 Host 成功接入
CMD /usr/local/bin/xts -l ws://0.0.0.0:${PORT:-3000}/ggjj -token sliao530
