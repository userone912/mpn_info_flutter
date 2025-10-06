import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';

// Mock the SettingsService for testing
class MockDatabaseConfig {
  final String type;
  final String host;
  final int port;
  final String name;
  final String username;
  final String password;
  final bool useSsl;

  MockDatabaseConfig({
    required this.type,
    required this.host,
    required this.port,
    required this.name,
    required this.username,
    required this.password,
    this.useSsl = false,
  });

  MockDatabaseConfig copyWith({
    String? type,
    String? host,
    int? port,
    String? name,
    String? username,
    String? password,
    bool? useSsl,
  }) {
    return MockDatabaseConfig(
      type: type ?? this.type,
      host: host ?? this.host,
      port: port ?? this.port,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      useSsl: useSsl ?? this.useSsl,
    );
  }
}

class MockSettingsService {
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool _isPasswordHashed(String password) {
    return password.length == 64 && RegExp(r'^[a-f0-9]+$').hasMatch(password);
  }

  static bool verifyPassword(String plainTextPassword, String storedPassword) {
    if (!_isPasswordHashed(storedPassword)) {
      return plainTextPassword == storedPassword;
    }
    return _hashPassword(plainTextPassword) == storedPassword;
  }

  static MockDatabaseConfig? getDatabaseConfigWithPassword(String plainTextPassword, String storedHashedPassword) {
    if (storedHashedPassword.isEmpty && plainTextPassword.isEmpty) {
      return MockDatabaseConfig(
        type: 'mysql',
        host: 'localhost',
        port: 3306,
        name: 'test_db',
        username: 'test_user',
        password: plainTextPassword,
      );
    }
    
    if (verifyPassword(plainTextPassword, storedHashedPassword)) {
      return MockDatabaseConfig(
        type: 'mysql',
        host: 'localhost',
        port: 3306,
        name: 'test_db',
        username: 'test_user',
        password: plainTextPassword,
      );
    }
    
    return null;
  }
}

void main() {
  print('Testing password hashing functionality...');
  
  final originalPassword = 'my_secret_password';
  print('Original password: $originalPassword');
  
  // Hash the password
  final hashedPassword = MockSettingsService._hashPassword(originalPassword);
  print('Hashed password: $hashedPassword');
  print('Hash length: ${hashedPassword.length}');
  
  // Check if password is detected as hashed
  final isHashed = MockSettingsService._isPasswordHashed(hashedPassword);
  print('Is password hashed: $isHashed');
  
  // Verify correct password
  final verificationResult1 = MockSettingsService.verifyPassword(originalPassword, hashedPassword);
  print('Verification with correct password: $verificationResult1');
  
  // Verify wrong password
  final verificationResult2 = MockSettingsService.verifyPassword('wrong_password', hashedPassword);
  print('Verification with wrong password: $verificationResult2');
  
  // Test getDatabaseConfigWithPassword with correct password
  final authenticatedConfig = MockSettingsService.getDatabaseConfigWithPassword(originalPassword, hashedPassword);
  if (authenticatedConfig != null) {
    print('Authentication successful - password: ${authenticatedConfig.password}');
  } else {
    print('Authentication failed');
  }
  
  // Test getDatabaseConfigWithPassword with wrong password
  final failedAuthConfig = MockSettingsService.getDatabaseConfigWithPassword('wrong_password', hashedPassword);
  if (failedAuthConfig != null) {
    print('ERROR: Authentication should have failed!');
  } else {
    print('Authentication correctly failed for wrong password');
  }
  
  // Test backwards compatibility with plain text password
  print('\nTesting backwards compatibility...');
  final plainTextStoredPassword = 'old_plain_password';
  final backwardsCompatResult = MockSettingsService.verifyPassword('old_plain_password', plainTextStoredPassword);
  print('Backwards compatibility test: $backwardsCompatResult');
  
  print('\nPassword hashing test completed successfully!');
}