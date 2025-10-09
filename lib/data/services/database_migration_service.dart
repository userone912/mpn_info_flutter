import 'package:csv/csv.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'database_service.dart';
import '../../core/constants/app_enums.dart';

/// Database Migration Service
/// Handles schema synchronization from assets/data files
class DatabaseMigrationService {
  
  /// Check and update database schema from external data files
  static Future<bool> migrateDatabase() async {
    try {
      print('Starting database migration...');
      
      // Check database type
      final dbType = DatabaseService.databaseType;
      
      if (dbType == DatabaseType.sqlite) {
        // For SQLite, the database is already created with schema in DatabaseHelper
        // Just run CSV updates if needed
        return await _migrateSQLiteDatabase();
      } else {
        // MySQL migration logic
        return await _migrateMySQLDatabase();
      }
      
    } catch (e) {
      print('Database migration failed: $e');
      return false;
    }
  }

  /// Handle SQLite database migration (mainly CSV updates)
  static Future<bool> _migrateSQLiteDatabase() async {
    try {
      print('Running SQLite database migration...');
      
      // Check if basic tables exist, if not they should be created by DatabaseHelper
      try {
        await DatabaseService.query('users', limit: 1);
      } catch (e) {
        // Tables don't exist yet, this is expected for new database
        print('Database tables not yet created, will be handled by DatabaseHelper');
        return true;
      }
      
      // Update CSV data if update files exist
      await _updateCsvDataFromFiles();
      
      print('SQLite database migration completed successfully');
      return true;
      
    } catch (e) {
      print('SQLite migration error: $e');
      return false;
    }
  }

  /// Handle MySQL database migration (original logic)
  static Future<bool> _migrateMySQLDatabase() async {
    try {
      // Check if we can connect to the database
      try {
        await DatabaseService.query('info', limit: 1);
      } catch (e) {
        final errorMessage = e.toString();
        if (errorMessage.contains('Unknown database')) {
          print('═══════════════════════════════════════════');
          print('ERROR: Database "mpninfo" does not exist!');
          print('═══════════════════════════════════════════');
          print('Please create the database first:');
          print('1. Open MySQL command line or phpMyAdmin');
          print('2. Run: CREATE DATABASE mpninfo;');
          print('3. Restart the application');
          print('═══════════════════════════════════════════');
          return false;
        } else if (errorMessage.contains('access denied') || errorMessage.contains('connection refused')) {
          print('ERROR: Cannot connect to database: $e');
          print('Please check your database configuration and ensure MySQL is running.');
          return false;
        }
        // If it's just "table doesn't exist", that's expected for fresh database
      }
      
      // Read from external data directory
      final structData = await _readExternalFile('data/db-struct');
      final valueData = await _readExternalFile('data/db-value');
      print('Loading database files');
      
      // Parse structure and value files
      final structCommands = _parseStructFile(structData);
      final valueCommands = _parseValueFile(valueData);
      
      // Get current database version and target version
      final targetVersion = _getTargetVersion(structData);
      
      // Start Qt-style migration algorithm
      String currentVersion = await _getCurrentDatabaseVersion();
      print('Current DB version: $currentVersion, Target: $targetVersion');
      
      // Qt algorithm: while current version < target version, keep updating
      bool updatesApplied = false;
      while (_compareVersions(currentVersion, targetVersion) < 0) {
        String lastVersion = currentVersion;
        
        if (currentVersion == "0.0") {
          // Fresh database: run db-struct first
          print('Fresh database detected, running db-struct');
          await _applyStructureCommands(structCommands);
          
          // Then immediately run db-value (Qt does this right after db-struct)
          print('Running db-value immediately after db-struct');
          await _applyValueCommands(valueCommands, valueData);
          
          updatesApplied = true;
        } else {
          // Run update file for current version
          print('Applying update-$currentVersion...');
          
          final updateContent = await _readUpdateFile(currentVersion);
          if (updateContent != null) {
            await _applyUpdateFile(updateContent);
            print('Successfully applied update-$currentVersion');
            updatesApplied = true;
          } else {
            print('No update file found for version $currentVersion - stopping updates');
            break;
          }
        }
        
        // Get the new version after update
        currentVersion = await _getCurrentDatabaseVersion();
        
        // Safety check: if version didn't change, break to avoid infinite loop
        if (lastVersion == currentVersion) {
          print('ERROR: Database version did not change after update. Breaking loop.');
          break;
        }
        
        print('Database updated from $lastVersion to $currentVersion');
      }
      
      // Load CSV data after all updates are complete
      if (updatesApplied) {
        await _loadCsvData();
      }
      
      if (updatesApplied || _compareVersions(currentVersion, targetVersion) >= 0) {
        print('Database migration completed successfully');
        return true;
      } else {
        print('Database is up to date - no migration needed');
        return true;
      }
      
    } catch (e) {
      print('Database migration failed: $e');
      return false;
    }
  }
  
