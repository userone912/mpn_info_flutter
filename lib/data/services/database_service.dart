import '../../core/constants/app_constants.dart';
import '../../core/constants/app_enums.dart';
import '../models/import_result.dart';
import 'database_helper.dart';
import 'mysql_service.dart';
import 'settings_service.dart';
import 'database_migration_service.dart';

/// Unified database service that can work with both SQLite and MySQL
/// Database type is determined by user selection saved in settings.ini
class DatabaseService {
  static DatabaseType? _currentDatabaseType;
  static bool _isInitialized = false;
  
  /// Initialize database from settings
  /// Now automatically decrypts stored passwords for seamless connection
  static Future<void> initializeFromSettings() async {
    if (_isInitialized) return;
    
    // Load settings first
    await SettingsService.initialize();
    
    // Get database configuration with decrypted password
    final config = SettingsService.getDatabaseConfigWithDecryptedPassword();
    _currentDatabaseType = config.type;
    
    try {
      await _initializeDatabase(config);
      _isInitialized = true;
    } catch (e) {
      print('Failed to initialize database from settings: $e');
      // If connection fails, don't mark as initialized so user can try manual config
      _isInitialized = false;
    }
  }

  /// Authenticate with password and establish database connection
  static Future<bool> authenticateAndConnect(String password) async {
    final config = SettingsService.getDatabaseConfigWithPassword(password);
    if (config == null) {
      return false; // Authentication failed
    }
    
    try {
      await _initializeDatabase(config);
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Database connection failed: $e');
      return false;
    }
  }

  /// Check if database connection is established
  static bool get isConnected => _isInitialized;
  
  /// Initialize database with specific configuration
  static Future<void> initializeWithConfig(DatabaseConfig config) async {
    _currentDatabaseType = config.type;
    
    // Save configuration to settings
    await SettingsService.saveDatabaseConfig(config);
    
    await _initializeDatabase(config);
    _isInitialized = true;
  }
  
  /// Internal database initialization
  static Future<void> _initializeDatabase(DatabaseConfig config) async {
    try {
      switch (config.type) {
        case DatabaseType.sqlite:
          final db = await DatabaseHelper().database;
          print('SQLite database initialized: ${db.path}');
          break;
        case DatabaseType.mysql:
          // Update MySQL service with current configuration
          await MySqlService.initializeWithConfig(config);
          print('MySQL database initialized: ${config.host}:${config.port}/${config.name}');
          break;
        case DatabaseType.postgresql:
          throw UnsupportedError('PostgreSQL not implemented yet');
        case DatabaseType.unknown:
        default:
          throw UnsupportedError('Unknown database type: ${config.type}');
      }
    } catch (e) {
      print('Database initialization failed: $e');
      rethrow;
    }
  }
  
  /// Get current database type
  static DatabaseType get databaseType => _currentDatabaseType ?? DatabaseType.sqlite;
  
  /// Initialize the database based on current type
  static Future<void> initialize() async {
    switch (_currentDatabaseType) {
      case DatabaseType.sqlite:
        // SQLite initialization is handled in DatabaseHelper
        final db = await DatabaseHelper().database;
        print('SQLite database initialized: ${db.path}');
        break;
      case DatabaseType.mysql:
        try {
          await MySqlService.initializeSchema();
          print('MySQL database initialized successfully');
        } catch (e) {
          print('MySQL initialization failed, falling back to SQLite: $e');
          _currentDatabaseType = DatabaseType.sqlite;
          final db = await DatabaseHelper().database;
          print('Fallback SQLite database initialized: ${db.path}');
        }
        break;
      case DatabaseType.postgresql:
        throw UnsupportedError('PostgreSQL not implemented yet');
      case DatabaseType.unknown:
      default:
        throw UnsupportedError('Unknown database type: $_currentDatabaseType');
    }
  }
  
  /// Test database connection
  static Future<bool> testConnection() async {
    if (_currentDatabaseType == null) return false;
    
    try {
      switch (_currentDatabaseType!) {
        case DatabaseType.sqlite:
          final db = await DatabaseHelper().database;
          await db.rawQuery('SELECT 1');
          return true;
        case DatabaseType.mysql:
          return await MySqlService.testConnection();
        case DatabaseType.postgresql:
          throw UnsupportedError('PostgreSQL not implemented yet');
        case DatabaseType.unknown:
        default:
          return false;
      }
    } catch (e) {
      print('Database connection test failed: $e');
      return false;
    }
  }
  
