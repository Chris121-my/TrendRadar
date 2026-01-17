@echo off
REM 简化版启动脚本 - 直接使用系统Python
cd /d "%~dp0"

echo Starting TrendRadar Web Server...
echo.

REM 检查Python
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found!
    echo Please install Python first.
    pause
    exit /b 1
)

REM 检查web_server.py
if not exist "web_server.py" (
    echo ERROR: web_server.py not found!
    pause
    exit /b 1
)

echo Web Server will start at: http://localhost:8080
echo Press Ctrl+C to stop
echo.

python web_server.py --port 8080

pause

