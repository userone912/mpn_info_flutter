import 'package:mysql1/mysql1.dart';
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

  /// Initialize database schema (tables will be created by migration system)
  static Future<void> initializeSchema() async {
    // Schema initialization is handled by the database migration system
    // This ensures consistency with db-struct, db-value, and update-* files
    print('MySQL schema initialization deferred to migration system');
  }

  /// Generic insert method for MySQL
  static Future<int> insert(String table, Map<String, dynamic> data) async {
    final conn = await connection;
    
    // Don't automatically add timestamps for legacy tables
    // The existing MySQL database schema doesn't have created_at/updated_at columns
    // Only add timestamps for tables that actually have these columns
    
    final fields = data.keys.map((key) => '`$key`').join(', '); // Escape field names
    final placeholders = List.filled(data.length, '?').join(', ');
    
    final result = await conn.query(
      'INSERT INTO `$table` ($fields) VALUES ($placeholders)',
      data.values.toList(),
    );
    
    return result.insertId!;
  }

  /// Generic update method for MySQL
  static Future<int> update(String table, Map<String, dynamic> data, String whereClause, List<dynamic> whereArgs) async {
    final conn = await connection;
    
    // Don't automatically add updated timestamp for legacy tables
    
    final setClause = data.keys.map((key) => '`$key` = ?').join(', ');
    
    final result = await conn.query(
      'UPDATE `$table` SET $setClause WHERE $whereClause',
      [...data.values.toList(), ...whereArgs],
    );
    
    return result.affectedRows!;
  }

  /// Generic delete method for MySQL
  static Future<int> delete(String table, String whereClause, List<dynamic> whereArgs) async {
    final conn = await connection;
    
    final result = await conn.query(
      'DELETE FROM `$table` WHERE $whereClause',
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
    
    // Escape table name with backticks
    final escapedTable = '`$table`';
    final columnsList = columns?.join(', ') ?? '*';
    final whereClause = where != null ? 'WHERE $where' : '';
    final orderClause = orderBy != null ? 'ORDER BY $orderBy' : '';
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final offsetClause = offset != null ? 'OFFSET $offset' : '';
    
    final sql = 'SELECT $columnsList FROM $escapedTable $whereClause $orderClause $limitClause $offsetClause';
    
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