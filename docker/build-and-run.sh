#!/bin/bash
set -e

echo "🚀 开始构建镜像..."
# 注意：Dockerfile 必须在根目录，所以我们要 cd .. 或者指定上下文
cd "$(dirname "$0")/.."
docker build -t trendradar-server:v1 .

echo "🛑 停止旧容器..."
docker rm -f trend-web 2>/dev/null || true

echo "▶️ 启动新容器..."
docker run -d \
  --name trend-web \
  -p 8080:8080 \
  -v $(pwd)/config:/app/config \
  --restart always \
  trendradar-server:v1 \
  python web_server.py

echo "✅ Web 服务启动成功！访问 http://<IP>:8080"
