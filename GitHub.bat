@echo off
title GitHub Accelerator

:: Self-elevate to admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile "Start-Process cmd -ArgumentList '/c \"%~s0\"' -Verb RunAs"
    exit /b
)

cls
echo =================================
echo       GitHub Accelerator
echo =================================
echo.

:: Step 1: Download hosts
echo [1/3] Downloading latest GitHub hosts data...
set "TMPFILE=%TEMP%\gh520.txt"
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;(New-Object Net.WebClient).DownloadFile('https://raw.hellogithub.com/hosts','%TMPFILE%')"
if %errorlevel% neq 0 (
    echo FAILED: Cannot download hosts data. Check your network.
    echo.
    pause
    exit /b 1
)
echo       OK
echo.

:: Step 2: Update hosts
echo [2/3] Updating system hosts file...
set "HOSTS=C:\Windows\System32\drivers\etc\hosts"
copy "%HOSTS%" "%HOSTS%.bak" >nul 2>&1

powershell -NoProfile -Command ^
"$h='%HOSTS%';$t='%TMPFILE%';" ^
"$c=@();$s=0;" ^
"foreach($l in (Get-Content $h -Encoding UTF8)){" ^
"  if($l -match 'GitHub520 Host Start'){$s=1}" ^
"  if(-not$s){$c+=$l}" ^
"  if($l -match 'GitHub520 Host End'){$s=0}" ^
"}" ^
"[IO.File]::WriteAllLines($h,$c);" ^
"[IO.File]::AppendAllLines($h,[IO.File]::ReadAllLines($t))"
echo       OK
echo.

:: Step 3: Flush DNS
echo [3/3] Flushing DNS cache...
ipconfig /flushdns
echo       OK
echo.

:: Cleanup
del "%TMPFILE%" >nul 2>&1

:: Open Edge to GitHub
echo Opening GitHub...
start "" "https://github.com"

echo.
echo =================================
echo    DONE! GitHub is accelerated
echo =================================
echo.
pause
