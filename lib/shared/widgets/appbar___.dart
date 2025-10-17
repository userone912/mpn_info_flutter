import 'package:flutter/material.dart';
import '../../data/services/dashboard_data_service2.dart';
import 'app_logo.dart';
import '../../core/constants/app_constants.dart';

// ...existing code...
// --- AppBar-related helper methods copied from DashboardPage ---
Widget buildAppBarMenu(
  BuildContext context,
  String title,
  List<PopupMenuEntry<VoidCallback>> items,
) {
  return PopupMenuButton<VoidCallback>(
    onSelected: (callback) => callback(),
    itemBuilder: (context) => items,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}

PopupMenuItem<VoidCallback> buildMenuItem(
  String title,
  IconData icon,
  VoidCallback onTap,
) {
  return PopupMenuItem<VoidCallback>(
    value: onTap,
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14)),
      ],
    ),
  );
}

List<PopupMenuEntry<VoidCallback>> buildMenuItems(
  BuildContext context,
  List<dynamic> items,
  MenuActionCallbacks callbacks,
) {
  // Note: MenuItem type is dynamic here, adapt as needed
  return items.map<PopupMenuEntry<VoidCallback>>((item) {
    if (item.isDivider) {
      return const PopupMenuDivider();
    } else {
      return buildMenuItem(
        item.title ?? '',
        item.icon ?? Icons.menu,
        () => handleMenuAction(context, item.action, callbacks),
      );
    }
  }).toList();
}

Widget buildDynamicMenuBar(BuildContext context, dynamic menuConfig, MenuActionCallbacks callbacks) {
  final isMobile = MediaQuery.of(context).size.width < 600;
  if (isMobile) {
    return const SizedBox.shrink();
  }
  List<Widget> menuWidgets = [
    ...menuConfig.menus.map(
      (section) => buildAppBarMenu(
        context,
        section.title,
        buildMenuItems(context, section.items, callbacks),
      ),
    ),
  ];
  return Row(children: menuWidgets);
}

class MenuActionCallbacks {
  final void Function()? onLogout;
  final void Function()? onExit;
  final void Function()? onImportSeksi;
  final void Function()? onImportPegawai;
  final void Function()? onImportUser;
  final void Function()? onImportRencanaPenerimaan;
  final void Function()? onUpdateDatabase;
  final void Function()? onNavigateKlu;
  final void Function()? onNavigateMap;
  final void Function()? onUpdateReferenceData;
  final void Function()? onAboutDialog;
  final void Function()? onManageSeksi;
  final void Function()? onManagePegawai;
  final void Function()? onSettings;
  final void Function()? onManageUsers;
  final void Function(String feature)? onComingSoon;
  final void Function()? onNavigatePenerimaan;

  const MenuActionCallbacks({
    this.onLogout,
    this.onExit,
    this.onImportSeksi,
    this.onImportPegawai,
    this.onImportUser,
    this.onImportRencanaPenerimaan,
    this.onUpdateDatabase,
    this.onNavigateKlu,
    this.onNavigateMap,
    this.onUpdateReferenceData,
    this.onAboutDialog,
    this.onManageSeksi,
    this.onManagePegawai,
    this.onSettings,
    this.onManageUsers,
    this.onComingSoon,
    this.onNavigatePenerimaan,
  });
}

void handleMenuAction(BuildContext context, String? actionString, MenuActionCallbacks callbacks) {
  switch (actionString) {
    case 'navigatePenerimaan':
      callbacks.onNavigatePenerimaan?.call();
      break;
    case 'logout':
      callbacks.onLogout?.call();
      break;
    case 'exit':
      callbacks.onExit?.call();
      break;
    case 'importSeksi':
      callbacks.onImportSeksi?.call();
      break;
    case 'importPegawai':
      callbacks.onImportPegawai?.call();
      break;
    case 'importUser':
      callbacks.onImportUser?.call();
      break;
    case 'importRencanaPenerimaan':
      callbacks.onImportRencanaPenerimaan?.call();
      break;
    case 'updateDatabase':
      callbacks.onUpdateDatabase?.call();
      break;
    case 'navigateKlu':
      callbacks.onNavigateKlu?.call();
      break;
    case 'navigateMap':
      callbacks.onNavigateMap?.call();
      break;
    case 'updateReferenceData':
      callbacks.onUpdateReferenceData?.call();
      break;
    case 'aboutDialog':
      callbacks.onAboutDialog?.call();
      break;
    case 'manageSeksi':
      callbacks.onManageSeksi?.call();
      break;
    case 'managePegawai':
      callbacks.onManagePegawai?.call();
      break;
    case 'settings':
      callbacks.onSettings?.call();
      break;
    case 'manageUsers':
      callbacks.onManageUsers?.call();
      break;
    case 'comingSoon':
    default:
      callbacks.onComingSoon?.call(actionString ?? 'Unknown Action');
      break;
  }
}
// --- End helper methods ---


class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final dynamic menuConfig;
  final dynamic authState;
  final void Function(dynamic user) onShowProfile;
  final VoidCallback onLogout;
  final Widget Function(BuildContext, dynamic) buildDynamicMenuBar;

  const DashboardAppBar({
    Key? key,
    required this.menuConfig,
    required this.authState,
    required this.onShowProfile,
    required this.onLogout,
    required this.buildDynamicMenuBar,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          const AppLogo.small(fallbackIconColor: Colors.white),
          const SizedBox(width: 12),
          Text(AppConstants.appName),
        ],
      ),
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_forever),
          tooltip: 'Clear Disk Cache',
          onPressed: () async {
            final svc = DashboardDataService();
            int deleted = await svc.clearAllDiskCaches();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Disk cache dihapus: $deleted file'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            } else {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    buildDynamicMenuBar(context, menuConfig),
                    const SizedBox(width: 16),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'profile':
                            if (authState.user != null) {
                              onShowProfile(authState.user);
                            }
                            break;
                          case 'logout':
                            onLogout();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person, color: Colors.grey.shade700),
                              const SizedBox(width: 8),
                              const Text('Profile'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Logout',
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 16,
                              child: Text(
                                authState.user?.fullname
                                        .substring(0, 1)
                                        .toUpperCase() ??
                                    'U',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authState.user?.fullname ?? 'User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  authState.user?.userGroup.displayName ?? '',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_drop_down, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
