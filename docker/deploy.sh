#!/bin/bash
set -e

echo "🌟 开始一键部署 TrendRadar..."

# 获取当前脚本所在目录的父目录 (即项目根目录)
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

# 1. 构建并启动
./docker/build-and-run.sh

# 2. 设置定时任务
./docker/setup-cron.sh

echo ""
echo "🎉 部署全部完成!"
echo "   - Web 服务已启动: http://<你的IP>:8080"
echo "   - 定时任务已设定: 每天 8:00, 15:00"
echo "   - 日志文件位置: $PROJECT_DIR/run_log.txt"
