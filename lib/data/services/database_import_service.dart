import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/import_result.dart';
import '../../core/constants/app_constants.dart';
import 'database_service.dart';
import 'csv_import_service.dart';

/// Database Import Service
/// Consolidated import service that scans for CSV files and imports them automatically
/// Similar to Update Referensi but for database tables (Seksi, Pegawai, User, Renpen)
class DatabaseImportService {
  static void updateProgress(void Function(double, int, int, String)? onProgress, int currentRow, int totalRows, String fileName) {
    if (onProgress != null && totalRows > 0) {
      onProgress(currentRow / totalRows, currentRow, totalRows, fileName);
    }
  }
  /// Import all database CSV files from selected directory
  /// Scans for SEKSI-{KODE}.csv, PEGAWAI-{KODE}.csv, USER.csv, RENPEN-{KODE}-{YEAR}.csv
  /// Validates KODE_KANTOR against settings.kantor.kode (Qt legacy behavior)
  static Future<ImportResult> importAllDatabaseFiles({void Function(double progress, int currentRow, int totalRows, String fileName)? onProgress}) async {
  print('[DEBUG] Scanning for PKPM/PPM files...');
    // Scan for CSV files
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
      // Scan for CSV files
      final csvFiles = directory
          .listSync()
          .where((file) => file is File && file.path.toLowerCase().endsWith('.csv'))
          .cast<File>()
          .toList();

      if (csvFiles.isEmpty) {
        return ImportResult.error('NO_CSV_FILES', 'Tidak ada file CSV ditemukan di direktori');
      }

      // Get office code from database settings (not file-based settings) ONLY if SEKSI, PEGAWAI, or USER files are present
      final hasSeksi = csvFiles.any((f) => _isSeksiFile(f.path));
      final hasPegawai = csvFiles.any((f) => _isPegawaiFile(f.path));
      final hasUser = csvFiles.any((f) => _isUserFile(f.path));
      String kantorKode = '';
      if (hasSeksi || hasPegawai || hasUser) {
        kantorKode = await _getOfficeCodeFromDatabase();
        if (kantorKode.isEmpty || kantorKode.length != 3) {
          return ImportResult.error(
            'INVALID_KANTOR_KODE', 
            'Kode kantor tidak valid di settings. Silakan atur kode kantor 3 digit di menu Konfigurasi.'
          );
        }
      }

      if (csvFiles.isEmpty) {
        return ImportResult.error('NO_CSV_FILES', 'Tidak ada file CSV ditemukan di direktori');
      }

      // PKPM/PPM file detection (NEW)
      bool _isPkpmboFile(String path) {
        final fileName = path.split(Platform.pathSeparator).last;
        // Match any file containing PKM or PPM (case-insensitive)
        return fileName.toUpperCase().contains('PKM') || fileName.toUpperCase().contains('PPM');
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
        final fileName = file.path.split(Platform.pathSeparator).last;
        if (kantorKode.isNotEmpty && kodeFromFile != kantorKode) {
          results['SEKSI-$kodeFromFile'] = ImportResult.error(
            'KANTOR_MISMATCH',
            'Kode kantor $kodeFromFile tidak sesuai dengan settings ($kantorKode)'
          );
          totalErrors++;
          allErrors.add('SEKSI-$kodeFromFile: Kode kantor tidak sesuai');
          continue;
        }
        final content = await file.readAsString();
        final lines = content.split('\n');
        final totalRows = lines.length - 1;
  if (onProgress != null) onProgress(0.0, 0, totalRows, fileName);
        int currentRow = 0;
        final result = await _importSeksiFile(file);
  updateProgress(onProgress, currentRow, totalRows, fileName);
        results['SEKSI-$kodeFromFile'] = result;
        totalSuccess += result.successCount;
        totalErrors += result.errorCount;
        allErrors.addAll(result.errors);
      }

      // 2. Import PEGAWAI files
      final pegawaiFiles = csvFiles.where((f) => _isPegawaiFile(f.path)).toList();
      for (final file in pegawaiFiles) {
        final kodeFromFile = _extractKodeFromPegawaiFile(file.path);
        final fileName = file.path.split(Platform.pathSeparator).last;
        if (kantorKode.isNotEmpty && kodeFromFile != kantorKode) {
          results['PEGAWAI-$kodeFromFile'] = ImportResult.error(
            'KANTOR_MISMATCH',
            'Kode kantor $kodeFromFile tidak sesuai dengan settings ($kantorKode)'
          );
          totalErrors++;
          allErrors.add('PEGAWAI-$kodeFromFile: Kode kantor tidak sesuai');
          continue;
        }
        final content = await file.readAsString();
        final lines = content.split('\n');
        final totalRows = lines.length - 1;
        if (onProgress != null) onProgress(0.0, 0, totalRows, fileName);
        int currentRow = 0;
        final result = await _importPegawaiFile(file);
  updateProgress(onProgress, currentRow, totalRows, fileName);
        results['PEGAWAI-$kodeFromFile'] = result;
        totalSuccess += result.successCount;
        totalErrors += result.errorCount;
        allErrors.addAll(result.errors);
      }

      // 3. Import USER files (NEW: office code validation)
      final userFiles = csvFiles.where((f) => _isUserFile(f.path)).toList();
      for (final file in userFiles) {
        final kodeFromFile = _extractKodeFromUserFile(file.path);
        final fileName = file.path.split(Platform.pathSeparator).last;
        if (kantorKode.isNotEmpty && kodeFromFile != kantorKode) {
          results['USER-$kodeFromFile'] = ImportResult.error(
            'KANTOR_MISMATCH',
            'Kode kantor $kodeFromFile tidak sesuai dengan settings ($kantorKode)'
          );
          totalErrors++;
          allErrors.add('USER-$kodeFromFile: Kode kantor tidak sesuai');
          continue;
        }
        final content = await file.readAsString();
        final lines = content.split('\n');
        final totalRows = lines.length - 1;
        if (onProgress != null) onProgress(0.0, 0, totalRows, fileName);
        int currentRow = 0;
        final result = await _importUserFile(file);
        updateProgress(onProgress, currentRow, totalRows, fileName);
        results['USER-$kodeFromFile'] = result;
        totalSuccess += result.successCount;
        totalErrors += result.errorCount;
        allErrors.addAll(result.errors);
      }

      // 4. Import RENPEN files
      final renpenFiles = csvFiles.where((f) => _isRenpenFile(f.path)).toList();
      for (final file in renpenFiles) {
        final kodeFromFile = _extractKodeFromRenpenFile(file.path);
        final fileName = file.path.split(Platform.pathSeparator).last;
        if (kodeFromFile != kantorKode) {
          results[fileName] = ImportResult.error(
            'KANTOR_MISMATCH',
            'Kode kantor $kodeFromFile tidak sesuai dengan settings ($kantorKode)'
          );
          totalErrors++;
          allErrors.add('$fileName: Kode kantor tidak sesuai');
          continue;
        }
        final content = await file.readAsString();
        final lines = content.split('\n');
        final totalRows = lines.length - 1;
        if (onProgress != null) onProgress(0.0, 0, totalRows, fileName);
        int currentRow = 0;
        final result = await _importRenpenFile(file);
        updateProgress(onProgress, currentRow, totalRows, fileName);
        results[fileName] = result;
        totalSuccess += result.successCount;
        totalErrors += result.errorCount;
        allErrors.addAll(result.errors);
      }

      // 5. Import PKPM/PPM files (NEW)
      final pkpmboFiles = csvFiles.where((f) => _isPkpmboFile(f.path)).toList();
      print('[DEBUG] Found PKPM/PPM files: ${pkpmboFiles.map((f) => f.path).toList()}');
      for (final file in pkpmboFiles) {
        print('[DEBUG] Importing PKPM/PPM file: ${file.path}');
        final fileName = file.path.split(Platform.pathSeparator).last;
        final fileNameOnly = file.path.split(Platform.pathSeparator).last;
        final content = await file.readAsString();
        final lines = content.split('\n');
        final totalRows = lines.length - 1;
        if (onProgress != null) onProgress(0.0, 0, totalRows, fileName);
        int currentRow = 0;
        // PKPM/PPM files do NOT use kantor.kode validation, use their own validation system
        final result = await CsvImportService.importPkpmboCsvFiles(
          file,
          fileNameOnly,
          onProgress: onProgress != null
            ? (double p, int row, int total) => onProgress(p, row, total, fileName)
            : null,
        );
        updateProgress(onProgress, currentRow, totalRows, fileName);
        print('[DEBUG] Import result for $fileName: success=${result.successCount}, error=${result.errorCount}');
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

  static bool _isRenpenFile(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    return RegExp(r'^RENPEN-\w{3}-\d{4}\.csv$', caseSensitive: false).hasMatch(fileName);
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

  static String _extractKodeFromRenpenFile(String path) {
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

    final kantorKodeSettings = await _getOfficeCodeFromDatabase();
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
          if (data.length < AppConstants.seksiColumnCount) {
            errors.add('$fileName baris ${i + 1}: Kolom tidak lengkap');
            errorCount++;
            continue;
          }

          // Strict validation: KANTOR field must match both filename KODE_KANTOR and settings value
          if (data[1] != kodeKantor || data[1] != kantorKodeSettings) {
            errors.add('$fileName baris ${i + 1}: KANTOR ${data[1]} tidak sesuai dengan file $kodeKantor dan settings $kantorKodeSettings');
            errorCount++;
            continue;
          }

          // Insert into database
          await DatabaseService.insert(AppConstants.tableSeksi, {
            'id': int.tryParse(data[0]) ?? 0,
            'kantor': data[1],
            'tipe': int.tryParse(data[2]) ?? 0,
            'nama': data[3]
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
  final kantorKodeSettings = await _getOfficeCodeFromDatabase();

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
          if (data.length < AppConstants.pegawaiColumnCount) {
            errors.add('$fileName baris ${i + 1}: Kolom tidak lengkap');
            errorCount++;
            continue;
          }

          // Strict validation: KANTOR field must match both filename KODE_KANTOR and settings value
          if (data[0] != kodeKantor || data[0] != kantorKodeSettings) {
            errors.add('$fileName baris ${i + 1}: KANTOR ${data[0]} tidak sesuai dengan file $kodeKantor dan settings $kantorKodeSettings');
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
          if (data.length < AppConstants.userColumnCount) {
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

  static Future<ImportResult> _importRenpenFile(File file) async {
    try {
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      if (lines.isEmpty) {
        return ImportResult.error(AppConstants.importErrorContent, 'File kosong');
      }

      // Validate header
      final header = lines[0].trim();
      if (header != AppConstants.renpenHeaderFormat) {
        return ImportResult.error(
          AppConstants.importErrorHeader,
          'Header harus: ${AppConstants.renpenHeaderFormat}'
        );
      }

      final fileName = file.path.split(Platform.pathSeparator).last;
      final parts = fileName.split('-');
      final kodeKantor = parts[1];
      final tahun = int.tryParse(parts[2].split('.')[0]) ?? DateTime.now().year;

      // Delete existing RENPEN data for this office and year (Qt legacy behavior)
      await DatabaseService.delete(
        AppConstants.tableRenpen, 
        'kpp = ? AND tahun = ?', 
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
          if (data.length < AppConstants.renpenColumnCount) {
            errors.add('$fileName baris ${i + 1}: Kolom tidak lengkap');
            errorCount++;
            continue;
          }

          // Insert into database with admin field from filename (Qt legacy behavior)
          await DatabaseService.insert(AppConstants.tableRenpen, {
            'kpp': data[0],
            'nip': data[1],
            'kdmap': data[2], 
            'bulan': int.tryParse(data[3])?? 1,  
            'tahun': int.tryParse(data[4])?? tahun,     
            'target': int.tryParse(data[5]) ?? 0.0
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