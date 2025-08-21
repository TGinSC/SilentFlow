@echo off
chcp 65001 > nul
echo =====================================
echo     静默协作 Web版本 v1.0.2
echo     智能连接切换版本
echo =====================================
echo.

REM 检查Python是否可用
python --version >nul 2>&1
if %errorlevel% equ 0 (
    echo 使用Python启动Web服务器...
    echo 访问地址: http://localhost:8080
    echo 按 Ctrl+C 停止服务器
    echo.
    python -m http.server 8080
) else (
    REM 检查Node.js是否可用
    node --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo 使用Node.js启动Web服务器...
        echo 访问地址: http://localhost:8080
        echo 按 Ctrl+C 停止服务器
        echo.
        npx http-server -p 8080 -c-1
    ) else (
        echo 错误: 未找到Python或Node.js
        echo 请安装Python 3.x 或 Node.js 来运行Web服务器
        echo.
        echo Python下载: https://www.python.org/downloads/
        echo Node.js下载: https://nodejs.org/
        pause
    )
)
