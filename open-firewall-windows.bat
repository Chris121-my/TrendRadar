@echo off
chcp 65001 >nul

echo ╔════════════════════════════════════════╗
echo ║  Windows防火墙配置助手                  ║
echo ╚════════════════════════════════════════╝
echo.
echo 此脚本将为TrendRadar Web服务器配置Windows防火墙规则
echo 允许端口8080的入站连接，使其他设备可以访问
echo.

REM 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [错误] 需要管理员权限！
    echo 请右键点击此文件，选择"以管理员身份运行"
    echo.
    pause
    exit /b 1
)

echo [提示] 正在添加防火墙规则...
echo.

REM 删除可能存在的旧规则
netsh advfirewall firewall delete rule name="TrendRadar Web Server" >nul 2>&1

REM 添加新的防火墙规则（允许TCP端口8080）
netsh advfirewall firewall add rule name="TrendRadar Web Server" dir=in action=allow protocol=TCP localport=8080

if %errorLevel% equ 0 (
    echo [成功] 防火墙规则已添加！
    echo.
    echo 现在其他设备可以通过以下方式访问：
    echo   1. 确保设备在同一WiFi/局域网
    echo   2. 运行 start-web-server.bat 启动服务器
    echo   3. 在其他设备浏览器中输入：http://服务器IP:8080
    echo.
    echo 提示：服务器启动时会显示IP地址
    echo.
) else (
    echo [失败] 无法添加防火墙规则
    echo 请手动配置：
    echo   1. 打开"Windows Defender 防火墙"
    echo   2. 点击"高级设置"
    echo   3. 选择"入站规则" -^> "新建规则"
    echo   4. 选择"端口" -^> TCP -^> 端口8080
    echo   5. 选择"允许连接"
    echo.
)

pause

