@echo off
setlocal
where ml.exe >nul 2>&1
if %ERRORLEVEL% neq 0 (
    if exist "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars32.bat" (
        call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars32.bat" >nul 2>&1
    )
)

if /i "%1"=="clean" (
    echo Cleaning build artifacts...
    del /q *.obj main.exe >nul 2>&1
    echo Clean completed.
    exit /b 0
)

ml /nologo /c /coff /Cx /Zd /Zi /W3 main.asm crypto.asm stego.asm fileio.asm gui.asm
if %ERRORLEVEL% neq 0 (
    echo Assembly failed with error %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

link /NOLOGO /SUBSYSTEM:WINDOWS /ENTRY:start %* main.obj crypto.obj stego.obj fileio.obj gui.obj kernel32.lib user32.lib gdi32.lib comdlg32.lib gdiplus.lib
if %ERRORLEVEL% neq 0 (
    echo Link failed with error %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

echo Build succeeded: main.exe ready.
exit /b 0
