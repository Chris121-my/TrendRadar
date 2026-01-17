#!/bin/bash

echo "╔════════════════════════════════════════╗"
echo "║  TrendRadar Web Server                 ║"
echo "╚════════════════════════════════════════╝"
echo ""

# 检查虚拟环境
if [ ! -d ".venv" ]; then
    echo "❌ [错误] 虚拟环境未找到"
    echo "请先运行 ./setup-mac.sh 进行部署"
    echo ""
    exit 1
fi

echo "[服务] Web服务器（提供HTML访问和刷新功能）"
echo "[地址] http://localhost:8080"
echo "[提示] 按 Ctrl+C 停止服务"
echo ""

python web_server.py --port 8080

