@echo off
title GitHub Accelerator
setlocal enabledelayedexpansion

set "HOSTS=C:\Windows\System32\drivers\etc\hosts"
set "CACHE_DIR=%TEMP%\gh520"
set "TMPFILE=%CACHE_DIR%\hosts_tmp.txt"
set "CACHE_FILE=%CACHE_DIR%\hosts_cached.txt"
set "TIMESTAMP_FILE=%CACHE_DIR%\timestamp.txt"
set "MARKER_START=GitHub520 Host Start"
set "MARKER_END=GitHub520 Host End"
set "TASK_NAME=GitHub-Hosts-Update"

if /i "%~1"=="/startup"    goto :startup
if /i "%~1"=="/install"    goto :install
if /i "%~1"=="/uninstall"  goto :uninstall
if /i "%~1"=="/check"      goto :check_only

:: --- Double click: open browser + update hosts ---
start "" "https://github.com"

net session >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs -WindowStyle Normal" >nul 2>&1
    exit /b
)

call :do_update
exit /b


:: --- Startup mode (scheduled task) ---
:startup
call :do_update
exit /b


:: --- Core update logic ---
:do_update
setlocal

if not exist "%CACHE_DIR%" mkdir "%CACHE_DIR%" >nul 2>&1

:: Check cache freshness (YYYYMMDD)
if exist "%TIMESTAMP_FILE%" (
    for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd"') do set "TODAY=%%a"
    set /p CACHE_DATE=<"%TIMESTAMP_FILE%"
    for /f "tokens=*" %%a in ("!CACHE_DATE!") do set "CACHE_DATE=%%a"
    if "!CACHE_DATE!"=="!TODAY!" (
        findstr /c:"%MARKER_START%" "%HOSTS%" >nul 2>&1
        if errorlevel 1 (
            call :apply_to_hosts
        ) else (
            ipconfig /flushdns >nul 2>&1
        )
        exit /b 0
    )
)

:: Network check
ping -n 1 -w 2000 raw.githubusercontent.com >nul 2>&1
if errorlevel 1 (
    ping -n 1 -w 2000 github.com >nul 2>&1
    if errorlevel 1 (
        if exist "%CACHE_FILE%" call :apply_to_hosts
        exit /b 1
    )
)

:: Download
call :try_download
if errorlevel 1 (
    if exist "%CACHE_FILE%" call :apply_to_hosts
    exit /b 1
)

:: Validate
findstr /c:"%MARKER_START%" "%TMPFILE%" >nul 2>&1
if errorlevel 1 (
    if exist "%CACHE_FILE%" call :apply_to_hosts
    exit /b 1
)

:: Save cache
copy /y "%TMPFILE%" "%CACHE_FILE%" >nul 2>&1
for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd"') do <nul set /p "=%%a" > "%TIMESTAMP_FILE%"

:: Apply
call :apply_to_hosts
del "%TMPFILE%" >nul 2>&1
exit /b 0


:: --- Download with fallback ---
:try_download
set "URL1=https://raw.hellogithub.com/hosts"
set "URL2=https://raw.githubusercontent.com/521xueweihan/GitHub520/main/hosts"

curl.exe -sL --connect-timeout 5 --max-time 10 -o "%TMPFILE%" "%URL1%" 2>nul
if errorlevel 1 (
    curl.exe -sL --connect-timeout 5 --max-time 10 -o "%TMPFILE%" "%URL2%" 2>nul
)
if errorlevel 1 exit /b 1

for %%A in ("%TMPFILE%") do if %%~zA lss 100 exit /b 1
exit /b 0


:: --- Apply hosts (remove old block, append new) ---
:apply_to_hosts
if not exist "%CACHE_FILE%" exit /b 1

attrib -r "%HOSTS%" >nul 2>&1
copy /y "%HOSTS%" "%HOSTS%.bak" >nul 2>&1

powershell -NoProfile -Command "$h='%HOSTS%';$c='%CACHE_FILE%';$b=@();$s=0;foreach($l in (Get-Content $h -Encoding UTF8)){if($l -match 'GitHub520 Host Start'){$s=1}if(-not$s){$b+=$l}if($l -match 'GitHub520 Host End'){$s=0}}$n=@();$n+=$b;$n+='';$n+=(Get-Content $c -Encoding UTF8);[IO.File]::WriteAllLines($h,$n,[Text.Encoding]::UTF8)" >nul 2>&1

if errorlevel 1 (
    copy /y "%HOSTS%.bak" "%HOSTS%" >nul 2>&1
    exit /b 1
)

ipconfig /flushdns >nul 2>&1
exit /b 0


:: --- Status check ---
:check_only
echo ===== GitHub Accelerator - Status =====
echo.
findstr /c:"%MARKER_START%" "%HOSTS%" >nul 2>&1
if errorlevel 1 ( echo [HOSTS] GitHub520: MISSING
) else ( echo [HOSTS] GitHub520: PRESENT )

if exist "%CACHE_FILE%" (
    if exist "%TIMESTAMP_FILE%" (
        set /p TS=<"%TIMESTAMP_FILE%"
        for /f "tokens=*" %%a in ("!TS!") do set "TS=%%a"
        echo [CACHE] Last update: !TS!
        for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd"') do set "TODAY=%%a"
        if "!TS!"=="!TODAY!" ( echo [CACHE] Status: Fresh
        ) else ( echo [CACHE] Status: Stale )
    ) else ( echo [CACHE] File present )
) else ( echo [CACHE] No cached data )

schtasks /query /tn "%TASK_NAME%" >nul 2>&1
if errorlevel 1 ( echo [TASK] Not installed
) else ( echo [TASK] Installed )

echo ============================================
echo.
pause
exit /b


:: --- Install scheduled task ---
:install
net session >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\" /install' -Verb RunAs -WindowStyle Normal" >nul 2>&1
    exit /b
)

(
    echo Set WshShell = CreateObject^("WScript.Shell"^)
    echo WshShell.Run "cmd.exe /c """"D:\Desktop\GitHub.bat"""" /startup", 0, False
) > "D:\Desktop\gh520_launcher.vbs"

schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1

schtasks /create /tn "%TASK_NAME%" ^
    /tr "wscript.exe //B \"D:\Desktop\gh520_launcher.vbs\"" ^
    /sc onlogon /delay 0000:30 /rl highest /f >nul 2>&1

echo ============================================
echo   GitHub Accelerator - Installed!
echo   Task: %TASK_NAME%
echo   To uninstall: GitHub.bat /uninstall
echo ============================================
echo.
pause
exit /b


:: --- Uninstall ---
:uninstall
net session >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\" /uninstall' -Verb RunAs -WindowStyle Normal" >nul 2>&1
    exit /b
)
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1
if exist "%CACHE_DIR%" (
    del /q "%CACHE_DIR%\*" >nul 2>&1
    rmdir "%CACHE_DIR%" >nul 2>&1
)
echo ============================================
echo   GitHub Accelerator - Uninstalled!
echo ============================================
echo.
pause
exit /b