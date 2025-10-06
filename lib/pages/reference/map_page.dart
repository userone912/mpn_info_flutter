import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/map_service.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedSektor;
  String? _selectedKdbayar;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(mapListProvider.notifier).searchMap(query);
      setState(() {
        _isSearching = true;
        _selectedSektor = null;
        _selectedKdbayar = null;
      });
    } else {
      _clearSearch();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(mapListProvider.notifier).loadAllMap();
    setState(() {
      _isSearching = false;
      _selectedSektor = null;
      _selectedKdbayar = null;
    });
  }

  void _filterBySektor(int? sektor) {
    if (sektor != null) {
      ref.read(mapListProvider.notifier).filterBySektor(sektor);
      setState(() {
        _selectedSektor = sektor;
        _selectedKdbayar = null;
        _isSearching = false;
      });
      _searchController.clear();
    } else {
      _clearSearch();
    }
  }

  void _filterByKdbayar(String? kdbayar) {
    if (kdbayar != null && kdbayar.isNotEmpty) {
      ref.read(mapListProvider.notifier).filterByKdbayar(kdbayar);
      setState(() {
        _selectedKdbayar = kdbayar;
        _selectedSektor = null;
        _isSearching = false;
      });
      _searchController.clear();
    } else {
      _clearSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapListAsync = ref.watch(mapListProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Modal Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.map,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'MAP - Mapping Reference',
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
                    ref.read(mapListProvider.notifier).refresh();
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
                                  onPressed: _clearSearch,
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
                        onSubmitted: (_) => _performSearch(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _performSearch,
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text('Cari', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
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
                      child: FutureBuilder<Map<int, String>>(
                        future: ref.read(mapServiceProvider).getUniqueSektorsWithDisplay(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          final sektorMap = snapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Filter by Sektor:', style: TextStyle(fontSize: 12)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<int>(
                                value: _selectedSektor,
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
                                  ...sektorMap.entries.map((entry) => DropdownMenuItem<int>(
                                        value: entry.key,
                                        child: Text(entry.value, style: const TextStyle(fontSize: 12)),
                                      )),
                                ],
                                onChanged: _filterBySektor,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Kdbayar Filter
                    Expanded(
                      child: FutureBuilder<List<String>>(
                        future: ref.read(mapServiceProvider).getUniqueKdbayar(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          final kdbayars = snapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Filter by Kdbayar:', style: TextStyle(fontSize: 12)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: _selectedKdbayar,
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
                                  ...kdbayars.map((kdbayar) => DropdownMenuItem(
                                        value: kdbayar,
                                        child: Text(kdbayar, style: const TextStyle(fontSize: 12)),
                                      )),
                                ],
                                onChanged: _filterByKdbayar,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
                // Status indicator
                if (_isSearching || _selectedSektor != null || _selectedKdbayar != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          _isSearching ? Icons.search : Icons.filter_alt,
                          size: 16,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isSearching
                              ? 'Hasil pencarian: "${_searchController.text}"'
                              : _selectedSektor != null
                                  ? 'Filter Sektor: ${_getSektorDisplay(_selectedSektor!)}'
                                  : 'Filter Kdbayar: $_selectedKdbayar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _clearSearch,
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Data Table
          Expanded(
            child: mapListAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $error',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(mapListProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (mapList) {
                if (mapList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching || _selectedSektor != null || _selectedKdbayar != null
                              ? 'Tidak ada data yang sesuai dengan kriteria pencarian'
                              : 'Tidak ada data MAP',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_isSearching || _selectedSektor != null || _selectedKdbayar != null) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _clearSearch,
                            child: const Text('Tampilkan Semua Data'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.map, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                'Data MAP (${mapList.length} records)',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Table
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'Kdmap',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Kdbayar',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Sektor',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Uraian',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows: mapList.map((map) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    SelectableText(
                                      map.kdmap,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SelectableText(
                                      map.kdbayar,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SelectableText(
                                      map.sektorDisplay,
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 400,
                                      child: SelectableText(
                                        map.uraian,
                                        style: const TextStyle(),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}