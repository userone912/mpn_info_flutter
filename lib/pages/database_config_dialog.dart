import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../../data/services/settings_service.dart';
import '../../data/services/database_service.dart';
import '../../data/services/database_migration_service.dart';
import '../../core/constants/app_enums.dart';

/// Database configuration dialog
/// Allows users to select and configure database connection
class DatabaseConfigDialog extends ConsumerStatefulWidget {
  const DatabaseConfigDialog({super.key});

  @override
  ConsumerState<DatabaseConfigDialog> createState() => _DatabaseConfigDialogState();
}

class _DatabaseConfigDialogState extends ConsumerState<DatabaseConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  DatabaseType _selectedType = DatabaseType.sqlite;
  bool _useSsl = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loadCurrentConfig() {
    final config = SettingsService.getDatabaseConfig();
    setState(() {
      _selectedType = config.type;
      _hostController.text = config.host;
      _portController.text = config.port.toString();
      _nameController.text = config.name;
      _usernameController.text = config.username;
      // Don't show the hashed password in the UI - leave it empty for security
      _passwordController.text = '';
      _useSsl = config.useSsl;
    });
  }

  /// Check if SQLite database file exists in executable directory
  Future<bool> _checkSqliteFileExists() async {
    try {
      final executablePath = Platform.resolvedExecutable;
      final executableDirectory = Directory(path.dirname(executablePath));
      final dbPath = path.join(executableDirectory.path, 'data.db');
      final dbFile = File(dbPath);
      return await dbFile.exists();
    } catch (e) {
      print('Error checking SQLite file: $e');
      return false;
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final config = _buildDatabaseConfig();
      
      // Test connection with the configuration
      await DatabaseService.initializeWithConfig(config);
      final isConnected = await DatabaseService.testConnection();

      if (!mounted) return;

      if (isConnected) {
        // Run database migration after successful connection
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Koneksi berhasil! Memeriksa struktur database...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
        
        final migrationSuccess = await DatabaseMigrationService.migrateDatabase();
        
        if (!mounted) return;
        
        if (migrationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database berhasil disinkronisasi!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Koneksi berhasil! Database sudah up-to-date.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Koneksi database gagal!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveAndConnect() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final config = _buildDatabaseConfig();
      
      // Initialize database with the configuration
      await DatabaseService.initializeWithConfig(config);
      
      // Run database migration to ensure schema is up-to-date
      await DatabaseMigrationService.migrateDatabase();
      
      if (!mounted) return;
      Navigator.of(context).pop(true); // Return success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  DatabaseConfig _buildDatabaseConfig() {
    return DatabaseConfig(
      type: _selectedType,
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text) ?? 3306,
      name: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      useSsl: _useSsl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Konfigurasi Database'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Database Type Selection
                DropdownButtonFormField<DatabaseType>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipe Database',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: DatabaseType.sqlite,
                      child: Row(
                        children: [
                          Icon(Icons.storage, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          const Text('SQLite (Lokal)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: DatabaseType.mysql,
                      child: Row(
                        children: [
                          Icon(Icons.cloud, color: Colors.orange.shade600),
                          const SizedBox(width: 8),
                          const Text('MySQL (Server)'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                      // Set default values based on type
                      if (value == DatabaseType.sqlite) {
                        _hostController.text = 'localhost';
                        _portController.text = '0';
                        _nameController.text = 'data.db';
                        _usernameController.text = '';
                        _passwordController.text = '';
                      } else {
                        _hostController.text = 'localhost';
                        _portController.text = '3306';
                        _nameController.text = 'mpninfo';
                        _usernameController.text = 'mpninfo';
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // MySQL Configuration (only show when MySQL is selected)
                if (_selectedType == DatabaseType.mysql) ...[
                  // Host
                  TextFormField(
                    controller: _hostController,
                    decoration: const InputDecoration(
                      labelText: 'Host/Server',
                      border: OutlineInputBorder(),
                      hintText: 'localhost atau IP address',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Host tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Port
                  TextFormField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      border: OutlineInputBorder(),
                      hintText: '3306',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Port tidak boleh kosong';
                      }
                      final port = int.tryParse(value);
                      if (port == null || port < 1 || port > 65535) {
                        return 'Port harus antara 1-65535';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Database Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Database',
                      border: OutlineInputBorder(),
                      hintText: 'mpn_info',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama database tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Username
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                      hintText: 'mpn_user',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // SSL Option
                  CheckboxListTile(
                    title: const Text('Gunakan SSL'),
                    value: _useSsl,
                    onChanged: (value) {
                      setState(() {
                        _useSsl = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ] else ...[
                  // SQLite Info with file existence check
                  FutureBuilder<bool>(
                    future: _checkSqliteFileExists(),
                    builder: (context, snapshot) {
                      final fileExists = snapshot.data ?? false;
                      final isLoading = !snapshot.hasData;
                      
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: fileExists ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: fileExists ? Colors.green.shade200 : Colors.orange.shade200,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                if (isLoading)
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                                    ),
                                  )
                                else
                                  Icon(
                                    fileExists ? Icons.check_circle : Icons.warning,
                                    color: fileExists ? Colors.green.shade700 : Colors.orange.shade700,
                                  ),
                                const SizedBox(width: 8),
                                Text(
                                  'Database Lokal (SQLite)',
                                  style: TextStyle(
                                    color: fileExists ? Colors.green.shade700 : Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              fileExists
                                  ? 'File data.db ditemukan di direktori aplikasi. Aplikasi siap digunakan.'
                                  : 'File data.db tidak ditemukan di direktori aplikasi. '
                                    'Pastikan file data.db sudah tersedia dengan struktur database yang sesuai.',
                              style: TextStyle(
                                color: fileExists ? Colors.green.shade700 : Colors.orange.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        if (_selectedType == DatabaseType.mysql)
          ElevatedButton(
            onPressed: _isLoading ? null : _testConnection,
            child: _isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Test Koneksi'),
          ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveAndConnect,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Simpan & Gunakan'),
        ),
      ],
    );
  }
}