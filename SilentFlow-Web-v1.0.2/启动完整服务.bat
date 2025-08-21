@echo off
REM 确保使用ANSI编码保存此文件以避免符号问题
chcp 65001 > nul
title SilentFlow 完整服务启动器 v1.0.2+5
cls

echo.
echo     ╔═══════════════════════════════════════════╗
echo     ║        静默协作 SilentFlow v1.0.2+5       ║
echo     ║         完整服务启动器 (稳定版)            ║
echo     ╚═══════════════════════════════════════════╝
echo.

REM 初始化变量
set "LOCAL_IP=127.0.0.1"
set "BACKEND_DIR=backend"
set "BACKEND_MAIN=%BACKEND_DIR%\main.go"
set "FRONTEND_PORT=8080"
set "BACKEND_PORT=8081"

REM 获取本机IP地址（增强版，兼容多网卡环境）
echo 🔍 正在检测本机IP地址...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4" ^| findstr /v "127.0.0.1"') do (
    for /f "tokens=1 delims= " %%b in ("%%a") do (
        set "LOCAL_IP=%%b"
        goto :ip_found
    )
)
:ip_found
if "%LOCAL_IP%"=="" set "LOCAL_IP=127.0.0.1"
echo 🌐 本机IP地址: %LOCAL_IP%
echo.

REM 检查Go环境（增强版检测）
echo 🔍 正在检查Go语言环境...
set "GO_FOUND=0"
where go >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=3" %%v in ('go version') do (
        echo ✅ Go语言已安装，版本: %%v
        set "GO_FOUND=1"
    )
)

if %GO_FOUND% equ 0 (
    echo ❌ 未检测到Go语言环境
    echo 📌 请确保已安装Go并添加到系统PATH
    echo 📥 下载地址: https://golang.org/dl/
    echo.
    pause
    exit /b 1
)

REM 检查后端文件
echo 🔍 正在检查后端文件...
if exist "%BACKEND_MAIN%" (
    echo ✅ 后端主程序已找到: %BACKEND_MAIN%
) else (
    echo ❌ 未找到后端主程序: %BACKEND_MAIN%
    echo 📌 请确认backend目录下存在main.go文件
    echo.
    pause
    exit /b 1
)

REM 检查前端启动环境
echo 🔍 正在检查前端启动环境...
set "LAUNCHER_TYPE="
python --version >nul 2>&1
if %errorlevel% equ 0 (
    set "LAUNCHER_TYPE=python"
    echo ✅ 检测到Python环境，将用于启动前端
) else (
    node --version >nul 2>&1
    if %errorlevel% equ 0 (
        set "LAUNCHER_TYPE=node"
        echo ✅ 检测到Node.js环境，将用于启动前端
    ) else (
        echo ❌ 未检测到Python或Node.js环境
        echo 📌 请安装其中之一以启动前端服务器
        echo 📥 Python: https://www.python.org/downloads/
        echo 📥 Node.js: https://nodejs.org/
        echo.
        pause
        exit /b 1
    )
)

echo.
echo ✅ 所有环境检查通过
echo.

REM 启动后端服务器（带错误捕获）
echo 🚀 正在启动后端API服务器...
if not exist "%BACKEND_DIR%" (
    echo ❌ 后端目录不存在: %BACKEND_DIR%
    pause
    exit /b 1
)

pushd "%BACKEND_DIR%"
set "BACKEND_START_CMD=title SilentFlow后端API服务器 && echo 后端API服务器启动中... && echo 监听地址: 0.0.0.0:%BACKEND_PORT% && echo 按Ctrl+C停止服务器 && go run main.go && echo 后端服务器已停止 && pause"
start "SilentFlow-Backend" cmd /k "%BACKEND_START_CMD%"
if %errorlevel% neq 0 (
    echo ❌ 后端服务器启动失败
    pause
    exit /b 1
)
popd

REM 等待后端初始化
echo ⏳ 等待后端服务器初始化（5秒）...
timeout /t 5 /nobreak > nul

REM 显示启动信息
echo.
echo ┌─────────────────────────────────────────────────┐
echo │  🎉 SilentFlow v1.0.2+5 服务启动信息            │
echo │                                                 │
echo │  🌐 前端访问地址:                               │
echo │     http://localhost:%FRONTEND_PORT%            │
echo │     http://%LOCAL_IP%:%FRONTEND_PORT% (局域网)  │
echo │                                                 │
echo │  🔌 后端API地址:                                │
echo │     http://localhost:%BACKEND_PORT%             │
echo │     http://%LOCAL_IP%:%BACKEND_PORT% (局域网)   │
echo │                                                 │
echo │  🔑 测试账号:                                   │
echo │     用户名: admin                               │
echo │     密码: 123456                                │
echo │                                                 │
echo │  💡 提示:                                       │
echo │     - 关闭此窗口将停止前端服务器                │
echo │     - 后端服务器在独立窗口运行                  │
echo │     - 若服务异常，请查看对应窗口的错误信息      │
echo └─────────────────────────────────────────────────┘
echo.

REM 自动打开浏览器
echo 🌐 正在打开浏览器...
start http://localhost:%FRONTEND_PORT%

REM 启动前端服务器
echo 🚀 正在启动前端服务器...
if "%LAUNCHER_TYPE%"=="python" (
    python -m http.server %FRONTEND_PORT%
) else (
    npx http-server -p %FRONTEND_PORT% -c-1
)

REM 捕获前端服务器错误
if %errorlevel% neq 0 (
    echo ❌ 前端服务器启动失败，错误代码: %errorlevel%
    echo 📌 请检查端口%FRONTEND_PORT%是否被占用或重新安装依赖
    pause
    exit /b 1
)

REM 防止窗口意外关闭
echo.
echo 服务已停止
pause
