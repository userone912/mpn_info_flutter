import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/klu_model.dart';
import 'database_service.dart';

/// Service for managing KLU (Klasifikasi Lapangan Usaha) reference data
class KluService {
  
  // Cache for better performance
  static List<KluModel>? _cachedKluList;
  static List<String>? _cachedSektors;
  static DateTime? _cacheTime;
  static const Duration cacheExpiry = Duration(minutes: 5);

  /// Check if cache is valid
  static bool get _isCacheValid {
    if (_cacheTime == null) return false;
    return DateTime.now().difference(_cacheTime!) < cacheExpiry;
  }

  /// Clear cache
  static void clearCache() {
    _cachedKluList = null;
    _cachedSektors = null;
    _cacheTime = null;
  }

  /// Get all KLU records with caching
  Future<List<KluModel>> getAllKlu() async {
    try {
      // Return cached data if valid
      if (_isCacheValid && _cachedKluList != null) {
        return _cachedKluList!;
      }

      final result = await DatabaseService.query(
        'klu',
        orderBy: 'kode',
      );

      final kluList = result.map((json) => KluModel.fromJson(json)).toList();
      
      // Cache the results
      _cachedKluList = kluList;
      _cacheTime = DateTime.now();
      
      return kluList;
    } catch (e) {
      print('Error fetching KLU data: $e');
      return _cachedKluList ?? [];
    }
  }

  /// Get paginated KLU records
  Future<List<KluModel>> getPaginatedKlu({
    int offset = 0,
    int limit = 100,
    String? searchQuery,
    String? sektor,
  }) async {
    try {
      String whereClause = '';
      List<dynamic> whereArgs = [];

      // Build where clause
      List<String> conditions = [];
      
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        conditions.add('(kode LIKE ? OR nama LIKE ?)');
        whereArgs.addAll(['%$searchQuery%', '%$searchQuery%']);
      }
      
      if (sektor != null && sektor.trim().isNotEmpty) {
        conditions.add('sektor = ?');
        whereArgs.add(sektor);
      }

      if (conditions.isNotEmpty) {
        whereClause = conditions.join(' AND ');
      }

      final result = await DatabaseService.query(
        'klu',
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'kode',
        limit: limit,
        offset: offset,
      );

      return result.map((json) => KluModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching paginated KLU data: $e');
      return [];
    }
  }

  /// Search KLU by kode or nama
  Future<List<KluModel>> searchKlu(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllKlu();
      }

      final result = await DatabaseService.query(
        'klu',
        where: 'kode LIKE ? OR nama LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'kode',
      );

      return result.map((json) => KluModel.fromJson(json)).toList();
    } catch (e) {
      print('Error searching KLU data: $e');
      return [];
    }
  }

  /// Get KLU by specific kode
  Future<KluModel?> getKluByKode(String kode) async {
    try {
      final result = await DatabaseService.query(
        'klu',
        where: 'kode = ?',
        whereArgs: [kode],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return KluModel.fromJson(result.first);
      }
      return null;
    } catch (e) {
      print('Error fetching KLU by kode: $e');
      return null;
    }
  }

  /// Get KLU records by sektor
  Future<List<KluModel>> getKluBySektor(String sektor) async {
    try {
      final result = await DatabaseService.query(
        'klu',
        where: 'sektor = ?',
        whereArgs: [sektor],
        orderBy: 'kode',
      );

      return result.map((json) => KluModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching KLU by sektor: $e');
      return [];
    }
  }

  /// Get count of KLU records
  Future<int> getKluCount() async {
    try {
      final result = await DatabaseService.rawQuery('SELECT COUNT(*) as count FROM klu');
      if (result.isNotEmpty) {
        return result.first['count'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting KLU count: $e');
      return 0;
    }
  }

  /// Get unique sektor values with caching
  Future<List<String>> getUniqueSektors() async {
    try {
      // Return cached data if valid
      if (_isCacheValid && _cachedSektors != null) {
        return _cachedSektors!;
      }

      final result = await DatabaseService.rawQuery(
        'SELECT DISTINCT sektor FROM klu ORDER BY sektor'
      );

      final sektors = result.map((row) => row['sektor']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      
      // Cache the results
      _cachedSektors = sektors;
      if (_cacheTime == null) _cacheTime = DateTime.now();
      
      return sektors;
    } catch (e) {
      print('Error fetching unique sektors: $e');
      return _cachedSektors ?? [];
    }
  }
}

/// KLU service provider
final kluServiceProvider = Provider<KluService>((ref) => KluService());

/// KLU list state notifier
class KluListNotifier extends StateNotifier<AsyncValue<List<KluModel>>> {
  final KluService _kluService;

  KluListNotifier(this._kluService) : super(const AsyncValue.loading()) {
    loadAllKlu();
  }

  /// Load all KLU records
  Future<void> loadAllKlu() async {
    state = const AsyncValue.loading();
    try {
      final kluList = await _kluService.getAllKlu();
      state = AsyncValue.data(kluList);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Search KLU records
  Future<void> searchKlu(String query) async {
    state = const AsyncValue.loading();
    try {
      final kluList = await _kluService.searchKlu(query);
      state = AsyncValue.data(kluList);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Filter by sektor
  Future<void> filterBySektor(String sektor) async {
    state = const AsyncValue.loading();
    try {
      final kluList = await _kluService.getKluBySektor(sektor);
      state = AsyncValue.data(kluList);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadAllKlu();
  }
}

/// KLU list provider
final kluListProvider = StateNotifierProvider<KluListNotifier, AsyncValue<List<KluModel>>>((ref) {
  final kluService = ref.read(kluServiceProvider);
  return KluListNotifier(kluService);
});