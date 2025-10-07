import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:crypto/crypto.dart';
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
    final kantorKode = await getOfficeCodeFromDatabase();
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

  /// Import Rencana Penerimaan data from CSV file
  /// File format: RENPEN-{KODE_KANTOR}-{TAHUN}.csv
  /// Header: KPP;NIP;KDMAP;BULAN;TAHUN;TARGET
  static Future<ImportResult> importRencanaPenerimaan() async {
    final result = await _pickFile('Import Rencana Penerimaan');
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
      if (header != 'KPP;NIP;KDMAP;BULAN;TAHUN;TARGET') {
        return ImportResult.error(
          AppConstants.importErrorHeader, 
          'Header harus: KPP;NIP;KDMAP;BULAN;TAHUN;TARGET'
        );
      }

      // Validate filename format (STRICT: Exact pattern for function detection)
      final fileName = result.files.single.name;
      if (!RegExp(r'^RENPEN-\w{3}-\d{4}\.csv$').hasMatch(fileName)) {
        return ImportResult.error(
          AppConstants.importErrorFilename,
          'Format nama file: RENPEN-{KODE_KANTOR}-{TAHUN}.csv'
        );
      }

      // Extract office code and year from filename (STRICT: Position-based)
      final parts = fileName.split('-');
      final kodeKantor = parts[1];
      final tahun = int.tryParse(parts[2].split('.')[0]) ?? DateTime.now().year;

      // Validate office code against current office settings (database-based)
  final kantorKode = await getOfficeCodeFromDatabase();
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

      // Delete existing Rencana Penerimaan data for this office and year (Qt legacy behavior)
      await DatabaseService.delete(
        AppConstants.tableRenpen, 
        'kpp = ? AND tahun = ?', 
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
          if (data.length < 6) {
            errors.add('Baris ${i + 1}: Kolom tidak lengkap');
            errorCount++;
            continue;
          }

          // Validate NIP exists in PEGAWAI table (business rule)
          final nipExists = await DatabaseService.query(
            AppConstants.tablePegawai,
            where: 'nip = ?',
            whereArgs: [data[1]]
          );
          if (nipExists.isEmpty) {
            errors.add('Baris ${i + 1}: NIP ${data[1]} tidak ditemukan dalam tabel pegawai');
            errorCount++;
            continue;
          }

          // Insert into database
          await DatabaseService.insert(AppConstants.tableRenpen, {
            'kpp': data[0],                               // KPP field
            'nip': data[1],                               // NIP field
            'kdmap': data[2],                             // KDMAP field
            'bulan': int.tryParse(data[3]) ?? 1,          // BULAN field
            'tahun': int.tryParse(data[4]) ?? tahun,      // TAHUN field
            'target': double.tryParse(data[5]) ?? 0.0,    // TARGET field
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

  /// Import PKPM/PPM CSV files to DRM_PPMPKM table
  /// Supports multiple header patterns and filename patterns
  static Future<ImportResult> importPkpmboCsvFiles(File file, String sourceContext, {void Function(double progress, int currentRow, int totalRows)? onProgress}) async {

    print('[DEBUG] importPkpmboCsvFiles called for file: ${file.path}, sourceContext: $sourceContext');
    final content = await file.readAsString();
    final lines = content.split('\n');
    if (lines.isEmpty) {
      print('[DEBUG] File is empty');
      return ImportResult.error('IMPORT_ERROR_CONTENT', 'File kosong');
    }

    // For progress callback
    final totalRows = lines.length - 1;

    // Calculate SHA-1 hash of the file
    final fileBytes = await file.readAsBytes();
    final fileHash = _sha1Hex(fileBytes);
    print('[DEBUG] Calculated file hash: $fileHash');

    // Detect header pattern
    final header = lines[0].replaceAll('"', '').replaceAll("'", '').trim();
    final validHeaders = [
      'KD_KANWIL,KPPADM,NPWP,NO PRODUK HUKUM,NO PBK,NTPN,TGL SETOR,THN SETOR,BLN SETOR,THN PAJAK,MASA PAJAK,JML SETOR,KODE MAP,KODE SETOR,ID SBR DATA',
      'KD_KANWIL,KPPADM,NPWP,NO PBK,NTPN,TGL SETOR,THN SETOR,BLN SETOR,THN PAJAK,MASA PAJAK,JML SETOR,KODE MAP,KODE SETOR,ID SBR DATA',
      'KD_KANWIL,KPPADM,NPWP,NO PBK,NTPN,TGL SETOR,THN SETOR,BLN SETOR,THN PAJAK,MASA PAJAK,JML SETOR,KODE MAP,KODE SETOR,ID_SBR_DATA',
      'KD_KANWIL,KPPADM,NPWP,NO PBK,NTPN,TGL SETOR,THN SETOR,BLN SETOR,THN PAJAK,MASA PAJAK,JML SETOR,KODE MAP,KODE SETOR,FLAG SKP,ID SBR DATA',
    ];
    print('[DEBUG] Header detected: $header');
    if (!validHeaders.contains(header)) {
      print('[DEBUG] Header not recognized, aborting import');
      return ImportResult.error('IMPORT_ERROR_HEADER', 'Header tidak dikenali: $header');
    }

    // Check if this file hash already exists in ppmpkmbo table
    final existing = await DatabaseService.query(
      'ppmpkmbo',
      where: 'FILE_HASH = ?',
      whereArgs: [fileHash],
      limit: 1,
    );
    print('[DEBUG] Existing file hash found: ${existing.isNotEmpty}');
    if (existing.isNotEmpty) {
      // Show confirmation dialog to user
      final shouldReimport = await _showReimportConfirmationDialog(fileHash, existing.first['SOURCE'], existing.first['created_at']);
      print('[DEBUG] Reimport confirmation: $shouldReimport');
      if (!shouldReimport) {
        return ImportResult.error('IMPORT_SKIPPED', 'File sudah pernah diimport (hash: $fileHash)');
      }
    }

    // Map columns based on header
    final isProdukHukum = header.contains('NO PRODUK HUKUM');
    final hasFlagSkp = header.contains('FLAG SKP');

    int successCount = 0;
    int errorCount = 0;
    final errors = <String>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      // Progress callback
      if (onProgress != null) {
        onProgress(i / totalRows, i, totalRows);
      }
      print('[DEBUG] Importing row $i/$totalRows: $line');
      try {
        final data = line.split(',');
        int idx = 0;
        final row = <String, dynamic>{};
        row['KD_KANWIL'] = data[idx++];
        row['KPPADM'] = data[idx++];
        row['NPWP'] = data[idx++];
        if (isProdukHukum) idx++; // skip NO PRODUK HUKUM
        row['NO_PBK'] = data[idx++];
        row['NTPN'] = data[idx++];
        row['TGL_SETOR'] = data[idx++];
        row['THN_SETOR'] = int.tryParse(data[idx++]) ?? 0;
        row['BLN_SETOR'] = int.tryParse(data[idx++]) ?? 0;
        row['THN_PAJAK'] = int.tryParse(data[idx++]) ?? 0;
        row['MASA_PAJAK'] = data[idx++];
        row['JML_SETOR'] = double.tryParse(data[idx++].replaceAll('"', '')) ?? 0.0;
        row['KD_MAP'] = data[idx++];
        row['KD_SETOR'] = data[idx++];
        if (hasFlagSkp) idx++; // skip FLAG SKP
        row['ID_SBR_DATA'] = data[idx++];

        // Add SOURCE from context (filename or folder)
        row['SOURCE'] = sourceContext;
        row['FILE_HASH'] = fileHash;

        // Apply rules for VOLUNTARY
        if (row['SOURCE'].toString().toUpperCase().contains('WRA')) {
          row['VOLUNTARY'] = 'W';
        } else if (row['SOURCE'].toString().toUpperCase().contains('AKTIVITAS')) {
          row['VOLUNTARY'] = 'N';
        } else {
          row['VOLUNTARY'] = 'Y';
        }

        // Apply rules for FLAG_PKPM
        if (row['SOURCE'].toString().toUpperCase().contains('PKM')) {
          row['FLAG_PKPM'] = 'PKM';
        } else {
          row['FLAG_PKPM'] = 'PPM';
        }

        // Apply rules for FLAG_BO
        final src = row['SOURCE'].toString().toUpperCase();
        if (src.contains('LAINNYA')) {
          row['FLAG_BO'] = 'PENGAWASAN';
        } else if (src.contains('PEMERIKSAAN')) {
          row['FLAG_BO'] = 'PEMERIKSAAN';
        } else if (src.contains('PENAGIHAN')) {
          row['FLAG_BO'] = 'PENAGIHAN';
        } else if (src.contains('PENGAWASAN')) {
          row['FLAG_BO'] = 'PENGAWASAN';
        } else if (src.contains('PENEGAKAN')) {
          row['FLAG_BO'] = 'GAKKUM';
        } else if (src.contains('EDUKASI')) {
          row['FLAG_BO'] = 'EDUKASI';
        }

        // Insert into ppmpkmbo table
        print('[DEBUG] Inserting row into ppmpkmbo: $row');
        await DatabaseService.insert('ppmpkmbo', row);
        successCount++;
      } catch (e) {
        print('[DEBUG] Error importing row $i: $e');
        errors.add('Baris ${i + 1}: ${e.toString()}');
        errorCount++;
      }
    }

    print('[DEBUG] PKPM/PPM import finished: success=$successCount, error=$errorCount');
    return ImportResult.success(
      message: '$successCount data berhasil diimport, $errorCount error',
      successCount: successCount,
      errorCount: errorCount,
      errors: errors,
    );
  }

  /// Show confirmation dialog for re-import if file hash already exists
  static Future<bool> _showReimportConfirmationDialog(String fileHash, dynamic source, dynamic createdAt) async {
    // This function should be called from a context where BuildContext is available
    // For now, use a placeholder implementation. Integrate with UI as needed.
    // You can use showDialog in Flutter to show a confirmation dialog.
    // Example:
    // return await showDialog<bool>(
    //   context: context,
    //   builder: (context) => AlertDialog(
    //     title: Text('File sudah diimport'),
    //     content: Text('File dengan hash $fileHash sudah diimport pada $createdAt dari $source.\nIngin re-import?'),
    //     actions: [
    //       TextButton(child: Text('Tidak'), onPressed: () => Navigator.of(context).pop(false)),
    //       TextButton(child: Text('Ya'), onPressed: () => Navigator.of(context).pop(true)),
    //     ],
    //   ),
    // ) ?? false;
    // For non-UI context, always return false (skip re-import)
    return false;
  }

  /// Calculate SHA-1 hash and return as hex string
  static String _sha1Hex(List<int> bytes) {
  // Use Dart's crypto library
  // If not available, you need to add `crypto: ^3.0.0` to pubspec.yaml
  return sha1.convert(bytes).toString();
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
  static Future<String> getOfficeCodeFromDatabase() async {
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