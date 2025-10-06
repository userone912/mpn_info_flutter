import '../../data/models/menu_models.dart';
import '../../data/models/user_model.dart';

/// Static menu configurations for different user roles
/// These are compiled into the application and cannot be modified by users
class MenuConfigurations {
  
  /// Administrator menu configuration
  static const MenuConfig adminMenuConfig = MenuConfig(
    version: '1.0.0',
    menuTitle: 'Administrator Menu',
    menus: [
      MenuSection(
        id: 'sistem',
        title: 'Sistem',
        icon: 'admin_panel_settings',
        items: [
          MenuItem(
            id: 'logout',
            title: 'Logout',
            icon: 'logout',
            action: 'logout',
            enabled: true,
          ),
          MenuItem(
            id: 'exit',
            title: 'Exit',
            icon: 'exit_to_app',
            action: 'exit',
            enabled: true,
          ),
        ],
      ),
      MenuSection(
        id: 'database',
        title: 'Database',
        icon: 'storage',
        items: [
          MenuItem(
            id: 'update_database',
            title: 'Update Database',
            icon: 'sync',
            action: 'update_database',
            enabled: true,
          ),
          MenuItem(
            id: 'divider_legacy',
            type: 'divider',
          ),
          MenuItem(
            id: 'import_seksi',
            title: 'Import Seksi',
            icon: 'business',
            action: 'import_seksi',
            enabled: true,
          ),
          MenuItem(
            id: 'import_pegawai',
            title: 'Import Pegawai',
            icon: 'person',
            action: 'import_pegawai',
            enabled: true,
          ),
          MenuItem(
            id: 'import_user',
            title: 'Import User',
            icon: 'group',
            action: 'import_user',
            enabled: true,
          ),
          MenuItem(
            id: 'import_spmkp',
            title: 'Import SPMKP',
            icon: 'description',
            action: 'import_spmkp',
            enabled: true,
          ),
          MenuItem(
            id: 'import_rencana',
            title: 'Import Rencana Penerimaan',
            icon: 'schedule',
            action: 'import_rencana',
            enabled: true,
          ),
          MenuItem(
            id: 'import_mpn',
            title: 'Import MPN',
            icon: 'receipt',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'import_spm',
            title: 'Import SPM',
            icon: 'description',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'import_pkpm',
            title: 'Import PKPM',
            icon: 'document_scanner',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'import_pbk',
            title: 'Import PBK',
            icon: 'folder',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'divider_1',
            type: 'divider',
          ),
          MenuItem(
            id: 'import_masterfile',
            title: 'Import Masterfile',
            icon: 'storage',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'import_master_spt',
            title: 'Import Master SPT',
            icon: 'storage',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'import_assign_klu',
            title: 'Import Assign KLU',
            icon: 'assignment',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'import_wp_besar',
            title: 'Import Wajib Pajak Besar',
            icon: 'business_center',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'assign_wp',
            title: 'Assign Wajib Pajak >',
            icon: 'assignment_ind',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'divider_2',
            type: 'divider',
          ),
          MenuItem(
            id: 'import_db_lokal',
            title: 'Import Dari Database Lokal >',
            icon: 'storage',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'import_appportal',
            title: 'Import Data AppPortal >',
            icon: 'cloud_download',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'divider_3',
            type: 'divider',
          ),
          MenuItem(
            id: 'export_database',
            title: 'Export Database',
            icon: 'upload',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'backup_settings',
            title: 'Backup Settings',
            icon: 'backup',
            action: 'coming_soon',
            enabled: true,
          ),
        ],
      ),
      MenuSection(
        id: 'appportal',
        title: 'AppPortal',
        icon: 'cloud',
        items: [
          MenuItem(
            id: 'login_appportal',
            title: 'Login AppPortal',
            icon: 'login',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'download_mpn',
            title: 'Download MPN',
            icon: 'download',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'download_spm',
            title: 'Download SPM',
            icon: 'download',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'download_spmkp',
            title: 'Download SPMKP',
            icon: 'download',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'download_spmpp',
            title: 'Download SPMPP',
            icon: 'download',
            action: 'coming_soon',
            enabled: true,
          ),
        ],
      ),
      MenuSection(
        id: 'eksternal',
        title: 'Eksternal',
        icon: 'integration_instructions',
        items: [
          MenuItem(
            id: 'dth_rth',
            title: 'DTH/RTH',
            icon: 'integration_instructions',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'import_dth',
            title: 'Import DTH',
            icon: 'import_export',
            action: 'coming_soon',
            enabled: true,
          ),
        ],
      ),
      MenuSection(
        id: 'sikka',
        title: 'Sikka',
        icon: 'verified_user',
        items: [
          MenuItem(
            id: 'login_sikka',
            title: 'Login Sikka',
            icon: 'login',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'download_pegawai',
            title: 'Download Pegawai',
            icon: 'download',
            action: 'coming_soon',
            enabled: true,
          ),
        ],
      ),
      MenuSection(
        id: 'data',
        title: 'Data',
        icon: 'dataset',
        items: [
          MenuItem(
            id: 'spmkp',
            title: 'SPMKP',
            icon: 'description',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'spmpp',
            title: 'SPMPP',
            icon: 'description',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'pbk',
            title: 'PBK',
            icon: 'description',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'manage_spmkp',
            title: 'Manage SPMKP',
            icon: 'edit',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'manage_spmpp',
            title: 'Manage SPMPP',
            icon: 'edit',
            action: 'coming_soon',
            enabled: true,
          ),
        ],
      ),
      MenuSection(
        id: 'referensi',
        title: 'Referensi',
        icon: 'library_books',
        items: [
          MenuItem(
            id: 'klu',
            title: 'KLU',
            icon: 'category',
            action: 'navigate_klu',
            enabled: true,
          ),
          MenuItem(
            id: 'map',
            title: 'MAP',
            icon: 'account_balance_wallet',
            action: 'navigate_map',
            enabled: true,
          ),
          MenuItem(
            id: 'divider_ref',
            type: 'divider',
          ),
          MenuItem(
            id: 'update_referensi',
            title: 'Update Referensi',
            icon: 'refresh',
            action: 'update_reference_data',
            enabled: true,
          ),
        ],
      ),
      MenuSection(
        id: 'pengaturan',
        title: 'Pengaturan',
        icon: 'settings',
        items: [
          MenuItem(
            id: 'manage_seksi',
            title: 'Manage Seksi',
            icon: 'apartment',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'manage_pegawai',
            title: 'Manage Pegawai',
            icon: 'people',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'manage_users',
            title: 'Manage Users',
            icon: 'group',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'settings',
            title: 'Settings',
            icon: 'settings',
            action: 'office_config',
            enabled: true,
          ),
        ],
      ),
      MenuSection(
        id: 'tools',
        title: 'Tools',
        icon: 'build',
        items: [
          MenuItem(
            id: 'wp_favorit',
            title: 'WP Favorit',
            icon: 'star',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'execute_sql',
            title: 'Execute SQL',
            icon: 'code',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'web_automation',
            title: 'Web Automation',
            icon: 'auto_awesome',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'change_password',
            title: 'Change Password',
            icon: 'lock',
            action: 'coming_soon',
            enabled: true,
          ),
        ],
      ),
      MenuSection(
        id: 'bantuan',
        title: 'Bantuan',
        icon: 'help',
        items: [
          MenuItem(
            id: 'manual',
            title: 'Manual',
            icon: 'help',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'tentang',
            title: 'Tentang',
            icon: 'info',
            action: 'about_dialog',
            enabled: true,
          ),
        ],
      ),
    ],
  );

