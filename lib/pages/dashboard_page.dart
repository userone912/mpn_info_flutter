import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/auth_service.dart';
import '../data/services/csv_import_service.dart';
import '../data/services/dashboard_data_service.dart';
import '../data/services/database_import_service.dart';
import '../data/services/database_service.dart';
import '../data/services/menu_service.dart';
import 'penerimaan_page.dart';
import '../data/models/user_model.dart';
import '../data/models/import_result.dart';
import '../data/models/menu_models.dart';
import '../core/constants/app_constants.dart';
import '../shared/widgets/app_logo.dart';
import '../shared/dialogs/about_dialog.dart' as app_about;
import '../shared/utils/menu_icon_helper.dart';
import '../shared/widgets/stat_gauge.dart';
import 'settings/seksi_page.dart';
import 'settings/pegawai_page.dart';
import 'settings/officeconfig_page.dart';
import 'login_page.dart';
import 'reference/klu_page.dart';
import 'reference/map_page.dart';
import '../data/services/reference_data_service.dart';
import '../data/services/setting_data_service.dart';
import '../charts/monthly_setor_chart.dart';

/// Main dashboard page after login
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  // Chart key to force rebuild and animation
  int _chartRefreshKey = 0;

  // Dashboard data service instance
  final DashboardDataService _dashboardDataService = DashboardDataService();

  // Dashboard state for kantor dropdown
  String? _selectedKpp;
  String? _selectedKppNama;
  List<Map<String, String>> _kantorList = [];

  // Chart type state for Penerimaan Per Bulan Setor chart
  String _chartTypeMonthlySetor = 'Bar';
  final List<String> _chartTypes = ['Bar', 'Line', 'Pie'];

  // Tahun Pembayaran state
  List<String> _tahunOptions = [];
  String? _selectedTahun;

  // Dataset selection state
  String _selectedDataset = 'PKPM';
  final List<String> _datasetOptions = ['PKPM', 'BO', 'VOLUNTARY'];

  // Animation trigger for statistics and gauge
  bool _animateStats = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final referenceData = ref.read(referenceDataProvider);
      print('[DashboardPage] referenceDataProvider cache: $referenceData');
      final settingData = ref.read(settingDataProvider);
      print('[DashboardPage] settingDataProvider cache: $settingData');
    });
    _refreshDataDashboard();
  }

  Future<void> _refreshDataDashboard() async {
    await _initKantorDropdown();
    await _initTahunDropdown();
    // Only load dashboard data if both are set
    if (_selectedKpp != null && _selectedTahun != null) {
      await _loadAllDashboardData();
      setState(() {
        _animateStats = false;
      });
      // Trigger animation after data is loaded
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) setState(() => _animateStats = true);
      });
    }
    // After refresh, check kantorKode again and show config dialog if needed
    final kantorKode = await SettingDataService.getOfficeCodeFromDatabase();
    if (kantorKode.isEmpty && mounted) {
      _navigateToOfficeConfig(context);
    }
  }

  Future<void> _initKantorDropdown() async {
    final kantorKode = await SettingDataService.getOfficeCodeFromDatabase();
    print('kode kantor : $kantorKode');
    final result = await DatabaseService.rawQuery(
      'SELECT kpp, nama FROM kantor WHERE kpp = ?',
      [kantorKode],
    );
    if (result.isNotEmpty) {
      setState(() {
        _selectedKpp = result.first['kpp']?.toString();
        _selectedKppNama = result.first['nama']?.toString();
        _kantorList = [
          {'kpp': _selectedKpp ?? '', 'nama': _selectedKppNama ?? ''},
        ];
      });
    }
  }

  Future<void> _initTahunDropdown() async {
    final result = await DatabaseService.rawQuery(
      'SELECT DISTINCT THN_SETOR FROM ppmpkmbo ORDER BY THN_SETOR DESC',
      [],
    );
    setState(() {
      _tahunOptions = result.map((row) => row['THN_SETOR'].toString()).toList();
      _selectedTahun = _tahunOptions.isNotEmpty ? _tahunOptions.first : null;
    });
  }

  Future<void> _loadAllDashboardData() async {
    // Load all datasets using selected kantor and tahun
    await _dashboardDataService.loadMonthlyFlagPkpmData(
      _selectedKpp ?? '',
      _selectedTahun,
    );
    await _dashboardDataService.loadMonthlyFlagBoData(
      _selectedKpp ?? '',
      _selectedTahun,
    );
    await _dashboardDataService.loadMonthlyVoluntaryData(
      _selectedKpp ?? '',
      _selectedTahun,
    );
    await _dashboardDataService.loadMonthlyRenpenData(
      _selectedKpp ?? '',
      _selectedTahun,
    );
    await _loadStatistics();
    await _dashboardDataService.loadRevenueData(_selectedKpp.toString());
    setState(() {
      _chartRefreshKey++;
    });
  }

  Future<void> _loadStatistics() async {
    if (_selectedKpp == null || _selectedTahun == null) {
      setState(() {});
      return;
    }
    final kpp = _selectedKpp!;
    final tahun = _selectedTahun!;
    await _dashboardDataService.loadStatistics(kpp, tahun);
    setState(() {});
  }

  String _formatCurrency(num val) {
    String s = val.toStringAsFixed(0);
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    s = s.replaceAllMapped(
      reg,
      (Match m) => '${m[1]}${AppConstants.thousandSeparator}',
    );
    return '${AppConstants.currencySymbol} $s';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final menuConfig = ref.watch(userMenuProvider);

    // Prevent null user access and handle unauthenticated state
    if (!authState.isAuthenticated || authState.user == null) {
      // Optionally show a loading indicator or blank page
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
          // Dynamic menu bar based on user role (now synchronous)
          _buildDynamicMenuBar(context, menuConfig),
          const SizedBox(width: 16),
          // User profile section
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  if (authState.user != null) {
                    _showProfile(context, authState.user!);
                  }
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
                      authState.user?.fullname.substring(0, 1).toUpperCase() ??
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IntrinsicWidth(
                  child: _kantorList.isEmpty
                      ? DropdownButtonFormField<String>(
                          value: null,
                          decoration: const InputDecoration(
                            labelText: 'Kantor',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(
                                'Silakan lakukan pengaturan Kantor',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                          onChanged: null,
                        )
                      : DropdownButtonFormField<String>(
                          value: _selectedKpp,
                          decoration: const InputDecoration(
                            labelText: 'Kantor',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: _kantorList
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item['kpp'],
                                  child: Text(
                                    item['nama'] ?? item['kpp'] ?? '',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) async {
                            setState(() {
                              _selectedKpp = value;
                            });
                            await _loadAllDashboardData();
                          },
                        ),
                ),
                const SizedBox(width: 16),
                IntrinsicWidth(
                  child: _tahunOptions.isEmpty
                      ? DropdownButtonFormField<String>(
                          value: null,
                          decoration: const InputDecoration(
                            labelText: 'Tahun Pembayaran',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(
                                'Table Penerimaan kosong!',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                          onChanged: null,
                        )
                      : DropdownButtonFormField<String>(
                          value: _selectedTahun,
                          decoration: const InputDecoration(
                            labelText: 'Tahun Pembayaran',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: _tahunOptions
                              .map(
                                (tahun) => DropdownMenuItem(
                                  value: tahun,
                                  child: Text(tahun),
                                ),
                              )
                              .toList(),
                          onChanged: (value) async {
                            setState(() {
                              _selectedTahun = value;
                            });
                            await _loadAllDashboardData();
                          },
                        ),
                ),
                const SizedBox(width: 16),
                // Chart type selector moved to chart header below
                const SizedBox(width: 16),
                IntrinsicWidth(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDataset,
                    decoration: const InputDecoration(
                      labelText: 'Dataset',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _datasetOptions
                        .map(
                          (opt) => DropdownMenuItem(
                            value: opt,
                            child: Text(AppConstants.datasetLabels[opt] ?? opt),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDataset = value;
                        });
                      }
                    },
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () async {
                    _dashboardDataService.clearCache();
                    await _refreshDataDashboard();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Data'),
                ),
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
                    flex: 3,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Gauge widget
                          Container(
                            width: double.infinity,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    // Placeholder for gauge - will implement with custom painter later
                                    Container(
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Container(
                                              child: StatGauge(
                                                value: _animateStats
                                                    ? _dashboardDataService
                                                          .statPencapaian
                                                    : 0.0,
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
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 8.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildStatRowAnimated(
                                      'Total Penerimaan',
                                      _dashboardDataService.statPenerimaan,
                                      formatter: _formatCurrency,
                                    ),
                                    _buildStatRowAnimated(
                                      'Total SPMKP',
                                      _dashboardDataService.statSpmkp,
                                      formatter: _formatCurrency,
                                    ),
                                    _buildStatRowAnimated(
                                      'Total PBK',
                                      _dashboardDataService.statPBK,
                                      formatter: _formatCurrency,
                                    ),
                                    _buildStatRowAnimated(
                                      'Total Netto',
                                      _dashboardDataService.statNetto,
                                      formatter: _formatCurrency,
                                    ),
                                    _buildStatRowAnimated(
                                      'Total Renpen',
                                      _dashboardDataService.statRenpen,
                                      formatter: _formatCurrency,
                                    ),
                                    _buildStatRowAnimated(
                                      'Pencapaian',
                                      _dashboardDataService.statPencapaian,
                                      formatter: (v) =>
                                          '${v.toStringAsFixed(2)}%',
                                    ),
                                    _buildStatRowAnimated(
                                      'Pertumbuhan',
                                      _dashboardDataService
                                              .statPertumbuhan
                                              .isNaN
                                          ? 0.0
                                          : _dashboardDataService
                                                .statPertumbuhan,
                                      formatter: (v) =>
                                          '${v.toStringAsFixed(2)}%',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 7,
                    child: Column(
                      children: [
                        ExpansionTile(
                          title: Text(
                            'Penerimaan Per Bulan',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          initiallyExpanded: true,
                          children: [
                            MonthlySetorChart(
                              chartRefreshKey: _chartRefreshKey,
                              chartTypeMonthlySetor: _chartTypeMonthlySetor,
                              chartTypes: _chartTypes,
                              selectedDataset: _selectedDataset,
                              selectedDatasetLabel:
                                  AppConstants
                                      .datasetLabels[_selectedDataset] ??
                                  _selectedDataset,
                              dashboardData: _selectedDataset == 'PKPM'
                                  ? _dashboardDataService.monthlyFlagPkpmData
                                  : _selectedDataset == 'BO'
                                  ? _dashboardDataService.monthlyFlagBoData
                                  : _dashboardDataService.monthlyVoluntaryData,
                              monthlyRenpenData:
                                  _dashboardDataService.monthlyRenpenData,
                              onChartTypeChanged: (type) {
                                setState(() {
                                  _chartTypeMonthlySetor = type;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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

  Widget _buildAppBarMenu(
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

  PopupMenuItem<VoidCallback> _buildMenuItem(
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

  Widget _buildStatRowAnimated(
    String label,
    num value, {
    String Function(num)? formatter,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          TweenAnimationBuilder<num>(
            tween: Tween<num>(begin: _animateStats ? 0 : value, end: value),
            duration: const Duration(milliseconds: 500),
            builder: (context, animatedValue, child) {
              final display = formatter != null
                  ? formatter(animatedValue)
                  : animatedValue.toString();
              return Text(
                display,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
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
            _buildProfileRow(
              'Dibuat',
              user.createdAt?.toString().split(' ')[0] ?? '-',
            ),
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
            onPressed: () async {
              Navigator.of(context).pop(); // close dialog first
              await ref.read(authProvider.notifier).logout();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              });
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
    await _performImport(
      context,
      'Import Seksi',
      ({onProgress}) => CsvImportService.importSeksi(),
    );
  }

  Future<void> _importPegawai(BuildContext context) async {
    await _performImport(
      context,
      'Import Pegawai',
      ({onProgress}) => CsvImportService.importPegawai(),
    );
  }

  Future<void> _importUser(BuildContext context) async {
    await _performImport(
      context,
      'Import User',
      ({onProgress}) => CsvImportService.importUser(),
    );
  }

  Future<void> _importRencanaPenerimaan(BuildContext context) async {
    await _performImport(
      context,
      'Import Rencana Penerimaan',
      ({onProgress}) => CsvImportService.importRencanaPenerimaan(),
    );
  }

  /// Update all database files from selected directory
  /// Scans for CSV files and imports them automatically with office validation
  Future<void> _updateAllDatabaseFiles(BuildContext context) async {
    await _performImport(
      context,
      'Update Database',
      ({onProgress}) =>
          DatabaseImportService.importAllDatabaseFiles(onProgress: onProgress),
    );
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

  void _navigateToPegawai(BuildContext context) {
    // Refresh Pegawai cache before opening dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingDataProvider);
    });
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
          child: const PegawaiManageDialog(),
        ),
      ),
    );
  }

  void _navigateToSeksi(BuildContext context) {
    // Refresh Seksi cache before opening dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingDataProvider);
    });
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
          child: const SeksiManageDialog(),
        ),
      ),
    );
  }

  void _navigateToOfficeConfig(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 350,
              maxWidth: 420,
              minHeight: 400,
              maxHeight: 600,
            ),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const OfficeConfigDialog(),
          ),
        ),
      ),
    );
  }

  /// Generic import handler with progress dialog
  Future<void> _performImport(
    BuildContext context,
    String title,
    Future<ImportResult> Function({
      void Function(
        double progress,
        int currentRow,
        int totalRows,
        String fileName,
      )?
      onProgress,
    })
    importFunction,
  ) async {
    double progress = 0.0;
    int currentRow = 0;
    int totalRows = 0;
    String currentFile = '';
    late StateSetter setDialogState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            setDialogState = setState;
            return AlertDialog(
              contentPadding: const EdgeInsets.all(24),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$title...', style: const TextStyle(fontSize: 15)),
                    if (currentFile.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'File: $currentFile',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    LinearProgressIndicator(value: progress, minHeight: 8),
                    const SizedBox(height: 12),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%  ($currentRow/$totalRows)',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    try {
      final result = await importFunction(
        onProgress: (p, row, total, file) {
          progress = p;
          currentRow = row;
          totalRows = total;
          currentFile = file;
          setDialogState(() {});
        },
      );

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
  void _showImportResult(
    BuildContext context,
    String title,
    ImportResult result,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(20),
        content: SizedBox(
          width: 320, // Compact fixed width
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title with icon
              Row(
                children: [
                  Icon(
                    result.isSuccess
                        ? Icons.check_circle
                        : result.isCancelled
                        ? Icons.cancel
                        : Icons.error,
                    color: result.isSuccess
                        ? Colors.green
                        : result.isCancelled
                        ? Colors.orange
                        : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Result summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: result.isSuccess
                      ? Colors.green.shade50
                      : result.isCancelled
                      ? Colors.orange.shade50
                      : Colors.red.shade50,
                  border: Border.all(
                    color: result.isSuccess
                        ? Colors.green.shade200
                        : result.isCancelled
                        ? Colors.orange.shade200
                        : Colors.red.shade200,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  result.summary,
                  style: TextStyle(
                    fontSize: 14,
                    color: result.isSuccess
                        ? Colors.green.shade800
                        : result.isCancelled
                        ? Colors.orange.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ),

              // Error details (compact)
              if (result.hasErrors && result.errors.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Errors (${result.errors.length}):',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 100, // Compact height
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      result.errors.take(10).join('\n'), // Show max 10 errors
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                if (result.errors.length > 10)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${result.errors.length - 10} more errors...',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 16),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: result.isSuccess
                        ? Colors.green
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog(BuildContext context, String title, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(20),
        content: SizedBox(
          width: 320, // Compact fixed width
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title with error icon
              Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Error message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  error,
                  style: TextStyle(fontSize: 14, color: Colors.red.shade800),
                ),
              ),

              const SizedBox(height: 16),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
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

  // ============================================================================
  // UNIFIED REFERENCE DATA UPDATE FUNCTIONS
  // Replaces 6 separate manual sync functions with one comprehensive update
  // ============================================================================

  /// Unified Update All Reference Data (replaces 6 separate functions)
  Future<void> _updateAllReferenceData(BuildContext context) async {
    await _performDatabaseSync(
      context,
      'Update Semua Data Referensi',
      () => ReferenceDataService.updateAllReferenceData(),
    );
  }

  /// Generic method to perform database sync operations
  Future<void> _performDatabaseSync(
    BuildContext context,
    String operationName,
    Future<SyncResult> Function() syncFunction,
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
            Text('Menjalankan $operationName...'),
          ],
        ),
      ),
    );

    try {
      final result = await syncFunction();

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (result.success) {
          _showSuccessDialog(context, operationName, result.message);
        } else {
          _showErrorDialog(context, '$operationName Gagal', result.message);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog(context, '$operationName Error', e.toString());
      }
    }
  }

  /// Show success dialog
  void _showSuccessDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text('$title Berhasil'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Build dynamic menu bar from JSON configuration
  Widget _buildDynamicMenuBar(BuildContext context, MenuConfig menuConfig) {
    return Row(
      children: menuConfig.menus.map((section) {
        return _buildAppBarMenu(
          context,
          section.title,
          _buildMenuItems(context, section.items),
        );
      }).toList(),
    );
  }

  /// Build menu items from JSON configuration
  List<PopupMenuEntry<VoidCallback>> _buildMenuItems(
    BuildContext context,
    List<MenuItem> items,
  ) {
    return items.map<PopupMenuEntry<VoidCallback>>((item) {
      if (item.isDivider) {
        return const PopupMenuDivider();
      } else {
        return _buildMenuItem(
          item.title ?? '',
          MenuIconHelper.getIcon(item.icon),
          () => _handleMenuAction(context, item.action),
        );
      }
    }).toList();
  }

  /// Handle menu actions from JSON configuration
  void _handleMenuAction(BuildContext context, String? actionString) {
    final menuService = ref.read(menuServiceProvider);
    final action = menuService.getMenuAction(actionString);

    switch (action) {
      case MenuAction.navigatePenerimaan:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const PenerimaanPage()));
        break;
      case MenuAction.logout:
        _handleLogout(context, ref);
        break;
      case MenuAction.exit:
        Navigator.of(context).pop();
        break;
      case MenuAction.importSeksi:
        _importSeksi(context);
        break;
      case MenuAction.importPegawai:
        _importPegawai(context);
        break;
      case MenuAction.importUser:
        _importUser(context);
        break;
      case MenuAction.importRencanaPenerimaan:
        _importRencanaPenerimaan(context);
        break;
      case MenuAction.updateDatabase:
        _updateAllDatabaseFiles(context);
        break;
      case MenuAction.navigateKlu:
        _navigateToKlu(context);
        break;
      case MenuAction.navigateMap:
        _navigateToMap(context);
        break;
      case MenuAction.updateReferenceData:
        _updateAllReferenceData(context);
        break;
      case MenuAction.aboutDialog:
        app_about.AboutDialog.show(context);
        break;
      case MenuAction.manageSeksi:
        _navigateToSeksi(context);
        break;
      case MenuAction.managePegawai:
        _navigateToPegawai(context);
        break;
      case MenuAction.settings:
        _navigateToOfficeConfig(context);
        break;

      case MenuAction.manageUsers:
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Kelola User'),
            content: const Text('Fitur kelola user akan segera hadir.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
        break;
      case MenuAction.comingSoon:
      default:
        _showComingSoon(context, actionString ?? 'Unknown Action');
        break;
    }
  }
}
