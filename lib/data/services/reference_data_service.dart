import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/klu_model.dart';
import '../models/map_model.dart';
import 'database_service.dart';

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