import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/login_page.dart';
import 'core/constants/app_constants.dart';
import 'data/services/database_helper.dart';
import 'data/services/settings_service.dart';
import 'data/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database factory for desktop platforms
  DatabaseHelper.initialize();
  
  // Initialize settings service
  await SettingsService.initialize();
  
  // Try to initialize database from existing settings
  try {
    await DatabaseService.initializeFromSettings();
    print('Database initialized from settings');
  } catch (e) {
    print('Database not yet configured: $e');
    // This is fine, user will configure it through the login page
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
