@echo off
setlocal EnableExtensions EnableDelayedExpansion

for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
call :init_repos

if /I "%~1"=="-h" (
  call :usage
  exit /b 0
)

if /I "%~1"=="--help" (
  call :usage
  exit /b 0
)

call :collect_targets %*
call :validate_targets
if errorlevel 1 exit /b 1

call :count_selected
set "STEP=0"

echo ============================================
echo   Push repositories
echo ============================================
echo.

for /L %%I in (1,1,%REPO_COUNT%) do (
  call set "REPO_NAME=%%REPO_NAME[%%I]%%"
  call set "REPO_PATH=%%REPO_PATH[%%I]%%"

  call :should_process "!REPO_NAME!"
  if errorlevel 1 (
    rem skip
  ) else (
    set /a STEP+=1
    set "REPO_DIR=%ROOT_DIR%\!REPO_PATH!"

    echo [!STEP!/%SELECTED_COUNT%] !REPO_NAME!

    if not exist "!REPO_DIR!" (
      echo   Skip: directory not found -^> !REPO_DIR!
      echo.
    ) else (
      git -C "!REPO_DIR!" rev-parse --is-inside-work-tree >nul 2>&1
      if errorlevel 1 (
        echo   Skip: not a git repository
        echo.
      ) else (
        set "HAS_STATUS="
        for /f "delims=" %%S in ('git -C "!REPO_DIR!" status --short 2^>nul') do set "HAS_STATUS=1"

        if defined HAS_STATUS (
          echo   Skip: working tree is not clean
          echo.
        ) else (
          set "BRANCH_NAME="
          for /f "delims=" %%B in ('git -C "!REPO_DIR!" rev-parse --abbrev-ref HEAD 2^>nul') do set "BRANCH_NAME=%%B"

          if /I "!BRANCH_NAME!"=="HEAD" (
            echo   Skip: detached HEAD
            echo.
          ) else (
            git -C "!REPO_DIR!" remote get-url origin >nul 2>&1
            if errorlevel 1 (
              echo   Skip: remote origin not configured
              echo.
            ) else (
              git -C "!REPO_DIR!" fetch origin "!BRANCH_NAME!" --quiet >nul 2>&1

              git -C "!REPO_DIR!" rev-parse --abbrev-ref --symbolic-full-name "@{u}" >nul 2>&1
              if errorlevel 1 (
                git -C "!REPO_DIR!" push -u origin "!BRANCH_NAME!"
                if errorlevel 1 exit /b 1
                echo   Pushed and set upstream: !BRANCH_NAME!
                echo.
              ) else (
                set "LOCAL_REF="
                set "UPSTREAM_REF="
                set "BASE_REF="
                for /f "delims=" %%L in ('git -C "!REPO_DIR!" rev-parse @ 2^>nul') do set "LOCAL_REF=%%L"
                for /f "delims=" %%U in ('git -C "!REPO_DIR!" rev-parse "@{u}" 2^>nul') do set "UPSTREAM_REF=%%U"
                for /f "delims=" %%M in ('git -C "!REPO_DIR!" merge-base @ "@{u}" 2^>nul') do set "BASE_REF=%%M"

                if "!LOCAL_REF!"=="!UPSTREAM_REF!" (
                  echo   Nothing to push
                  echo.
                ) else if "!UPSTREAM_REF!"=="!BASE_REF!" (
                  git -C "!REPO_DIR!" push
                  if errorlevel 1 exit /b 1
                  echo   Pushed branch: !BRANCH_NAME!
                  echo.
                ) else if "!LOCAL_REF!"=="!BASE_REF!" (
                  echo   Skip: remote branch is ahead, pull first
                  echo.
                ) else (
                  echo   Skip: local and upstream have diverged
                  echo.
                )
              )
            )
          )
        )
      )
    )
  )
)

exit /b 0

:usage
echo Usage: scripts\push_all.bat [repo ...]
call :print_available_repos
exit /b 0

:init_repos
set "REPO_COUNT=9"
set "REPO_NAME[1]=workspace-rw"
set "REPO_PATH[1]=."
set "REPO_NAME[2]=core-platform"
set "REPO_PATH[2]=core-platform"
set "REPO_NAME[3]=documents"
set "REPO_PATH[3]=documents"
set "REPO_NAME[4]=rippleclio-admin-console"
set "REPO_PATH[4]=rippleclio-admin-console"
set "REPO_NAME[5]=rippleclio-content"
set "REPO_PATH[5]=rippleclio-content"
set "REPO_NAME[6]=rippleclio-web"
set "REPO_PATH[6]=rippleclio-web"
set "REPO_NAME[7]=wabifair-admin-console"
set "REPO_PATH[7]=wabifair-admin-console"
set "REPO_NAME[8]=wabifair-commerce"
set "REPO_PATH[8]=wabifair-commerce"
set "REPO_NAME[9]=wabifair-storefront-web"
set "REPO_PATH[9]=wabifair-storefront-web"
exit /b 0

:print_available_repos
echo Available repositories:
for /L %%I in (1,1,%REPO_COUNT%) do (
  call echo   - %%REPO_NAME[%%I]%%
)
exit /b 0

:collect_targets
set "TARGET_COUNT=0"
for %%A in (%*) do (
  set /a TARGET_COUNT+=1
  call set "TARGET[!TARGET_COUNT!]=%%~A"
)
exit /b 0

:validate_targets
if "%TARGET_COUNT%"=="0" exit /b 0
for /L %%I in (1,1,%TARGET_COUNT%) do (
  call set "TARGET_NAME=%%TARGET[%%I]%%"
  call :repo_exists "!TARGET_NAME!"
  if errorlevel 1 (
    echo ERROR: Unknown repository -^> !TARGET_NAME!
    call :print_available_repos
    exit /b 1
  )
)
exit /b 0

:repo_exists
for /L %%I in (1,1,%REPO_COUNT%) do (
  call set "KNOWN_REPO=%%REPO_NAME[%%I]%%"
  if /I "%~1"=="!KNOWN_REPO!" exit /b 0
)
exit /b 1

:should_process
if "%TARGET_COUNT%"=="0" exit /b 0
for /L %%I in (1,1,%TARGET_COUNT%) do (
  call set "TARGET_NAME=%%TARGET[%%I]%%"
  if /I "%~1"=="!TARGET_NAME!" exit /b 0
)
exit /b 1

:count_selected
set "SELECTED_COUNT=0"
for /L %%I in (1,1,%REPO_COUNT%) do (
  call set "REPO_NAME=%%REPO_NAME[%%I]%%"
  call :should_process "!REPO_NAME!"
  if not errorlevel 1 set /a SELECTED_COUNT+=1
)
exit /b 0
