import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/reference_data_service.dart';
import '../../data/models/klu_model.dart';

class KluPage extends ConsumerStatefulWidget {
  const KluPage({super.key});

  @override
  ConsumerState<KluPage> createState() => _KluPageState();
}

class _KluPageState extends ConsumerState<KluPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedSektor;
  List<KluModel> _filteredData = [];

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
      _filteredData = service.filterKluData(
        searchQuery: _searchController.text,
        sektor: _selectedSektor,
      );
    });
  }

  void _onSearchChanged() {
    _updateFilteredData();
  }

  void _onSektorChanged(String? sektor) {
    setState(() {
      _selectedSektor = sektor;
    });
    _updateFilteredData();
  }

  void _clearFilter() {
    _searchController.clear();
    setState(() {
      _selectedSektor = null;
    });
    _updateFilteredData();
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
              color: Colors.blue.shade700,
            ),
            child: Row(
              children: [
                const Icon(Icons.category, color: Colors.white, size: 20),
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
                          hintText: 'Cari kode atau nama KLU...',
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
                    if (_searchController.text.isNotEmpty || _selectedSektor != null)
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
                // Sektor Filter
                Row(
                  children: [
                    const Text('Filter by Sektor: ', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
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
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Semua Sektor', style: TextStyle(fontSize: 12)),
                          ),
                          ...service.getKluSektors().map((sektor) => DropdownMenuItem(
                                value: sektor,
                                child: Text(sektor, style: const TextStyle(fontSize: 12)),
                              )),
                        ],
                        onChanged: _onSektorChanged,
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
                          _searchController.text.isNotEmpty || _selectedSektor != null
                              ? 'Tidak ada data yang sesuai dengan kriteria pencarian'
                              : 'Tidak ada data KLU',
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
                        color: Colors.blue.shade50,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.business, color: Colors.blue, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Data KLU (${_filteredData.length} of ${service.getKluCount()} records)',
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
                          final klu = _filteredData[index];
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Container(
                                width: 60,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  klu.kode,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Colors.blue.shade800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              title: Text(
                                klu.nama,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
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
                                  klu.sektor,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ),
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