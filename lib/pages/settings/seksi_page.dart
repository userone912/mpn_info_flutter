import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/seksi_model.dart';
import '../../data/services/setting_data_service.dart';
import '../../data/services/csv_import_service.dart';

class SeksiManageDialog extends ConsumerStatefulWidget {
  const SeksiManageDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<SeksiManageDialog> createState() => _SeksiManageDialogState();
}

class _SeksiManageDialogState extends ConsumerState<SeksiManageDialog> {
  List<SeksiModel> _seksiList = [];
  bool _loading = true;
  int? _editingIndex;
  final _formKey = GlobalKey<FormState>();
  String _kantor = '';
  String _nama = '';
  int _tipe = 0;
  final TextEditingController _kantorController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _tipeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSeksi();
  }

  Future<void> _loadSeksi() async {
    setState(() => _loading = true);
    final settingService = SettingDataService();
    if (!settingService.isSeksiLoaded) {
      await settingService.loadSeksiData();
    }
    _seksiList = settingService.seksiData;
    setState(() => _loading = false);
  }

  void _startEdit(int index) {
    setState(() {
      _editingIndex = index;
      final seksi = _seksiList[index];
      _kantor = seksi.kantor;
      _nama = seksi.nama;
      _tipe = seksi.tipe;
      _kantorController.text = _kantor;
      _namaController.text = _nama;
      _tipeController.text = _tipe.toString();
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingIndex = null;
      _kantor = '';
      _nama = '';
      _tipe = 0;
      _kantorController.clear();
      _namaController.clear();
      _tipeController.clear();
    });
  }

  Future<void> _saveEdit() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
    final settingService = ref.read(settingDataServiceProvider);
      final kantor = _kantorController.text;
      final nama = _namaController.text;
      final tipe = int.tryParse(_tipeController.text) ?? 0;
  // Fetch kantor from settings using CsvImportService
      if (_editingIndex != null) {
        // Update existing
        final updated = SeksiModel(
          id: _seksiList[_editingIndex!].id,
          kantor: kantor,
          nama: nama,
          tipe: tipe,
        );
        await settingService.updateSeksi(updated);
        await settingService.refreshSeksiData();
        _seksiList = settingService.seksiData;
      } else {
        // Add new
        final newSeksi = SeksiModel( kantor: kantor, nama: nama, tipe: tipe);
        await settingService.addSeksi(newSeksi);
        await settingService.refreshSeksiData();
        _seksiList = settingService.seksiData;
      }
      setState(() {
        _editingIndex = null;
        _kantor = '';
        _nama = '';
        _kantorController.clear();
        _namaController.clear();
        _tipeController.clear();
      });
    }
  }

  Future<void> _deleteSeksi(int index) async {
    final id = _seksiList[index].id;
    if (id != null) {
      final settingService = ref.read(settingDataServiceProvider);
      await settingService.deleteSeksi(id);
      await settingService.refreshSeksiData();
      setState(() {
        _seksiList = settingService.seksiData;
      });
    }
  }

  void _clearFilter() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade700,
            ),
            child: Row(
              children: [
                const Icon(Icons.apartment, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Seksi - Manajemen Data Seksi',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                  onPressed: () async {
                    await _loadSeksi();
                  },
                  tooltip: 'Refresh Data',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),

          // Search bar section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Cari Data Seksi',
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          ),

          // Form Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Form(
              key: _formKey,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        controller: _kantorController,
                        decoration: const InputDecoration(labelText: 'Kode'),
                        maxLength: 2,
                        validator: (v) => v == null || v.isEmpty ? 'Kode wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 180,
                      child: TextFormField(
                        controller: _namaController,
                        decoration: const InputDecoration(labelText: 'Nama Seksi'),
                        maxLength: 128,
                        validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        controller: _tipeController,
                        decoration: const InputDecoration(labelText: 'Tipe'),
                        keyboardType: TextInputType.number,
                        maxLength: 11,
                        validator: (v) => v == null || v.isEmpty ? 'Tipe wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_editingIndex != null)
                      ElevatedButton(
                        onPressed: _saveEdit,
                        child: const Text('Simpan'),
                      )
                    else
                      ElevatedButton(
                        onPressed: _saveEdit,
                        child: const Text('Tambah'),
                      ),
                    if (_editingIndex != null)
                      TextButton(
                        onPressed: _cancelEdit,
                        child: const Text('Batal'),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Table Section
          Expanded(
            child: Container(
              color: Colors.white,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Kantor')),
                              DataColumn(label: Text('Nama Seksi')),
                              DataColumn(label: Text('Tipe')),
                              DataColumn(label: Text('Aksi')),
                            ],
                            rows: _seksiList
                                .where((seksi) {
                                  final q = _searchQuery.toLowerCase();
                                  if (q.isEmpty) return true;
                                  return seksi.kantor.toLowerCase().contains(q) ||
                                      seksi.nama.toLowerCase().contains(q) ||
                                      seksi.tipe.toString().contains(q);
                                })
                                .map((seksi) {
                                  final index = _seksiList.indexOf(seksi);
                                  return DataRow(cells: [
                                    DataCell(Text(seksi.kantor)),
                                    DataCell(Text(seksi.nama)),
                                    DataCell(Text(seksi.tipe.toString())),
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18),
                                          onPressed: () => _startEdit(index),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 18),
                                          onPressed: () => _deleteSeksi(index),
                                        ),
                                      ],
                                    )),
                                  ]);
                                })
                                .toList(),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}