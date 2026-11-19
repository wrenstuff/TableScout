@echo off
title TableScout Launcher

echo ================================
echo       TABLESCOUT LAUNCHER
echo ================================

REM Main project directory
set "ROOT=%~dp0"

REM Backend directory
set "BACKEND=%ROOT%backend\"

REM Python virtual environment
set "PYTHON=%BACKEND%venv\Scripts\python.exe"

REM Flutter executable
set "EXE=%ROOT%tablescout\build\windows\x64\runner\Release\tablescout.exe"

cd /d "%ROOT%"

echo.
echo Checking Python is installed

python --version
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH.
    pause
    exit /b 1
)

echo.
echo Creating a virtual environment

if not exist "%PYTHON%" (
    python -m venv "%BACKEND%venv"
)

echo.
echo Installing all depenecies

"%PYTHON%" -m pip install -r "%ROOT%requirements.txt"

if errorlevel 1 (
    echo ERROR: Failed installing required libraries.
    pause
    exit /b 1
)

echo.
echo starting a websocket

start "TableScout WebSockets" cmd /k "cd /d "%BACKEND%" && "%PYTHON%" "%BACKEND%server.py""

timeout /t 2 /nobreak >nul

echo.
echo Starting auth services

start "TableScout Login API" cmd /k "cd /d "%ROOT%" && "%PYTHON%" "%BACKEND%database\Login.py""

timeout /t 2 /nobreak >nul

echo.
echo Checking if tablescout launcher exists

if not exist "%EXE%" (
    echo ERROR: Could not find launcher
    pause
    exit /b 1
)

echo.
echo Launching TableScout...

start "" "%EXE%"

exit
