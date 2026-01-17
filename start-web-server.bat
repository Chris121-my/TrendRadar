@echo off
chcp 65001 >nul 2>&1
cd /d "%~dp0"

echo ╔════════════════════════════════════════╗
echo ║  TrendRadar Web Server                 ║
echo ╚════════════════════════════════════════╝
echo.

REM 设置Python命令变量
set PYTHON_CMD=

REM 检查虚拟环境，如果存在则使用虚拟环境的Python
if exist ".venv\Scripts\python.exe" (
    set PYTHON_CMD=.venv\Scripts\python.exe
    echo [信息] 使用虚拟环境中的Python
) else (
    echo [信息] 未找到虚拟环境，检查系统Python...
    REM 检查系统Python是否可用
    python --version >nul 2>&1
    if errorlevel 1 (
        echo [错误] 未找到Python
        echo 请先安装Python或运行 setup-windows.bat 进行部署
        echo.
        pause
        exit /b 1
    )
    set PYTHON_CMD=python
    echo [信息] 使用系统Python
)

REM 检查web_server.py文件是否存在
if not exist "web_server.py" (
    echo [错误] 未找到 web_server.py 文件
    echo 请确保在项目根目录运行此脚本
    echo.
    pause
    exit /b 1
)

echo.
echo [服务] Web服务器（提供HTML访问和刷新功能）
echo.
echo ⚠️  重要提示：
echo    1. 必须通过Web服务器访问，不要直接打开HTML文件
echo    2. 如果其他设备无法访问，请运行 open-firewall-windows.bat 配置防火墙
echo.
echo [地址] http://localhost:8080
echo [提示] 按 Ctrl+C 停止服务
echo.

REM 运行Web服务器
%PYTHON_CMD% web_server.py --port 8080

if errorlevel 1 (
    echo.
    echo [错误] 服务器启动失败
    echo.
    echo 可能的原因：
    echo   1. Python依赖包未安装
    echo     解决方案：运行 pip install -r requirements.txt
    echo.
    echo   2. 端口8080已被占用
    echo     解决方案：使用其他端口或关闭占用8080端口的程序
    echo.
    echo   3. web_server.py 文件有错误
    echo     解决方案：检查Python版本是否兼容（建议Python 3.8+）
    echo.
)

pause

