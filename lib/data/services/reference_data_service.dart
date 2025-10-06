import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/klu_model.dart';
import '../models/map_model.dart';
import 'database_service.dart';
import 'database_migration_service.dart';

/// Centralized reference data service that loads all data once at startup
/// This mimics the Qt legacy approach where all data is loaded in memory
class ReferenceDataService {
  // In-memory storage for all reference data
  List<KluModel> _kluData = [];
  List<MapModel> _mapData = [];
  
  // Loading states
  bool _isKluLoaded = false;
  bool _isMapLoaded = false;
  bool _isLoading = false;

  // Getters for the cached data
  List<KluModel> get kluData => List.unmodifiable(_kluData);
  List<MapModel> get mapData => List.unmodifiable(_mapData);
  
  bool get isKluLoaded => _isKluLoaded;
  bool get isMapLoaded => _isMapLoaded;
  bool get isLoading => _isLoading;

  /// Load all reference data at startup (called once)
  Future<void> loadAllReferenceData() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads
    
    _isLoading = true;
    print('Loading all reference data...');
    
    try {
      // Load all data in parallel for better performance
      await Future.wait([
        _loadKluData(),
        _loadMapData(),
      ]);
      
      print('Reference data loaded successfully:');
      print('- KLU records: ${_kluData.length}');
      print('- MAP records: ${_mapData.length}');
    } catch (e) {
      print('Error loading reference data: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Load KLU data from database
  Future<void> _loadKluData() async {
    try {
      final result = await DatabaseService.rawQuery('SELECT * FROM klu ORDER BY kode');
      _kluData = result.map((json) => KluModel.fromJson(json)).toList();
      _isKluLoaded = true;
      print('Loaded ${_kluData.length} KLU records');
    } catch (e) {
      print('Error loading KLU data: $e');
      _kluData = [];
      _isKluLoaded = false;
      rethrow;
    }
  }

  /// Load MAP data from database
  Future<void> _loadMapData() async {
    try {
      final result = await DatabaseService.rawQuery('SELECT * FROM map ORDER BY kdmap');
      _mapData = result.map((json) => MapModel.fromJson(json)).toList();
      _isMapLoaded = true;
      print('Loaded ${_mapData.length} MAP records');
    } catch (e) {
      print('Error loading MAP data: $e');
      _mapData = [];
      _isMapLoaded = false;
      rethrow;
    }
  }

  /// Refresh KLU data (re-load from database)
  Future<void> refreshKluData() async {
    _isKluLoaded = false;
    await _loadKluData();
  }

  /// Refresh MAP data (re-load from database)
  Future<void> refreshMapData() async {
    _isMapLoaded = false;
    await _loadMapData();
  }

  /// Filter KLU data in memory (application layer filtering)
  List<KluModel> filterKluData({String? searchQuery, String? sektor}) {
    if (!_isKluLoaded) return [];
    
    var filtered = _kluData;
    
    // Apply search filter
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      filtered = filtered.where((klu) =>
        klu.kode.toLowerCase().contains(query) ||
        klu.nama.toLowerCase().contains(query)
      ).toList();
    }
    
    // Apply sektor filter
    if (sektor != null && sektor.trim().isNotEmpty) {
      filtered = filtered.where((klu) => klu.sektor == sektor).toList();
    }
    
    return filtered;
  }

  /// Filter MAP data in memory (application layer filtering)
  List<MapModel> filterMapData({String? searchQuery, int? sektor, String? kdbayar}) {
    if (!_isMapLoaded) return [];
    
    var filtered = _mapData;
    
    // Apply search filter
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      filtered = filtered.where((map) =>
        map.kdmap.toLowerCase().contains(query) ||
        map.kdbayar.toLowerCase().contains(query) ||
        map.uraian.toLowerCase().contains(query)
      ).toList();
    }
    
    // Apply sektor filter
    if (sektor != null) {
      filtered = filtered.where((map) => map.sektor == sektor).toList();
    }
    
    // Apply kdbayar filter
    if (kdbayar != null && kdbayar.trim().isNotEmpty) {
      filtered = filtered.where((map) => map.kdbayar == kdbayar).toList();
    }
    
    return filtered;
  }

  /// Get unique KLU sektors from memory
  List<String> getKluSektors() {
    if (!_isKluLoaded) return [];
    return _kluData.map((klu) => klu.sektor).toSet().toList()..sort();
  }

