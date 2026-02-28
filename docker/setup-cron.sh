#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "⏰ 正在配置定时任务..."

# 先清除旧的 trendradar 任务
crontab -l 2>/dev/null | grep -v "trendradar-server" | crontab - || true

# 添加新任务 (使用绝对路径)
(crontab -l 2>/dev/null; echo "0 8 * * * docker run --rm -v $PROJECT_DIR/config:/app/config trendradar-server:v1 python main.py >> $PROJECT_DIR/run_log.txt 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "0 15 * * * docker run --rm -v $PROJECT_DIR/config:/app/config trendradar-server:v1 python main.py >> $PROJECT_DIR/run_log.txt 2>&1") | crontab -

echo "✅ 定时任务设置成功 (每天 8:00 和 15:00)"
crontab -l
