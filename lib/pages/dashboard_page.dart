import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/auth_service.dart';
import '../data/services/csv_import_service.dart';
import '../data/models/user_model.dart';
import '../data/models/import_result.dart';
import '../core/constants/app_constants.dart';
import '../shared/widgets/app_logo.dart';
import '../shared/dialogs/about_dialog.dart' as app_about;
import 'login_page.dart';
import 'reference/klu_page.dart';
import 'reference/map_page.dart';

/// Main dashboard page after login
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      appBar: AppBar(
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
          // Menu bar similar to original Qt app
          if (authState.isAdmin) ...[
            _buildAppBarMenu(context, 'Sistem', [
              _buildMenuItem('Logout', Icons.logout, () => _handleLogout(context, ref)),
              _buildMenuItem('Exit', Icons.exit_to_app, () => Navigator.of(context).pop()),
            ]),
            _buildAppBarMenu(context, 'Database', [
              _buildMenuItem('Import Seksi', Icons.business, () => _importSeksi(context)),
              _buildMenuItem('Import Pegawai', Icons.person, () => _importPegawai(context)),
              _buildMenuItem('Import User', Icons.group, () => _importUser(context)),
              _buildMenuItem('Import SPMKP', Icons.description, () => _importSpmkp(context)),
              _buildMenuItem('Import Rencana Penerimaan', Icons.schedule, () => _showComingSoon(context, 'Import Rencana Penerimaan')),
              _buildMenuItem('Import MPN', Icons.receipt, () => _showComingSoon(context, 'Import MPN')),
              _buildMenuItem('Import SPM', Icons.description, () => _showComingSoon(context, 'Import SPM')),
              _buildMenuItem('Import PKPM', Icons.document_scanner, () => _showComingSoon(context, 'Import PKPM')),
              _buildMenuItem('Import PBK', Icons.folder, () => _showComingSoon(context, 'Import PBK')),
              const PopupMenuDivider(),
              _buildMenuItem('Import Masterfile', Icons.storage, () => _showComingSoon(context, 'Import Masterfile')),
              _buildMenuItem('Import Master SPT', Icons.storage, () => _showComingSoon(context, 'Import Master SPT')),
              _buildMenuItem('Import Assign KLU', Icons.assignment, () => _showComingSoon(context, 'Import Assign KLU')),
              _buildMenuItem('Import Wajib Pajak Besar', Icons.business_center, () => _showComingSoon(context, 'Import Wajib Pajak Besar')),
              _buildMenuItem('Assign Wajib Pajak >', Icons.assignment_ind, () => _showComingSoon(context, 'Assign Wajib Pajak Menu')),
              const PopupMenuDivider(),
              _buildMenuItem('Import Dari Database Lokal >', Icons.storage, () => _showComingSoon(context, 'Import Database Lokal Menu')),
              _buildMenuItem('Import Data AppPortal >', Icons.cloud_download, () => _showComingSoon(context, 'Import AppPortal Menu')),
              const PopupMenuDivider(),
              _buildMenuItem('Export Database', Icons.upload, () => _showComingSoon(context, 'Export Database')),
              _buildMenuItem('Backup Settings', Icons.backup, () => _showComingSoon(context, 'Backup Settings')),
            ]),
            _buildAppBarMenu(context, 'AppPortal', [
              _buildMenuItem('Login AppPortal', Icons.login, () => _showComingSoon(context, 'Login AppPortal')),
              _buildMenuItem('Download MPN', Icons.download, () => _showComingSoon(context, 'Download MPN')),
              _buildMenuItem('Download SPM', Icons.download, () => _showComingSoon(context, 'Download SPM')),
              _buildMenuItem('Download SPMKP', Icons.download, () => _showComingSoon(context, 'Download SPMKP')),
              _buildMenuItem('Download SPMPP', Icons.download, () => _showComingSoon(context, 'Download SPMPP')),
            ]),
            _buildAppBarMenu(context, 'Eksternal', [
              _buildMenuItem('DTH/RTH', Icons.integration_instructions, () => _showComingSoon(context, 'DTH/RTH')),
              _buildMenuItem('Import DTH', Icons.import_export, () => _showComingSoon(context, 'Import DTH')),
            ]),
            _buildAppBarMenu(context, 'Sikka', [
              _buildMenuItem('Login Sikka', Icons.login, () => _showComingSoon(context, 'Login Sikka')),
              _buildMenuItem('Download Pegawai', Icons.download, () => _showComingSoon(context, 'Download Pegawai')),
            ]),
            _buildAppBarMenu(context, 'Data', [
              _buildMenuItem('SPMKP', Icons.description, () => _showComingSoon(context, 'SPMKP')),
              _buildMenuItem('SPMPP', Icons.description, () => _showComingSoon(context, 'SPMPP')),
              _buildMenuItem('PBK', Icons.description, () => _showComingSoon(context, 'PBK')),
              _buildMenuItem('Manage SPMKP', Icons.edit, () => _showComingSoon(context, 'Manage SPMKP')),
              _buildMenuItem('Manage SPMPP', Icons.edit, () => _showComingSoon(context, 'Manage SPMPP')),
            ]),
            _buildAppBarMenu(context, 'Referensi', [
              _buildMenuItem('KLU', Icons.category, () => _navigateToKlu(context)),
              _buildMenuItem('Maps', Icons.map, () => _navigateToMap(context)),
              _buildMenuItem('Import KLU', Icons.import_export, () => _showComingSoon(context, 'Import KLU')),
              _buildMenuItem('Import Maps', Icons.import_export, () => _showComingSoon(context, 'Import Maps')),
            ]),
            _buildAppBarMenu(context, 'Pengaturan', [
              _buildMenuItem('Manage Seksi', Icons.apartment, () => _showComingSoon(context, 'Manage Seksi')),
              _buildMenuItem('Manage Pegawai', Icons.people, () => _showComingSoon(context, 'Manage Pegawai')),
              _buildMenuItem('Manage Users', Icons.group, () => _showComingSoon(context, 'Manage Users')),
              _buildMenuItem('Settings', Icons.settings, () => _showComingSoon(context, 'Settings')),
            ]),
            _buildAppBarMenu(context, 'Tools', [
              _buildMenuItem('WP Favorit', Icons.star, () => _showComingSoon(context, 'WP Favorit')),
              _buildMenuItem('Execute SQL', Icons.code, () => _showComingSoon(context, 'Execute SQL')),
              _buildMenuItem('Web Automation', Icons.auto_awesome, () => _showComingSoon(context, 'Web Automation')),
              _buildMenuItem('Change Password', Icons.lock, () => _showComingSoon(context, 'Change Password')),
            ]),
          ],
          _buildAppBarMenu(context, 'Bantuan', [
            _buildMenuItem('Manual', Icons.help, () => _showComingSoon(context, 'Manual')),
            _buildMenuItem('Tentang', Icons.info, () => app_about.AboutDialog.show(context)),
          ]),
          const SizedBox(width: 16),
          // User profile section
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _showProfile(context, authState.user!);
                  break;
                case 'logout':
                  _handleLogout(context, ref);
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
                    Text('Logout', style: TextStyle(color: Colors.red.shade700)),
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
                      authState.user?.fullname.substring(0, 1).toUpperCase() ?? 'U',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top toolbar with office and year selection
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: 'KPP Pratama Denpasar Barat',
                    decoration: const InputDecoration(
                      labelText: 'Kantor',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'KPP Pratama Denpasar Barat', child: Text('KPP Pratama Denpasar Barat')),
                      DropdownMenuItem(value: 'KPP Pratama Denpasar Timur', child: Text('KPP Pratama Denpasar Timur')),
                      DropdownMenuItem(value: 'KPP Pratama Badung', child: Text('KPP Pratama Badung')),
                    ],
                    onChanged: (value) {
                      // Handle kantor selection
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: '2025',
                    decoration: const InputDecoration(
                      labelText: 'Tahun Pembayaran',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: '2025', child: Text('2025')),
                      DropdownMenuItem(value: '2024', child: Text('2024')),
                      DropdownMenuItem(value: '2023', child: Text('2023')),
                      DropdownMenuItem(value: '2022', child: Text('2022')),
                    ],
                    onChanged: (value) {
                      // Handle year selection
                    },
                  ),
                ),
                const Spacer(), // Push content to the left and avoid overflow
              ],
            ),
            const SizedBox(height: 24),

            // Main content area
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left panel with gauge and statistics
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Gauge widget
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    'Penerimaan Kantor Tahun 2025',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Placeholder for gauge - will implement with custom painter later
                                  Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.grey.shade300, width: 2),
                                    ),
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: Container(
                                            width: 180,
                                            height: 180,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: RadialGradient(
                                                colors: [Colors.grey.shade100, Colors.grey.shade300],
                                              ),
                                            ),
                                            child: const Center(
                                              child: Text(
                                                '0%',
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Statistics table
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatRow('Total Penerimaan', '0,00'),
                                _buildStatRow('Total SPMKP dan SPMPP', '0,00'),
                                _buildStatRow('Total PBK', '0,00'),
                                _buildStatRow('Total Netto', '0,00'),
                                _buildStatRow('Total Renpen', '0,00'),
                                _buildStatRow('Pencapaian', '0,00%'),
                                _buildStatRow('Pertumbuhan', 'nan%'),
                                const Divider(),
                                _buildStatRow('Data MPN:', ''),
                                _buildStatRow('Data SPM:', ''),
                                _buildStatRow('MPN-Info v0.14.0', ''),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                  const SizedBox(width: 16),

                  // Right panel with charts
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Accumulation comparison chart
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Perbandingan Akumulasi Penerimaan',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Chart placeholder\n(Renpen 2025, Realisasi 2025, Realisasi 2024)',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Monthly comparison chart
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Perbandingan Penerimaan Per Bulan',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Chart placeholder\n(MPN, SPM, SPMKP/PP, MPN Lalu, SPM Lalu, SPMKP/PP Lalu)',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarMenu(BuildContext context, String title, List<PopupMenuEntry<VoidCallback>> items) {
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

  PopupMenuItem<VoidCallback> _buildMenuItem(String title, IconData icon, VoidCallback onTap) {
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showProfile(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Pengguna'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileRow('Username', user.username),
            _buildProfileRow('Nama Lengkap', user.fullname),
            _buildProfileRow('Role', user.userGroup.displayName),
            _buildProfileRow('Dibuat', user.createdAt?.toString().split(' ')[0] ?? '-'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // CSV Import Methods
  Future<void> _importSeksi(BuildContext context) async {
    await _performImport(context, 'Import Seksi', CsvImportService.importSeksi);
  }

  Future<void> _importPegawai(BuildContext context) async {
    await _performImport(context, 'Import Pegawai', CsvImportService.importPegawai);
  }

  Future<void> _importUser(BuildContext context) async {
    await _performImport(context, 'Import User', CsvImportService.importUser);
  }

  Future<void> _importSpmkp(BuildContext context) async {
    await _performImport(context, 'Import SPMKP', CsvImportService.importSpmkp);
  }

  // Reference data navigation methods
  void _navigateToKlu(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height * 0.7,
          constraints: const BoxConstraints(
            minWidth: 500,
            minHeight: 400,
            maxWidth: 900,
            maxHeight: 600,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const KluPage(),
        ),
      ),
    );
  }

  void _navigateToMap(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height * 0.7,
          constraints: const BoxConstraints(
            minWidth: 500,
            minHeight: 400,
            maxWidth: 900,
            maxHeight: 600,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const MapPage(),
        ),
      ),
    );
  }

  /// Generic import handler with progress dialog
  Future<void> _performImport(
    BuildContext context,
    String title,
    Future<ImportResult> Function() importFunction,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('$title sedang berlangsung...'),
          ],
        ),
      ),
    );

    try {
      final result = await importFunction();
      
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      // Show result dialog
      if (context.mounted) {
        _showImportResult(context, title, result);
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      // Show error dialog
      if (context.mounted) {
        _showErrorDialog(context, title, e.toString());
      }
    }
  }

  /// Show import result dialog
  void _showImportResult(BuildContext context, String title, ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.isSuccess ? Icons.check_circle : 
                  result.isCancelled ? Icons.cancel : Icons.error,
                  color: result.isSuccess ? Colors.green : 
                         result.isCancelled ? Colors.orange : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.summary,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (result.hasErrors && result.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Detail Error:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                width: double.maxFinite,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    result.errors.join('\n'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog(BuildContext context, String title, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Fitur akan segera hadir!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}