  /// Parse db-struct file
  static List<DatabaseCommand> _parseStructFile(String content) {
    final commands = <DatabaseCommand>[];
    final lines = content.split('\n');
    
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
          commands.add(DatabaseCommand(
            type: CommandType.sql,
            dbType: dbType,
            sql: sql,
          ));
        }
      }
    }
    
    return commands;
  }
  
  /// Parse db-value file
  static List<DatabaseCommand> _parseValueFile(String content) {
    final commands = <DatabaseCommand>[];
    final lines = content.split('\n');
    
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
          commands.add(DatabaseCommand(
            type: CommandType.sql,
            dbType: dbType,
            sql: sql,
          ));
        }
      } else if (trimmed.startsWith('update')) {
        // Remove semicolon if present at the end
        final csvType = trimmed.endsWith(';') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
        commands.add(DatabaseCommand(
          type: CommandType.csvUpdate,
          csvType: csvType,
        ));
      }
    }
    
    return commands;
  }
  
  /// Get target version from struct file
  static String _getTargetVersion(String structContent) {
    // Look for the INSERT statement that sets db.version in the info table
    final lines = structContent.split('\n');
    for (final line in lines) {
      if (line.contains("INSERT INTO `info` VALUES('db.version'") ||
          line.contains('INSERT INTO `info` VALUES("db.version"')) {
        // Extract version from: INSERT INTO `info` VALUES('db.version', '4.7');
        final versionMatch = RegExp(r"VALUES\('db\.version',\s*'([^']+)'\)").firstMatch(line);
        if (versionMatch != null) {
          return versionMatch.group(1)!;
        }
        // Also try double quotes
        final versionMatch2 = RegExp(r'VALUES\("db\.version",\s*"([^"]+)"\)').firstMatch(line);
        if (versionMatch2 != null) {
          return versionMatch2.group(1)!;
        }
      }
    }
    // Fallback: if no version found in SQL, default to 4.7
    return '4.7';
  }
  
  /// Get current database version
  static Future<String> _getCurrentDatabaseVersion() async {
    try {
      // First check if the info table exists
      final tableExists = await _checkTableExists('info');
      if (!tableExists) {
        print('Info table does not exist, treating as new database');
        return '0.0';
      }
      
      final result = await DatabaseService.query(
        'info',
        where: '`key` = ?',
        whereArgs: ['db.version'],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return result.first['value']?.toString() ?? '0.0';
      }
    } catch (e) {
      print('Could not get database version: $e');
    }
    return '0.0';
  }

  /// Check if a table exists in the database
  static Future<bool> _checkTableExists(String tableName) async {
    try {
      await DatabaseService.query(tableName, limit: 1);
      return true;
    } catch (e) {
      // If query fails, table probably doesn't exist
      return false;
    }
  }
  
  /// Compare version strings (simple semantic versioning)
  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.tryParse).where((e) => e != null).cast<int>().toList();
    final parts2 = v2.split('.').map(int.tryParse).where((e) => e != null).cast<int>().toList();
    
    final maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;
    
    for (int i = 0; i < maxLength; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }
    
    return 0;
  }
  
  /// Apply structure commands
  static Future<void> _applyStructureCommands(List<DatabaseCommand> commands) async {
    for (final command in commands) {
      if (command.type == CommandType.sql) {
        try {
          // Determine if this SQL is for our database type
          // 0 = general, 1 = MySQL, 2 = SQLite
          final currentDbType = DatabaseService.databaseType;
          
          if (command.dbType == 0 || 
              (command.dbType == 1 && currentDbType.name.toLowerCase().contains('mysql')) ||
              (command.dbType == 2 && currentDbType.name.toLowerCase().contains('sqlite'))) {
            
            // Convert SQL for our database type
            String sql = command.sql;
            sql = _convertSqlForDatabase(sql);
            
            print('Executing SQL: ${sql.substring(0, sql.length > 100 ? 100 : sql.length)}...');
            await DatabaseService.rawQuery(sql);
          }
        } catch (e) {
          print('Failed to execute SQL: ${command.sql}\nError: $e');
          
          // Check if this is a critical database error that should stop migration
          final errorMessage = e.toString().toLowerCase();
          if (errorMessage.contains('unknown database') || 
              errorMessage.contains('access denied') ||
              errorMessage.contains('connection refused')) {
            print('Critical database error detected. Stopping migration.');
            rethrow; // Stop the migration process
          }
          // Continue with other commands for non-critical errors
        }
      }
    }
  }
  
  /// Apply value commands
  static Future<void> _applyValueCommands(List<DatabaseCommand> commands, String valueContent) async {
    // Check if current database version matches the value file version requirement
    final valueFileVersion = _getValueFileVersion(valueContent);
    final currentVersion = await _getCurrentDatabaseVersion();
    
    if (currentVersion != valueFileVersion) {
      print('Skipping value commands - current version: $currentVersion, required version: $valueFileVersion');
      return;
    }
    
    print('Applying value commands for version $valueFileVersion...');
    
    for (final command in commands) {
      if (command.type == CommandType.sql) {
        try {
          final currentDbType = DatabaseService.databaseType;
          
          if (command.dbType == 0 || 
              (command.dbType == 1 && currentDbType.name.toLowerCase().contains('mysql')) ||
              (command.dbType == 2 && currentDbType.name.toLowerCase().contains('sqlite'))) {
            
            String sql = command.sql;
            sql = _convertSqlForDatabase(sql);
            
            print('Executing value SQL: ${sql.substring(0, sql.length > 100 ? 100 : sql.length)}...');
            await DatabaseService.rawQuery(sql);
          }
        } catch (e) {
          print('Failed to execute value SQL: ${command.sql}\nError: $e');
        }
      } else if (command.type == CommandType.csvUpdate) {
        await loadSpecificCsvData(command.csvType);
      }
    }
  }
  
  /// Convert SQL for current database type
  static String _convertSqlForDatabase(String sql) {
    final currentDbType = DatabaseService.databaseType;
    
    if (currentDbType.name.toLowerCase().contains('mysql')) {
      // Convert SQLite-specific syntax to MySQL
      sql = sql.replaceAll('AUTOINCREMENT', 'AUTO_INCREMENT');
      sql = sql.replaceAll('integer PRIMARY KEY AUTO_INCREMENT', 'INT AUTO_INCREMENT PRIMARY KEY');
      sql = sql.replaceAll('integer PRIMARY KEY', 'INT PRIMARY KEY');
      sql = sql.replaceAll('integer', 'INT');
      sql = sql.replaceAll('text', 'TEXT');
    } else {
      // Convert MySQL-specific syntax to SQLite
      sql = sql.replaceAll('AUTO_INCREMENT', 'AUTOINCREMENT');
      sql = sql.replaceAll('INT AUTO_INCREMENT PRIMARY KEY', 'integer PRIMARY KEY AUTOINCREMENT');
      sql = sql.replaceAll('INT PRIMARY KEY', 'integer PRIMARY KEY');
      sql = sql.replaceAll('INT', 'integer');
      sql = sql.replaceAll('varchar', 'text');
      sql = sql.replaceAll('VARCHAR', 'text');
    }
    
    return sql;
  }
  
  /// Check if command should be executed for current database type
  static bool _shouldExecuteForCurrentDatabase(int? commandDbType) {
    if (commandDbType == null) return true; // No restriction
    
    final currentDbType = DatabaseService.databaseType;
    
    // dbType: 1 = MySQL, 2 = SQLite, null/0 = both
    return (commandDbType == 1 && currentDbType.name.toLowerCase().contains('mysql')) ||
           (commandDbType == 2 && currentDbType.name.toLowerCase().contains('sqlite'));
  }
  
  /// Get target version from value file header
  static String _getValueFileVersion(String valueContent) {
    final lines = valueContent.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('!')) {
        return trimmed.substring(1);
      }
    }
    return '0.0'; // Default version if not found
  }
  
  /// Update CSV data from external update files
  static Future<void> _updateCsvDataFromFiles() async {
    try {
      await _loadCsvData();
    } catch (e) {
      print('Error updating CSV data: $e');
    }
  }
  
  /// Load CSV data from assets
  static Future<void> _loadCsvData() async {
    final csvFiles = ['kantor', 'klu', 'map', 'jatuhtempo', 'maxlapor'];
    
    for (final csvFile in csvFiles) {
      await loadSpecificCsvData('update$csvFile');
    }
  }
  
  /// Load specific CSV data from external files and return actual record count
  static Future<int> loadSpecificCsvData(String csvType) async {
    try {
      final csvFileName = csvType.replaceFirst('update', '');
      final csvData = await _readExternalFile('data/$csvFileName.csv');
      print('Loading CSV from external file: data/$csvFileName.csv');
      
      // Parse CSV - detect delimiter automatically
      String delimiter = ';'; // Default
      
      // Try to detect delimiter by checking the first few lines
      final firstLines = csvData.split('\n').take(3).toList();
      int semicolonCount = 0;
      int commaCount = 0;
      
      for (final line in firstLines) {
        semicolonCount += ';'.allMatches(line).length;
        commaCount += ','.allMatches(line).length;
      }
      
      // Use the delimiter that appears more frequently
      if (commaCount > semicolonCount) {
        delimiter = ',';
        print('Detected CSV delimiter: comma (,)');
      } else {
        delimiter = ';';
        print('Detected CSV delimiter: semicolon (;)');
      }
      
      // Manual CSV parsing to preserve leading zeros
      final lines = csvData.split('\n').where((line) => line.trim().isNotEmpty).toList();
      if (lines.isEmpty) return 0;

      // Parse header
      final headers = lines[0].split(delimiter).map((e) => e.trim()).toList();

      // Clear existing data
      await DatabaseService.rawQuery('DELETE FROM `$csvFileName`');

      // Insert new data
      int recordsInserted = 0;
      for (int i = 1; i < lines.length; i++) {
        final row = lines[i].split(delimiter);
        if (row.isEmpty) continue;

        final data = <String, dynamic>{};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          // Preserve leading zeros by treating all as String
          data[headers[j]] = row[j].trim();
        }

        // Use raw SQL to avoid automatic timestamp columns during migration
        final fields = data.keys.map((key) => '`$key`').join(', ');
        final placeholders = List.filled(data.length, '?').join(', ');
        await DatabaseService.rawQuery(
          'INSERT INTO `$csvFileName` ($fields) VALUES ($placeholders)',
          data.values.toList(),
        );
        recordsInserted++;
      }

      print('Loaded $recordsInserted records into $csvFileName table');
      return recordsInserted;
      
    } catch (e) {
      print('Failed to load CSV data for $csvType: $e');
      
      // Check if this is a critical database error that should stop migration
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('unknown database') || 
          errorMessage.contains('access denied') ||
          errorMessage.contains('connection refused')) {
        print('Critical database error during CSV loading. Stopping migration.');
        rethrow; // Stop the migration process
      }
      // Continue for non-critical errors (like missing CSV files)
      return 0; // Return 0 records for failed CSV loads
    }
  }

  /// Read file from external data directory (for production deployment)
  /// Read external file (public wrapper for CSV import integration)
  static Future<String> readExternalFile(String relativePath) async {
    return await _readExternalFile(relativePath);
  }

  static Future<String> _readExternalFile(String relativePath) async {
    // Get executable directory
    final executablePath = Platform.resolvedExecutable;
    final executableDir = path.dirname(executablePath);
    final filePath = path.join(executableDir, relativePath);
    
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('External file not found: $filePath');
    }
    
    return await file.readAsString(encoding: utf8);
  }

  /// Get data directory path for external files
  /// During development: looks in project root/data
  /// During production: looks next to executable/data
  static String getDataDirectory() {
    final executablePath = Platform.resolvedExecutable;
    final executableDir = path.dirname(executablePath);
    
    // Check if we're in development mode (executable is in build directory)
    if (executablePath.contains('build\\windows\\x64\\runner\\Debug') || 
        executablePath.contains('build\\windows\\x64\\runner\\Release') ||
        executablePath.contains('build/windows/x64/runner/Debug') ||
        executablePath.contains('build/windows/x64/runner/Release')) {
      
      // Development mode: go up to project root and look for data directory
      final projectRoot = executableDir
          .replaceAll('\\build\\windows\\x64\\runner\\Debug', '')
          .replaceAll('\\build\\windows\\x64\\runner\\Release', '')
          .replaceAll('/build/windows/x64/runner/Debug', '')
          .replaceAll('/build/windows/x64/runner/Release', '');
      
      return path.join(projectRoot, 'data');
    }
    
    // Production mode: look next to executable
    return path.join(executableDir, 'data');
  }

  /// Get images directory path for external files
  static String getImagesDirectory() {
    final executablePath = Platform.resolvedExecutable;
    final executableDir = path.dirname(executablePath);
    return path.join(executableDir, 'images');
  }
  
  /// Read content of update file from external data directory
  static Future<String?> _readUpdateFile(String version) async {
    try {
      final content = await _readExternalFile('data/update-$version');
      print('Loading update-$version from external data directory');
      return content;
    } catch (e) {
      print('Could not read update-$version from data directory: $e');
      return null;
    }
  }
  
  /// Apply commands from an update file
  static Future<void> _applyUpdateFile(String updateContent) async {
    final commands = _parseStructFile(updateContent);
    
    for (final command in commands) {
      switch (command.type) {
        case CommandType.sql:
          if (_shouldExecuteForCurrentDatabase(command.dbType)) {
            try {
              await DatabaseService.rawQuery(command.sql);
              print('Executed: ${command.sql}');
            } catch (e) {
              print('Failed to execute SQL: ${command.sql}, Error: $e');
            }
          }
          break;
          
        case CommandType.csvUpdate:
          await loadSpecificCsvData(command.csvType);
          break;
      }
    }
  }
}

/// Database command types
enum CommandType {
  sql,
  csvUpdate,
}

/// Database command model
class DatabaseCommand {
  final CommandType type;
  final int dbType; // 0=general, 1=MySQL, 2=SQLite
  final String sql;
  final String csvType;
  
  DatabaseCommand({
    required this.type,
    this.dbType = 0,
    this.sql = '',
    this.csvType = '',
  });
}