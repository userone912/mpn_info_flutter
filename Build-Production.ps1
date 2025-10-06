# PowerShell Build Script for MPN-Info Flutter Application
param(
    [string]$OutputPath = "C:\mpn-info"
)

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
$ImagesDir = "$BuildDir\images"

# Create directories in build output
Write-Host "Setting up external data directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $DataDir | Out-Null
New-Item -ItemType Directory -Force -Path $ImagesDir | Out-Null

# Copy data files
Write-Host "Copying data files..." -ForegroundColor Yellow
Copy-Item -Path "assets\data\*" -Destination $DataDir -Recurse -Force

# Copy image files
Write-Host "Copying image files..." -ForegroundColor Yellow
Copy-Item -Path "assets\images\*" -Destination $ImagesDir -Recurse -Force
Copy-Item -Path "assets\icons\*" -Destination $ImagesDir -Recurse -Force

# Create distribution directory
Write-Host "Creating distribution directory: $OutputPath" -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputPath\data" | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputPath\images" | Out-Null

# Copy executable and dependencies
Write-Host "Copying application files..." -ForegroundColor Yellow
Copy-Item -Path "$BuildDir\*.exe" -Destination $OutputPath -Force
Copy-Item -Path "$BuildDir\*.dll" -Destination $OutputPath -Force

# Copy data and images to distribution
Write-Host "Copying data and images to distribution..." -ForegroundColor Yellow
Copy-Item -Path "$DataDir\*" -Destination "$OutputPath\data\" -Recurse -Force
Copy-Item -Path "$ImagesDir\*" -Destination "$OutputPath\images\" -Recurse -Force

Write-Host ""
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "Application location: $OutputPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Directory structure:" -ForegroundColor White
Write-Host "$OutputPath\" -ForegroundColor Cyan
Write-Host "├── mpn_info_flutter.exe" -ForegroundColor White
Write-Host "├── settings.ini (created on first run)" -ForegroundColor Gray
Write-Host "├── *.dll (Flutter dependencies)" -ForegroundColor Gray
Write-Host "├── data\" -ForegroundColor Yellow
Write-Host "│   ├── db-struct" -ForegroundColor White
Write-Host "│   ├── db-value" -ForegroundColor White
Write-Host "│   ├── kantor.csv" -ForegroundColor White
Write-Host "│   ├── klu.csv" -ForegroundColor White
Write-Host "│   ├── map.csv" -ForegroundColor White
Write-Host "│   ├── jatuhtempo.csv" -ForegroundColor White
Write-Host "│   ├── maxlapor.csv" -ForegroundColor White
Write-Host "│   └── update-x.x\" -ForegroundColor White
Write-Host "└── images\" -ForegroundColor Yellow
Write-Host "    ├── logo-medium.png" -ForegroundColor White
Write-Host "    └── ..." -ForegroundColor Gray
Write-Host ""

# Show next steps
Write-Host "Next steps:" -ForegroundColor Magenta
Write-Host "1. Test the application: $OutputPath\mpn_info_flutter.exe" -ForegroundColor White
Write-Host "2. Configure database on first run (settings.ini will be created)" -ForegroundColor White
Write-Host "3. Update data files in $OutputPath\data\ as needed" -ForegroundColor White
Write-Host "4. Distribute the entire $OutputPath directory" -ForegroundColor White
Write-Host ""