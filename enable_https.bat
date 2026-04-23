@echo off
setlocal
title pix2tex2svg - Enable HTTPS

echo =================================================
echo  pix2tex2svg ^| Enable HTTPS (Self-Signed)
echo =================================================
echo.
echo This script will generate a self-signed certificate.
echo This allows the Clipboard API (Paste button) to work on LAN devices.
echo.
echo NOTE: Browsers will show a "Your connection is not private" warning.
echo You must click "Advanced" -> "Proceed anyway" on your devices.
echo.

:: Find openssl (usually in Git/usr/bin)
set OPENSSL_EXE=
where openssl >nul 2>nul
if %errorlevel% == 0 (
    set OPENSSL_EXE=openssl
) else (
    if exist "C:\Program Files\Git\usr\bin\openssl.exe" set OPENSSL_EXE="C:\Program Files\Git\usr\bin\openssl.exe"
    if exist "C:\Program Files (x86)\Git\usr\bin\openssl.exe" set OPENSSL_EXE="C:\Program Files (x86)\Git\usr\bin\openssl.exe"
)

if "%OPENSSL_EXE%" == "" (
    echo ERROR: openssl not found. 
    echo Please install Git for Windows to get openssl.
    pause
    exit /b 1
)

echo [1/2] Generating certificate and key...
%OPENSSL_EXE% req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 3650 -nodes -subj "/CN=pix2tex2svg"

if %errorlevel% == 0 (
    echo.
    echo Success! cert.pem and key.pem have been generated.
    echo.
    echo Now run start_server.bat. It will automatically detect 
    echo these files and start in HTTPS mode.
    echo.
) else (
    echo.
    echo ERROR: Failed to generate certificates.
    echo.
)

pause
