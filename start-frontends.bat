@echo off
echo ============================================
echo   Starting all frontend dev servers
echo ============================================
echo.

echo [1/4] wabifair-storefront-web  (port 3000)
start "wabifair-storefront-web" cmd /c "cd /d %~dp0wabifair-storefront-web && npm run dev"

echo [2/4] wabifair-admin-console   (port 3001)
start "wabifair-admin-console" cmd /c "cd /d %~dp0wabifair-admin-console && npm run dev"

echo [3/4] rippleclio-web           (port 5173)
start "rippleclio-web" cmd /c "cd /d %~dp0rippleclio-web && npm run dev"

echo [4/4] rippleclio-admin-console (port 5174)
start "rippleclio-admin-console" cmd /c "cd /d %~dp0rippleclio-admin-console && npm run dev"

echo.
echo All dev servers started:
echo   wabifair-storefront-web   http://localhost:3000
echo   wabifair-admin-console    http://localhost:3001
echo   rippleclio-web            http://localhost:5173
echo   rippleclio-admin-console  http://localhost:5174
echo.
echo Use stop-frontends.bat to shut them all down.
