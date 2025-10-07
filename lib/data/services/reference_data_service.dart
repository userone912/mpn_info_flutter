import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/klu_model.dart';
import '../models/map_model.dart';
import 'database_service.dart';
import 'database_migration_service.dart';

/// Centralized reference data service that loads all data once at startup
/// This mimics the Qt legacy approach where all data is loaded in memory
class ReferenceDataService {
  // Cached Kanwil and KPP data for office config dropdowns
  List<Map<String, String>> _kanwilList = [];
  List<Map<String, String>> get kanwilList => List.unmodifiable(_kanwilList);


  /// Load Kanwil data for office config dropdowns
  Future<void> loadKantorDropdownData() async {
    print('Loading Kanwil data for office config...');
    final kanwilResult = await DatabaseService.rawQuery(
      "SELECT kanwil, CONCAT(kanwil, ' - ', nama) AS label FROM kantor WHERE kpp='000' ORDER BY kanwil"
    );
    _kanwilList = kanwilResult.map((row) => {
      'value': row['kanwil']?.toString() ?? '',
      'label': row['label']?.toString() ?? '',
    }).toList();
    print('- Kanwil records: ${_kanwilList.length}');
    print('Kanwil data loaded successfully.');
  }

  /// Load KPP list for a selected Kanwil (no cache)
  Future<List<Map<String, String>>> loadKppListForKanwil(String kanwil) async {
    print('Loading KPP list for Kanwil: $kanwil');
    final kppResult = await DatabaseService.rawQuery(
      "SELECT kpp, nama FROM kantor WHERE kanwil = ? ORDER BY kpp",
      [kanwil]
    );
    final kppList = kppResult.map((row) {
      final kpp = row['kpp']?.toString() ?? '';
      final nama = row['nama']?.toString() ?? '';
      final label = nama.isNotEmpty ? '$kpp - $nama' : kpp;
      return {
        'value': kpp,
        'label': label,
      };
    }).toList();
    print('KPP for Kanwil $kanwil: ${kppList.length}');
    return kppList;
  }
  /// Utility: Normalize CSV by removing all commas (for kantor.csv import)
  Future<void> _normalizeCsvRemoveCommas(String srcPath, String destPath) async {
    final srcFile = File(srcPath);
    String actualDestPath = destPath;
    bool isDebug = false;
    assert(() {
      isDebug = true;
      return true;
    }());
    if (isDebug) {
      // Write to debug build directory
      actualDestPath = 'build/windows/x64/runner/Debug/data/kantor.csv';
      print('[normalizeCsv] DEBUG mode detected, writing to: ' + actualDestPath);
    }
    final destFile = File(actualDestPath);
    print('[normalizeCsv] Source (relative): $srcPath');
    print('[normalizeCsv] Dest   (relative): $actualDestPath');
    if (!await srcFile.exists()) {
      print('[normalizeCsv] ERROR: Source CSV file not found: $srcPath');
      throw Exception('Source CSV file not found: $srcPath');
    }
    final lines = await srcFile.readAsLines();
    print('[normalizeCsv] Read ${lines.length} lines from source.');
    // Remove commas and double quotes from each line
    final normalizedLines = lines.map((line) => line.replaceAll(',', '').replaceAll('"', '')).toList();
    print('[normalizeCsv] Normalized ${normalizedLines.length} lines.');
    try {
      await destFile.writeAsString(normalizedLines.join('\n'));
      final exists = await destFile.exists();
      if (exists) {
        print('[normalizeCsv] Successfully wrote to dest: $destPath');
      } else {
        print('[normalizeCsv] ERROR: Dest file does NOT exist after write: $destPath');
      }
    } catch (e) {
      print('[normalizeCsv] ERROR writing to dest: $e');
      rethrow;
    }
    print('CSV normalization complete: commas and double quotes removed from $srcPath');
  }
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
      // Load all data sequentially for correct Kanwil/KPP cache
      await _loadKluData();
      await _loadMapData();
      await loadKantorDropdownData();
      print('Reference data loaded successfully:');
      print('- KLU records: ${_kluData.length}');
      print('- MAP records: ${_mapData.length}');
      print('- Kanwil records: ${_kanwilList.length}');
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
      // Normalize kantor.csv: remove all commas before import
      final importPath = 'data/kantor.csv';
      final normalizedPath = 'data/kantor.csv';
      await _normalizeCsvRemoveCommas(importPath, normalizedPath);
      // Execute SQL script to import normalized kantor.csv to database
      final result = await DatabaseService.executeCsvImport(
        tableName: 'kantor',
        csvAssetPath: normalizedPath,
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
        csvAssetPath: 'data/klu.csv',
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
        csvAssetPath: 'data/map.csv',
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
        csvAssetPath: 'data/jatuhtempo.csv',
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
        csvAssetPath: 'data/maxlapor.csv',
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
      
      // Always normalize kantor.csv before importing
      try {
        final importPath = 'data/kantor.csv';
        final normalizedPath = 'data/kantor.csv';
        final refService = ReferenceDataService();
        await refService._normalizeCsvRemoveCommas(importPath, normalizedPath);
        final recordCount = await DatabaseService.executeCsvImport(
          tableName: 'kantor',
          csvAssetPath: normalizedPath,
        );
        print('Successfully updated: kantor ($recordCount records)');
      } catch (e) {
        final error = 'Failed to update kantor: $e';
        print(error);
      }
      // Continue with other reference types
      final otherCsvTypes = ['updateklu', 'updatemap', 'updatejatuhtempo', 'updatemaxlapor'];
      int totalRecords = 0;
      final errors = <String>[];
      final successDetails = <String>[];
      for (final csvType in otherCsvTypes) {
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