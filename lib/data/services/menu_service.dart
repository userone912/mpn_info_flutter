import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_models.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../core/constants/menu_configurations.dart';

/// Service for loading dynamic menus from compiled constants
/// Menu configurations are compiled into the application and cannot be modified by users
class MenuService {
  /// Load menu configuration based on user role
  MenuConfig loadMenuForUser(UserModel user) {
    return MenuConfigurations.getMenuForUser(user);
  }

  /// Load menu configuration for admin users
  MenuConfig loadAdminMenu() {
    return MenuConfigurations.getAdminMenu();
  }

  /// Load menu configuration for regular users
  MenuConfig loadUserMenu() {
    return MenuConfigurations.getUserMenu();
  }

  /// Get menu action from string
  MenuAction? getMenuAction(String? actionString) {
    return MenuActionExtension.fromString(actionString);
  }
}

/// Provider for menu service
final menuServiceProvider = Provider<MenuService>((ref) {
  return MenuService();
});

/// Provider for current user's menu configuration
final userMenuProvider = Provider.autoDispose<MenuConfig?>((ref) {
  final menuService = ref.read(menuServiceProvider);
  // Get current user from auth provider
  final authState = ref.watch(authProvider);
  if (authState.user == null) {
    return null;
  }
  return menuService.loadMenuForUser(authState.user!);
});
