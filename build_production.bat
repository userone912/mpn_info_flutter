@echo off
echo Building MPN-Info Application...

REM Get the directory where this script is located
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

REM First, prepare the data directory structure
echo Preparing data files...
set BUILD_DIR=build\windows\x64\runner\Release

REM Ensure build directory exists
if not exist "build\windows\x64\runner" mkdir "build\windows\x64\runner"
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

REM Remove existing data directory and recreate
if exist "%BUILD_DIR%\data" rmdir /S /Q "%BUILD_DIR%\data"
mkdir "%BUILD_DIR%\data"

REM Copy data files from project root data folder
echo Copying data files...
xcopy /Y /E "data\*" "%BUILD_DIR%\data\"

REM Copy update files from project root update folder
echo Copying update files...
xcopy /Y /E "update\*" "%BUILD_DIR%\update\"

REM Verify copy was successful
if %ERRORLEVEL% neq 0 (
    echo Failed to copy data files!
    pause
    exit /b 1
) else (
    echo Data files copied successfully!
)

REM Now build the Flutter Windows application
echo Building Flutter app...
flutter build windows --release

REM Check if build was successful
if %ERRORLEVEL% neq 0 (
    echo Build failed!
    pause
    exit /b 1
)

echo.
echo Build completed successfully!
echo Application location: %BUILD_DIR%
echo.
echo Directory structure:
echo %BUILD_DIR%\
echo ├── mpninfo.exe
echo ├── settings.ini (created on first run)
echo ├── *.dll (Flutter dependencies)
echo └── data\
echo     ├── db-struct
echo     ├── db-value
echo     ├── kantor.csv
echo     ├── klu.csv
echo     ├── map.csv
echo     ├── jatuhtempo.csv
echo     ├── maxlapor.csv
echo     └── update-x.x\
echo.
echo Next steps:
echo 1. Test the application: %BUILD_DIR%\mpninfo.exe
echo 2. Configure database on first run (settings.ini will be created)
echo 3. Update data files in %BUILD_DIR%\data\ as needed
echo 4. Distribute the entire %BUILD_DIR% directory
echo.
pause