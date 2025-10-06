# CSV Import Integration with Database Setup

## Overview
The CSV import system is now **automatically integrated** with the "Test Koneksi" and "Simpan & Gunakan" database configuration flow, exactly matching the Qt legacy application behavior.

## Integration Flow

### 1. "Test Koneksi" Button Flow
```
User clicks "Test Koneksi" 
    ↓
database_config_dialog.dart: _testConnection()
    ↓
DatabaseService.initializeWithConfig(config)
    ↓
DatabaseMigrationService.migrateDatabase()
    ↓
Reads db-struct and db-value from external data/
    ↓
Processes migration commands including:
    - updatekantor;
    - updateklu;  
    - updatemap;
    - updatejatuhtempo;
    - updatemaxlapor;
    ↓
DatabaseMigrationService.loadSpecificCsvData() for each CSV
    ↓
DatabaseService.executeCsvImport() with external data integration
    ↓
Success message: "Database berhasil disinkronisasi!"
```

### 2. "Simpan & Gunakan" Button Flow  
```
User clicks "Simpan & Gunakan"
    ↓
database_config_dialog.dart: _saveAndConnect()
    ↓
DatabaseService.initializeWithConfig(config)
    ↓
DatabaseMigrationService.migrateDatabase()
    ↓
[Same CSV import process as above]
    ↓
Navigator.pop(true) // Returns to main application
```

## Qt Legacy Migration Commands

The database migration files contain these commands that trigger CSV imports:

### db-value file:
```
!4.7
message;Memasukkan default data;
sql;0;INSERT INTO `users`(`username`, `password`, `fullname`, `group`) VALUES('admin', 'admin', 'Administrator', 0);
updatekantor;    ← Triggers kantor.csv import
updateklu;       ← Triggers klu.csv import  
updatemap;       ← Triggers map.csv import
updatejatuhtempo; ← Triggers jatuhtempo.csv import
updatemaxlapor;  ← Triggers maxlapor.csv import
```

### Update files (e.g., update-4.6):
```
!4.6
title;Updating Database;
message;Update Data;

updatekantor;    ← Automatic CSV reload
updatemap;       ← Automatic CSV reload
updatejatuhtempo; ← Automatic CSV reload  
updatemaxlapor;  ← Automatic CSV reload

message;Updating versi database;
sql;0;UPDATE `info` SET `value`='4.7' WHERE `key`='db.version';
```

## Automatic CSV Processing

### External Data Directory Integration
- **Development:** Reads from `mpn_info_flutter/data/`
- **Production:** Reads from `executable_directory/data/`
- **Smart Detection:** Automatically detects development vs production mode

### CSV Import Process (per table)
1. **Read from external data directory** - No more bundled assets
2. **Parse CSV with correct field mappings** - Handles all 5 table formats
3. **Truncate existing table** - `DELETE FROM table WHERE 1=1` (Qt legacy)
4. **Insert new records** - Real database operations, no simulation
5. **Return actual counts** - Shows real processed record numbers

### Supported CSV Files
| CSV File | Database Table | Format | Auto-Import Trigger |
|----------|----------------|---------|-------------------|
| kantor.csv | kantor | KANWIL;KPP;NAMA | updatekantor; |
| klu.csv | klu | KODE;NAMA;SEKTOR | updateklu; |
| map.csv | map | KDMAP;KDBAYAR;SEKTOR;URAIAN | updatemap; |
| jatuhtempo.csv | jatuhtempo | BULAN;TAHUN;POTPUT;PPH;PPN;PPHOP;PPHBDN | updatejatuhtempo; |
| maxlapor.csv | maxlapor | BULAN;TAHUN;PPH;PPN;PPHOP;PPHBDN | updatemaxlapor; |

## User Experience

### First Time Setup
1. User opens application
2. Database not configured → Shows database config dialog
3. User enters MySQL/SQLite settings
4. User clicks "Test Koneksi"
5. **CSV files automatically imported** during connection test
6. Success message confirms both connection AND data import
7. User clicks "Simpan & Gunakan" 
8. Application ready with all reference data loaded

### Ongoing Usage
1. User modifies CSV files in `data/` directory
2. User opens "Update Referensi" menu 
3. All 5 CSV files reloaded in one operation
4. Changes effective immediately

### Database Upgrades
1. Update version in `data/db-struct` 
2. Add migration commands to new `data/update-X.Y` file
3. Include `updatekantor;` etc. commands as needed
4. Next "Test Koneksi" automatically runs migration + CSV updates

## Technical Integration Points

### DatabaseService.executeCsvImport()
```dart
// Now integrated with external data system
static Future<ImportResult> executeCsvImport({
  required String tableName,
  required String csvAssetPath, // Legacy parameter, ignored
}) async {
  // Get CSV content from external data directory
  final csvData = await DatabaseMigrationService.readExternalFile('data/$tableName.csv');
  
  // [Rest of import process using external files]
}
```

### DatabaseMigrationService.loadSpecificCsvData()
```dart
static Future<void> loadSpecificCsvData(String csvType) async {
  final csvFileName = csvType.replaceFirst('update', ''); // updatekantor → kantor
  final csvData = await _readExternalFile('data/$csvFileName.csv');
  
  // [Parse and import CSV data]
}
```

### ReferenceDataService.updateAllReferenceData()
```dart
static Future<SyncResult> updateAllReferenceData() async {
  // Reuse the existing CSV loading mechanism from DatabaseMigrationService
  // This is the same process that runs during database connection setup
  final csvTypes = ['updatekantor', 'updateklu', 'updatemap', 'updatejatuhtempo', 'updatemaxlapor'];
  
  for (final csvType in csvTypes) {
    await DatabaseMigrationService.loadSpecificCsvData(csvType);
  }
}
```

## Benefits of Integration

✅ **Automatic Data Loading** - CSV files imported during initial database setup  
✅ **Consistent with Qt Legacy** - Same migration command pattern  
✅ **No Manual Steps** - User doesn't need separate CSV import operations  
✅ **External File System** - Users can modify CSV files easily  
✅ **Version Control** - Database upgrades can include CSV updates  
✅ **Error Handling** - Connection test shows both connectivity AND data issues  
✅ **Real Operations** - No more simulated import processes  

## Comparison with Qt Application

| Aspect | Qt Legacy | Flutter Implementation |
|--------|-----------|----------------------|
| **Initial Setup** | Manual CSV import after DB connect | Automatic during "Test Koneksi" |
| **CSV Location** | ./data/ directory | External data/ directory |
| **Update Process** | 6 separate import functions | 1 unified "Update Referensi" |
| **Migration** | updatekantor; commands | Same updatekantor; commands |
| **File Format** | Semicolon-separated CSV | Same semicolon-separated CSV |
| **Import Method** | TRUNCATE + INSERT | Same TRUNCATE + INSERT pattern |

The Flutter implementation now **exactly matches** the Qt legacy behavior while providing better integration and user experience.