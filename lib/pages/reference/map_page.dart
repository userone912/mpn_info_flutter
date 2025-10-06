import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/reference_data_service.dart';
import '../../data/models/map_model.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedSektor;
  String? _selectedKdbayar;
  List<MapModel> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _updateFilteredData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilteredData() {
    final service = ref.read(referenceDataServiceProvider);
    setState(() {
      _filteredData = service.filterMapData(
        searchQuery: _searchController.text,
        sektor: _selectedSektor,
        kdbayar: _selectedKdbayar,
      );
    });
  }

  void _onSearchChanged() {
    _updateFilteredData();
  }

  void _onSektorChanged(int? sektor) {
    setState(() {
      _selectedSektor = sektor;
      // Don't clear kdbayar - allow both filters to work together
    });
    _updateFilteredData();
  }

  void _onKdbayarChanged(String? kdbayar) {
    setState(() {
      _selectedKdbayar = kdbayar;
      // Don't clear sektor - allow both filters to work together
    });
    _updateFilteredData();
  }

  void _clearFilter() {
    _searchController.clear();
    setState(() {
      _selectedSektor = null;
      _selectedKdbayar = null;
    });
    _updateFilteredData();
  }

  String _getSektorDisplay(int sektor) {
    switch (sektor) {
      case 1:
        return 'PPh';
      case 2:
        return 'PPN';
      case 3:
        return 'PBB';
      default:
        return 'Lainnya';
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.read(referenceDataServiceProvider);
    final refDataState = ref.watch(referenceDataProvider);

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
              color: Colors.green.shade700,
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'MAP - Mata Anggaran Penerimaan',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                  onPressed: () {
                    ref.read(referenceDataProvider.notifier).refresh();
                    _updateFilteredData();
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

          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari kdmap, kdbayar, atau uraian...',
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        onChanged: (_) => _onSearchChanged(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_searchController.text.isNotEmpty || _selectedSektor != null || _selectedKdbayar != null)
                      ElevatedButton.icon(
                        onPressed: _clearFilter,
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: const Size(60, 32),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filters Row
                Row(
                  children: [
                    // Sektor Filter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Filter by Sektor:', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedSektor,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              isDense: true,
                            ),
                            hint: const Text('Pilih Sektor', style: TextStyle(fontSize: 12)),
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('Semua Sektor', style: TextStyle(fontSize: 12)),
                              ),
                              ...service.getMapSektors().entries.map((entry) => DropdownMenuItem<int>(
                                    value: entry.key,
                                    child: Text(entry.value, style: const TextStyle(fontSize: 12)),
                                  )),
                            ],
                            onChanged: _onSektorChanged,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Kdbayar Filter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Filter by Kdbayar:', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedKdbayar,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              isDense: true,
                            ),
                            hint: const Text('Pilih Kdbayar', style: TextStyle(fontSize: 12)),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Semua Kdbayar', style: TextStyle(fontSize: 12)),
                              ),
                              ...service.getMapKdbayars().map((kdbayar) => DropdownMenuItem(
                                    value: kdbayar,
                                    child: Text(kdbayar, style: const TextStyle(fontSize: 12)),
                                  )),
                            ],
                            onChanged: _onKdbayarChanged,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Data Display
          Expanded(
            child: refDataState.when(
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading reference data...'),
                  ],
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(referenceDataProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (_) {
                if (_filteredData.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty || _selectedSektor != null || _selectedKdbayar != null
                              ? 'Tidak ada data yang sesuai dengan kriteria pencarian'
                              : 'Tidak ada data Mata Anggaran Penerimaan',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Results count
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Mata Anggaran Penerimaan (${_filteredData.length} of ${service.getMapCount()} records)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Fast ListView
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredData.length,
                        itemBuilder: (context, index) {
                          final map = _filteredData[index];
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: ExpansionTile(
                              dense: true,
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              childrenPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 50,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  map.kdmap,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    color: Colors.blue.shade800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      map.kdbayar,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      map.uraian,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getSektorDisplay(map.sektor),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ),
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    map.uraian,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}