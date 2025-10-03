import 'package:mysql1/mysql1.dart';
import '../models/user_model.dart';
import 'settings_service.dart';

/// MySQL database service for production use
/// Handles connection to MySQL database similar to original MPN-Info
class MySqlService {
  static MySqlConnection? _connection;
  static DatabaseConfig? _config;
  
  static Future<MySqlConnection> get connection async {
    _connection ??= await _initConnection();
    return _connection!;
  }

  /// Initialize with database configuration
  static Future<void> initializeWithConfig(DatabaseConfig config) async {
    _config = config;
    // Close existing connection if any
    await close();
    // Initialize schema
    await initializeSchema();
  }

  static Future<MySqlConnection> _initConnection() async {
    if (_config == null) {
      throw StateError('MySQL service not initialized with configuration');
    }

    final settings = ConnectionSettings(
      host: _config!.host,
      port: _config!.port,
      user: _config!.username,
      password: _config!.password,
      db: _config!.name,
      useSSL: _config!.useSsl,
      timeout: const Duration(seconds: 30),
    );

    try {
      final conn = await MySqlConnection.connect(settings);
      print('Connected to MySQL database successfully');
      return conn;
    } catch (e) {
      print('Failed to connect to MySQL: $e');
      rethrow;
    }
  }

  /// Initialize database schema (create tables if not exist)
  static Future<void> initializeSchema() async {
    final conn = await connection;
    
    // Create users table
    await conn.query('''
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        fullname VARCHAR(100) NOT NULL,
        group_type INT NOT NULL DEFAULT 2,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    ''');

    // Create pegawai table
    await conn.query('''
      CREATE TABLE IF NOT EXISTS pegawai (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nip VARCHAR(20) UNIQUE,
        nama VARCHAR(100),
        username VARCHAR(50),
        password VARCHAR(255),
        jabatan INT,
        seksi INT,
        email VARCHAR(100),
        telepon VARCHAR(20),
        alamat TEXT,
        tanggal_lahir DATE,
        tempat_lahir VARCHAR(50),
        status INT DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    ''');

    // Create wp (wajib pajak) table
    await conn.query('''
      CREATE TABLE IF NOT EXISTS wp (
        id INT AUTO_INCREMENT PRIMARY KEY,
        npwp VARCHAR(15) UNIQUE,
        nama VARCHAR(200),
        alamat TEXT,
        kelurahan VARCHAR(50),
        kecamatan VARCHAR(50),
        kabupaten VARCHAR(50),
        provinsi VARCHAR(50),
        kode_pos VARCHAR(10),
        telepon VARCHAR(20),
        email VARCHAR(100),
        jenis_wp INT,
        status_wp INT DEFAULT 1,
        keterangan TEXT,
        user_id INT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Create mpn table
    await conn.query('''
      CREATE TABLE IF NOT EXISTS mpn (
        id INT AUTO_INCREMENT PRIMARY KEY,
        kd_mpn VARCHAR(20),
        nomor VARCHAR(50),
        tanggal DATE,
        nilai DECIMAL(15,2),
        kd_kpp INT,
        npwp VARCHAR(15),
        nama VARCHAR(200),
        kd_map INT,
        uraian TEXT,
        keterangan TEXT,
        user_id INT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Create indexes for better performance
    await _createIndexIfNotExists(conn, 'idx_users_username', 'users', 'username');
    await _createIndexIfNotExists(conn, 'idx_pegawai_nip', 'pegawai', 'nip');
    await _createIndexIfNotExists(conn, 'idx_wp_npwp', 'wp', 'npwp');
    await _createIndexIfNotExists(conn, 'idx_mpn_npwp', 'mpn', 'npwp');
    await _createIndexIfNotExists(conn, 'idx_mpn_tanggal', 'mpn', 'tanggal');

    // Insert default admin user if not exists
    await _insertDefaultUser();
  }

  /// Helper method to create index only if it doesn't exist
  static Future<void> _createIndexIfNotExists(
    MySqlConnection conn,
    String indexName,
    String tableName,
    String columnName,
  ) async {
    try {
      // Check if index exists
      final result = await conn.query('''
        SELECT COUNT(*) as count 
        FROM information_schema.statistics 
        WHERE table_schema = DATABASE() 
        AND table_name = ? 
        AND index_name = ?
      ''', [tableName, indexName]);
      
      final count = result.first['count'] as int;
      if (count == 0) {
        // Index doesn't exist, create it
        await conn.query('CREATE INDEX $indexName ON $tableName($columnName)');
        print('Created index: $indexName on $tableName($columnName)');
      } else {
        print('Index $indexName already exists on $tableName($columnName)');
      }
    } catch (e) {
      print('Error creating index $indexName: $e');
    }
  }

  static Future<void> _insertDefaultUser() async {
    final conn = await connection;
    
    // Check if admin user exists
    final result = await conn.query(
      'SELECT COUNT(*) as count FROM users WHERE username = ?',
      ['admin']
    );
    
    final count = result.first['count'] as int;
    if (count == 0) {
      // Insert default admin user
      await conn.query('''
        INSERT INTO users (username, password, fullname, group_type)
        VALUES (?, ?, ?, ?)
      ''', [
        'admin',
        '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', // SHA-256 of 'admin123'
        'Administrator',
        UserGroupType.administrator.value,
      ]);
      
      print('Default admin user created in MySQL');
    }
  }

  /// Generic insert method for MySQL
  static Future<int> insert(String table, Map<String, dynamic> data) async {
    final conn = await connection;
    
    data['created_at'] = DateTime.now();
    data['updated_at'] = DateTime.now();
    
    final fields = data.keys.join(', ');
    final placeholders = List.filled(data.length, '?').join(', ');
    
    final result = await conn.query(
      'INSERT INTO $table ($fields) VALUES ($placeholders)',
      data.values.toList(),
    );
    
    return result.insertId!;
  }

  /// Generic update method for MySQL
  static Future<int> update(String table, Map<String, dynamic> data, String whereClause, List<dynamic> whereArgs) async {
    final conn = await connection;
    
    data['updated_at'] = DateTime.now();
    
    final setClause = data.keys.map((key) => '$key = ?').join(', ');
    
    final result = await conn.query(
      'UPDATE $table SET $setClause WHERE $whereClause',
      [...data.values.toList(), ...whereArgs],
    );
    
    return result.affectedRows!;
  }

  /// Generic delete method for MySQL
  static Future<int> delete(String table, String whereClause, List<dynamic> whereArgs) async {
    final conn = await connection;
    
    final result = await conn.query(
      'DELETE FROM $table WHERE $whereClause',
      whereArgs,
    );
    
    return result.affectedRows!;
  }

  /// Generic query method for MySQL
  static Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final conn = await connection;
    
    final columnsList = columns?.join(', ') ?? '*';
    final whereClause = where != null ? 'WHERE $where' : '';
    final orderClause = orderBy != null ? 'ORDER BY $orderBy' : '';
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final offsetClause = offset != null ? 'OFFSET $offset' : '';
    
    final sql = 'SELECT $columnsList FROM $table $whereClause $orderClause $limitClause $offsetClause';
    
    final result = await conn.query(sql, whereArgs ?? []);
    
    return result.map((row) => Map<String, dynamic>.from(row.fields)).toList();
  }

  /// Execute raw SQL query
  static Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final conn = await connection;
    final result = await conn.query(sql, arguments ?? []);
    return result.map((row) => Map<String, dynamic>.from(row.fields)).toList();
  }

  /// Close MySQL connection
  static Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }

  /// Test MySQL connection
  static Future<bool> testConnection() async {
    try {
      final conn = await connection;
      await conn.query('SELECT 1');
      return true;
    } catch (e) {
      print('MySQL connection test failed: $e');
      return false;
    }
  }
}