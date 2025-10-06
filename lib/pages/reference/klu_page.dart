import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/klu_service.dart';

class KluPage extends ConsumerStatefulWidget {
  const KluPage({super.key});

  @override
  ConsumerState<KluPage> createState() => _KluPageState();
}

class _KluPageState extends ConsumerState<KluPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedSektor;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(kluListProvider.notifier).searchKlu(query);
      setState(() {
        _isSearching = true;
        _selectedSektor = null;
      });
    } else {
      _clearSearch();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(kluListProvider.notifier).loadAllKlu();
    setState(() {
      _isSearching = false;
      _selectedSektor = null;
    });
  }

  void _filterBySektor(String? sektor) {
    if (sektor != null && sektor.isNotEmpty) {
      ref.read(kluListProvider.notifier).filterBySektor(sektor);
      setState(() {
        _selectedSektor = sektor;
        _isSearching = false;
      });
      _searchController.clear();
    } else {
      _clearSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final kluListAsync = ref.watch(kluListProvider);

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
              color: Colors.blue.shade700,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.category,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'KLU - Klasifikasi Lapangan Usaha',
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
                    ref.read(kluListProvider.notifier).refresh();
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
                          hintText: 'Cari kode atau nama KLU...',
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
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: const Size(60, 32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Sektor Filter
                FutureBuilder<List<String>>(
                  future: ref.read(kluServiceProvider).getUniqueSektors(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final sektors = snapshot.data!;
                    return Row(
                      children: [
                        const Text('Filter by Sektor: ', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
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
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Semua Sektor', style: TextStyle(fontSize: 12)),
                              ),
                              ...sektors.map((sektor) => DropdownMenuItem(
                                    value: sektor,
                                    child: Text(sektor, style: const TextStyle(fontSize: 12)),
                                  )),
                            ],
                            onChanged: _filterBySektor,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                // Status indicator
                if (_isSearching || _selectedSektor != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          _isSearching ? Icons.search : Icons.filter_alt,
                          size: 16,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isSearching
                              ? 'Hasil pencarian: "${_searchController.text}"'
                              : 'Filter: $_selectedSektor',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
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
            child: kluListAsync.when(
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
                      onPressed: () => ref.read(kluListProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (kluList) {
                if (kluList.isEmpty) {
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
                          _isSearching || _selectedSektor != null
                              ? 'Tidak ada data yang sesuai dengan kriteria pencarian'
                              : 'Tidak ada data KLU',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_isSearching || _selectedSektor != null) ...[
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
                            color: Colors.blue.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.business, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'Data KLU (${kluList.length} records)',
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
                                  'Kode',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Nama',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Sektor',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows: kluList.map((klu) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    SelectableText(
                                      klu.kode,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 300,
                                      child: SelectableText(
                                        klu.nama,
                                        style: const TextStyle(),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SelectableText(
                                      klu.sektor,
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w500,
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