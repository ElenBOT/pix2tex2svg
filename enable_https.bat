@echo off
setlocal enabledelayedexpansion
title pix2tex2svg - Enable HTTPS

echo.
echo  =================================================
echo   pix2tex2svg ^| Enable HTTPS Setup
echo  =================================================
echo.

:: -- Find Conda ----------------------------------------------------------------
set CONDA_ROOT=

for %%P in (
    "%USERPROFILE%\miniconda3"
    "%USERPROFILE%\Miniconda3"
    "%USERPROFILE%\anaconda3"
    "%USERPROFILE%\Anaconda3"
    "%LOCALAPPDATA%\miniconda3"
    "%LOCALAPPDATA%\Miniconda3"
    "%LOCALAPPDATA%\anaconda3"
    "%LOCALAPPDATA%\Anaconda3"
    "C:\miniconda3"
    "C:\Miniconda3"
    "C:\anaconda3"
    "C:\Anaconda3"
    "C:\ProgramData\miniconda3"
    "C:\ProgramData\Miniconda3"
    "C:\ProgramData\anaconda3"
    "C:\ProgramData\Anaconda3"
) do (
    if exist "%%~P\Scripts\conda.exe" (
        set "CONDA_ROOT=%%~P"
        goto :found_conda
    )
)

echo.
echo  ERROR: Conda not found. Please run auto_setup.bat first.
echo.
pause & exit /b 1

:found_conda
call "%CONDA_ROOT%\Scripts\activate.bat" "%CONDA_ROOT%"
call conda activate pix2tex2svg

if errorlevel 1 (
    echo.
    echo  ERROR: Could not activate "pix2tex2svg" environment.
    echo  Run auto_setup.bat first to install dependencies.
    echo.
    pause & exit /b 1
)

:: -- Run Python script to generate certs ---------------------------------------
python generate_certs.py

if exist cert.pem (
    echo.
    echo  =================================================
    echo   SUCCESS! HTTPS is now enabled.
    echo  =================================================
    echo.
    echo  1. Close your current server window (if open).
    echo  2. Run start_server.bat again.
    echo  3. Access via: https://192.168.x.x:7070
    echo.
) else (
    echo.
    echo  ERROR: Failed to create certificates.
    echo.
)

pause


