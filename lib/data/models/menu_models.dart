class MenuConfig {
  final String version;
  final String menuTitle;
  final List<MenuSection> menus;

  const MenuConfig({
    required this.version,
    required this.menuTitle,
    required this.menus,
  });

  factory MenuConfig.fromJson(Map<String, dynamic> json) {
    return MenuConfig(
      version: json['version'] as String,
      menuTitle: json['menuTitle'] as String,
      menus: (json['menus'] as List<dynamic>)
          .map((e) => MenuSection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MenuSection {
  final String id;
  final String title;
  final String icon;
  final List<MenuItem> items;

  const MenuSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.items,
  });

  factory MenuSection.fromJson(Map<String, dynamic> json) {
    return MenuSection(
      id: json['id'] as String,
      title: json['title'] as String,
      icon: json['icon'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MenuItem {
  final String id;
  final String? title;
  final String? icon;
  final String? action;
  final bool enabled;
  final String type; // 'item' or 'divider'

  const MenuItem({
    required this.id,
    this.title,
    this.icon,
    this.action,
    this.enabled = true,
    this.type = 'item',
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      title: json['title'] as String?,
      icon: json['icon'] as String?,
      action: json['action'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      type: json['type'] as String? ?? 'item',
    );
  }
  
  bool get isDivider => type == 'divider';
}

enum MenuAction {
  logout,
  exit,
  importSeksi,
  importPegawai,
  importUser,
  importSpmkp,
  importRencanaPenerimaan,
  updateDatabase,
  navigateKlu,
  navigateMap,
  navigatePenerimaan,
  updateReferenceData,
  aboutDialog,
  comingSoon,
  manageSeksi,
  managePegawai,
  manageUsers,
  settings,
}

extension MenuActionExtension on MenuAction {
  static MenuAction? fromString(String? action) {
    switch (action) {
      case 'logout':
        return MenuAction.logout;
      case 'exit':
        return MenuAction.exit;
      case 'import_seksi':
        return MenuAction.importSeksi;
      case 'import_pegawai':
        return MenuAction.importPegawai;
      case 'import_user':
        return MenuAction.importUser;
      case 'import_rencana':
        return MenuAction.importRencanaPenerimaan;
      case 'update_database':
        return MenuAction.updateDatabase;
      case 'navigate_klu':
        return MenuAction.navigateKlu;
      case 'navigate_map':
        return MenuAction.navigateMap;
      case 'navigate_penerimaan':
        return MenuAction.navigatePenerimaan;
      case 'update_reference_data':
        return MenuAction.updateReferenceData;
      case 'about_dialog':
        return MenuAction.aboutDialog;
      case 'manage_seksi':
        return MenuAction.manageSeksi;
      case 'manage_pegawai':
        return MenuAction.managePegawai;
      case 'manage_users':
        return MenuAction.manageUsers;
      case 'settings':
        return MenuAction.settings;
      default:
        return MenuAction.comingSoon;
    }
  }
}