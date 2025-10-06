import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/import_result.dart';
import '../../core/constants/app_constants.dart';
import 'database_service.dart';

/// CSV Import Service
/// Handles file import operations similar to Qt application
class CsvImportService {
  
  /// Import Seksi data from CSV file
  /// File format: SEKSI-{KODE_KANTOR}.csv
  /// Header: ID;KANTOR;TIPE;NAMA;KODE;TELP
  static Future<ImportResult> importSeksi() async {
    final result = await _pickFile('Import Seksi');
    if (result == null) return ImportResult.cancelled();

    try {
      final file = File(result.files.single.path!);
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

      // Validate filename format (STRICT: Exact pattern for function detection)
      final fileName = result.files.single.name;
      if (!RegExp(r'^SEKSI-\w{3}\.csv$').hasMatch(fileName)) {
        return ImportResult.error(
          AppConstants.importErrorFilename,
          'Format nama file: ${AppConstants.seksiFilePattern}'
        );
      }

      // Extract office code from filename (STRICT: Position-based)
      final kodeKantor = fileName.split('-')[1].split('.')[0];

      // Process data lines
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
            errors.add('Baris ${i + 1}: Kolom tidak lengkap');
            errorCount++;
            continue;
          }

          // Validate that KANTOR field matches filename KODE_KANTOR (Qt legacy behavior)
          final kantorField = data[1];
          if (kantorField != kodeKantor) {
            errors.add('Baris ${i + 1}: KANTOR field ($kantorField) tidak sesuai dengan filename ($kodeKantor)');
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
          errors.add('Baris ${i + 1}: ${e.toString()}');
          errorCount++;
        }
      }

