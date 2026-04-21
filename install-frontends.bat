@echo off
setlocal enabledelayedexpansion

echo ============================================
echo   Installing frontend npm dependencies
echo ============================================
echo.

call :install_repo 1 4 wabifair-storefront-web
if errorlevel 1 exit /b 1

call :install_repo 2 4 wabifair-admin-console
if errorlevel 1 exit /b 1

call :install_repo 3 4 rippleclio-admin-console
if errorlevel 1 exit /b 1

call :install_repo 4 4 rippleclio-web
if errorlevel 1 exit /b 1

echo.
echo All frontend npm dependencies installed successfully.
exit /b 0

:install_repo
set "STEP=%~1"
set "TOTAL=%~2"
set "REPO=%~3"

echo [%STEP%/%TOTAL%] %REPO%
pushd "%~dp0%REPO%"
if errorlevel 1 (
  echo ERROR: Failed to enter %REPO%
  exit /b 1
)

call npm install
if errorlevel 1 (
  popd
  echo ERROR: npm install failed in %REPO%
  exit /b 1
)

popd
echo.
exit /b 0