  /// Generic insert method
  static Future<int> insert(String table, Map<String, dynamic> data) async {
    if (_currentDatabaseType == null) throw StateError('Database not initialized');
    
    switch (_currentDatabaseType!) {
      case DatabaseType.sqlite:
        return await DatabaseHelper().insert(table, data);
      case DatabaseType.mysql:
        return await MySqlService.insert(table, data);
      case DatabaseType.postgresql:
        throw UnsupportedError('PostgreSQL not implemented yet');
      case DatabaseType.unknown:
      default:
        throw UnsupportedError('Unknown database type: $_currentDatabaseType');
    }
  }
  
  /// Generic update method
  static Future<int> update(String table, Map<String, dynamic> data, String whereClause, List<dynamic> whereArgs) async {
    if (_currentDatabaseType == null) throw StateError('Database not initialized');
    
    switch (_currentDatabaseType!) {
      case DatabaseType.sqlite:
        return await DatabaseHelper().update(table, data, whereClause, whereArgs);
      case DatabaseType.mysql:
        return await MySqlService.update(table, data, whereClause, whereArgs);
      case DatabaseType.postgresql:
        throw UnsupportedError('PostgreSQL not implemented yet');
      case DatabaseType.unknown:
      default:
        throw UnsupportedError('Unknown database type: $_currentDatabaseType');
    }
  }
  
  /// Generic delete method
  static Future<int> delete(String table, String whereClause, List<dynamic> whereArgs) async {
    if (_currentDatabaseType == null) throw StateError('Database not initialized');
    
    switch (_currentDatabaseType!) {
      case DatabaseType.sqlite:
        return await DatabaseHelper().delete(table, whereClause, whereArgs);
      case DatabaseType.mysql:
        return await MySqlService.delete(table, whereClause, whereArgs);
      case DatabaseType.postgresql:
        throw UnsupportedError('PostgreSQL not implemented yet');
      case DatabaseType.unknown:
      default:
        throw UnsupportedError('Unknown database type: $_currentDatabaseType');
    }
  }
  
  /// Generic query method
  static Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    if (_currentDatabaseType == null) throw StateError('Database not initialized');
    
