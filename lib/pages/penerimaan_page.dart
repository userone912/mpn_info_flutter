import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../data/models/menu_models.dart';
import '../data/models/user_model.dart';
import '../core/constants/menu_configurations.dart';
import '../data/services/auth_service.dart';
import '../data/services/dashboard_data_service.dart';
import '../data/services/menu_service.dart';
import '../shared/widgets/app_logo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_page.dart';

class PenerimaanPage extends ConsumerStatefulWidget {
  const PenerimaanPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PenerimaanPage> createState() => _PenerimaanPageState();
}

class _PenerimaanPageState extends ConsumerState<PenerimaanPage> {
  // Checkbox states for each filter
  bool _useNpwp = true;
  bool _useNama = false;
  bool _useMasaPajak = false;
  bool _useTahun = false;
  bool _useNtpn = false;
  bool _useNoPbk = false;
  bool _useKdMap = false;
  bool _useKdSetor = false;
  bool _useVoluntary = false;
  bool _useFlagPkpm = false;
  bool _useFlagBo = false;
  bool _useTglSetor = false;
  Widget _buildDynamicMenuBar(BuildContext context, MenuConfig menuConfig) {
    final menuService = ref.read(menuServiceProvider);
    return Row(
      children: menuConfig.menus.map((section) {
        return PopupMenuButton<VoidCallback>(
          onSelected: (callback) => callback(),
          itemBuilder: (context) =>
              section.items.map<PopupMenuEntry<VoidCallback>>((item) {
                if (item.isDivider) {
                  return const PopupMenuDivider();
                } else {
                  return PopupMenuItem<VoidCallback>(
                    value: () {
                      final action = menuService.getMenuAction(item.action);
                      switch (action) {
                        case MenuAction.navigatePenerimaan:
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PenerimaanPage(),
                            ),
                          );
                          break;
                        case MenuAction.logout:
                          _handleLogout(context, ref);
                          break;
                        case MenuAction.exit:
                          Navigator.of(context).pop();
                          break;
                        default:
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(item.title ?? 'Unknown Action'),
                            ),
                          );
                      }
                    },
                    child: Row(
                      children: [
                        Icon(
                          item.icon is IconData
                              ? item.icon as IconData
                              : Icons.menu,
                          size: 16,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.title ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }
              }).toList(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Text(
              section.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  final MenuConfig menuConfig = MenuConfigurations.userMenuConfig;
  final DashboardDataService _dashboardDataService = DashboardDataService();
  String? _selectedTahun;
  String? _selectedFlagPkpm;
  String? _selectedFlagBo;
  String? _selectedVoluntary;
  String? _selectedKdMap;
  String? _selectedKdSetor;
  DateTime? _selectedTglSetor;
  final TextEditingController _npwpController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _ntpnController = TextEditingController();
  final TextEditingController _noPbkController = TextEditingController();
  final TextEditingController _masaPajakController = TextEditingController();
  List<Map<String, dynamic>> _data = [];

  List<String> _tahunOptions = [];
  List<String> _kdMapOptions = [];
  List<String> _kdSetorOptions = [];
  List<String> _voluntaryOptions = [];
  List<String> _flagPkpmOptions = [];
  List<String> _flagBoOptions = [];

  @override
  void initState() {
    super.initState();
    // Initialize dropdown options from cache asynchronously
    _initializeDropdownOptions();
    // TODO: Load initial data
  }

  Future<void> _initializeDropdownOptions() async {
    final cache = await _dashboardDataService.getPenerimaanCache();
    setState(() {
      _tahunOptions = cache['tahunOptions'] ?? [];
      _kdMapOptions = cache['kdMapOptions'] ?? [];
      _kdSetorOptions = cache['kdSetorOptions'] ?? [];
      _voluntaryOptions = cache['voluntaryOptions'] ?? [];
      _flagPkpmOptions = cache['flagPkpmOptions'] ?? [];
      _flagBoOptions = cache['flagBoOptions'] ?? [];
      // Set initial selected values if available
      if (_tahunOptions.isNotEmpty) _selectedTahun = _tahunOptions.first;
      if (_kdMapOptions.isNotEmpty) _selectedKdMap = _kdMapOptions.first;
      if (_kdSetorOptions.isNotEmpty) _selectedKdSetor = _kdSetorOptions.first;
      if (_voluntaryOptions.isNotEmpty)
        _selectedVoluntary = _voluntaryOptions.first;
      if (_flagPkpmOptions.isNotEmpty)
        _selectedFlagPkpm = _flagPkpmOptions.first;
      if (_flagBoOptions.isNotEmpty) _selectedFlagBo = _flagBoOptions.first;
    });
  }

  Future<void> _loadData() async {
    // Query pkpmbo data from DashboardDataService
    setState(() {
      _data = _dashboardDataService.filterPenerimaanData(
        npwp: _useNpwp && _npwpController.text.isNotEmpty ? _npwpController.text : null,
        nama: _useNama && _namaController.text.isNotEmpty ? _namaController.text : null,
        kdMap: _useKdMap ? _selectedKdMap : null,
        kdSetor: _useKdSetor ? _selectedKdSetor : null,
        masaPajak: _useMasaPajak && _masaPajakController.text.isNotEmpty ? _masaPajakController.text : null,
        tahunSetor: _useTahun && _selectedTahun != null ? int.tryParse(_selectedTahun!) : null,
        tglSetor: _useTglSetor ? _selectedTglSetor : null,
        ntpn: _useNtpn && _ntpnController.text.isNotEmpty ? _ntpnController.text : null,
        noPbk: _useNoPbk && _noPbkController.text.isNotEmpty ? _noPbkController.text : null,
        voluntary: _useVoluntary ? _selectedVoluntary : null,
        flagPkpm: _useFlagPkpm ? _selectedFlagPkpm : null,
        flagBo: _useFlagBo ? _selectedFlagBo : null,
      );
    });
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
      body: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Card(
                    margin: const EdgeInsets.all(12),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filter',
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall?.copyWith(
                                fontSize: 15,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Checkbox(
                                  value: _useNpwp,
                                  onChanged: (val) {
                                    setState(() => _useNpwp = val ?? false);
                                    _loadData();
                                  },
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _npwpController,
                                    decoration: const InputDecoration(
                                      labelText: 'NPWP',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                    onChanged: (_) => _loadData(),
                                    enabled: _useNpwp,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Checkbox(
                                  value: _useNama,
                                  onChanged: (val) {
                                    setState(() => _useNama = val ?? false);
                                    _loadData();
                                  },
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _namaController,
                                    decoration: const InputDecoration(
                                      labelText: 'Nama',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                    onChanged: (_) => _loadData(),
                                    enabled: _useNama,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Checkbox(
                                  value: _useMasaPajak,
                                  onChanged: (val) {
                                    setState(() => _useMasaPajak = val ?? false);
                                    _loadData();
                                  },
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _masaPajakController,
                                    decoration: const InputDecoration(
                                      labelText: 'Masa Pajak',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                    onChanged: (_) => _loadData(),
                                    enabled: _useMasaPajak,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Checkbox(
                                  value: _useTahun,
                                  onChanged: (val) {
                                    setState(() => _useTahun = val ?? false);
                                    _loadData();
                                  },
                                ),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedTahun,
                                    decoration: const InputDecoration(
                                      labelText: 'Tahun Setor',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                    ),
                                    items: _tahunOptions
                                        .map(
                                          (tahun) => DropdownMenuItem(
                                            value: tahun,
                                            child: Text(tahun, style: const TextStyle(color: Colors.black)),
                                          ),
                                        )
                                        .toList(),
                                    style: const TextStyle(fontSize: 13, color: Colors.black),
                                    onChanged: _useTahun
                                        ? (value) {
                                            setState(() {
                                              _selectedTahun = value;
                                            });
                                            _loadData();
                                          }
                                        : null,
                                    disabledHint: const Text('Tahun Setor', style: TextStyle(color: Colors.grey)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Checkbox(
                                  value: _useNtpn,
                                  onChanged: (val) {
                                    setState(() => _useNtpn = val ?? false);
                                    _loadData();
                                  },
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _ntpnController,
                                    decoration: const InputDecoration(
                                      labelText: 'NTPN',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                    onChanged: (_) => _loadData(),
                                    enabled: _useNtpn,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Checkbox(
                                  value: _useNoPbk,
                                  onChanged: (val) {
                                    setState(() => _useNoPbk = val ?? false);
                                    _loadData();
                                  },
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _noPbkController,
                                    decoration: const InputDecoration(
                                      labelText: 'No PBK',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                    onChanged: (_) => _loadData(),
                                    enabled: _useNoPbk,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Checkbox(
                                  value: _useKdMap,
                                  onChanged: (val) {
                                    setState(() => _useKdMap = val ?? false);
                                    _loadData();
                                  },
                                ),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedKdMap,
                                    decoration: const InputDecoration(
                                      labelText: 'Kode MAP',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                    ),
                                    items: _kdMapOptions
                                        .map(
                                          (kdMap) => DropdownMenuItem(
                                            value: kdMap,
                                            child: Text(kdMap, style: const TextStyle(color: Colors.black)),
                                          ),
                                        )
                                        .toList(),
                                    style: const TextStyle(fontSize: 13, color: Colors.black),
                                    onChanged: _useKdMap
                                        ? (value) {
                                            setState(() {
                                              _selectedKdMap = value;
                                            });
                                            _loadData();
                                          }
                                        : null,
                                    disabledHint: const Text('Kode MAP', style: TextStyle(color: Colors.grey)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Checkbox(
                                  value: _useKdSetor,
                                  onChanged: (val) {
                                    setState(() => _useKdSetor = val ?? false);
                                    _loadData();
                                  },
                                ),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedKdSetor,
                                    decoration: const InputDecoration(
                                      labelText: 'Kode Setor',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                    ),
                                    items: _kdSetorOptions
                                        .map(
                                          (kdSetor) => DropdownMenuItem(
                                            value: kdSetor,
                                            child: Text(kdSetor, style: const TextStyle(color: Colors.black)),
                                          ),
                                        )
                                        .toList(),
                                    style: const TextStyle(fontSize: 13, color: Colors.black),
                                    onChanged: _useKdSetor
                                        ? (value) {
                                            setState(() {
                                              _selectedKdSetor = value;
                                            });
                                            _loadData();
                                          }
                                        : null,
                                    disabledHint: const Text('Kode Setor', style: TextStyle(color: Colors.grey)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Checkbox(
                                  value: _useVoluntary,
                                  onChanged: (val) {
                                    setState(() => _useVoluntary = val ?? false);
                                    _loadData();
                                  },
                                ),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedVoluntary,
                                    decoration: const InputDecoration(
                                      labelText: 'Voluntary',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                    ),
                                    items: _voluntaryOptions
                                        .map(
                                          (vol) => DropdownMenuItem(
                                            value: vol,
                                            child: Text(vol, style: const TextStyle(color: Colors.black)),
                                          ),
                                        )
                                        .toList(),
                                    style: const TextStyle(fontSize: 13, color: Colors.black),
                                    onChanged: _useVoluntary
                                        ? (value) {
                                            setState(() {
                                              _selectedVoluntary = value;
                                            });
                                            _loadData();
                                          }
                                        : null,
                                    disabledHint: const Text('Voluntary', style: TextStyle(color: Colors.grey)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Checkbox(
                                  value: _useFlagPkpm,
                                  onChanged: (val) {
                                    setState(() => _useFlagPkpm = val ?? false);
                                    _loadData();
                                  },
                                ),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedFlagPkpm,
                                    decoration: const InputDecoration(
                                      labelText: 'Flag PPM / PKM',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                    ),
                                    items: _flagPkpmOptions
                                        .map(
                                          (flag) => DropdownMenuItem(
                                            value: flag,
                                            child: Text(flag, style: const TextStyle(color: Colors.black)),
                                          ),
                                        )
                                        .toList(),
                                    style: const TextStyle(fontSize: 13, color: Colors.black),
                                    onChanged: _useFlagPkpm
                                        ? (value) {
                                            setState(() {
                                              _selectedFlagPkpm = value;
                                            });
                                            _loadData();
                                          }
                                        : null,
                                    disabledHint: const Text('Flag PPM / PKM', style: TextStyle(color: Colors.grey)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Checkbox(
                                  value: _useFlagBo,
                                  onChanged: (val) {
                                    setState(() => _useFlagBo = val ?? false);
                                    _loadData();
                                  },
                                ),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedFlagBo,
                                    decoration: const InputDecoration(
                                      labelText: 'Bussiness Owner',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                    ),
                                    items: _flagBoOptions
                                        .map(
                                          (flag) => DropdownMenuItem(
                                            value: flag,
                                            child: Text(flag, style: const TextStyle(color: Colors.black)),
                                          ),
                                        )
                                        .toList(),
                                    style: const TextStyle(fontSize: 13, color: Colors.black),
                                    onChanged: _useFlagBo
                                        ? (value) {
                                            setState(() {
                                              _selectedFlagBo = value;
                                            });
                                            _loadData();
                                          }
                                        : null,
                                    disabledHint: const Text('Bussiness Owner', style: TextStyle(color: Colors.grey)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Checkbox(
                                  value: _useTglSetor,
                                  onChanged: (val) {
                                    setState(() => _useTglSetor = val ?? false);
                                    _loadData();
                                  },
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedTglSetor != null
                                              ? 'Tgl Setor: ${_selectedTglSetor!.toLocal().toString().split(' ')[0]}'
                                              : 'Tgl Setor: -',
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.calendar_today),
                                        onPressed: _useTglSetor
                                            ? () async {
                                                final picked = await showDatePicker(
                                                  context: context,
                                                  initialDate: DateTime.now(),
                                                  firstDate: DateTime(2000),
                                                  lastDate: DateTime(2100),
                                                );
                                                if (picked != null) {
                                                  setState(() {
                                                    _selectedTglSetor = picked;
                                                  });
                                                  _loadData();
                                                }
                                              }
                                            : null,
                                      ),
                                      if (_selectedTglSetor != null)
                                        IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: _useTglSetor
                                              ? () {
                                                  setState(() {
                                                    _selectedTglSetor = null;
                                                  });
                                                  _loadData();
                                                }
                                              : null,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Right data section (80%)
                Expanded(
                  flex: 8,
                  child: Card(
                    margin: const EdgeInsets.all(12),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data Penerimaan',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          Expanded(child: _buildDataTable()),
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
    );
  }

  Widget _buildDataTable() {
    if (_data.isEmpty) {
      return const Center(child: Text('Tidak ada data'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('NPWP')),
          DataColumn(label: Text('Nama')),
          DataColumn(label: Text('KD_MAP')),
          DataColumn(label: Text('KD_SETOR')),
          DataColumn(label: Text('Masa Pajak')),
          DataColumn(label: Text('Tahun Setor')),
          DataColumn(label: Text('Tgl Setor')),
          DataColumn(label: Text('Jml Setor')),
          DataColumn(label: Text('NTPN')),
          DataColumn(label: Text('No PBK')),
          DataColumn(label: Text('Voluntary')),
          DataColumn(label: Text('FLAG_PKPM')),
          DataColumn(label: Text('FLAG_BO')),
          DataColumn(label: Text('Source')),
          DataColumn(label: Text('Kantor')),
        ],
        rows: _data.map((row) {
          return DataRow(
            cells: [
              DataCell(Text(row['NPWP']?.toString() ?? '')),
              DataCell(Text(row['NAMA']?.toString() ?? '')),
              DataCell(Text(row['KD_MAP']?.toString() ?? '')),
              DataCell(Text(row['KD_SETOR']?.toString() ?? '')),
              DataCell(Text(row['MASA_PAJAK']?.toString() ?? '')),
              DataCell(Text(row['THN_SETOR']?.toString() ?? '')),
              DataCell(Text(row['TGL_SETOR']?.toString() ?? '')),
              DataCell(Text(row['JML_SETOR']?.toString() ?? '')),
              DataCell(Text(row['NTPN']?.toString() ?? '')),
              DataCell(Text(row['NO_PBK']?.toString() ?? '')),
              DataCell(Text(row['VOLUNTARY']?.toString() ?? '')),
              DataCell(Text(row['FLAG_PKPM']?.toString() ?? '')),
              DataCell(Text(row['FLAG_BO']?.toString() ?? '')),
              DataCell(Text(row['SOURCE']?.toString() ?? '')),
              DataCell(Text(row['KPPADM']?.toString() ?? '')),
            ],
          );
        }).toList(),
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
}
