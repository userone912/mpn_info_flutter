import 'package:flutter/material.dart';

/// Helper class to map icon strings from JSON to IconData
class MenuIconHelper {
  static const Map<String, IconData> _iconMap = {
    // System icons
    'admin_panel_settings': Icons.admin_panel_settings,
    'account_circle': Icons.account_circle,
    'logout': Icons.logout,
    'exit_to_app': Icons.exit_to_app,
    
    // Storage and data icons
    'storage': Icons.storage,
    'dataset': Icons.dataset,
    'cloud': Icons.cloud,
    'cloud_download': Icons.cloud_download,
    
    // User and people icons
    'business': Icons.business,
    'person': Icons.person,
    'group': Icons.group,
    'people': Icons.people,
    'apartment': Icons.apartment,
    'assignment_ind': Icons.assignment_ind,
    'business_center': Icons.business_center,
    
    // Document icons
    'description': Icons.description,
    'document_scanner': Icons.document_scanner,
    'folder': Icons.folder,
    'receipt': Icons.receipt,
    'schedule': Icons.schedule,
    
    // Action icons
    'download': Icons.download,
    'upload': Icons.upload,
    'backup': Icons.backup,
    'import_export': Icons.import_export,
    'login': Icons.login,
    'refresh': Icons.refresh,
    'assignment': Icons.assignment,
    
    // Reference and data icons
    'library_books': Icons.library_books,
    'category': Icons.category,
    'account_balance_wallet': Icons.account_balance_wallet,
    
    // Tools and settings icons
    'settings': Icons.settings,
    'build': Icons.build,
    'star': Icons.star,
    'code': Icons.code,
    'auto_awesome': Icons.auto_awesome,
    'lock': Icons.lock,
    'edit': Icons.edit,
    
    // Integration icons
    'integration_instructions': Icons.integration_instructions,
    'verified_user': Icons.verified_user,
    
    // Help icons
    'help': Icons.help,
    'info': Icons.info,
  };

  /// Get IconData from string name
  static IconData getIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return Icons.help_outline; // Default icon
    }
    
    return _iconMap[iconName] ?? Icons.help_outline;
  }

  /// Check if icon exists in the map
  static bool hasIcon(String iconName) {
    return _iconMap.containsKey(iconName);
  }

  /// Get all available icon names
  static List<String> getAvailableIcons() {
    return _iconMap.keys.toList()..sort();
  }
}