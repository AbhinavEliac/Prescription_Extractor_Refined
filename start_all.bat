@echo off
setlocal enabledelayedexpansion
title Agentic Prescription Extractor - Launcher
chcp 65001 >nul 2>&1

set "ROOT_DIR=%~dp0"
cd /d "%ROOT_DIR%"

set "MODE=all"
if /i "%~1"=="web" set "MODE=web"
if /i "%~1"=="--web" set "MODE=web"
if /i "%~1"=="streamlit" set "MODE=streamlit"
if /i "%~1"=="--streamlit" set "MODE=streamlit"
if /i "%~1"=="stop" goto do_stop
if /i "%~1"=="--stop" goto do_stop
if /i "%~1"=="help" goto show_help
if /i "%~1"=="--help" goto show_help
if /i "%~1"=="/?" goto show_help

echo.
echo ======================================================================
echo   Agentic Prescription Extractor ^& Studio - Startup
echo ======================================================================
echo.

:: 1. Locate Python environment
set "PYTHON_EXE="
if exist "%ROOT_DIR%env\Scripts\python.exe" (
    set "PYTHON_EXE=%ROOT_DIR%env\Scripts\python.exe"
) else if exist "%ROOT_DIR%venv\Scripts\python.exe" (
    set "PYTHON_EXE=%ROOT_DIR%venv\Scripts\python.exe"
) else if exist "%ROOT_DIR%.venv\Scripts\python.exe" (
    set "PYTHON_EXE=%ROOT_DIR%.venv\Scripts\python.exe"
) else (
    where python >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        set "PYTHON_EXE=python"
    )
)

if "%PYTHON_EXE%"=="" (
    echo [ERROR] Python environment was not found.
    echo Please create a virtual environment first:
    echo   python -m venv env
    echo   .\env\Scripts\pip install -r requirements.txt
    echo.
    pause
    exit /b 1
)

:: Enable UTF-8 for Python 3.13 / Streamlit / Click / LangGraph on Windows
set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"

:: 2. Locate Node.js
set "NODE_EXE="
where node >nul 2>&1
if !ERRORLEVEL! equ 0 (
    set "NODE_EXE=node"
) else if exist "C:\Program Files\nodejs\node.exe" (
    set "NODE_EXE=C:\Program Files\nodejs\node.exe"
    set "PATH=C:\Program Files\nodejs;%PATH%"
)

:: Check Node modules if Node is available
if not "%NODE_EXE%"=="" (
    if not exist "%ROOT_DIR%rx_node_app\node_modules" (
        echo [*] Installing Node.js dependencies for rx_node_app...
        pushd "%ROOT_DIR%rx_node_app"
        call npm install --no-audit --no-fund
        popd
    )
) else (
    if not "%MODE%"=="streamlit" (
        echo [WARNING] Node.js was not found in PATH or 'C:\Program Files\nodejs\node.exe'.
        echo The Node.js Web App [Port 3000] will be skipped.
        echo You can install Node.js from https://nodejs.org/
        echo.
    )
)

:: 3. Clear lingering processes on required ports
echo [*] Checking and freeing ports 3000, 8080, and 8501...
powershell -NoProfile -Command "3000, 8080, 8501 | ForEach-Object { (Get-NetTCPConnection -LocalPort $_ -ErrorAction SilentlyContinue).OwningProcess } | Where-Object { $_ -gt 0 } | Select-Object -Unique | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }" >nul 2>&1

:: 4. Launch Services depending on MODE
if not "%MODE%"=="streamlit" (
    echo [*] Starting FastAPI REST Gateway on Port 8080...
    start "FastAPI Gateway [Port 8080]" cmd /k "chcp 65001 >nul 2>&1 && cd /d "%ROOT_DIR%" && title [1/2] FastAPI REST Gateway [Port 8080] && "%PYTHON_EXE%" -m uvicorn api_server:app --app-dir rx_extractor_app --host 127.0.0.1 --port 8080"

    if not "%NODE_EXE%"=="" (
        echo [*] Starting Node.js RxAgent Studio on Port 3000...
        start "Node.js Web App [Port 3000]" cmd /k "chcp 65001 >nul 2>&1 && cd /d "%ROOT_DIR%rx_node_app" && title [2/2] Node.js RxAgent Studio [Port 3000] && "%NODE_EXE%" server.js"
    )
)

if not "%MODE%"=="web" (
    echo [*] Starting Streamlit Clinical Portal on Port 8501...
    start "Streamlit Portal [Port 8501]" cmd /k "chcp 65001 >nul 2>&1 && cd /d "%ROOT_DIR%" && title Streamlit Clinical Portal [Port 8501] && "%PYTHON_EXE%" -m streamlit run rx_extractor_app/app.py --server.port 8501"
)

:: Wait for services to initialize
echo [*] Waiting for services to initialize...
ping 127.0.0.1 -n 4 >nul 2>&1

:: Open Browser
if not "%NODE_EXE%"=="" (
    if not "%MODE%"=="streamlit" (
        echo [*] Opening http://localhost:3000 in your browser...
        start http://localhost:3000
    )
)
if "%MODE%"=="streamlit" (
    echo [*] Opening http://localhost:8501 in your browser...
    start http://localhost:8501
)

echo.
echo ======================================================================
echo   Prescription Extractor Services are Running!
echo ======================================================================
if not "%NODE_EXE%"=="" (
    if not "%MODE%"=="streamlit" (
        echo   - Node.js Studio Web UI:   http://localhost:3000
    )
)
if not "%MODE%"=="streamlit" (
    echo   - FastAPI REST Gateway:    http://127.0.0.1:8080
    echo   - REST API Documentation:  http://127.0.0.1:8080/docs
)
if not "%MODE%"=="web" (
    echo   - Streamlit Dashboard:     http://localhost:8501
)
echo ======================================================================
echo   To stop all services at any time, run: stop_all.bat
echo ======================================================================
echo.
goto end

:do_stop
call "%ROOT_DIR%stop_all.bat"
goto end

:show_help
echo Usage: start_all.bat [option]
echo.
echo Options:
echo   (no option)   Start full system (FastAPI Gateway + Node.js Studio + Streamlit)
echo   web           Start Modern Web Studio only (FastAPI Gateway + Node.js Studio)
echo   streamlit     Start Streamlit Clinical Dashboard only
echo   stop          Stop and terminate all running services
echo   help          Display this help message
echo.

:end
