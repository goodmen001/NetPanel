# ─────────────────────────────────────────────
# 阶段 1：构建前端（始终在构建机器原生架构上运行）
# ─────────────────────────────────────────────
FROM --platform=$BUILDPLATFORM node:20-alpine AS frontend-builder

WORKDIR /app/webpage
COPY webpage/package*.json ./
RUN npm ci --prefer-offline

COPY webpage/ ./
RUN npm run build

# ─────────────────────────────────────────────
# xx：Docker 官方交叉编译辅助工具
# ─────────────────────────────────────────────
FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx

# ─────────────────────────────────────────────
# 阶段 2：构建后端（支持交叉编译到目标架构）
# ─────────────────────────────────────────────
FROM --platform=$BUILDPLATFORM golang:1.25.0-alpine AS backend-builder

# 接收目标平台参数
ARG TARGETPLATFORM
ARG TARGETARCH
ARG TARGETOS

# 引入 xx 工具（提供 xx-apk、xx-go、xx-cc 等辅助命令）
COPY --from=xx / /

# 安装本机 gcc/musl-dev，再由 xx-apk 为目标架构安装交叉编译工具链
RUN apk add --no-cache gcc musl-dev && \
    xx-apk add --no-cache gcc musl-dev

WORKDIR /app

# 复制 go.mod / go.sum 先缓存依赖
COPY backend/go.mod backend/go.sum ./backend/

WORKDIR /app/backend
RUN go mod download

# 复制源码
COPY backend/ ./

# 复制前端构建产物到 embed 目录
# vite.config.ts 中 outDir 为 '../backend/embed/dist'，即输出到 /app/backend/embed/dist
COPY --from=frontend-builder /app/backend/embed/dist/ ./embed/dist/

ARG VERSION=docker
ARG BUILD_TIME

# 使用 xx-go 自动设置 GOARCH/CC 等交叉编译环境变量
RUN BUILD_TIME=${BUILD_TIME:-$(date -u '+%Y-%m-%dT%H:%M:%SZ')} && \
    CGO_ENABLED=1 xx-go build \
      -ldflags="-s -w -X main.Version=${VERSION} -X main.BuildTime=${BUILD_TIME}" \
      -o /app/netpanel .

# ─────────────────────────────────────────────
# 阶段 3：最终运行镜像
# ─────────────────────────────────────────────
FROM alpine:3.19

LABEL org.opencontainers.image.title="NetPanel"
LABEL org.opencontainers.image.description="NetPanel - Network Management Panel"
LABEL org.opencontainers.image.source="https://github.com/netpanel/netpanel"

# 安装运行时依赖
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    iptables \
    ip6tables \
    iproute2 \
    && update-ca-certificates

# 创建非特权用户（可选，网络功能需要 root）
# RUN addgroup -S netpanel && adduser -S netpanel -G netpanel

WORKDIR /app

COPY --from=backend-builder /app/netpanel ./netpanel

# 数据目录
VOLUME ["/app/data"]

# 默认端口
EXPOSE 8080

ENV TZ=Asia/Shanghai

ENTRYPOINT ["/app/netpanel"]
CMD ["--port", "8080", "--data", "/app/data"]
