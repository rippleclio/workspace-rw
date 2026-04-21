@echo off
setlocal enabledelayedexpansion

for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
if defined SETUP_REMOTE_BASE (
  set "REMOTE_BASE=%SETUP_REMOTE_BASE%"
) else (
  set "REMOTE_BASE=https://github.com/rippleclio"
)

echo ============================================
echo   Workspace repository clone setup
echo ============================================
echo.

where git >nul 2>&1
if errorlevel 1 (
  echo git is required but was not found in PATH.
  exit /b 1
)

set REPOS[1]=core-platform
set REPOS[2]=documents
set REPOS[3]=rippleclio-admin-console
set REPOS[4]=rippleclio-content
set REPOS[5]=rippleclio-web
set REPOS[6]=wabifair-admin-console
set REPOS[7]=wabifair-commerce
set REPOS[8]=wabifair-storefront-web
set "REPO_COUNT=8"

if "%~1"=="" (
  set "TARGET_COUNT=%REPO_COUNT%"
  for /L %%I in (1,1,%REPO_COUNT%) do call set "TARGET[%%I]=%%REPOS[%%I]%%"
) else (
  set "TARGET_COUNT=0"
  :collect_targets
  if "%~1"=="" goto targets_ready
  call :is_known_repo "%~1"
  if errorlevel 1 exit /b 1
  set /a TARGET_COUNT+=1
  call set "TARGET[!TARGET_COUNT!]=%~1"
  shift
  goto collect_targets
)

:targets_ready
for /L %%I in (1,1,%TARGET_COUNT%) do (
  set "CURRENT_REPO=!TARGET[%%I]!"
  call :clone_repo %%I %TARGET_COUNT% "!CURRENT_REPO!"
  if errorlevel 1 exit /b 1
)

echo.
echo Setup complete. Suggested next steps:
echo   1. scripts\install-frontends.bat
echo   2. scripts\reset-and-build.bat
echo   3. scripts\start-frontends.bat
echo.
echo Tips:
echo   - Default clone source: %REMOTE_BASE%/repo.git
echo   - Override with SETUP_REMOTE_BASE, for example:
echo       set SETUP_REMOTE_BASE=git@github.com:rippleclio
echo       scripts\setup.bat
endlocal
exit /b 0

:is_known_repo
set "CANDIDATE=%~1"
for /L %%I in (1,1,%REPO_COUNT%) do (
  call set "KNOWN=%%REPOS[%%I]%%"
  if /I "%CANDIDATE%"=="!KNOWN!" exit /b 0
)
echo Unknown repository: %CANDIDATE%
echo Allowed values: core-platform documents rippleclio-admin-console rippleclio-content rippleclio-web wabifair-admin-console wabifair-commerce wabifair-storefront-web
exit /b 1

:clone_repo
setlocal enabledelayedexpansion
set "STEP=%~1"
set "TOTAL=%~2"
set "REPO=%~3"
set "TARGET_DIR=%ROOT_DIR%\%REPO%"
set "CLONE_URL=%REMOTE_BASE%/%REPO%.git"

echo [%STEP%/%TOTAL%] %REPO%

if exist "!TARGET_DIR!\.git" (
  echo   Skip: repository already exists at !TARGET_DIR!
  echo.
  endlocal & exit /b 0
)

if exist "!TARGET_DIR!" (
  echo   Skip: target path already exists but is not a git repository: !TARGET_DIR!
  echo.
  endlocal & exit /b 0
)

echo   Clone: !CLONE_URL!
git clone "!CLONE_URL!" "!TARGET_DIR!"
if errorlevel 1 (
  endlocal & exit /b 1
)

echo.
endlocal & exit /b 0