  /// Regular user menu configuration
  static const MenuConfig userMenuConfig = MenuConfig(
    version: '1.0.0',
    menuTitle: 'User Menu',
    menus: [
      MenuSection(
        id: 'sistem',
        title: 'Sistem',
        icon: 'account_circle',
        items: [
          MenuItem(
            id: 'logout',
            title: 'Logout',
            icon: 'logout',
            action: 'logout',
            enabled: true,
          ),
          MenuItem(
            id: 'exit',
            title: 'Exit',
            icon: 'exit_to_app',
            action: 'exit',
            enabled: true,
          ),
        ],
      ),
      MenuSection(
        id: 'data',
        title: 'Data',
        icon: 'dataset',
        items: [
          MenuItem(
            id: 'spmkp',
            title: 'SPMKP',
            icon: 'description',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'spmpp',
            title: 'SPMPP',
            icon: 'description',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'pbk',
            title: 'PBK',
            icon: 'description',
            action: 'coming_soon',
            enabled: true,
          ),
        ],
      ),
      MenuSection(
        id: 'referensi',
        title: 'Referensi',
        icon: 'library_books',
        items: [
          MenuItem(
            id: 'klu',
            title: 'KLU',
            icon: 'category',
            action: 'navigate_klu',
            enabled: true,
          ),
          MenuItem(
            id: 'map',
            title: 'MAP',
            icon: 'account_balance_wallet',
            action: 'navigate_map',
            enabled: true,
          ),
        ],
      ),
      MenuSection(
        id: 'tools',
        title: 'Tools',
        icon: 'build',
        items: [
          MenuItem(
            id: 'wp_favorit',
            title: 'WP Favorit',
            icon: 'star',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'change_password',
            title: 'Change Password',
            icon: 'lock',
            action: 'coming_soon',
            enabled: true,
          ),
        ],
      ),
      MenuSection(
        id: 'bantuan',
        title: 'Bantuan',
        icon: 'help',
        items: [
          MenuItem(
            id: 'manual',
            title: 'Manual',
            icon: 'help',
            action: 'coming_soon',
            enabled: true,
          ),
          MenuItem(
            id: 'tentang',
            title: 'Tentang',
            icon: 'info',
            action: 'about_dialog',
            enabled: true,
          ),
        ],
      ),
    ],
  );

  /// Get menu configuration for a specific user
  static MenuConfig getMenuForUser(UserModel user) {
    return user.userGroup == UserGroupType.administrator 
        ? adminMenuConfig 
        : userMenuConfig;
  }

  /// Get admin menu configuration
  static MenuConfig getAdminMenu() => adminMenuConfig;

  /// Get user menu configuration  
  static MenuConfig getUserMenu() => userMenuConfig;
}