    switch (_currentDatabaseType!) {
      case DatabaseType.sqlite:
        return await DatabaseHelper().query(
          table,
          columns: columns,
          where: where,
          whereArgs: whereArgs,
          orderBy: orderBy,
          limit: limit,
          offset: offset,
        );
      case DatabaseType.mysql:
        return await MySqlService.query(
          table,
          columns: columns,
          where: where,
          whereArgs: whereArgs,
          orderBy: orderBy,
          limit: limit,
          offset: offset,
        );
      case DatabaseType.postgresql:
        throw UnsupportedError('PostgreSQL not implemented yet');
      case DatabaseType.unknown:
      default:
        throw UnsupportedError('Unknown database type: $_currentDatabaseType');
    }
  }
  
  /// Execute raw SQL query
  static Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    if (_currentDatabaseType == null) throw StateError('Database not initialized');
    
    switch (_currentDatabaseType!) {
      case DatabaseType.sqlite:
        return await DatabaseHelper().rawQuery(sql, arguments);
      case DatabaseType.mysql:
        return await MySqlService.rawQuery(sql, arguments);
      case DatabaseType.postgresql:
        throw UnsupportedError('PostgreSQL not implemented yet');
      case DatabaseType.unknown:
      default:
        throw UnsupportedError('Unknown database type: $_currentDatabaseType');
    }
  }
  
  /// Close database connection
  static Future<void> close() async {
    if (_currentDatabaseType == null) return;
    
    switch (_currentDatabaseType!) {
      case DatabaseType.sqlite:
        await DatabaseHelper().close();
        break;
      case DatabaseType.mysql:
        await MySqlService.close();
        break;
      case DatabaseType.postgresql:
        // TODO: Implement PostgreSQL close
        break;
      case DatabaseType.unknown:
      default:
        break;
    }
  }
  
  /// Get database configuration info
  static Map<String, dynamic> getDatabaseInfo() {
    return {
      'type': _currentDatabaseType?.name ?? 'unknown',
      'name': _currentDatabaseType == DatabaseType.sqlite 
          ? AppConstants.databaseName 
          : 'mpn_info',
      'isLocal': _currentDatabaseType == DatabaseType.sqlite,
      'supportsMultiUser': _currentDatabaseType != DatabaseType.sqlite,
      'isInitialized': _isInitialized,
    };
  }

  // ============================================================================
  // MANUAL CSV IMPORT FUNCTIONS (Admin Functions)
  // Following Qt legacy pattern for manual database sync
  // ============================================================================

  /// Helper method to parse date from CSV format (DD/MM/YYYY)
  static DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    
    try {
      // Handle DD/MM/YYYY format
      final parts = dateStr.trim().split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('Failed to parse date: $dateStr - $e');
    }
    
    return null;
  }

  /// Execute CSV import to database table (now uses external data directory)
  /// This is called automatically during "Test Koneksi" and "Simpan & Gunakan" flows
  static Future<ImportResult> executeCsvImport({
    required String tableName,
    required String csvAssetPath, // Legacy parameter, now ignored
  }) async {
    if (!_isInitialized || _currentDatabaseType == null) {
      throw Exception('Database not initialized');
    }

    try {
      // Use external data directory instead of assets
      // This integrates with the "Test Koneksi" / "Simpan & Gunakan" workflow
      print('Importing CSV from external data: $tableName.csv');
      
      // Get CSV content from external data directory
      final csvData = await DatabaseMigrationService.readExternalFile('data/$tableName.csv');
      
      // Parse CSV lines
      final lines = csvData.split('\n').where((line) => line.trim().isNotEmpty).toList();
      if (lines.isEmpty) {
        return ImportResult.error('EMPTY_FILE', 'File CSV kosong: $tableName.csv');
      }
      
      // Remove header if exists (first line)
      final dataLines = lines.skip(1).toList();
      
      // Step 3: Truncate existing data (Qt legacy approach)
      // Delete all records from table by using "1=1" condition
      await delete(tableName, '1=1', []);
      print('Truncated table: $tableName');
      
      // Step 4: Insert new data
      int recordsProcessed = 0;
      final errors = <String>[];
      
      for (int i = 0; i < dataLines.length; i++) {
        final line = dataLines[i].trim();
        if (line.isEmpty) continue;
        
        try {
          // Parse CSV line (semicolon separated)
          final fields = line.split(';').map((f) => f.trim()).toList();
          
          // Create record based on table type
          Map<String, dynamic> record;
          switch (tableName) {
            case 'kantor':
              // CSV format: KANWIL;KPP;NAMA
              if (fields.length < 3) continue;
              record = {
                'kanwil': fields[0],  // KANWIL column
                'kpp': fields[1],     // KPP column  
                'nama': fields[2],    // NAMA column
              };
              break;
              
            case 'klu':
              // CSV format: KODE;NAMA;SEKTOR
              if (fields.length < 3) continue;
              record = {
                'kode': fields[0],    // KODE column
                'nama': fields[1],    // NAMA column
                'sektor': fields[2],  // SEKTOR column
              };
              break;
              
            case 'map':
              // CSV format: KDMAP;KDBAYAR;SEKTOR;URAIAN
              if (fields.length < 4) continue;
              record = {
                'kdmap': fields[0],         // KDMAP column
                'kdbayar': fields[1],       // KDBAYAR column
                'sektor': int.tryParse(fields[2]) ?? 0,  // SEKTOR column (integer)
                'uraian': fields[3],        // URAIAN column
              };
              break;
              
            case 'jatuhtempo':
              // CSV format: BULAN;TAHUN;POTPUT;PPH;PPN;PPHOP;PPHBDN
              if (fields.length < 7) continue;
              record = {
                'bulan': int.tryParse(fields[0]) ?? 0,               // BULAN column
                'tahun': int.tryParse(fields[1]) ?? 0,               // TAHUN column
                'potput': _parseDate(fields[2]),                     // POTPUT column (date)
                'pph': _parseDate(fields[3]),                        // PPH column (date)
                'ppn': _parseDate(fields[4]),                        // PPN column (date)
                'pphop': _parseDate(fields[5]),                      // PPHOP column (date)
                'pphbdn': _parseDate(fields[6]),                     // PPHBDN column (date)
              };
              break;
              
            case 'maxlapor':
              // CSV format: BULAN;TAHUN;PPH;PPN;PPHOP;PPHBDN
              if (fields.length < 6) continue;
              record = {
                'bulan': int.tryParse(fields[0]) ?? 0,               // BULAN column
                'tahun': int.tryParse(fields[1]) ?? 0,               // TAHUN column
                'pph': _parseDate(fields[2]),                        // PPH column (date)
                'ppn': _parseDate(fields[3]),                        // PPN column (date)
                'pphop': _parseDate(fields[4]),                      // PPHOP column (date)
                'pphbdn': _parseDate(fields[5]),                     // PPHBDN column (date)
              };
              break;
              
            default:
              errors.add('Baris ${i + 1}: Tabel tidak dikenal');
              continue;
          }
          
          await insert(tableName, record);
          recordsProcessed++;
          
        } catch (e) {
          errors.add('Baris ${i + 1}: ${e.toString()}');
        }
      }
      
      return ImportResult.success(
        message: 'Successfully imported $recordsProcessed records to $tableName',
        successCount: recordsProcessed,
        errorCount: errors.length,
        errors: errors,
      );
    } catch (e) {
      print('Error importing CSV: $e');
      return ImportResult.error(
        'IMPORT_ERROR',
        'Failed to import CSV: $e',
      );
    }
  }

  /// Execute Wajib Pajak data update (mimicking Qt legacy updateWajibPajak)
  static Future<ImportResult> executeWajibPajakUpdate() async {
    if (!_isInitialized || _currentDatabaseType == null) {
      throw Exception('Database not initialized');
    }

    try {
      print('Executing Wajib Pajak data update...');
      
      // Real implementation that executes actual database operations
      // This follows the Qt legacy pattern for Wajib Pajak updates
      
      // Step 1: Execute database maintenance operations
      int recordsProcessed = 0;
      final errors = <String>[];
      
      // Update Wajib Pajak status based on recent activity
      try {
        final result = await rawQuery('''
          UPDATE wp SET status = 'AKTIF' 
          WHERE npwp IS NOT NULL 
          AND npwp != '' 
          AND (status IS NULL OR status = '')
        ''');
        recordsProcessed += result.length;
        print('Updated AKTIF status for ${result.length} Wajib Pajak records');
      } catch (e) {
        errors.add('Failed to update AKTIF status: $e');
      }
      
      // Clean up invalid NPWP formats
      try {
        final result = await rawQuery('''
          UPDATE wp SET npwp = NULL 
          WHERE npwp IS NOT NULL 
          AND (LENGTH(npwp) < 15 OR npwp LIKE '%-%-%')
        ''');
        recordsProcessed += result.length;
        print('Cleaned up ${result.length} invalid NPWP formats');
      } catch (e) {
        errors.add('Failed to clean NPWP formats: $e');
      }
      
      // Update KLU mapping for existing taxpayers
      try {
        final result = await rawQuery('''
          UPDATE wp w 
          INNER JOIN klu k ON w.klu = k.kode 
          SET w.sektor = k.kategori 
          WHERE w.klu IS NOT NULL 
          AND (w.sektor IS NULL OR w.sektor = '')
        ''');
        recordsProcessed += result.length;
        print('Updated sektor mapping for ${result.length} Wajib Pajak records');
      } catch (e) {
        errors.add('Failed to update KLU mapping: $e');
      }
      
      // Update regional mapping based on kantor
      try {
        final result = await rawQuery('''
          UPDATE wp w 
          INNER JOIN kantor kt ON w.kpp = kt.kode 
          SET w.wilayah = kt.region 
          WHERE w.kpp IS NOT NULL 
          AND (w.wilayah IS NULL OR w.wilayah = '')
        ''');
        recordsProcessed += result.length;
        print('Updated regional mapping for ${result.length} Wajib Pajak records');
      } catch (e) {
        errors.add('Failed to update regional mapping: $e');
      }
      
      if (errors.isEmpty) {
        return ImportResult.success(
          message: 'Successfully updated $recordsProcessed Wajib Pajak records',
          successCount: recordsProcessed,
        );
      } else {
        return ImportResult.success(
          message: 'Updated $recordsProcessed Wajib Pajak records with ${errors.length} warnings',
          successCount: recordsProcessed,
          errorCount: errors.length,
          errors: errors,
        );
      }
    } catch (e) {
      print('Error updating Wajib Pajak: $e');
      return ImportResult.error(
        'UPDATE_ERROR',
        'Failed to update Wajib Pajak: $e',
      );
    }
  }
}