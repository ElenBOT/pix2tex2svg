@echo off
setlocal enabledelayedexpansion
title pix2tex2svg - Enable HTTPS

echo.
echo  =================================================
echo   pix2tex2svg ^| Enable HTTPS Setup
echo  =================================================
echo.

set "EXE_PATH="

:: Check 1: Is it already on PATH?
where openssl >nul 2>nul
if !errorlevel! == 0 (
    set "EXE_PATH=openssl"
)

:: Check 2: Common Git install paths
if "!EXE_PATH!" == "" (
    if exist "C:\Program Files\Git\usr\bin\openssl.exe" (
        set "EXE_PATH=C:\Program Files\Git\usr\bin\openssl.exe"
    )
)
if "!EXE_PATH!" == "" (
    if exist "C:\Program Files (x86)\Git\usr\bin\openssl.exe" (
        set "EXE_PATH=C:\Program Files (x86)\Git\usr\bin\openssl.exe"
    )
)

if "!EXE_PATH!" == "" (
    echo  ERROR: openssl.exe was not found on your system.
    echo  Please install Git for Windows (https://git-scm.com) 
    echo  to get the required encryption tools.
    echo.
    pause
    exit /b 1
)

echo  Found OpenSSL at: !EXE_PATH!
echo.
echo  [1/2] Generating self-signed certificate (cert.pem and key.pem)...
echo.

"!EXE_PATH!" req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 3650 -nodes -subj "/CN=pix2tex2svg"

if exist cert.pem (
    echo.
    echo  =================================================
    echo   SUCCESS! Certificates have been generated.
    echo  =================================================
    echo.
    echo  1. Close your current server window.
    echo  2. Run start_server.bat again.
    echo  3. Access the site via: https://192.168.x.x:7070
    echo.
) else (
    echo.
    echo  ERROR: Failed to create certificates.
    echo.
)

pause