      return ImportResult.success(
        message: '$successCount data berhasil diimport, $errorCount error',
        successCount: successCount,
        errorCount: errorCount,
        errors: errors,
      );

    } catch (e) {
      return ImportResult.error(AppConstants.importErrorOpenFile, e.toString());
    }
  }

  /// Import Pegawai data from CSV file
  /// File format: PEGAWAI-{KODE_KANTOR}.csv
  /// Header: KANTOR;NIP;NIP2;NAMA;PANGKAT;SEKSI;JABATAN;TAHUN
  static Future<ImportResult> importPegawai() async {
    final result = await _pickFile('Import Pegawai');
    if (result == null) return ImportResult.cancelled();

    try {
      final file = File(result.files.single.path!);
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

      // Validate filename format (STRICT: Exact pattern for function detection)
      final fileName = result.files.single.name;
      if (!RegExp(r'^PEGAWAI-\w{3}\.csv$').hasMatch(fileName)) {
        return ImportResult.error(
          AppConstants.importErrorFilename,
          'Format nama file: ${AppConstants.pegawaiFilePattern}'
        );
      }

      // Extract office code from filename (STRICT: Position-based)
      final kodeKantor = fileName.split('-')[1].split('.')[0];

      // Process data lines
      int successCount = 0;
      int errorCount = 0;
      final errors = <String>[];

      // Clear existing data for this office (Qt uses 'kpp' field for pegawai)
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
            errors.add('Baris ${i + 1}: Kolom tidak lengkap');
            errorCount++;
            continue;
          }

          // Validate that KANTOR field matches filename KODE_KANTOR (Qt legacy behavior)
          final kantorField = data[0];
          if (kantorField != kodeKantor) {
            errors.add('Baris ${i + 1}: KANTOR field ($kantorField) tidak sesuai dengan filename ($kodeKantor)');
            errorCount++;
            continue;
          }

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
          errors.add('Baris ${i + 1}: ${e.toString()}');
          errorCount++;
        }
      }

      return ImportResult.success(
        message: '$successCount data berhasil diimport, $errorCount error',
        successCount: successCount,
        errorCount: errorCount,
        errors: errors,
      );

    } catch (e) {
      return ImportResult.error(AppConstants.importErrorOpenFile, e.toString());
    }
  }

  /// Import User data from CSV file
  /// File format: USER-{KODE_KANTOR}.csv
  /// Header: ID;USERNAME;PASSWORD;FULLNAME;GROUP
  static Future<ImportResult> importUser() async {
    final result = await _pickFile('Import User');
    if (result == null) return ImportResult.cancelled();

    try {
      final file = File(result.files.single.path!);
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

      // Validate filename format (STRICT: Exact pattern for function detection)
      final fileName = result.files.single.name;
      if (!RegExp(r'^USER-\w{3}\.csv$').hasMatch(fileName)) {
        return ImportResult.error(
          AppConstants.importErrorFilename,
          'Format nama file: ${AppConstants.userFilePattern}'
        );
      }

      // Extract office code from filename (STRICT: Position-based)
      final kodeKantor = fileName.split('-')[1].split('.')[0];

      // Validate against current office settings (database-based)
      final kantorKode = await _getOfficeCodeFromDatabase();
      if (kantorKode.isEmpty || kantorKode.length != 3) {
        return ImportResult.error(
          AppConstants.importErrorOfficeCode,
          'Kode kantor tidak valid di settings. Silakan atur kode kantor 3 digit di menu Konfigurasi.'
        );
      }
      
      if (kantorKode != kodeKantor) {
        return ImportResult.error(
          AppConstants.importErrorOfficeCode,
          'File untuk kantor $kodeKantor, saat ini kantor $kantorKode'
        );
      }

      // Process data lines
      int successCount = 0;
      int errorCount = 0;
      final errors = <String>[];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        try {
          final data = _parseCsvLine(line);
          if (data.length < 5) {
            errors.add('Baris ${i + 1}: Kolom tidak lengkap');
            errorCount++;
            continue;
          }

          final userId = int.tryParse(data[0]) ?? 0;
          final username = data[1];
          final password = data[2];
          final fullname = data[3];
          final groupType = int.tryParse(data[4]) ?? 2;

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

          // Qt legacy behavior: Check if user ID exists (not username)
          final existing = await DatabaseService.query(
            AppConstants.tableUsers,
            where: 'id = ?',
            whereArgs: [userId],
            limit: 1,
          );

          if (existing.isNotEmpty) {
            // UPDATE existing user (Qt legacy behavior)
            await DatabaseService.update(
              AppConstants.tableUsers,
              {
                'username': username,
                'password': password,
                'fullname': fullname,
                'group_type': groupType,
              },
              'id = ?',
              [userId],
            );
          } else {
            // INSERT new user
            await DatabaseService.insert(AppConstants.tableUsers, {
              'id': userId,
              'username': username,
              'password': password,
              'fullname': fullname,
              'group_type': groupType,
            });
          }

          successCount++;
        } catch (e) {
          errors.add('Baris ${i + 1}: ${e.toString()}');
          errorCount++;
        }
      }

      return ImportResult.success(
        message: '$successCount data berhasil diimport, $errorCount error',
        successCount: successCount,
        errorCount: errorCount,
        errors: errors,
      );

    } catch (e) {
      return ImportResult.error(AppConstants.importErrorOpenFile, e.toString());
    }
  }

  /// Import SPMKP data from CSV file
  /// File format: SPMKP-{KODE_KANTOR}-{TAHUN}.csv
  /// Header: ID;NPWP;KPP;CABANG;KDMAP;BULAN;TAHUN;NOMINAL
  static Future<ImportResult> importSpmkp() async {
    final result = await _pickFile('Import SPMKP');
    if (result == null) return ImportResult.cancelled();

    try {
      final file = File(result.files.single.path!);
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

      // Validate filename format (STRICT: Exact pattern for function detection)
      final fileName = result.files.single.name;
      if (!RegExp(r'^SPMKP-\w{3}-\d{4}\.csv$').hasMatch(fileName)) {
        return ImportResult.error(
          AppConstants.importErrorFilename,
          'Format nama file: ${AppConstants.spmkpFilePattern}'
        );
      }

      // Extract office code and year from filename (STRICT: Position-based)
      final parts = fileName.split('-');
      final kodeKantor = parts[1];
      final tahun = int.tryParse(parts[2].split('.')[0]) ?? DateTime.now().year;

      // Validate office code (Qt legacy behavior: must be "000" or valid 3-digit KPP)
      if (kodeKantor.length != 3) {
        return ImportResult.error(
          AppConstants.importErrorFilename,
          'Kode kantor harus 3 digit'
        );
      }

      // Delete existing SPMKP data for this office and year (Qt legacy behavior)
      await DatabaseService.delete(
        AppConstants.tableSpmkp, 
        'admin = ? AND tahun = ?', 
        [kodeKantor, tahun]
      );

      // Process data lines
      int successCount = 0;
      int errorCount = 0;
      final errors = <String>[];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        try {
          final data = _parseCsvLine(line);
          if (data.length < 7) {
            errors.add('Baris ${i + 1}: Kolom tidak lengkap');
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
          errors.add('Baris ${i + 1}: ${e.toString()}');
          errorCount++;
        }
      }

      return ImportResult.success(
        message: '$successCount data berhasil diimport, $errorCount error',
        successCount: successCount,
        errorCount: errorCount,
        errors: errors,
      );

    } catch (e) {
      return ImportResult.error(AppConstants.importErrorOpenFile, e.toString());
    }
  }

  /// Pick a CSV file using file picker
  static Future<FilePickerResult?> _pickFile(String title) async {
    return await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      dialogTitle: title,
    );
  }

  /// Parse CSV line handling quoted fields and semicolon separator
  static List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    bool inQuotes = false;
    final buffer = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ';' && !inQuotes) {
        fields.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    
    // Add the last field
    fields.add(buffer.toString().trim());
    
    return fields;
  }

  /// Get office code from database settings table
  static Future<String> _getOfficeCodeFromDatabase() async {
    try {
      final result = await DatabaseService.query(
        AppConstants.tableSettings,
        where: 'key = ?',
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
}