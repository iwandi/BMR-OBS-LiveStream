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
set "DSKZIP=source-bin\downstream-keyer-0.4.4-windows.zip"

rem --- 1. OBS Studio (lays down bin\, data\, obs-plugins\) ---
echo.
echo [1/4] Extracting OBS Studio: !OBSNAME!
if not exist "!OBSZIP!" (
    echo [ERROR] Missing archive: !OBSZIP!
    goto :fail
)
"!TAR!" -xf "!OBSZIP!" -C .
if errorlevel 1 goto :fail

rem --- 2. Scene Tree Folder plugin (merges on top of OBS) ---
echo.
echo [2/4] Extracting Scene Tree Folder plugin
if not exist "!PLUGINZIP!" (
    echo [ERROR] Missing archive: !PLUGINZIP!
    goto :fail
)
"!TAR!" -xf "!PLUGINZIP!" -C .
if errorlevel 1 goto :fail

rem --- 3. Downstream Keyer plugin (overlay layer, merges on top) ---
rem  Provides the downstream key used to composite the race overlay
rem  on top of the live camera, independent of which camera is on
rem  program. The keyer itself ('Overlay', channel 7) is pre-configured
rem  in the scene collection JSON, so it appears automatically once this
rem  DLL is present. Zip layout is obs-plugins\ + data\, extracts as-is.
echo.
echo [3/4] Extracting Downstream Keyer plugin
if not exist "!DSKZIP!" (
    echo [ERROR] Missing archive: !DSKZIP!
    goto :fail
)
"!TAR!" -xf "!DSKZIP!" -C .
if errorlevel 1 goto :fail

rem --- 4. Repoint absolute asset/script paths to THIS folder ---
rem The scene collection stores media sources and loaded Lua/Python
rem scripts (the Grid organizer, camera control, refresh-browsers) as
rem absolute paths. After a fresh clone or a move they point at the old
rem location, so those assets and scripts silently fail to load. This
rem step rewrites them to wherever the repo now lives.
echo.
echo [4/4] Normalizing scene paths to this folder
if not exist "normalize-paths.ps1" (
    echo [ERROR] Missing helper: normalize-paths.ps1
    goto :fail
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0normalize-paths.ps1"
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
