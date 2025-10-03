import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

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
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConstants.databaseName);
    
    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
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
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConstants.databaseName);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    _database = null;
  }

  /// Get database file size
  Future<int> getDatabaseSize() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConstants.databaseName);
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Backup database to specified path
  Future<bool> backup(String backupPath) async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final sourcePath = join(documentsDirectory.path, AppConstants.databaseName);
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
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final targetPath = join(documentsDirectory.path, AppConstants.databaseName);
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