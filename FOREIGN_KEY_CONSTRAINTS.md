# Foreign Key Constraints Implementation

## Overview

This document describes the foreign key constraints implemented in the CSV import system to ensure data integrity between related tables.

## Database Relationships

### 1. PEGAWAI → SEKSI Relationship
- **Constraint**: `PEGAWAI.seksi` must exist as `SEKSI.id`
- **Purpose**: Ensures employees belong to valid sections
- **Implementation**: Added validation in `importPegawai()` function
- **Validation Logic**:
  ```dart
  // Validate SEKSI exists (NEW: Foreign key constraint)
  final seksiId = int.tryParse(data[4]) ?? 0;
  if (seksiId > 0) {
    final seksiExists = await DatabaseService.query(
      AppConstants.tableSeksi,
      where: 'id = ?',
      whereArgs: [seksiId]
    );
    if (seksiExists.isEmpty) {
      errors.add('Baris ${i + 1}: SEKSI ID $seksiId tidak ditemukan dalam tabel seksi');
      errorCount++;
      continue;
    }
  }
  ```

### 2. USER → PEGAWAI Relationship  
- **Constraint**: `USER.username` must exist as `PEGAWAI.nip`
- **Purpose**: Ensures users are valid employees (inherited from PEGAWAI)
- **Implementation**: Added validation in `importUser()` function
- **Validation Logic**:
  ```dart
  // Validate USERNAME exists as NIP in PEGAWAI table (NEW: Foreign key constraint)
  final pegawaiExists = await DatabaseService.query(
    AppConstants.tablePegawai,
    where: 'nip = ?',
    whereArgs: [username]
  );
  if (pegawaiExists.isEmpty) {
    errors.add('Baris ${i + 1}: USERNAME $username tidak ditemukan dalam tabel pegawai');
    errorCount++;
    continue;
  }
  ```

## Import Order Requirements

Due to these foreign key constraints, the import order is critical:

1. **SEKSI** (no dependencies) - Must be imported first
2. **PEGAWAI** (depends on SEKSI) - Must be imported after SEKSI
3. **USER** (depends on PEGAWAI) - Must be imported after PEGAWAI
4. **SPMKP** (no dependencies) - Can be imported anytime

The `DatabaseImportService.importAllDatabaseFiles()` method respects this order automatically.

## Sample Data Compliance

The sample CSV files have been updated to comply with these constraints:

### SEKSI-907.csv
- Contains SEKSI records with IDs 1-9
- Office code is consistent (907)

### PEGAWAI-907.csv  
- All `PEGAWAI.seksi` values (3,4,5,6,7,8) reference valid `SEKSI.id` values
- Office code is consistent (907)
- NIPs: 123456789, 234567890, 345678901, etc.

### USER-907.csv
- All `USER.username` values match `PEGAWAI.nip` values exactly
- Examples: 123456789, 234567890, 345678901, etc.
- Office code is consistent (907)

## Error Handling

When foreign key constraints are violated:
1. The specific row is skipped
2. An error message is added to the result
3. Error count is incremented  
4. Import continues with remaining rows
5. Final result shows success/error counts

## Modernization Changes

### USER Import Pattern
- **Old Pattern**: `USER.csv` (system-wide, no office validation)
- **New Pattern**: `USER-{KODE_KANTOR}.csv` (office-specific validation)
- **Benefit**: Consistent with other imports, prevents cross-office user pollution

### Office Code Validation
All imports now validate that:
- Filename office code matches settings office code
- Data office code (KANTOR field) matches filename office code
- Ensures data integrity and prevents accidental cross-office imports

## Constants Added

New error constant in `AppConstants`:
```dart
static const String importErrorOfficeCode = 'Kode kantor tidak sesuai';
```

New file pattern for USER:
```dart
static const String userFilePattern = 'USER-{KODE_KANTOR}.csv';
```

## Testing

To test the foreign key constraints:
1. Import SEKSI-907.csv first
2. Import PEGAWAI-907.csv (should succeed with valid SEKSI references)
3. Import USER-907.csv (should succeed with valid PEGAWAI NIP references)
4. Try importing USER with invalid NIP - should fail with appropriate error message
5. Try importing PEGAWAI with invalid SEKSI ID - should fail with appropriate error message

## Benefits

1. **Data Integrity**: Prevents orphaned records
2. **Consistency**: Enforces proper relationships between tables
3. **Error Prevention**: Catches invalid references early in import process
4. **Qt Legacy Compatibility**: Maintains Qt application behavior while adding modern validation
5. **Office Security**: Prevents cross-office data pollution