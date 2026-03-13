@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "REPO_DIR=%SCRIPT_DIR%"
set "LOG_DIR=%REPO_DIR%.longmen"
set "LOG_FILE=%LOG_DIR%\auto_push.log"
set "CONFIG_FILE=%REPO_DIR%config.json"

:: 获取当天日期（格式 YYMMDD）
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "TODAY=%dt:~2,2%%dt:~4,2%%dt:~6,2%"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo [%date% %time%] === 开始每日上传 (%TODAY%) === >> "%LOG_FILE%"

:: 读取助教名称
set "TA_NAME=助教"
if exist "%CONFIG_FILE%" (
    for /f "usebackq delims=" %%i in (
        `python -c "import json; print(json.load(open(r'%CONFIG_FILE%'))['ta_name'])" 2^>nul`
    ) do set "TA_NAME=%%i"
)

cd /d "%REPO_DIR%"

:: 检查是否为 Git 仓库
git rev-parse --git-dir >nul 2>&1
if %errorlevel% neq 0 (
    echo [%date% %time%] 错误：当前目录不是 Git 仓库 >> "%LOG_FILE%"
    goto :end
)

:: 只暂存4个每日工作文件夹（不提交其他文件）
git add "每日输出/" "每日解答/" "每日补充/" "每日反馈/" >> "%LOG_FILE%" 2>&1

:: 检查是否有新内容
git diff --staged --quiet
if %errorlevel% equ 0 (
    echo [%date% %time%] 今天没有新内容，跳过上传 >> "%LOG_FILE%"
    goto :end
)

:: 提交
git commit -m "每日上传 %TODAY% - %TA_NAME%" >> "%LOG_FILE%" 2>&1

:: 推送
git push origin main >> "%LOG_FILE%" 2>&1
if %errorlevel% equ 0 (
    echo [%date% %time%] 上传成功 >> "%LOG_FILE%"
) else (
    echo [%date% %time%] 上传失败，请检查网络连接或联系管理员 >> "%LOG_FILE%"
)

:end
endlocal
