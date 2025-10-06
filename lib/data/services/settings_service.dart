import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:path/path.dart';
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
  
  // Encryption for database passwords
  static late final Encrypter _encrypter;
  static late final IV _iv;
  static bool _encryptionInitialized = false;

  /// Initialize settings service
  static Future<void> initialize() async {
    // Get the directory where the executable is located
    final executablePath = Platform.resolvedExecutable;
    final executableDirectory = Directory(dirname(executablePath));
    
    // Use the executable directory for settings.ini (like Qt legacy)
    _settingsPath = join(executableDirectory.path, _settingsFileName);
    
    print('Settings path: $_settingsPath');
    
    // Initialize encryption for database passwords
    _initializeEncryption();
    
    await _loadSettings();
  }

  /// Initialize encryption for database passwords
  static void _initializeEncryption() {
    if (_encryptionInitialized) return;
    
    try {
      // Create a machine-specific key based on executable path and hostname
      final machineInfo = '${Platform.resolvedExecutable}${Platform.localHostname}MPN-Info-Secret';
      final keyBytes = sha256.convert(utf8.encode(machineInfo)).bytes;
      final key = Key(Uint8List.fromList(keyBytes));
      _encrypter = Encrypter(AES(key));
      _iv = IV.fromSecureRandom(16);
      _encryptionInitialized = true;
    } catch (e) {
      print('Failed to initialize encryption: $e');
      // Fallback: create a simple key if machine-specific approach fails
      final fallbackKey = Key.fromSecureRandom(32);
      _encrypter = Encrypter(AES(fallbackKey));
      _iv = IV.fromSecureRandom(16);
      _encryptionInitialized = true;
    }
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
        // Do NOT create default settings file automatically
        // This allows the login page to detect missing settings.ini
        print('Settings file not found at: $_settingsPath');
      }
    } catch (e) {
      print('Error loading settings: $e');
      // Do NOT create default settings on error
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
  /// Note: password field contains the hashed password, not plain text
  static DatabaseConfig getDatabaseConfig() {
    return DatabaseConfig(
      type: _getDatabaseTypeFromString(getSetting('Database.type', 'sqlite')),
      host: getSetting('Database.host', 'localhost'),
      port: int.tryParse(getSetting('Database.port', '3306')) ?? 3306,
      name: getSetting('Database.name', 'mpn_info'),
      username: getSetting('Database.username', 'mpn_user'),
      password: getSetting('Database.password', ''), // This returns the hashed password
      useSsl: getSetting('Database.use_ssl', 'false').toLowerCase() == 'true',
    );
  }

  /// Verify database password and return config with plain text password for connection
  /// Returns null if the provided password doesn't match the stored hash
  static DatabaseConfig? getDatabaseConfigWithPassword(String plainTextPassword) {
    final config = getDatabaseConfig();
    
    // If no password is stored, allow empty password
    if (config.password.isEmpty && plainTextPassword.isEmpty) {
      return config.copyWith(password: plainTextPassword);
    }
    
    // Verify the provided password against stored hash
    if (verifyPassword(plainTextPassword, config.password)) {
      return config.copyWith(password: plainTextPassword);
    }
    
    return null; // Password verification failed
  }

  /// Check if database configuration requires authentication
  static bool requiresDatabasePassword() {
    final config = getDatabaseConfig();
    return config.password.isNotEmpty;
  }

  /// Get database configuration with decrypted password for actual connections
  static DatabaseConfig getDatabaseConfigWithDecryptedPassword() {
    final config = getDatabaseConfig();
    
    // Decrypt the password if it's encrypted
    String decryptedPassword = config.password;
    if (config.password.isNotEmpty) {
      decryptedPassword = _decryptPassword(config.password);
    }
    
    return config.copyWith(password: decryptedPassword);
  }

  /// Save database configuration
  static Future<void> saveDatabaseConfig(DatabaseConfig config) async {
    await setSetting('Database.type', config.type.name);
    await setSetting('Database.host', config.host);
    await setSetting('Database.port', config.port.toString());
    await setSetting('Database.name', config.name);
    await setSetting('Database.username', config.username);
    
    // Handle password encryption
    String passwordToSave;
    if (config.password.isEmpty) {
      // If password is empty, keep the existing stored password (don't overwrite)
      passwordToSave = getSetting('Database.password', '');
    } else if (_isPasswordEncrypted(config.password)) {
      // If it's already encrypted, save as-is
      passwordToSave = config.password;
    } else {
      // Encrypt the new plain text password
      passwordToSave = _encryptPassword(config.password);
    }
    
    await setSetting('Database.password', passwordToSave);
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

  /// Encrypt password for secure storage
  static String _encryptPassword(String password) {
    if (password.isEmpty) return '';
    if (!_encryptionInitialized) _initializeEncryption();
    
    try {
      final encrypted = _encrypter.encrypt(password, iv: _iv);
      // Store IV + encrypted data as base64
      return base64.encode(_iv.bytes + encrypted.bytes);
    } catch (e) {
      print('Failed to encrypt password: $e');
      // If encryption fails, return original (fallback for development)
      return password;
    }
  }

  /// Decrypt password for database connections
  static String _decryptPassword(String encryptedPassword) {
    if (encryptedPassword.isEmpty) return '';
    if (!_encryptionInitialized) _initializeEncryption();
    
    try {
      final combined = base64.decode(encryptedPassword);
      if (combined.length < 16) {
        // Too short to be encrypted, assume plain text
        return encryptedPassword;
      }
      
      final iv = IV(combined.sublist(0, 16));
      final encryptedBytes = combined.sublist(16);
      final encrypted = Encrypted(encryptedBytes);
      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      print('Failed to decrypt password, assuming plain text: $e');
      // If decryption fails, assume it's plain text (backwards compatibility)
      return encryptedPassword;
    }
  }

  /// Check if a password string appears to be encrypted
  static bool _isPasswordEncrypted(String password) {
    if (password.isEmpty || password.length < 20) return false;
    try {
      base64.decode(password);
      return true; // If it's valid base64 and long enough, assume encrypted
    } catch (e) {
      return false;
    }
  }

  /// Verify a plain text password against stored encrypted password
  static bool verifyPassword(String plainTextPassword, String storedPassword) {
    // If stored password is empty, only allow empty plain text
    if (storedPassword.isEmpty) return plainTextPassword.isEmpty;
    
    // If stored password appears encrypted, decrypt and compare
    if (_isPasswordEncrypted(storedPassword)) {
      final decryptedStored = _decryptPassword(storedPassword);
      return decryptedStored == plainTextPassword;
    }
    
    // Otherwise, compare directly (plain text fallback)
    return plainTextPassword == storedPassword;
  }
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
