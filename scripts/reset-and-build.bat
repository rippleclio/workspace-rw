@echo off
setlocal enabledelayedexpansion

for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"

echo [0/9] Check Docker daemon...
docker version >nul 2>&1
if errorlevel 1 (
  echo Docker CLI not found. Please install Docker Desktop first.
  exit /b 1
)

docker info >nul 2>&1
if errorlevel 1 (
  echo Docker daemon not ready. Trying to start Docker Desktop...

  sc query com.docker.service >nul 2>&1
  if not errorlevel 1 (
    net start com.docker.service >nul 2>&1
  )

  set "DOCKER_DESKTOP_EXE=%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
  if exist "%DOCKER_DESKTOP_EXE%" (
    start "" "%DOCKER_DESKTOP_EXE%"
  )

  set /a DOCKER_WAIT_RETRIES=0
  :wait_docker
  docker info >nul 2>&1
  if not errorlevel 1 goto docker_ready

  set /a DOCKER_WAIT_RETRIES+=1
  if !DOCKER_WAIT_RETRIES! GEQ 24 (
    echo Docker daemon is still unavailable after waiting 120 seconds.
    echo Please open Docker Desktop and wait until engine status is Running, then rerun this script.
    exit /b 1
  )
  timeout /t 5 /nobreak >nul
  goto wait_docker
)

:docker_ready

echo [1/9] Stop and remove all containers...
for /f %%i in ('docker ps -aq') do (
  docker rm -f %%i
)

echo [2/9] Remove all volumes...
for /f %%v in ('docker volume ls -q') do (
  docker volume rm %%v
)

echo [3/9] Build core-platform services...
pushd "%ROOT_DIR%\core-platform"
call build-services.bat
if errorlevel 1 (
  popd
  echo core-platform build failed.
  exit /b 1
)
popd

echo [4/9] Build wabifair-commerce services...
pushd "%ROOT_DIR%\wabifair-commerce"
call build-services.bat
if errorlevel 1 (
  popd
  echo wabifair-commerce build failed.
  exit /b 1
)
popd

echo [5/9] Build rippleclio-content services...
pushd "%ROOT_DIR%\rippleclio-content"
call build-services.bat
if errorlevel 1 (
  popd
  echo rippleclio-content build failed.
  exit /b 1
)
popd

echo [6/9] Run core-platform migrations...
pushd "%ROOT_DIR%\core-platform"
call run-migrations.bat
if errorlevel 1 (
  popd
  echo core-platform migrations failed.
  exit /b 1
)
popd

echo [7/9] Run wabifair-commerce migrations...
pushd "%ROOT_DIR%\wabifair-commerce"
call run-migrations.bat
if errorlevel 1 (
  popd
  echo wabifair-commerce migrations failed.
  exit /b 1
)
popd

echo [8/9] Run rippleclio-content migrations...
pushd "%ROOT_DIR%\rippleclio-content"
call run-migrations.bat
if errorlevel 1 (
  popd
  echo rippleclio-content migrations failed.
  exit /b 1
)
popd

echo [9/9] Restart application services...
for /f "tokens=*" %%c in ('docker ps --filter "name=core-platform-auth" --filter "name=core-platform-revenue" --format "{{.Names}}"') do (
  docker restart %%c >nul 2>&1
)
for /f "tokens=*" %%c in ('docker ps --filter "name=wabifair-commerce" --format "{{.Names}}"') do (
  docker restart %%c >nul 2>&1
)
for /f "tokens=*" %%c in ('docker ps --filter "name=rippleclio" --format "{{.Names}}"') do (
  docker restart %%c >nul 2>&1
)
timeout /t 3 /nobreak >nul

echo Done.
endlocal