  /// Get unique MAP sektors from memory with display names
  Map<int, String> getMapSektors() {
    if (!_isMapLoaded) return {};
    
    final sektorMap = <int, String>{};
    final uniqueSektors = _mapData.map((map) => map.sektor).toSet().toList()..sort();
    
    for (final sektor in uniqueSektors) {
      switch (sektor) {
        case 1:
          sektorMap[sektor] = 'PPh';
          break;
        case 2:
          sektorMap[sektor] = 'PPN';
          break;
        case 3:
          sektorMap[sektor] = 'PBB';
          break;
        default:
          sektorMap[sektor] = 'Lainnya';
      }
    }
    return sektorMap;
  }

  /// Get unique MAP kdbayar values from memory
  List<String> getMapKdbayars() {
    if (!_isMapLoaded) return [];
    return _mapData.map((map) => map.kdbayar).toSet().toList()..sort();
  }

  /// Get KLU count from memory
  int getKluCount() => _kluData.length;

  /// Get MAP count from memory
  int getMapCount() => _mapData.length;

  /// Clear all cached data (useful for testing or memory management)
  void clearCache() {
    _kluData.clear();
    _mapData.clear();
    _isKluLoaded = false;
    _isMapLoaded = false;
  }

  // ============================================================================
  // MANUAL DATABASE SYNC FUNCTIONS (Admin Functions)
  // Following Qt legacy pattern: importKantor(), importKlu(), etc.
  // ============================================================================

  /// Manually sync Kantor database from kantor.csv (Admin function)
  Future<SyncResult> syncKantorFromCsv() async {
    try {
      print('Starting manual sync: Kantor from kantor.csv');
      
      // Execute SQL script to import kantor.csv to database
      // This mimics Qt legacy: KantorImportController with "./data/kantor.csv"
      final result = await DatabaseService.executeCsvImport(
        tableName: 'kantor',
        csvAssetPath: 'assets/data/kantor.csv',
      );
      
      print('Kantor sync completed: ${result.successCount} records');
      return SyncResult(
        success: true,
        message: 'Referensi Kantor berhasil diupdate. ${result.successCount} records diproses.',
        recordsProcessed: result.successCount,
      );
    } catch (e) {
      print('Error syncing Kantor: $e');
      return SyncResult(
        success: false,
        message: 'Error: File kantor.csv tidak dapat diproses - $e',
        recordsProcessed: 0,
      );
    }
  }

  /// Manually sync KLU database from klu.csv (Admin function)
  Future<SyncResult> syncKluFromCsv() async {
    try {
      print('Starting manual sync: KLU from klu.csv');
      
      final result = await DatabaseService.executeCsvImport(
        tableName: 'klu',
        csvAssetPath: 'assets/data/klu.csv',
      );
      
      // Reload KLU data in memory after sync
      await _loadKluData();
      
      print('KLU sync completed: ${result.successCount} records');
      return SyncResult(
        success: true,
        message: 'Referensi KLU berhasil diupdate. ${result.successCount} records diproses.',
        recordsProcessed: result.successCount,
      );
    } catch (e) {
      print('Error syncing KLU: $e');
      return SyncResult(
        success: false,
        message: 'Error: File klu.csv tidak dapat diproses - $e',
        recordsProcessed: 0,
      );
    }
  }

  /// Manually sync MAP database from map.csv (Admin function)
  Future<SyncResult> syncMapFromCsv() async {
    try {
      print('Starting manual sync: MAP from map.csv');
      
      final result = await DatabaseService.executeCsvImport(
        tableName: 'map',
        csvAssetPath: 'assets/data/map.csv',
      );
      
      // Reload MAP data in memory after sync
      await _loadMapData();
      
      print('MAP sync completed: ${result.successCount} records');
      return SyncResult(
        success: true,
        message: 'Referensi MAP berhasil diupdate. ${result.successCount} records diproses.',
        recordsProcessed: result.successCount,
      );
    } catch (e) {
      print('Error syncing MAP: $e');
      return SyncResult(
        success: false,
        message: 'Error: File map.csv tidak dapat diproses - $e',
        recordsProcessed: 0,
      );
    }
  }

  /// Manually sync Jatuh Tempo Pembayaran from jatuhtempo.csv (Admin function)
  Future<SyncResult> syncJatuhTempoFromCsv() async {
    try {
      print('Starting manual sync: Jatuh Tempo Pembayaran from jatuhtempo.csv');
      
      final result = await DatabaseService.executeCsvImport(
        tableName: 'jatuhtempo',
        csvAssetPath: 'assets/data/jatuhtempo.csv',
      );
      
      print('Jatuh Tempo sync completed: ${result.successCount} records');
      return SyncResult(
        success: true,
        message: 'Referensi Jatuh Tempo Pembayaran berhasil diupdate. ${result.successCount} records diproses.',
        recordsProcessed: result.successCount,
      );
    } catch (e) {
      print('Error syncing Jatuh Tempo: $e');
      return SyncResult(
        success: false,
        message: 'Error: File jatuhtempo.csv tidak dapat diproses - $e',
        recordsProcessed: 0,
      );
    }
  }

