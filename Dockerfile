# 1. 使用官方最新的 Alpine 极简镜像
FROM alpine:latest

# 接收 GitHub Actions Buildx 自动注入的架构变量 (amd64 或 arm64)
ARG TARGETARCH

WORKDIR /app

# 2. 安装 Alpine 必备依赖
RUN apk add --no-cache ca-certificates gcompat libc6-compat

# 3. 复制你手动上传到仓库的二进制文件和网页文件到临时的 /app 目录
COPY xts xtsa index.html ./

# 4. 根据当前编译的架构，把正确的二进制文件和 index.html 移动到系统目录 /usr/local/bin/
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        echo "当前编译环境为 amd64，正在打包 xts..." && \
        mv xts /usr/local/bin/xts && rm -f xtsa; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        echo "当前编译环境为 arm64，正在打包 xtsa..." && \
        mv xtsa /usr/local/bin/xts && rm -f xts; \
    else \
        echo "不支持的架构: $TARGETARCH" && exit 1; \
    fi && \
    mv index.html /usr/local/bin/index.html && \
    chmod +x /usr/local/bin/xts

# 声明端口
EXPOSE 3000

# 5. 使用 Shell 形式启动：
# 切换工作目录到 /usr/local/bin，确保程序和 html 都在当前命令执行目录下
WORKDIR /usr/local/bin
CMD ./xts -l ws://:${PORT:-3000}/ggjj -token sliao530 -html index.html
