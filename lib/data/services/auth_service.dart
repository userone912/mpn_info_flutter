import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'database_service.dart';
import '../../core/constants/app_constants.dart';

/// Authentication service for user login/logout and session management
class AuthService {

  /// Authenticate user with username and password
  Future<UserModel?> login(String username, String password) async {
    try {
      // Compare password directly (no hashing) since database stores plain text
      final result = await DatabaseService.query(
        AppConstants.tableUsers,
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return UserModel.fromJson(result.first);
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  /// Register new user (admin only)
  Future<bool> register({
    required String username,
    required String password,
    required String fullname,
    required int group,
  }) async {
    try {
      // Check if username already exists
      final existing = await DatabaseService.query(
        AppConstants.tableUsers,
        where: 'username = ?',
        whereArgs: [username],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        return false; // Username already exists
      }

      // Store password as plain text (to match database structure)
      await DatabaseService.insert(AppConstants.tableUsers, {
        'username': username,
        'password': password,
        'fullname': fullname,
        'group_type': group,
      });

      return true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  /// Change user password
  Future<bool> changePassword(int userId, String oldPassword, String newPassword) async {
    try {
      // Verify old password (plain text comparison)
      final user = await DatabaseService.query(
        AppConstants.tableUsers,
        where: 'id = ? AND password = ?',
        whereArgs: [userId, oldPassword],
        limit: 1,
      );

      if (user.isEmpty) {
        return false; // Old password is incorrect
      }

      // Update with new password (plain text)
      final result = await DatabaseService.update(
        AppConstants.tableUsers,
        {'password': newPassword},
        'id = ?',
        [userId],
      );

      return result > 0;
    } catch (e) {
      print('Change password error: $e');
      return false;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(int userId) async {
    try {
      final result = await DatabaseService.query(
        AppConstants.tableUsers,
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return UserModel.fromJson(result.first);
      }
      return null;
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  /// Get all users (admin only)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final result = await DatabaseService.query(
        AppConstants.tableUsers,
        orderBy: 'username',
      );

      return result.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      print('Get all users error: $e');
      return [];
    }
  }

  /// Update user information
  Future<bool> updateUser(UserModel user) async {
    try {
      final result = await DatabaseService.update(
        AppConstants.tableUsers,
        user.toJson(),
        'id = ?',
        [user.id],
      );

      return result > 0;
    } catch (e) {
      print('Update user error: $e');
      return false;
    }
  }

  /// Delete user (admin only)
  Future<bool> deleteUser(int userId) async {
    try {
      final result = await DatabaseService.delete(
        AppConstants.tableUsers,
        'id = ?',
        [userId],
      );

      return result > 0;
    } catch (e) {
      print('Delete user error: $e');
      return false;
    }
  }

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final result = await DatabaseService.query(
        AppConstants.tableUsers,
        where: 'username = ?',
        whereArgs: [username],
        limit: 1,
      );

      return result.isEmpty;
    } catch (e) {
      print('Username check error: $e');
      return false;
    }
  }
}

/// Authentication state management with Riverpod
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get isAuthenticated => user != null;
  
  UserGroupType? get userGroup => user?.userGroup;
  
  bool get isAdmin => userGroup == UserGroupType.administrator;
  
  bool get canWrite => userGroup != null && 
      (userGroup == UserGroupType.administrator || userGroup == UserGroupType.user);
}

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  /// Login user
  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.login(username, password);
      if (user != null) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Username atau password salah',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan saat login: $e',
      );
      return false;
    }
  }

  /// Logout user
  void logout() {
    state = const AuthState();
  }

  /// Update current user
  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth state notifier provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(authService);
});