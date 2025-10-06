import '../../core/constants/app_constants.dart';
import '../../core/constants/app_enums.dart';
import 'database_helper.dart';
import 'mysql_service.dart';
import 'settings_service.dart';

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
}