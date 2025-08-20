@echo off
echo ==========================================
echo   SilentFlow Web版本 v1.0.1 本地运行工具
echo   包含登录修复功能
echo ==========================================
echo.
echo 🔑 默认测试账户:
echo    用户名: admin
echo    密码: 123456
echo.
echo 📌 或使用任意用户名/密码组合登录
echo.

REM 检查Python是否可用
python --version >nul 2>&1
if %errorlevel% == 0 (
    echo ✅ 检测到Python，启动Web服务器...
    echo 📍 访问地址: http://localhost:8000
    echo 💡 按 Ctrl+C 停止服务器
    echo.
    python -m http.server 8000
    goto :end
)

REM 检查Node.js是否可用
node --version >nul 2>&1
if %errorlevel% == 0 (
    echo ✅ 检测到Node.js，启动Web服务器...
    echo 📍 访问地址: http://localhost:8000
    echo 💡 按 Ctrl+C 停止服务器
    echo.
    npx serve . -p 8000
    goto :end
)

REM 检查PHP是否可用
php --version >nul 2>&1
if %errorlevel% == 0 (
    echo ✅ 检测到PHP，启动Web服务器...
    echo 📍 访问地址: http://localhost:8000
    echo 💡 按 Ctrl+C 停止服务器
    echo.
    php -S localhost:8000
    goto :end
)

REM 如果都没有找到
echo ❌ 未找到Python、Node.js或PHP
echo.
echo 请安装以下任意一个：
echo 1. Python: https://www.python.org/downloads/
echo 2. Node.js: https://nodejs.org/
echo 3. PHP: https://www.php.net/downloads
echo.
echo 或者将文件上传到Web服务器使用。
echo.

:end
pause
