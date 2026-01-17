@echo off
chcp 65001 >nul 2>&1
:: 直接指定环境的Python解释器路径（替换成你的实际路径）
set PYTHON_PATH=D:\Programming\miniconda3\envs\python312\python.exe
:: 切换到脚本目录
cd /d E:\github\TrendRadar
:: 用指定的Python运行脚本，并输出详细日志
"%PYTHON_PATH%" main.py >> E:\github\TrendRadar\run_log.txt 2>&1
:: 记录执行状态
echo 执行时间：%date% %time% >> E:\github\TrendRadar\run_log.txt
echo Python路径：%PYTHON_PATH% >> E:\github\TrendRadar\run_log.txt
echo 错误码：%errorlevel% >> E:\github\TrendRadar\run_log.txt
pause