import 'lib/data/services/settings_service.dart';
import 'lib/data/services/database_service.dart';
import 'lib/data/services/auth_service.dart';

/// Test login functionality after fixing the group_type column issue
void main() async {
  print('🧪 Testing Login Functionality...');
  
  try {
    // Initialize services
    await SettingsService.initialize();
    print('✓ Settings service initialized');
    
    await DatabaseService.initializeFromSettings();
    print('✓ Database service initialized');
    
    // Test connection
    final isConnected = await DatabaseService.testConnection();
    print('✓ Database connection: ${isConnected ? "SUCCESS" : "FAILED"}');
    
    if (!isConnected) {
      print('❌ Cannot proceed without database connection');
      return;
    }
    
    // Test login
    print('\n🔐 Testing login with admin/admin123...');
    final authService = AuthService();
    final user = await authService.login('admin', 'admin123');
    
    if (user != null) {
      print('✅ Login successful!');
      print('   User ID: ${user.id}');
      print('   Username: ${user.username}');
      print('   Full name: ${user.fullname}');
      print('   Group: ${user.group} (${user.userGroup.displayName})');
      print('   Permissions: ${user.userGroup.permissions}');
    } else {
      print('❌ Login failed');
      
      // Let's check what's in the database
      print('\n🔍 Debugging: Checking database content...');
      final users = await DatabaseService.rawQuery('SELECT * FROM users WHERE username = ?', ['admin']);
      if (users.isNotEmpty) {
        final dbUser = users.first;
        print('📋 Database user data:');
        for (final entry in dbUser.entries) {
          print('   ${entry.key}: ${entry.value} (${entry.value.runtimeType})');
        }
      } else {
        print('❌ No admin user found in database');
      }
    }
    
  } catch (e, stackTrace) {
    print('❌ Test failed: $e');
    print('Stack trace: $stackTrace');
  }
}