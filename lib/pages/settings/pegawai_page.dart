import 'package:flutter/material.dart';
import '../../data/models/pegawai_model.dart';
import '../../data/services/setting_data_service.dart';
import '../../data/services/database_service.dart';

class PegawaiManageDialog extends StatefulWidget {
  const PegawaiManageDialog({Key? key}) : super(key: key);

  @override
  State<PegawaiManageDialog> createState() => _PegawaiManageDialogState();
}

class _PegawaiManageDialogState extends State<PegawaiManageDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<PegawaiModel> _pegawaiList = [];
  bool _loading = true;
  int? _editingIndex;
  final _formKey = GlobalKey<FormState>();
  String? _nip;
  String? _nama;
  int? _seksi;
  List<Map<String, dynamic>> _seksiOptions = [];
  String? _kantor;
  String? _nip2;
  int? _pangkat;
  int? _jabatan;
  int? _tahun;
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSeksiOptions().then((_) => _loadPegawai());
  }

  Future<void> _loadPegawai() async {
    setState(() => _loading = true);
    final settingService = SettingDataService();
    if (!settingService.isPegawaiLoaded) {
      await settingService.loadPegawaiData();
    }
    _pegawaiList = settingService.pegawaiData;
    setState(() => _loading = false);
  }

  Future<void> _loadSeksiOptions() async {
    final result = await DatabaseService.rawQuery(
      'SELECT tipe, nama FROM seksi ORDER BY nama',
    );
    setState(() {
      _seksiOptions = result;
    });
  }

  void _startEdit(int index) {
    setState(() {
      _editingIndex = index;
      final p = _pegawaiList[index];
      _nip = p.nip;
      _nama = p.nama;
      _seksi = p.seksi;
      _kantor = p.kantor;
      _nip2 = p.nip2;
      _pangkat = p.pangkat;
      _jabatan = p.jabatan;
      _tahun = p.tahun;
      // nmseksi is not part of PegawaiModel, so do not set it here
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingIndex = null;
      _nip = null;
      _nama = null;
      _seksi = null;
      _kantor = null;
      _nip2 = null;
      _pangkat = null;
      _jabatan = null;
      _tahun = null;
    });
  }

  Future<void> _saveEdit() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      final settingService = SettingDataService();
      final pegawai = PegawaiModel(
        kantor: _kantor ?? '',
        nip: _nip ?? '',
        nip2: _nip2,
        nama: _nama ?? '',
        pangkat: _pangkat ?? 0,
        seksi: _seksi,
        jabatan: _jabatan ?? 0,
        tahun: _tahun ?? 0,
      );
      if (_editingIndex != null) {
        await settingService.updatePegawai(pegawai);
      } else {
        await settingService.addPegawai(pegawai);
      }
      await settingService.refreshPegawaiData();
      _pegawaiList = settingService.pegawaiData;
      setState(() {
        _editingIndex = null;
        _nip = null;
        _nama = null;
        _seksi = null;
        _kantor = null;
        _nip2 = null;
        _pangkat = null;
        _jabatan = null;
        _tahun = null;
      });
    }
  }

  Future<void> _deletePegawai(int index) async {
    final nip = _pegawaiList[index].nip;
    final settingService = SettingDataService();
    await settingService.deletePegawai(nip);
    await settingService.refreshPegawaiData();
    setState(() {
      _pegawaiList = settingService.pegawaiData;
    });
  }

  void _clearFilter() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    _loadPegawai();
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 900, maxHeight: 700),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.indigo.shade700),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Pegawai - Manajemen Data Pegawai',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () async {
                      await _loadPegawai();
                    },
                    tooltip: 'Refresh Data',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
            // Search bar section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Cari Data Pegawai',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: _clearFilter,
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Scrollbar(
                          controller: _horizontalScrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 700),
                              child: Scrollbar(
                                controller: _verticalScrollController,
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  controller: _verticalScrollController,
                                  scrollDirection: Axis.vertical,
                                  child: DataTable(
                                    sortAscending: true,
                                    sortColumnIndex: 1,
                                    clipBehavior: Clip.none,
                                    showBottomBorder: true,
                                    columns: const [
                                      DataColumn(label: Text('NIP')),
                                      DataColumn(label: Text('Nama')),
                                      DataColumn(label: Text('Seksi')),
                                      DataColumn(label: Text('NIP2')),
                                      DataColumn(label: Text('Pangkat')),
                                      DataColumn(label: Text('Jabatan')),
                                      DataColumn(label: Text('Tahun')),
                                      DataColumn(label: Text('Aksi')),
                                    ],
                                    rows: _pegawaiList
                                        .where((pegawai) {
                                          final q = _searchQuery.toLowerCase();
                                          if (q.isEmpty) return true;
                                          String seksiDisplay = '-';
                                          if (pegawai.seksi != null) {
                                            final match = _seksiOptions
                                                .firstWhere(
                                                  (opt) =>
                                                      opt['tipe'] ==
                                                      pegawai.seksi,
                                                  orElse: () => {},
                                                );
                                            seksiDisplay =
                                                match['nama']?.toString() ??
                                                pegawai.seksi.toString();
                                          }
                                          return pegawai.nip
                                                  .toLowerCase()
                                                  .contains(q) ||
                                              pegawai.nama
                                                  .toLowerCase()
                                                  .contains(q) ||
                                              seksiDisplay
                                                  .toLowerCase()
                                                  .contains(q) ||
                                              (pegawai.nip2
                                                      ?.toLowerCase()
                                                      .contains(q) ??
                                                  false) ||
                                              pegawai.pangkat
                                                  .toString()
                                                  .contains(q) ||
                                              pegawai.jabatan
                                                  .toString()
                                                  .contains(q) ||
                                              pegawai.tahun.toString().contains(
                                                q,
                                              );
                                        })
                                        .map((pegawai) {
                                          String seksiDisplay = '-';
                                          if (pegawai.seksi != null) {
                                            final match = _seksiOptions
                                                .firstWhere(
                                                  (opt) =>
                                                      opt['tipe'] ==
                                                      pegawai.seksi,
                                                  orElse: () => {},
                                                );
                                            seksiDisplay =
                                                match['nama']?.toString() ??
                                                pegawai.seksi.toString();
                                          }
                                          return DataRow(
                                            cells: [
                                              DataCell(Text(pegawai.nip)),
                                              DataCell(Text(pegawai.nama)),
                                              DataCell(Text(seksiDisplay)),
                                              DataCell(
                                                Text(pegawai.nip2 ?? ''),
                                              ),
                                              DataCell(
                                                Text(
                                                  pegawai.pangkat.toString(),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  pegawai.jabatan.toString(),
                                                ),
                                              ),
                                              DataCell(
                                                Text(pegawai.tahun.toString()),
                                              ),
                                              const DataCell(SizedBox()),
                                            ],
                                          );
                                        })
                                        .toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
