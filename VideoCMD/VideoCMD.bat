@echo off
setlocal EnableExtensions DisableDelayedExpansion

chcp 65001 >nul

title VideoCMD - 16 Color
mode con: cols=110 lines=35
cls

echo ==========================================
echo               VideoCMD
echo ==========================================
echo.

where ffmpeg.exe >nul 2>&1
if errorlevel 1 (
    echo ERROR: FFmpeg was not found in PATH.
    echo.
    pause
    exit /b 1
)

echo FFmpeg: OK
echo.

set "WORK=%TEMP%\VideoCMD_%RANDOM%%RANDOM%"
mkdir "%WORK%" >nul 2>&1

if not exist "%WORK%" (
    echo ERROR: Could not create workspace.
    pause
    exit /b 1
)

echo Opening file picker...
echo.

powershell.exe -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $d=[System.Windows.Forms.OpenFileDialog]::new(); $d.Title='Choose video'; $d.Filter='Video files|*.mp4;*.gif;*.avi;*.mov;*.mkv;*.webm'; if($d.ShowDialog() -eq 'OK'){Set-Content -LiteralPath '%WORK%\input.txt' -Value $d.FileName}"

if not exist "%WORK%\input.txt" (
    echo No file selected.
    goto CLEANUP
)

set "INPUT="
set /p "INPUT="<"%WORK%\input.txt"

if not defined INPUT (
    echo No file selected.
    goto CLEANUP
)

echo.
echo Selected:
echo %INPUT%
echo.

echo ==========================================
echo               CONVERTING
echo ==========================================
echo.
echo Maximum: 10 seconds
echo FPS: 8
echo Resolution: 50 x 25
echo Colors: 16
echo.

ffmpeg.exe -hide_banner -loglevel error -y ^
-i "%INPUT%" ^
-t 10 ^
-vf "fps=8,scale=50:25:force_original_aspect_ratio=decrease,pad=50:25:(ow-iw)/2:(oh-ih)/2" ^
"%WORK%\frame_%%04d.png"

if errorlevel 1 (
    echo.
    echo ERROR: FFmpeg conversion failed.
    goto ERROR
)

if not exist "%WORK%\frame_*.png" (
    echo.
    echo ERROR: No frames were created.
    goto ERROR
)

set /a FRAMES=0

for %%F in ("%WORK%\frame_*.png") do (
    set /a FRAMES+=1
)

echo.
echo ==========================================
echo             CONVERSION DONE
echo ==========================================
echo.
echo Frames created: %FRAMES%
echo.
echo Starting 16-color player...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0VideoCMD.ps1" "%WORK%"

echo.
echo ==========================================
echo             PLAYER FINISHED
echo ==========================================
echo.

goto CLEANUP

:ERROR
echo.
echo ==========================================
echo                    ERROR
echo ==========================================
echo.
echo Temporary files:
echo %WORK%
echo.
pause
goto CLEANUP

:CLEANUP
rmdir /s /q "%WORK%" >nul 2>&1

echo.
pause

endlocal