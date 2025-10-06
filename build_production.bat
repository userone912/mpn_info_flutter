@echo off
echo Building MPN-Info Flutter Application...

REM Build the Flutter Windows application
echo Building Flutter app...
flutter build windows --release

REM Create data and images directories in build output
echo Setting up external data directories...
set BUILD_DIR=build\windows\x64\runner\Release
if not exist "%BUILD_DIR%\data" mkdir "%BUILD_DIR%\data"
if not exist "%BUILD_DIR%\images" mkdir "%BUILD_DIR%\images"

REM Copy data files
echo Copying data files...
xcopy /Y /E "assets\data\*" "%BUILD_DIR%\data\"

REM Copy image files  
echo Copying image files...
xcopy /Y /E "assets\images\*" "%BUILD_DIR%\images\"
xcopy /Y /E "assets\icons\*" "%BUILD_DIR%\images\"

REM Create distribution directory
echo Creating distribution directory...
set DIST_DIR=C:\mpn-info
if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"
if not exist "%DIST_DIR%\data" mkdir "%DIST_DIR%\data"
if not exist "%DIST_DIR%\images" mkdir "%DIST_DIR%\images"

REM Copy executable and dependencies
echo Copying application files...
copy "%BUILD_DIR%\*.exe" "%DIST_DIR%\"
copy "%BUILD_DIR%\*.dll" "%DIST_DIR%\"

REM Copy data and images to distribution
echo Copying data and images to distribution...
xcopy /Y /E "%BUILD_DIR%\data\*" "%DIST_DIR%\data\"
xcopy /Y /E "%BUILD_DIR%\images\*" "%DIST_DIR%\images\"

echo.
echo Build completed successfully!
echo Application location: %DIST_DIR%
echo.
echo Directory structure:
echo C:\mpn-info\
echo ├── MPN-Info.exe
echo ├── settings.ini (created on first run)
echo ├── data\
echo │   ├── db-struct
echo │   ├── db-value
echo │   ├── kantor.csv
echo │   ├── klu.csv
echo │   ├── map.csv
echo │   ├── jatuhtempo.csv
echo │   ├── maxlapor.csv
echo │   └── update-x.x\
echo └── images\
echo     ├── logo-medium.png
echo     └── ...
echo.
pause