  /// Manually sync Max Lapor (Jatuh Tempo Pelaporan) from maxlapor.csv (Admin function)
  Future<SyncResult> syncMaxLaporFromCsv() async {
    try {
      print('Starting manual sync: Jatuh Tempo Pelaporan from maxlapor.csv');
      
      final result = await DatabaseService.executeCsvImport(
        tableName: 'maxlapor',
        csvAssetPath: 'assets/data/maxlapor.csv',
      );
      
      print('Max Lapor sync completed: ${result.successCount} records');
      return SyncResult(
        success: true,
        message: 'Referensi Jatuh Tempo Pelaporan berhasil diupdate. ${result.successCount} records diproses.',
        recordsProcessed: result.successCount,
      );
    } catch (e) {
      print('Error syncing Max Lapor: $e');
      return SyncResult(
        success: false,
        message: 'Error: File maxlapor.csv tidak dapat diproses - $e',
        recordsProcessed: 0,
      );
    }
  }

  /// Manually update Wajib Pajak data (Admin function)
  /// This mimics Qt legacy updateWajibPajak() function
  Future<SyncResult> updateWajibPajakData() async {
    try {
      print('Starting manual update: Wajib Pajak data');
      
      // This would typically run complex update scripts
      // For now, we'll simulate the operation
      final result = await DatabaseService.executeWajibPajakUpdate();
      
      print('Wajib Pajak update completed: ${result.successCount} records');
      return SyncResult(
        success: true,
        message: 'Data Wajib Pajak berhasil diupdate. ${result.successCount} records diproses.',
        recordsProcessed: result.successCount,
      );
    } catch (e) {
      print('Error updating Wajib Pajak: $e');
      return SyncResult(
        success: false,
        message: 'Error: Update Wajib Pajak gagal - $e',
        recordsProcessed: 0,
      );
    }
  }

  /// Update all reference data from CSV files in external data directory
  /// This reuses the same CSV loading process that runs during "Test Koneksi" / "Simpan & Gunakan"
  /// Instead of 6 separate Update functions, we have one comprehensive update
  static Future<SyncResult> updateAllReferenceData() async {
    try {
      print('Starting comprehensive reference data update...');
      print('Loading data from external data directory');
      
      // Reuse the existing CSV loading mechanism from DatabaseMigrationService
      // This is the same process that runs during database connection setup
      final csvTypes = ['updatekantor', 'updateklu', 'updatemap', 'updatejatuhtempo', 'updatemaxlapor'];
      int totalRecords = 0;
      final errors = <String>[];
      final successDetails = <String>[];
      
      for (final csvType in csvTypes) {
        try {
          final recordCount = await DatabaseMigrationService.loadSpecificCsvData(csvType);
          final tableName = csvType.replaceFirst('update', '');
          print('Successfully updated: $csvType ($recordCount records)');
          totalRecords += recordCount;
          successDetails.add('$tableName: $recordCount records');
        } catch (e) {
          final error = 'Failed to update $csvType: $e';
          print(error);
          errors.add(error);
        }
      }
      
      return SyncResult(
        success: errors.isEmpty,
        message: errors.isEmpty 
            ? 'Semua data referensi berhasil diupdate.\nTotal: $totalRecords records\n${successDetails.join('\n')}'
            : 'Update selesai dengan ${errors.length} error(s). Total: $totalRecords records processed.',
        recordsProcessed: totalRecords,
      );
    } catch (e) {
      print('Error updating all reference data: $e');
      return SyncResult(
        success: false,
        message: 'Gagal mengupdate data referensi: $e',
        recordsProcessed: 0,
      );
    }
  }
}

/// Result of manual database sync operations
class SyncResult {
  final bool success;
  final String message;
  final int recordsProcessed;

  const SyncResult({
    required this.success,
    required this.message,
    required this.recordsProcessed,
  });
}

/// Global reference data service provider
final referenceDataServiceProvider = Provider<ReferenceDataService>((ref) => ReferenceDataService());

/// State notifier for managing reference data loading state
class ReferenceDataNotifier extends StateNotifier<AsyncValue<void>> {
  final ReferenceDataService _service;

  ReferenceDataNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _service.loadAllReferenceData();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Refresh all reference data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadData();
  }

  /// Check if data is ready
  bool get isDataReady => state.hasValue && _service.isKluLoaded && _service.isMapLoaded;
}

/// Provider for reference data loading state
final referenceDataProvider = StateNotifierProvider<ReferenceDataNotifier, AsyncValue<void>>((ref) {
  final service = ref.read(referenceDataServiceProvider);
  return ReferenceDataNotifier(service);
});