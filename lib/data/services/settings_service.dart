import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_enums.dart';

/// Settings service to manage application configuration
/// Handles reading/writing settings.ini file
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _settingsFileName = 'settings.ini';
  static String? _settingsPath;
  static Map<String, String> _settings = {};

  /// Initialize settings service
  static Future<void> initialize() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final appDirectory = Directory(join(documentsDirectory.path, 'MPN-Info'));
    
    // Create app directory if it doesn't exist
    if (!await appDirectory.exists()) {
      await appDirectory.create(recursive: true);
    }
    
    _settingsPath = join(appDirectory.path, _settingsFileName);
    await _loadSettings();
  }

  /// Load settings from settings.ini file
  static Future<void> _loadSettings() async {
    try {
      final file = File(_settingsPath!);
      if (await file.exists()) {
        final content = await file.readAsString();
        _parseIniContent(content);
        print('Settings loaded from: $_settingsPath');
      } else {
        // Create default settings file
        await _createDefaultSettings();
      }
    } catch (e) {
      print('Error loading settings: $e');
      await _createDefaultSettings();
    }
  }

  /// Parse INI file content
  static void _parseIniContent(String content) {
    _settings.clear();
    final lines = content.split('\n');
    String currentSection = '';

    for (String line in lines) {
      line = line.trim();
      
      // Skip empty lines and comments
      if (line.isEmpty || line.startsWith('#') || line.startsWith(';')) {
        continue;
      }
      
      // Handle sections [section_name]
      if (line.startsWith('[') && line.endsWith(']')) {
        currentSection = line.substring(1, line.length - 1);
        continue;
      }
      
      // Handle key=value pairs
      final equalIndex = line.indexOf('=');
      if (equalIndex > 0) {
        final key = line.substring(0, equalIndex).trim();
        final value = line.substring(equalIndex + 1).trim();
        final fullKey = currentSection.isNotEmpty ? '${currentSection}.$key' : key;
        _settings[fullKey] = value;
      }
    }
  }

  /// Create default settings file
  static Future<void> _createDefaultSettings() async {
    final defaultContent = '''# MPN-Info Flutter Application Settings
# Generated on ${DateTime.now().toIso8601String()}

[Database]
type=sqlite
host=localhost
port=3306
name=mpn_info
username=mpn_user
password=
use_ssl=false

[Application]
theme=light
language=id
auto_backup=true
backup_interval=daily

[Window]
width=1200
height=800
maximized=false
remember_size=true
''';

    try {
      final file = File(_settingsPath!);
      await file.writeAsString(defaultContent);
      _parseIniContent(defaultContent);
      print('Default settings created at: $_settingsPath');
    } catch (e) {
      print('Error creating default settings: $e');
    }
  }

  /// Save settings to file
  static Future<void> _saveSettings() async {
    try {
      final content = _generateIniContent();
      final file = File(_settingsPath!);
      await file.writeAsString(content);
      print('Settings saved to: $_settingsPath');
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  /// Generate INI file content from current settings
  static String _generateIniContent() {
    final buffer = StringBuffer();
    buffer.writeln('# MPN-Info Flutter Application Settings');
    buffer.writeln('# Last updated: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    // Group settings by section
    final sections = <String, Map<String, String>>{};
    
    for (final entry in _settings.entries) {
      final parts = entry.key.split('.');
      if (parts.length == 2) {
        final section = parts[0];
        final key = parts[1];
        sections.putIfAbsent(section, () => <String, String>{});
        sections[section]![key] = entry.value;
      } else {
        // Handle keys without sections
        sections.putIfAbsent('General', () => <String, String>{});
        sections['General']![entry.key] = entry.value;
      }
    }

    // Write sections
    for (final sectionEntry in sections.entries) {
      buffer.writeln('[${sectionEntry.key}]');
      for (final setting in sectionEntry.value.entries) {
        buffer.writeln('${setting.key}=${setting.value}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Get setting value
  static String getSetting(String key, [String defaultValue = '']) {
    return _settings[key] ?? defaultValue;
  }

  /// Set setting value
  static Future<void> setSetting(String key, String value) async {
    _settings[key] = value;
    await _saveSettings();
  }

  /// Get database configuration
  static DatabaseConfig getDatabaseConfig() {
    return DatabaseConfig(
      type: _getDatabaseTypeFromString(getSetting('Database.type', 'sqlite')),
      host: getSetting('Database.host', 'localhost'),
      port: int.tryParse(getSetting('Database.port', '3306')) ?? 3306,
      name: getSetting('Database.name', 'mpn_info'),
      username: getSetting('Database.username', 'mpn_user'),
      password: getSetting('Database.password', ''),
      useSsl: getSetting('Database.use_ssl', 'false').toLowerCase() == 'true',
    );
  }

  /// Save database configuration
  static Future<void> saveDatabaseConfig(DatabaseConfig config) async {
    await setSetting('Database.type', config.type.name);
    await setSetting('Database.host', config.host);
    await setSetting('Database.port', config.port.toString());
    await setSetting('Database.name', config.name);
    await setSetting('Database.username', config.username);
    await setSetting('Database.password', config.password);
    await setSetting('Database.use_ssl', config.useSsl.toString());
  }

  /// Convert string to DatabaseType enum
  static DatabaseType _getDatabaseTypeFromString(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'mysql':
        return DatabaseType.mysql;
      case 'postgresql':
        return DatabaseType.postgresql;
      case 'sqlite':
      default:
        return DatabaseType.sqlite;
    }
  }

  /// Get all settings as map
  static Map<String, String> getAllSettings() {
    return Map<String, String>.from(_settings);
  }

  /// Reset settings to default
  static Future<void> resetToDefault() async {
    _settings.clear();
    await _createDefaultSettings();
  }

  /// Check if settings file exists
  static Future<bool> settingsFileExists() async {
    if (_settingsPath == null) return false;
    final file = File(_settingsPath!);
    return await file.exists();
  }

  /// Get settings file path
  static String? getSettingsFilePath() => _settingsPath;
}

/// Database configuration data class
class DatabaseConfig {
  final DatabaseType type;
  final String host;
  final int port;
  final String name;
  final String username;
  final String password;
  final bool useSsl;

  const DatabaseConfig({
    required this.type,
    required this.host,
    required this.port,
    required this.name,
    required this.username,
    required this.password,
    this.useSsl = false,
  });

  DatabaseConfig copyWith({
    DatabaseType? type,
    String? host,
    int? port,
    String? name,
    String? username,
    String? password,
    bool? useSsl,
  }) {
    return DatabaseConfig(
      type: type ?? this.type,
      host: host ?? this.host,
      port: port ?? this.port,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      useSsl: useSsl ?? this.useSsl,
    );
  }

  @override
  String toString() {
    return 'DatabaseConfig(type: $type, host: $host, port: $port, name: $name, username: $username, useSsl: $useSsl)';
  }
}
