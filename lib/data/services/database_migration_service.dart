import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'database_service.dart';

/// Database Migration Service
/// Handles schema synchronization from assets/data files
class DatabaseMigrationService {
  
  /// Check and update database schema from assets or external files
  static Future<bool> migrateDatabase() async {
    try {
      print('Starting database migration...');
      
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
      
      // Try to read from external files first, then fall back to assets
      String structData;
      String valueData;
      
      try {
        // Try external files (production deployment)
        structData = await _readExternalFile('data/db-struct');
        valueData = await _readExternalFile('data/db-value');
        print('Using external data files');
      } catch (e) {
        // Fall back to bundled assets (development)
        structData = await rootBundle.loadString('assets/data/db-struct');
        valueData = await rootBundle.loadString('assets/data/db-value');
        print('Using bundled assets');
      }
      
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
  
  /// Set database version
  static Future<void> _setDatabaseVersion(String version) async {
    try {
      // Check if version record exists
      final existing = await DatabaseService.query(
        'info',
        where: '`key` = ?',
        whereArgs: ['db.version'],
        limit: 1,
      );
      
      if (existing.isNotEmpty) {
        // Use raw query to avoid automatic timestamp columns
        await DatabaseService.rawQuery(
          'UPDATE `info` SET `value` = ? WHERE `key` = ?',
          [version, 'db.version'],
        );
      } else {
        // Use raw query to avoid automatic timestamp columns
        await DatabaseService.rawQuery(
          'INSERT INTO `info` (`key`, `value`) VALUES (?, ?)',
          ['db.version', version],
        );
      }
    } catch (e) {
      print('Could not set database version: $e');
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
        await _loadSpecificCsvData(command.csvType);
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
  
  /// Load CSV data from assets
  static Future<void> _loadCsvData() async {
    final csvFiles = ['kantor', 'klu', 'map', 'jatuhtempo', 'maxlapor'];
    
    for (final csvFile in csvFiles) {
      await _loadSpecificCsvData('update$csvFile');
    }
  }
  
  /// Load specific CSV data from external files or assets
  static Future<void> _loadSpecificCsvData(String csvType) async {
    try {
      final csvFileName = csvType.replaceFirst('update', '');
      String csvData;
      
      try {
        // Try external file first
        csvData = await _readExternalFile('data/$csvFileName.csv');
        print('Loading CSV from external file: data/$csvFileName.csv');
      } catch (e) {
        // Fall back to bundled assets
        csvData = await rootBundle.loadString('assets/data/$csvFileName.csv');
        print('Loading CSV from assets: assets/data/$csvFileName.csv');
      }
      
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
      
      final List<List<dynamic>> csvTable = CsvToListConverter(
        fieldDelimiter: delimiter,
        eol: '\n',
      ).convert(csvData);
      
      if (csvTable.isEmpty) return;
      
      // First row is header
      final headers = csvTable[0].map((e) => e.toString().trim()).toList();
      
      // Clear existing data
      await DatabaseService.rawQuery('DELETE FROM `$csvFileName`');
      
      // Insert new data
      for (int i = 1; i < csvTable.length; i++) {
        final row = csvTable[i];
        if (row.isEmpty) continue;
        
        final data = <String, dynamic>{};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          // Trim data values to remove trailing whitespace/newlines
          data[headers[j]] = row[j]?.toString().trim() ?? '';
        }
        
        // Use raw SQL to avoid automatic timestamp columns during migration
        final fields = data.keys.map((key) => '`$key`').join(', ');
        final placeholders = List.filled(data.length, '?').join(', ');
        await DatabaseService.rawQuery(
          'INSERT INTO `$csvFileName` ($fields) VALUES ($placeholders)',
          data.values.toList(),
        );
      }
      
      print('Loaded ${csvTable.length - 1} records into $csvFileName table');
      
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
    }
  }

  /// Read file from external data directory (for production deployment)
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

  /// Get executable directory path for external files
  static String getDataDirectory() {
    final executablePath = Platform.resolvedExecutable;
    final executableDir = path.dirname(executablePath);
    return path.join(executableDir, 'data');
  }

  /// Get images directory path for external files
  static String getImagesDirectory() {
    final executablePath = Platform.resolvedExecutable;
    final executableDir = path.dirname(executablePath);
    return path.join(executableDir, 'images');
  }

  /// Check if external data files exist
  static Future<bool> hasExternalDataFiles() async {
    try {
      final dataDir = getDataDirectory();
      final structFile = File(path.join(dataDir, 'db-struct'));
      final valueFile = File(path.join(dataDir, 'db-value'));
      
      return await structFile.exists() && await valueFile.exists();
    } catch (e) {
      return false;
    }
  }
  
  /// Get list of available update file versions
  static Future<List<String>> _getAvailableUpdateFiles() async {
    final versions = <String>[];
    
    // Check for known update files in assets (complete list)
    final knownVersions = [
      '1.3', '1.4', '1.5', '1.6', '1.7', '1.8', '1.9',
      '2.0', '2.0.1', '2.1', '2.1.1', '2.2', '2.3', '2.4', '2.5', '2.6', '2.7', '2.8', '2.8.1', '2.9',
      '3.0', '3.1', '3.2', '3.3', '3.4', '3.5', '3.6', '3.7', '3.8', '3.9',
      '4.0', '4.1', '4.2', '4.3', '4.4', '4.5', '4.6'
    ];
    for (final version in knownVersions) {
      try {
        final content = await rootBundle.loadString('assets/data/update-$version');
        if (content.isNotEmpty) {
          versions.add(version);
        }
      } catch (e) {
        // File doesn't exist, skip
      }
    }
    
    return versions;
  }
  
  /// Read content of update file
  static Future<String?> _readUpdateFile(String version) async {
    try {
      return await rootBundle.loadString('assets/data/update-$version');
    } catch (e) {
      print('Could not read update-$version: $e');
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
          await _loadSpecificCsvData(command.csvType);
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