import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/import_result.dart';
import '../../core/constants/app_constants.dart';
import 'database_service.dart';

/// Database Import Service
/// Consolidated import service that scans for CSV files and imports them automatically
/// Similar to Update Referensi but for database tables (Seksi, Pegawai, User, SPMKP)
class DatabaseImportService {
  
  /// Import all database CSV files from selected directory
  /// Scans for SEKSI-{KODE}.csv, PEGAWAI-{KODE}.csv, USER.csv, SPMKP-{KODE}-{YEAR}.csv
  /// Validates KODE_KANTOR against settings.kantor.kode (Qt legacy behavior)
  static Future<ImportResult> importAllDatabaseFiles() async {
    try {
      // Let user select directory containing CSV files
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Pilih Folder yang Berisi File CSV Database',
      );
      
      if (selectedDirectory == null) {
        return ImportResult.cancelled();
      }

      final directory = Directory(selectedDirectory);
      if (!directory.existsSync()) {
        return ImportResult.error('DIRECTORY_NOT_FOUND', 'Direktori tidak ditemukan');
      }

      // Get office code from database settings (not file-based settings)
      final kantorKode = await _getOfficeCodeFromDatabase();
      if (kantorKode.isEmpty || kantorKode.length != 3) {
        return ImportResult.error(
          'INVALID_KANTOR_KODE', 
          'Kode kantor tidak valid di settings. Silakan atur kode kantor 3 digit di menu Konfigurasi.'
        );
      }

      // Scan for CSV files
      final csvFiles = directory
          .listSync()
          .where((file) => file is File && file.path.toLowerCase().endsWith('.csv'))
          .cast<File>()
          .toList();

      if (csvFiles.isEmpty) {
        return ImportResult.error('NO_CSV_FILES', 'Tidak ada file CSV ditemukan di direktori');
      }

      // Categorize and validate files
      final results = <String, ImportResult>{};
      int totalSuccess = 0;
      int totalErrors = 0;
      final allErrors = <String>[];

      // 1. Import SEKSI files
      final seksiFiles = csvFiles.where((f) => _isSeksiFile(f.path)).toList();
      for (final file in seksiFiles) {
        final kodeFromFile = _extractKodeFromSeksiFile(file.path);
        if (kodeFromFile != kantorKode) {
          results['SEKSI-$kodeFromFile'] = ImportResult.error(
            'KANTOR_MISMATCH',
            'Kode kantor $kodeFromFile tidak sesuai dengan settings ($kantorKode)'
          );
          totalErrors++;
          allErrors.add('SEKSI-$kodeFromFile: Kode kantor tidak sesuai');
          continue;
        }

        final result = await _importSeksiFile(file);
        results['SEKSI-$kodeFromFile'] = result;
        totalSuccess += result.successCount;
        totalErrors += result.errorCount;
        allErrors.addAll(result.errors);
      }

      // 2. Import PEGAWAI files
      final pegawaiFiles = csvFiles.where((f) => _isPegawaiFile(f.path)).toList();
      for (final file in pegawaiFiles) {
        final kodeFromFile = _extractKodeFromPegawaiFile(file.path);
        if (kodeFromFile != kantorKode) {
          results['PEGAWAI-$kodeFromFile'] = ImportResult.error(
            'KANTOR_MISMATCH',
            'Kode kantor $kodeFromFile tidak sesuai dengan settings ($kantorKode)'
          );
          totalErrors++;
          allErrors.add('PEGAWAI-$kodeFromFile: Kode kantor tidak sesuai');
          continue;
        }

        final result = await _importPegawaiFile(file);
        results['PEGAWAI-$kodeFromFile'] = result;
        totalSuccess += result.successCount;
        totalErrors += result.errorCount;
        allErrors.addAll(result.errors);
      }

      // 3. Import USER files (NEW: office code validation)
      final userFiles = csvFiles.where((f) => _isUserFile(f.path)).toList();
      for (final file in userFiles) {
        final kodeFromFile = _extractKodeFromUserFile(file.path);
        if (kodeFromFile != kantorKode) {
          results['USER-$kodeFromFile'] = ImportResult.error(
            'KANTOR_MISMATCH',
            'Kode kantor $kodeFromFile tidak sesuai dengan settings ($kantorKode)'
          );
          totalErrors++;
          allErrors.add('USER-$kodeFromFile: Kode kantor tidak sesuai');
          continue;
        }

        final result = await _importUserFile(file);
        results['USER-$kodeFromFile'] = result;
        totalSuccess += result.successCount;
        totalErrors += result.errorCount;
        allErrors.addAll(result.errors);
      }

      // 4. Import SPMKP files
      final spmkpFiles = csvFiles.where((f) => _isSpmkpFile(f.path)).toList();
      for (final file in spmkpFiles) {
        final kodeFromFile = _extractKodeFromSpmkpFile(file.path);
        if (kodeFromFile != kantorKode) {
          final fileName = file.path.split(Platform.pathSeparator).last;
          results[fileName] = ImportResult.error(
            'KANTOR_MISMATCH',
            'Kode kantor $kodeFromFile tidak sesuai dengan settings ($kantorKode)'
          );
          totalErrors++;
          allErrors.add('$fileName: Kode kantor tidak sesuai');
          continue;
        }

        final result = await _importSpmkpFile(file);
        final fileName = file.path.split(Platform.pathSeparator).last;
        results[fileName] = result;
        totalSuccess += result.successCount;
        totalErrors += result.errorCount;
        allErrors.addAll(result.errors);
      }

      // Generate summary
      final processedFiles = results.length;
      final successfulFiles = results.values.where((r) => r.isSuccess).length;
      
      return ImportResult.success(
        message: 'Database import selesai: $successfulFiles/$processedFiles file berhasil, $totalSuccess records imported, $totalErrors errors',
        successCount: totalSuccess,
        errorCount: totalErrors,
        errors: allErrors,
      );

    } catch (e) {
      return ImportResult.error('IMPORT_FAILED', 'Import gagal: $e');
    }
  }

  /// Get office code from database settings table
  static Future<String> _getOfficeCodeFromDatabase() async {
    try {
      final result = await DatabaseService.query(
        AppConstants.tableSettings,
        where: '`key` = ?',  // Escape the key column name with backticks
        whereArgs: ['kantor.kode'],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return result.first['value']?.toString() ?? '';
      }
      return '';
    } catch (e) {
      // If settings table doesn't exist or query fails, return empty
      return '';
    }
  }

  // File type detection methods (STRICT: Exact patterns for folder scanning)
  static bool _isSeksiFile(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    return RegExp(r'^SEKSI-\w{3}\.csv$', caseSensitive: false).hasMatch(fileName);
  }

  static bool _isPegawaiFile(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    return RegExp(r'^PEGAWAI-\w{3}\.csv$', caseSensitive: false).hasMatch(fileName);
  }

  static bool _isUserFile(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    return RegExp(r'^USER-\w{3}\.csv$', caseSensitive: false).hasMatch(fileName);
  }

  static bool _isSpmkpFile(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    return RegExp(r'^SPMKP-\w{3}-\d{4}\.csv$', caseSensitive: false).hasMatch(fileName);
  }

  // Code extraction methods (STRICT: Position-based extraction)
  static String _extractKodeFromSeksiFile(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    return fileName.split('-')[1].split('.')[0];
  }

  static String _extractKodeFromPegawaiFile(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    return fileName.split('-')[1].split('.')[0];
  }

  static String _extractKodeFromUserFile(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    return fileName.split('-')[1].split('.')[0];
  }

  static String _extractKodeFromSpmkpFile(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    return fileName.split('-')[1];
  }

  // Import methods using existing CsvImportService functionality
  static Future<ImportResult> _importSeksiFile(File file) async {
    try {
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      if (lines.isEmpty) {
        return ImportResult.error(AppConstants.importErrorContent, 'File kosong');
      }

      // Validate header
      final header = lines[0].trim();
      if (header != AppConstants.seksiHeaderFormat) {
        return ImportResult.error(
          AppConstants.importErrorHeader, 
          'Header harus: ${AppConstants.seksiHeaderFormat}'
        );
      }

      final fileName = file.path.split(Platform.pathSeparator).last;
      final kodeKantor = _extractKodeFromSeksiFile(file.path);

      // Process using existing logic
      int successCount = 0;
      int errorCount = 0;
      final errors = <String>[];

      // Clear existing data for this office
      await DatabaseService.delete(
        AppConstants.tableSeksi, 
        'kantor = ?', 
        [kodeKantor]
      );

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        try {
          final data = _parseCsvLine(line);
          if (data.length < 6) {
            errors.add('$fileName baris ${i + 1}: Kolom tidak lengkap');
            errorCount++;
            continue;
          }

          // Qt legacy validation: KANTOR field must match filename KODE_KANTOR
          if (data[1] != kodeKantor) {
            errors.add('$fileName baris ${i + 1}: KANTOR ${data[1]} tidak sesuai dengan file $kodeKantor');
            errorCount++;
            continue;
          }

          // Insert into database
          await DatabaseService.insert(AppConstants.tableSeksi, {
            'id': int.tryParse(data[0]) ?? 0,
            'kantor': data[1],
            'tipe': int.tryParse(data[2]) ?? 0,
            'nama': data[3],
            'kode': data[4],
            'telp': data[5],
          });

          successCount++;
        } catch (e) {
          errors.add('$fileName baris ${i + 1}: $e');
          errorCount++;
        }
      }

      return ImportResult.success(
        message: '$fileName: $successCount berhasil, $errorCount error',
        successCount: successCount,
        errorCount: errorCount,
        errors: errors,
      );

    } catch (e) {
      final fileName = file.path.split(Platform.pathSeparator).last;
      return ImportResult.error(AppConstants.importErrorOpenFile, '$fileName: $e');
    }
  }

  static Future<ImportResult> _importPegawaiFile(File file) async {
    try {
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      if (lines.isEmpty) {
        return ImportResult.error(AppConstants.importErrorContent, 'File kosong');
      }

      // Validate header
      final header = lines[0].trim();
      if (header != AppConstants.pegawaiHeaderFormat) {
        return ImportResult.error(
          AppConstants.importErrorHeader, 
          'Header harus: ${AppConstants.pegawaiHeaderFormat}'
        );
      }

      final fileName = file.path.split(Platform.pathSeparator).last;
      final kodeKantor = _extractKodeFromPegawaiFile(file.path);

      // Process using existing logic
      int successCount = 0;
      int errorCount = 0;
      final errors = <String>[];

      // Clear existing data for this office
      await DatabaseService.delete(
        AppConstants.tablePegawai, 
        'kantor = ?', 
        [kodeKantor]
      );

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        try {
          final data = _parseCsvLine(line);
          if (data.length < 8) {
            errors.add('$fileName baris ${i + 1}: Kolom tidak lengkap');
            errorCount++;
            continue;
          }

          // Qt legacy validation: KANTOR field must match filename KODE_KANTOR
          if (data[0] != kodeKantor) {
            errors.add('$fileName baris ${i + 1}: KANTOR ${data[0]} tidak sesuai dengan file $kodeKantor');
            errorCount++;
            continue;
          }

          // Insert into database
          await DatabaseService.insert(AppConstants.tablePegawai, {
            'kantor': data[0],
            'nip': data[1],
            'nip2': data[2],
            'nama': data[3],
            'seksi': int.tryParse(data[4]) ?? 0,
            'pangkat': int.tryParse(data[5]) ?? 0,
            'jabatan': int.tryParse(data[6]) ?? 0,
            'tahun': int.tryParse(data[7]) ?? DateTime.now().year,
          });

          successCount++;
        } catch (e) {
          errors.add('$fileName baris ${i + 1}: $e');
          errorCount++;
        }
      }

      return ImportResult.success(
        message: '$fileName: $successCount berhasil, $errorCount error',
        successCount: successCount,
        errorCount: errorCount,
        errors: errors,
      );

    } catch (e) {
      final fileName = file.path.split(Platform.pathSeparator).last;
      return ImportResult.error(AppConstants.importErrorOpenFile, '$fileName: $e');
    }
  }

  static Future<ImportResult> _importUserFile(File file) async {
    try {
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      if (lines.isEmpty) {
        return ImportResult.error(AppConstants.importErrorContent, 'File kosong');
      }

      // Validate header
      final header = lines[0].trim();
      if (header != AppConstants.userHeaderFormat) {
        return ImportResult.error(
          AppConstants.importErrorHeader, 
          'Header harus: ${AppConstants.userHeaderFormat}'
        );
      }

      final fileName = file.path.split(Platform.pathSeparator).last;

      // Process using existing logic
      int successCount = 0;
      int errorCount = 0;
      final errors = <String>[];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        try {
          final data = _parseCsvLine(line);
          if (data.length < 5) {
            errors.add('$fileName baris ${i + 1}: Kolom tidak lengkap');
            errorCount++;
            continue;
          }

          final userId = int.tryParse(data[0]) ?? 0;
          final username = data[1];
          final password = data[2];
          final fullname = data[3];
          final groupType = int.tryParse(data[4]) ?? 2;

          // Qt legacy behavior: Check if user ID exists (not username)
          final existing = await DatabaseService.query(
            AppConstants.tableUsers,
            where: 'id = ?',
            whereArgs: [userId],
            limit: 1,
          );

          if (existing.isNotEmpty) {
            // UPDATE existing user (Qt legacy behavior)
            // Use correct column name based on database type
            final groupColumnName = await _getGroupColumnName();
            await DatabaseService.update(
              AppConstants.tableUsers,
              {
                'username': username,
                'password': password,
                'fullname': fullname,
                groupColumnName: groupType,
              },
              'id = ?',
              [userId],
            );
          } else {
            // INSERT new user
            // Use correct column name based on database type
            final groupColumnName = await _getGroupColumnName();
            await DatabaseService.insert(AppConstants.tableUsers, {
              'id': userId,
              'username': username,
              'password': password,
              'fullname': fullname,
              groupColumnName: groupType,
            });
          }

          successCount++;
        } catch (e) {
          errors.add('$fileName baris ${i + 1}: $e');
          errorCount++;
        }
      }

      return ImportResult.success(
        message: '$fileName: $successCount berhasil, $errorCount error',
        successCount: successCount,
        errorCount: errorCount,
        errors: errors,
      );

    } catch (e) {
      final fileName = file.path.split(Platform.pathSeparator).last;
      return ImportResult.error(AppConstants.importErrorOpenFile, '$fileName: $e');
    }
  }

  static Future<ImportResult> _importSpmkpFile(File file) async {
    try {
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      if (lines.isEmpty) {
        return ImportResult.error(AppConstants.importErrorContent, 'File kosong');
      }

      // Validate header
      final header = lines[0].trim();
      if (header != AppConstants.spmkpHeaderFormat) {
        return ImportResult.error(
          AppConstants.importErrorHeader, 
          'Header harus: ${AppConstants.spmkpHeaderFormat}'
        );
      }

      final fileName = file.path.split(Platform.pathSeparator).last;
      final parts = fileName.split('-');
      final kodeKantor = parts[1];
      final tahun = int.tryParse(parts[2].split('.')[0]) ?? DateTime.now().year;

      // Delete existing SPMKP data for this office and year (Qt legacy behavior)
      await DatabaseService.delete(
        AppConstants.tableSpmkp, 
        'admin = ? AND tahun = ?', 
        [kodeKantor, tahun]
      );

      // Process using existing logic
      int successCount = 0;
      int errorCount = 0;
      final errors = <String>[];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        try {
          final data = _parseCsvLine(line);
          if (data.length < 7) {
            errors.add('$fileName baris ${i + 1}: Kolom tidak lengkap');
            errorCount++;
            continue;
          }

          // Insert into database with admin field from filename (Qt legacy behavior)
          await DatabaseService.insert(AppConstants.tableSpmkp, {
            'admin': kodeKantor,  // From filename, not from CSV data
            'npwp': data[0],      // NPWP field
            'kpp': data[1],       // KPP field
            'cabang': data[2],    // CABANG field
            'kdmap': data[3],     // KDMAP field
            'bulan': int.tryParse(data[4]) ?? 1,
            'tahun': int.tryParse(data[5]) ?? tahun,
            'nominal': double.tryParse(data[6]) ?? 0.0,
          });

          successCount++;
        } catch (e) {
          errors.add('$fileName baris ${i + 1}: $e');
          errorCount++;
        }
      }

      return ImportResult.success(
        message: '$fileName: $successCount berhasil, $errorCount error',
        successCount: successCount,
        errorCount: errorCount,
        errors: errors,
      );

    } catch (e) {
      final fileName = file.path.split(Platform.pathSeparator).last;
      return ImportResult.error(AppConstants.importErrorOpenFile, '$fileName: $e');
    }
  }

  // CSV parsing helper method
  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ';' && !inQuotes) {
        result.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    
    // Add the last field
    result.add(buffer.toString().trim());
    
    return result;
  }

  /// Get the correct group column name based on database schema
  /// Legacy MySQL databases use 'group', new SQLite databases use 'group_type'
  static Future<String> _getGroupColumnName() async {
    try {
      // Try to query with 'group' column first (legacy MySQL)
      await DatabaseService.rawQuery('SELECT `group` FROM ${AppConstants.tableUsers} LIMIT 1');
      return 'group';
    } catch (e) {
      // If 'group' column doesn't exist, use 'group_type' (new SQLite)
      return 'group_type';
    }
  }
}