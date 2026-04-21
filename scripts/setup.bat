@echo off
setlocal

for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"

echo ============================================
echo   Workspace first-time setup
echo ============================================
echo.

where git >nul 2>&1
if errorlevel 1 (
  echo git is required but was not found in PATH.
  exit /b 1
)

where npm >nul 2>&1
if errorlevel 1 (
  echo npm is required but was not found in PATH.
  exit /b 1
)

echo [1/2] Install frontend dependencies
call "%~dp0install-frontends.bat"
if errorlevel 1 exit /b 1

echo [2/2] Verify repository layout
for %%R in (
  core-platform
  documents
  rippleclio-admin-console
  rippleclio-content
  rippleclio-web
  wabifair-admin-console
  wabifair-commerce
  wabifair-storefront-web
) do (
  if not exist "%ROOT_DIR%\%%R\.git" (
    echo   Warning: %%R does not look like a git repository in %ROOT_DIR%\%%R
  )
)

echo.
echo Setup complete. Suggested next steps:
echo   1. scripts\reset-and-build.bat
echo   2. scripts\start-frontends.bat
endlocal
