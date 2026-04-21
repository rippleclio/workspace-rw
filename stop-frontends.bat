@echo off
echo ============================================
echo   Stopping all frontend dev servers
echo ============================================
echo.

set FOUND=0

echo Killing processes on port 3000 (wabifair-storefront-web)...
for /f "tokens=5" %%p in ('netstat -aon ^| findstr ":3000.*LISTENING"') do (
  taskkill /F /PID %%p >nul 2>&1 && set FOUND=1
)

echo Killing processes on port 3001 (wabifair-admin-console)...
for /f "tokens=5" %%p in ('netstat -aon ^| findstr ":3001.*LISTENING"') do (
  taskkill /F /PID %%p >nul 2>&1 && set FOUND=1
)

echo Killing processes on port 5173 (rippleclio-web)...
for /f "tokens=5" %%p in ('netstat -aon ^| findstr ":5173.*LISTENING"') do (
  taskkill /F /PID %%p >nul 2>&1 && set FOUND=1
)

echo Killing processes on port 5174 (rippleclio-admin-console)...
for /f "tokens=5" %%p in ('netstat -aon ^| findstr ":5174.*LISTENING"') do (
  taskkill /F /PID %%p >nul 2>&1 && set FOUND=1
)

REM Also close any remaining cmd windows started by start-frontends.bat
for %%t in ("wabifair-storefront-web" "wabifair-admin-console" "rippleclio-web" "rippleclio-admin-console") do (
  taskkill /FI "WINDOWTITLE eq %%~t" /F >nul 2>&1
)

echo.
echo All frontend dev servers stopped.
