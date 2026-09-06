@echo off
setlocal enabledelayedexpansion

rem ============================================================
rem  unpack.bat - restore the portable OBS binaries
rem
rem  The config for this portable OBS install is tracked in git,
rem  but the binaries (bin\, obs-plugins\, data\) are NOT - they
rem  are gitignored and shipped as zip archives in source-bin\.
rem
rem  This script extracts those archives back into place so the
rem  install is runnable after a fresh clone. Existing files are
rem  overwritten, so it is safe to re-run.
rem ============================================================

rem Work from the folder this script lives in (the repo root).
cd /d "%~dp0"

rem bsdtar ships with Windows 10 1803+ and Windows 11 and extracts
rem .zip archives while overwriting existing files. Call it by full
rem path so we always get the Windows one, never GNU tar from Git
rem or MSYS that may sit earlier on PATH (GNU tar cannot read zips).
set "TAR=%SystemRoot%\System32\tar.exe"
if not exist "%TAR%" (
    echo [ERROR] %TAR% was not found. Windows 10 1803+ or Windows 11 is required.
    goto :fail
)

rem OBS version / archive base name is tracked in version.txt.
set "OBSNAME="
if not exist "version.txt" (
    echo [ERROR] version.txt not found - cannot determine the OBS archive name.
    goto :fail
)
set /p OBSNAME=<version.txt
if "!OBSNAME!"=="" (
    echo [ERROR] version.txt is empty - cannot determine the OBS archive name.
    goto :fail
)

set "OBSZIP=source-bin\!OBSNAME!.zip"
set "PLUGINZIP=source-bin\obs_scene_tree_view_win_v0_1_6.zip"

rem --- 1. OBS Studio (lays down bin\, data\, obs-plugins\) ---
echo.
echo [1/2] Extracting OBS Studio: !OBSNAME!
if not exist "!OBSZIP!" (
    echo [ERROR] Missing archive: !OBSZIP!
    goto :fail
)
"!TAR!" -xf "!OBSZIP!" -C .
if errorlevel 1 goto :fail

rem --- 2. Scene Tree Folder plugin (merges on top of OBS) ---
echo.
echo [2/2] Extracting Scene Tree Folder plugin
if not exist "!PLUGINZIP!" (
    echo [ERROR] Missing archive: !PLUGINZIP!
    goto :fail
)
"!TAR!" -xf "!PLUGINZIP!" -C .
if errorlevel 1 goto :fail

echo.
echo [DONE] Portable OBS binaries unpacked. Launch bin\64bit\obs64.exe to start.
endlocal
exit /b 0

:fail
echo.
echo [FAILED] Unpack did not complete. See the message(s) above.
endlocal
exit /b 1
