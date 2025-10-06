/// User model for authentication and user management
/// Migrated from Qt users table structure
class UserModel {
  final int id;
  final String username;
  final String password;
  final String fullname;
  final int group;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.fullname,
    required this.group,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: _safeStringCast(json['username']),
      password: _safeStringCast(json['password']),
      fullname: _safeStringCast(json['fullname']),
      group: (json['group_type'] ?? json['group']) as int, // Handle both column names
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  /// Helper method to safely cast any value to String (handles Blob and other types)
  static String _safeStringCast(dynamic value) {
    if (value == null) return '';
    
    if (value is String) {
      return value;
    } else if (value is List<int>) {
      // Handle Blob data (binary data as List<int>)
      try {
        return String.fromCharCodes(value);
      } catch (e) {
        print('Error converting binary data to string: $e');
        return '';
      }
    } else {
      // For any other type, convert to string
      return value.toString();
    }
  }

  /// Helper method to parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    if (value is DateTime) {
      return value; // Already a DateTime object (MySQL direct result)
    }
    
    if (value is String) {
      try {
        return DateTime.parse(value); // Parse from string (SQLite or formatted result)
      } catch (e) {
        print('Error parsing datetime string: $value, error: $e');
        return null;
      }
    }
    
    print('Unexpected datetime type: ${value.runtimeType}, value: $value');
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'fullname': fullname,
      'group_type': group, // Use correct column name
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? password,
    String? fullname,
    int? group,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      fullname: fullname ?? this.fullname,
      group: group ?? this.group,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  UserGroupType get userGroup => UserGroupType.fromValue(group);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.username == username &&
        other.password == password &&
        other.fullname == fullname &&
        other.group == group &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      username,
      password,
      fullname,
      group,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, fullname: $fullname, group: $group)';
  }
}

/// User group enumeration with permissions
enum UserGroupType {
  administrator(0),
  user(1),
  guest(2);

  const UserGroupType(this.value);
  final int value;

  static UserGroupType fromValue(int value) {
    return UserGroupType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserGroupType.guest,
    );
  }

  String get displayName {
    switch (this) {
      case UserGroupType.administrator:
        return 'Administrator';
      case UserGroupType.user:
        return 'User';
      case UserGroupType.guest:
        return 'Guest';
    }
  }

  List<String> get permissions {
    switch (this) {
      case UserGroupType.administrator:
        return ['read', 'write', 'delete', 'admin', 'import', 'export'];
      case UserGroupType.user:
        return ['read', 'write', 'import', 'export'];
      case UserGroupType.guest:
        return ['read'];
    }
  }
}