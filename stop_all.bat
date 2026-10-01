@echo off
setlocal
chcp 65001 >nul 2>&1
title Stop RxAgent Services

echo.
echo ======================================================================
echo   Stopping All Agentic Prescription Generator Services
echo ======================================================================
echo.
echo [*] Terminating processes on ports 3000, 8080, and 8501...

powershell -NoProfile -Command "3000, 8080, 8501 | ForEach-Object { (Get-NetTCPConnection -LocalPort $_ -ErrorAction SilentlyContinue).OwningProcess } | Where-Object { $_ -gt 0 } | Select-Object -Unique | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue; Write-Host ('   [OK] Stopped PID ' + $_) }"

echo.
echo [*] All RxAgent services have been stopped.
echo ======================================================================
echo.
ping 127.0.0.1 -n 3 >nul 2>&1
