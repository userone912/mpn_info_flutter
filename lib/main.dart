import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/login_page.dart';
import 'core/constants/app_constants.dart';
import 'data/services/database_helper.dart';
import 'pages/test_gauge.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database factory for desktop platforms
  DatabaseHelper.initialize();
  
  // DO NOT auto-initialize settings service - let the login page handle this
  // This prevents automatic creation of settings.ini and data.db files
  
  runApp(const ProviderScope(child: MyApp()));
}


// void main() {
//   runApp(const MaterialApp(
//     home: TestGaugePage(),
//     debugShowCheckedModeBanner: false,
//   ));
// }

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
