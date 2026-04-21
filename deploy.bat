@echo off
chcp 65001 >nul
echo ========================================
echo   🐍 龍之森林 - 一鍵部署腳本
echo ========================================
echo.

cd /d "%~dp0"
echo [1/3] 正在編譯 Flutter Web...
call flutter build web
if errorlevel 1 (
    echo.
    echo ❌ 編譯失敗！
    pause
    exit /b 1
)

echo.
echo [2/3] 正在上傳到 Surge...
cd build\web
call surge . andy-snake-game.surge.sh
if errorlevel 1 (
    echo.
    echo ❌ 上傳失敗！
    pause
    exit /b 1
)

echo.
echo ========================================
echo   ✅ 部署成功！
echo   🌐 https://andy-snake-game.surge.sh
echo ========================================
pause
