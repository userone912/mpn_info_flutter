import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'database_migration_service.dart';

/// Database helper for local SQLite database
/// Provides database initialization, migration, and basic operations
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  /// Initialize database factory for desktop platforms
  static void initialize() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Initialize FFI for desktop platforms
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Use the same directory logic as settings.ini
    final dbPath = await _getDatabasePath();
    
    print('SQLite database path: $dbPath');
    
    // Check if database file already exists
    final dbFile = File(dbPath);
    final dbExists = await dbFile.exists();
    
    if (dbExists) {
      print('Existing database file found: $dbPath');
      // Open existing database without running onCreate
      return await openDatabase(
        dbPath,
        version: AppConstants.databaseVersion,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    } else {
      print('No existing database file found, creating new one: $dbPath');
      // Create new database with full schema from migration files
      return await openDatabase(
        dbPath,
        version: AppConstants.databaseVersion,
        onCreate: _onCreateWithMigration,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    }
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreateWithMigration(Database db, int version) async {
    print('Creating SQLite database with full schema from migration files...');
    
    try {
      // Read and execute schema from db-struct file
      await _createSchemaFromStructFile(db);
      
      // Load initial data from db-value file
      await _loadInitialDataFromValueFile(db);
      
      // Load CSV data from external files
      await _loadCsvDataFiles(db);
      
      print('SQLite database created successfully with full schema and data');
    } catch (e) {
      print('Error creating SQLite database with migration: $e');
      // Fall back to basic schema creation
      await _createBasicSchema(db);
    }
  }

  /// Create database schema from db-struct file
  Future<void> _createSchemaFromStructFile(Database db) async {
    try {
      final structData = await DatabaseMigrationService.readExternalFile('data/db-struct');
      final lines = structData.split('\n');
      
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('!') || trimmed.startsWith('title;') || trimmed.startsWith('message;')) {
          continue;
        }
        
        if (trimmed.startsWith('sql;')) {
          final parts = trimmed.split(';');
          if (parts.length >= 3) {
            final dbType = int.tryParse(parts[1]) ?? 0;
            final sql = parts.sublist(2).join(';');
            
            // Execute SQL for SQLite (dbType 1) or universal (dbType 0)
            if (dbType == 0 || dbType == 1) {
              // Convert MySQL syntax to SQLite syntax
              final sqliteSQL = _convertMySQLToSQLite(sql);
              if (sqliteSQL.isNotEmpty) {
                print('Executing SQLite schema: ${sqliteSQL.substring(0, sqliteSQL.length > 100 ? 100 : sqliteSQL.length)}...');
                await db.execute(sqliteSQL);
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error reading db-struct file: $e');
      rethrow;
    }
  }

  /// Load initial data from db-value file
  Future<void> _loadInitialDataFromValueFile(Database db) async {
    try {
      final valueData = await DatabaseMigrationService.readExternalFile('data/db-value');
      final lines = valueData.split('\n');
      
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('!') || trimmed.startsWith('message;')) {
          continue;
        }
        
        if (trimmed.startsWith('sql;')) {
          final parts = trimmed.split(';');
          if (parts.length >= 3) {
            final dbType = int.tryParse(parts[1]) ?? 0;
            final sql = parts.sublist(2).join(';');
            
            // Execute SQL for SQLite (dbType 1) or universal (dbType 0)
            if (dbType == 0 || dbType == 1) {
              // Convert MySQL syntax to SQLite syntax
              final sqliteSQL = _convertMySQLToSQLite(sql);
              if (sqliteSQL.isNotEmpty) {
                print('Executing SQLite data: ${sqliteSQL.substring(0, sqliteSQL.length > 100 ? 100 : sqliteSQL.length)}...');
                await db.execute(sqliteSQL);
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error reading db-value file: $e');
      // This is not critical, continue without initial data
    }
  }

  /// Load CSV data files (kantor, klu, map, etc.)
  Future<void> _loadCsvDataFiles(Database db) async {
    try {
      final csvFiles = ['kantor', 'klu', 'map', 'jatuhtempo', 'maxlapor'];
      
      for (final csvFile in csvFiles) {
        await _loadCsvFile(db, csvFile);
      }
    } catch (e) {
      print('Error loading CSV files: $e');
      // Continue without CSV data
    }
  }

  /// Load a specific CSV file into the database
  Future<void> _loadCsvFile(Database db, String csvFileName) async {
    try {
      final csvData = await DatabaseMigrationService.readExternalFile('data/$csvFileName.csv');
      
      // Parse CSV - detect delimiter automatically
      String delimiter = ';'; // Default
      
      final firstLines = csvData.split('\n').take(3).toList();
      int semicolonCount = 0;
      int commaCount = 0;
      
      for (final line in firstLines) {
        semicolonCount += ';'.allMatches(line).length;
        commaCount += ','.allMatches(line).length;
      }
      
      if (commaCount > semicolonCount) {
        delimiter = ',';
      }
      
      final csvTable = csvData.split('\n').map((line) => line.split(delimiter)).toList();
      
      if (csvTable.isEmpty) return;
      
      // First row is header
      final headers = csvTable[0].map((e) => e.toString().trim()).toList();
      
      // Insert data
      int recordsInserted = 0;
      for (int i = 1; i < csvTable.length; i++) {
        final row = csvTable[i];
        if (row.isEmpty || row.every((cell) => cell.trim().isEmpty)) continue;
        
        final data = <String, dynamic>{};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          data[headers[j]] = row[j].toString().trim();
        }
        
        // Insert into SQLite
        final fields = data.keys.map((key) => '`$key`').join(', ');
        final placeholders = List.filled(data.length, '?').join(', ');
        await db.rawInsert(
          'INSERT INTO `$csvFileName` ($fields) VALUES ($placeholders)',
          data.values.toList(),
        );
        recordsInserted++;
      }
      
      print('Loaded $recordsInserted records into $csvFileName table');
    } catch (e) {
      print('Error loading CSV file $csvFileName: $e');
      // Continue with other files
    }
  }

  /// Convert MySQL SQL syntax to SQLite syntax
  String _convertMySQLToSQLite(String sql) {
    String result = sql;
    
    // Skip non-essential SQL commands for SQLite
    if (result.toUpperCase().contains('SET ') || 
        result.toUpperCase().contains('LOCK TABLES') ||
        result.toUpperCase().contains('UNLOCK TABLES') ||
        result.toUpperCase().contains('/*!')) {
      return '';
    }
    
    // Convert MySQL types to SQLite types
    result = result.replaceAllMapped(RegExp(r'INT\(\d+\)', caseSensitive: false), (match) => 'INTEGER');
    result = result.replaceAllMapped(RegExp(r'VARCHAR\(\d+\)', caseSensitive: false), (match) => 'TEXT');
    result = result.replaceAllMapped(RegExp(r'CHAR\(\d+\)', caseSensitive: false), (match) => 'TEXT');
    result = result.replaceAll(RegExp(r'LONGTEXT', caseSensitive: false), 'TEXT');
    result = result.replaceAll(RegExp(r'MEDIUMTEXT', caseSensitive: false), 'TEXT');
    result = result.replaceAll(RegExp(r'TINYTEXT', caseSensitive: false), 'TEXT');
    result = result.replaceAll(RegExp(r'DECIMAL\([^)]+\)', caseSensitive: false), 'REAL');
    result = result.replaceAll(RegExp(r'DOUBLE', caseSensitive: false), 'REAL');
    result = result.replaceAll(RegExp(r'FLOAT', caseSensitive: false), 'REAL');
    result = result.replaceAll(RegExp(r'TINYINT\(\d+\)', caseSensitive: false), 'INTEGER');
    result = result.replaceAll(RegExp(r'BIGINT\(\d+\)', caseSensitive: false), 'INTEGER');
    
    // Remove MySQL-specific clauses
    result = result.replaceAll(RegExp(r'ENGINE=\w+', caseSensitive: false), '');
    result = result.replaceAll(RegExp(r'DEFAULT CHARSET=\w+', caseSensitive: false), '');
    result = result.replaceAll(RegExp(r'COLLATE=\w+', caseSensitive: false), '');
    result = result.replaceAll(RegExp(r'AUTO_INCREMENT=\d+', caseSensitive: false), '');
    
    // Convert AUTO_INCREMENT to SQLite AUTOINCREMENT
    result = result.replaceAll(RegExp(r'AUTO_INCREMENT', caseSensitive: false), 'AUTOINCREMENT');
    
    // Clean up extra spaces and semicolons
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return result;
  }

  /// Fallback basic schema creation if migration files are not available
  Future<void> _createBasicSchema(Database db) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        fullname TEXT NOT NULL,
        group_type INTEGER NOT NULL DEFAULT 2,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Create pegawai table
    await db.execute('''
      CREATE TABLE pegawai (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nip TEXT UNIQUE,
        nama TEXT,
        username TEXT,
        password TEXT,
        jabatan INTEGER,
        seksi INTEGER,
        email TEXT,
        telepon TEXT,
        alamat TEXT,
        tanggal_lahir TEXT,
        tempat_lahir TEXT,
        status INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Create wp (wajib pajak) table
    await db.execute('''
      CREATE TABLE wp (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        npwp TEXT UNIQUE,
        nama TEXT,
        alamat TEXT,
        kelurahan TEXT,
        kecamatan TEXT,
        kabupaten TEXT,
        provinsi TEXT,
        kode_pos TEXT,
        telepon TEXT,
        email TEXT,
        jenis_wp INTEGER,
        status_wp INTEGER DEFAULT 1,
        keterangan TEXT,
        user_id INTEGER,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Create mpn table
    await db.execute('''
      CREATE TABLE mpn (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kd_mpn TEXT,
        nomor TEXT,
        tanggal TEXT,
        nilai REAL,
        kd_kpp INTEGER,
        npwp TEXT,
        nama TEXT,
        kd_map INTEGER,
        uraian TEXT,
        keterangan TEXT,
        user_id INTEGER,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Create renpen (rencana penerimaan) table
    await db.execute('''
      CREATE TABLE renpen (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kpp TEXT NOT NULL,
        nip TEXT NOT NULL,
        kdmap TEXT NOT NULL,
        bulan INTEGER NOT NULL,
        tahun INTEGER NOT NULL,
        target REAL NOT NULL,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (nip) REFERENCES pegawai (nip)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_users_username ON users(username)');
    await db.execute('CREATE INDEX idx_pegawai_nip ON pegawai(nip)');
    await db.execute('CREATE INDEX idx_wp_npwp ON wp(npwp)');
    await db.execute('CREATE INDEX idx_mpn_npwp ON mpn(npwp)');
    await db.execute('CREATE INDEX idx_mpn_tanggal ON mpn(tanggal)');

    // Insert default admin user
    await _insertDefaultData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 2) {
      // Example migration for version 2
      // await db.execute('ALTER TABLE users ADD COLUMN new_column TEXT');
    }
  }

  Future<void> _insertDefaultData(Database db) async {
    // Insert default admin user
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123', // In production, this should be hashed
      'fullname': 'Administrator',
      'group_type': UserGroupType.administrator.value,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    print('Default admin user created: username=admin, password=admin123');
  }

  /// Generic insert method
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.insert(table, data);
  }

  /// Generic update method
  Future<int> update(String table, Map<String, dynamic> data, String whereClause, List<dynamic> whereArgs) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(table, data, where: whereClause, whereArgs: whereArgs);
  }

  /// Generic delete method
  Future<int> delete(String table, String whereClause, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.delete(table, where: whereClause, whereArgs: whereArgs);
  }

  /// Generic query method
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Execute raw SQL query
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// Execute raw SQL command
  Future<void> execute(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    await db.execute(sql, arguments);
  }

  /// Get the database file path (same logic as settings.ini)
  static Future<String> _getDatabasePath() async {
    final executablePath = Platform.resolvedExecutable;
    final executableDirectory = Directory(dirname(executablePath));
    
    // Check if we're running in debug mode (build directory)
    final isDebugMode = executablePath.contains('build\\windows\\x64\\runner\\Debug') || 
                       executablePath.contains('build/windows/x64/runner/Debug');
    
    if (isDebugMode) {
      // For debug mode, use Documents folder to persist database across rebuilds
      final documentsPath = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
      if (documentsPath != null) {
        final documentsDir = Directory(join(documentsPath, 'Documents', 'MPN-Info'));
        
        // Create directory if it doesn't exist
        if (!await documentsDir.exists()) {
          await documentsDir.create(recursive: true);
        }
        
        return join(documentsDir.path, AppConstants.sqliteFileName);
      } else {
        // Fallback to executable directory if can't find Documents
        return join(executableDirectory.path, AppConstants.sqliteFileName);
      }
    } else {
      // For release mode, use the executable directory (like Qt legacy)
      return join(executableDirectory.path, AppConstants.sqliteFileName);
    }
  }

  /// Close database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Delete database file
  Future<void> deleteDatabase() async {
    final path = await _getDatabasePath();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    _database = null;
  }

  /// Get database file size
  Future<int> getDatabaseSize() async {
    final path = await _getDatabasePath();
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Backup database to specified path
  Future<bool> backup(String backupPath) async {
    try {
      final sourcePath = await _getDatabasePath();
      final sourceFile = File(sourcePath);
      
      if (await sourceFile.exists()) {
        await sourceFile.copy(backupPath);
        return true;
      }
      return false;
    } catch (e) {
      print('Database backup failed: $e');
      return false;
    }
  }

  /// Restore database from specified path
  Future<bool> restore(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        return false;
      }

      // Close current database
      await close();

      // Copy backup file to database location
      final targetPath = await _getDatabasePath();
      await backupFile.copy(targetPath);

      // Reinitialize database
      _database = await _initDatabase();
      return true;
    } catch (e) {
      print('Database restore failed: $e');
      return false;
    }
  }
}