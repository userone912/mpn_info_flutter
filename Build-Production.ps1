# PowerShell Build Script for MPN-Info Flutter Application

Write-Host "Building MPN-Info Flutter Application..." -ForegroundColor Green

# Build the Flutter Windows application
Write-Host "Building Flutter app..." -ForegroundColor Yellow
flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter build failed!" -ForegroundColor Red
    exit 1
}

# Define paths
$BuildDir = "build\windows\x64\runner\Release"
$DataDir = "$BuildDir\data"
$UpdateDir = "$BuildDir\update"  

# Create data directory in build output
Write-Host "Setting up data directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $DataDir | Out-Null

# Create update directory in build output
Write-Host "Setting up update directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $UpdateDir | Out-Null

# Copy data files from project root data folder
Write-Host "Copying data files..." -ForegroundColor Yellow
Copy-Item -Path "data\*" -Destination $DataDir -Recurse -Force

# Copy update files from project root update folder
Write-Host "Copying update files..." -ForegroundColor Yellow
Copy-Item -Path "update\*" -Destination $UpdateDir -Recurse -Force

Write-Host ""
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "Application location: $BuildDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Directory structure:" -ForegroundColor White
Write-Host "$BuildDir\" -ForegroundColor Cyan
Write-Host "├── mpninfo.exe" -ForegroundColor White
Write-Host "├── settings.ini (created on first run)" -ForegroundColor Gray
Write-Host "├── *.dll (Flutter dependencies)" -ForegroundColor Gray
Write-Host "└── data\" -ForegroundColor Yellow
Write-Host "    ├── db-struct" -ForegroundColor White
Write-Host "    ├── db-value" -ForegroundColor White
Write-Host "    ├── kantor.csv" -ForegroundColor White
Write-Host "    ├── klu.csv" -ForegroundColor White
Write-Host "    ├── map.csv" -ForegroundColor White
Write-Host "    ├── jatuhtempo.csv" -ForegroundColor White
Write-Host "    ├── maxlapor.csv" -ForegroundColor White
Write-Host "    └── update-x.x\" -ForegroundColor White
Write-Host ""

# Show next steps
Write-Host "Next steps:" -ForegroundColor Magenta
Write-Host "1. Test the application: $BuildDir\mpninfo.exe" -ForegroundColor White
Write-Host "2. Configure database on first run (settings.ini will be created)" -ForegroundColor White
Write-Host "3. Update data files in $BuildDir\data\ as needed" -ForegroundColor White
Write-Host "4. Distribute the entire $BuildDir directory" -ForegroundColor White
Write-Host ""