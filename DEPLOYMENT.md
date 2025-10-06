# MPN-Info Flutter Deployment Guide

## Production Deployment Structure

The MPN-Info Flutter application supports external data and image files for easy updates without recompilation.

### Recommended Production Structure

```
C:\mpn-info\
├── mpn_info_flutter.exe          # Main executable
├── settings.ini                  # Application configuration
├── *.dll                         # Flutter runtime dependencies
├── data\                          # External data files
│   ├── db-struct                  # Database structure definition
│   ├── db-value                   # Default database values
│   ├── kantor.csv                 # Office data
│   ├── klu.csv                    # Business classification data
│   ├── map.csv                    # Tax code mapping
│   ├── jatuhtempo.csv             # Due dates
│   ├── maxlapor.csv               # Maximum reporting dates
│   └── update-x.x\                # Version update folders
└── images\                        # External image files
    ├── logo-medium.png            # Application logo
    ├── icons\                     # Application icons
    └── ...                        # Other image assets
```

## Building for Production

### Windows Build

1. **Using PowerShell Script (Recommended)**:
   ```powershell
   .\Build-Production.ps1
   ```
   
   Or with custom output path:
   ```powershell
   .\Build-Production.ps1 -OutputPath "D:\MyApp"
   ```

2. **Using Batch Script**:
   ```cmd
   build_production.bat
   ```

3. **Manual Build**:
   ```cmd
   flutter build windows --release
   mkdir C:\mpn-info
   mkdir C:\mpn-info\data
   mkdir C:\mpn-info\images
   copy build\windows\x64\runner\Release\*.exe C:\mpn-info\
   copy build\windows\x64\runner\Release\*.dll C:\mpn-info\
   xcopy /E assets\data\* C:\mpn-info\data\
   xcopy /E assets\images\* C:\mpn-info\images\
   ```

### Linux Build

```bash
chmod +x build_production.sh
./build_production.sh
```

## How External Files Work

### 1. Automatic Detection
The application automatically detects whether it's running in development (with bundled assets) or production (with external files):

- **Development Mode**: Uses bundled assets from `assets/` directory
- **Production Mode**: Uses external files from `data/` and `images/` directories

### 2. File Resolution Priority
1. Check for external file in executable directory
2. Fall back to bundled asset if external file not found
3. Show error/fallback if neither exists

### 3. Database Migration
- Reads database structure from `data/db-struct`
- Loads default data from `data/db-value`
- Imports CSV data from `data/*.csv` files
- Automatically updates database schema when needed

## Benefits of External Files

### 1. Easy Updates
- Update CSV data without recompiling application
- Modify database structure by editing `db-struct`
- Replace images without rebuilding

### 2. Customization
- Different offices can have different logo files
- Custom data sets per deployment
- Regional customizations

### 3. Maintenance
- Database administrators can update reference data
- IT staff can push updates via file replacement
- No need for developer involvement for data changes

## Deployment Steps

### 1. Build Application
```powershell
# Run build script
.\Build-Production.ps1 -OutputPath "C:\mpn-info"
```

### 2. Verify Structure
Check that all required files are present:
- [x] `mpn_info_flutter.exe`
- [x] All `*.dll` files
- [x] `settings.ini` (created on first run)
- [x] `data\db-struct`
- [x] `data\db-value`
- [x] `data\*.csv` files
- [x] `images\logo-medium.png`

### 3. Test Application
```cmd
cd C:\mpn-info
.\mpn_info_flutter.exe
```

### 4. Database Configuration
1. Run application
2. Click gear icon in login screen
3. Configure database connection
4. Test connection (this triggers migration)
5. Verify all tables are created

## Updating Data Files

### CSV Data Updates
Replace CSV files in `data\` directory:
```cmd
copy new_kantor.csv C:\mpn-info\data\kantor.csv
copy new_klu.csv C:\mpn-info\data\klu.csv
```

Next application startup will automatically reload the data.

### Database Structure Updates
1. Update `data\db-struct` file
2. Increment version number in first line (e.g., `!4.5`)
3. Add new SQL commands as needed
4. Restart application - migration runs automatically

### Image Updates
Replace image files in `images\` directory:
```cmd
copy new_logo.png C:\mpn-info\images\logo-medium.png
```

Changes take effect immediately on restart.

### Configuration Updates
The `settings.ini` file is automatically created in the executable directory on first run. It contains:

- Database connection settings
- Application preferences
- User interface settings

Example `settings.ini` content:
```ini
[database]
type=mysql
host=localhost
port=3306
name=mpninfo
username=root
password=
use_ssl=false

[application]
theme=system
language=id
window_maximized=false
```

To reset configuration:
1. Close application
2. Delete `settings.ini` file
3. Restart application (will recreate with defaults)

## Distribution

### Package for Distribution
Create a ZIP file or installer containing the entire `C:\mpn-info\` directory:

```powershell
Compress-Archive -Path "C:\mpn-info\*" -DestinationPath "MPN-Info-v1.0.zip"
```

### Network Deployment
For multiple installations:
1. Create shared network location
2. Copy application directory
3. Each workstation can run from network or copy locally
4. Central data updates via network share

## Troubleshooting

### External Files Not Loading
1. Check directory structure matches exactly
2. Verify file permissions (read access required)
3. Check application logs for file loading errors

### Database Migration Issues
1. Verify `data\db-struct` format is correct
2. Check database connection settings
3. Ensure database user has CREATE/ALTER permissions

### Image Loading Problems
1. Confirm `images\logo-medium.png` exists
2. Check file format is supported (PNG, JPG)
3. Verify file is not corrupted

## Environment Variables

Optional environment variables for advanced configuration:

- `MPN_DATA_DIR`: Override data directory path
- `MPN_IMAGES_DIR`: Override images directory path
- `MPN_DEBUG`: Enable debug logging

Example:
```cmd
set MPN_DATA_DIR=D:\CustomData
set MPN_IMAGES_DIR=D:\CustomImages
mpn_info_flutter.exe
```