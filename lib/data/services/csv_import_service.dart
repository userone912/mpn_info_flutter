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

      // Validate filename format
      final fileName = result.files.single.name;
      if (!RegExp(r'^SEKSI-\w{3}\.csv$').hasMatch(fileName)) {
        return ImportResult.error(
          AppConstants.importErrorFilename,
          'Format nama file: ${AppConstants.seksiFilePattern}'
        );
      }

      // Extract office code from filename
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

      // Validate filename format
      final fileName = result.files.single.name;
      if (!RegExp(r'^PEGAWAI-\w{3}\.csv$').hasMatch(fileName)) {
        return ImportResult.error(
          AppConstants.importErrorFilename,
          'Format nama file: ${AppConstants.pegawaiFilePattern}'
        );
      }

      // Extract office code from filename
      final kodeKantor = fileName.split('-')[1].split('.')[0];

      // Process data lines
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
            errors.add('Baris ${i + 1}: Kolom tidak lengkap');
            errorCount++;
            continue;
          }

          // Insert into database
          await DatabaseService.insert(AppConstants.tablePegawai, {
            'kantor': data[0],
            'nip': data[1],
            'nip2': data[2],
            'nama': data[3],
            'pangkat': data[4],
            'seksi': int.tryParse(data[5]) ?? 0,
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

          // Check if username already exists
          final existing = await DatabaseService.query(
            AppConstants.tableUsers,
            where: 'username = ?',
            whereArgs: [data[1]],
            limit: 1,
          );

          if (existing.isNotEmpty) {
            errors.add('Baris ${i + 1}: Username ${data[1]} sudah ada');
            errorCount++;
            continue;
          }

          // Insert into database
          await DatabaseService.insert(AppConstants.tableUsers, {
            'id': int.tryParse(data[0]) ?? 0,
            'username': data[1],
            'password': data[2], // Password should be already hashed in CSV
            'fullname': data[3],
            'group_type': int.tryParse(data[4]) ?? 2, // Default to guest
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

      // Validate filename format
      final fileName = result.files.single.name;
      if (!RegExp(r'^SPMKP-\w{3}-\d{4}\.csv$').hasMatch(fileName)) {
        return ImportResult.error(
          AppConstants.importErrorFilename,
          'Format nama file: ${AppConstants.spmkpFilePattern}'
        );
      }

      // Extract office code and year from filename
      final parts = fileName.split('-');
      final kodeKantor = parts[1];
      final tahun = int.tryParse(parts[2].split('.')[0]) ?? DateTime.now().year;

      // Process data lines
      int successCount = 0;
      int errorCount = 0;
      final errors = <String>[];

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

          // Insert into database
          await DatabaseService.insert(AppConstants.tableSpmkp, {
            'admin': kodeKantor,
            'npwp': data[1],
            'kpp': data[2],
            'cabang': data[3],
            'kdmap': data[4],
            'bulan': int.tryParse(data[5]) ?? 1,
            'tahun': int.tryParse(data[6]) ?? tahun,
            'tanggal': DateTime.now(), // Current date as default
            'nominal': double.tryParse(data[7]) ?? 0.0,
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
}