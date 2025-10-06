import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/map_model.dart';
import 'database_service.dart';

/// Service for managing MAP (Mata Anggaran Penerimaan) reference data
class MapService {
  
  /// Get all MAP records
  Future<List<MapModel>> getAllMap() async {
    try {
      final result = await DatabaseService.query(
        'map',
        orderBy: 'kdmap',
      );

      return result.map((json) => MapModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching MAP data: $e');
      return [];
    }
  }

  /// Search MAP by kdmap, kdbayar, or uraian
  Future<List<MapModel>> searchMap(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllMap();
      }

      final result = await DatabaseService.query(
        'map',
        where: 'kdmap LIKE ? OR kdbayar LIKE ? OR uraian LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'kdmap',
      );

      return result.map((json) => MapModel.fromJson(json)).toList();
    } catch (e) {
      print('Error searching MAP data: $e');
      return [];
    }
  }

  /// Get MAP by specific kdmap
  Future<MapModel?> getMapByKdmap(String kdmap) async {
    try {
      final result = await DatabaseService.query(
        'map',
        where: 'kdmap = ?',
        whereArgs: [kdmap],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return MapModel.fromJson(result.first);
      }
      return null;
    } catch (e) {
      print('Error fetching MAP by kdmap: $e');
      return null;
    }
  }

  /// Get MAP records by kdbayar
  Future<List<MapModel>> getMapByKdbayar(String kdbayar) async {
    try {
      final result = await DatabaseService.query(
        'map',
        where: 'kdbayar = ?',
        whereArgs: [kdbayar],
        orderBy: 'kdmap',
      );

      return result.map((json) => MapModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching MAP by kdbayar: $e');
      return [];
    }
  }

  /// Get MAP records by sektor
  Future<List<MapModel>> getMapBySektor(int sektor) async {
    try {
      final result = await DatabaseService.query(
        'map',
        where: 'sektor = ?',
        whereArgs: [sektor],
        orderBy: 'kdmap',
      );

      return result.map((json) => MapModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching MAP by sektor: $e');
      return [];
    }
  }

  /// Get count of MAP records
  Future<int> getMapCount() async {
    try {
      final result = await DatabaseService.rawQuery('SELECT COUNT(*) as count FROM map');
      if (result.isNotEmpty) {
        return result.first['count'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting MAP count: $e');
      return 0;
    }
  }

  /// Get unique sektor values with display names
  Future<Map<int, String>> getUniqueSektorsWithDisplay() async {
    try {
      final result = await DatabaseService.rawQuery(
        'SELECT DISTINCT sektor FROM map ORDER BY sektor'
      );

      final sektorMap = <int, String>{};
      for (final row in result) {
        final sektor = row['sektor'] is int ? row['sektor'] as int : int.tryParse(row['sektor']?.toString() ?? '0') ?? 0;
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
    } catch (e) {
      print('Error fetching unique sektors: $e');
      return {};
    }
  }

  /// Get unique kdbayar values
  Future<List<String>> getUniqueKdbayar() async {
    try {
      final result = await DatabaseService.rawQuery(
        'SELECT DISTINCT kdbayar FROM map ORDER BY kdbayar'
      );

      return result.map((row) => row['kdbayar']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    } catch (e) {
      print('Error fetching unique kdbayar: $e');
      return [];
    }
  }
}

/// MAP service provider
final mapServiceProvider = Provider<MapService>((ref) => MapService());

/// MAP list state notifier
class MapListNotifier extends StateNotifier<AsyncValue<List<MapModel>>> {
  final MapService _mapService;

  MapListNotifier(this._mapService) : super(const AsyncValue.loading()) {
    loadAllMap();
  }

  /// Load all MAP records
  Future<void> loadAllMap() async {
    state = const AsyncValue.loading();
    try {
      final mapList = await _mapService.getAllMap();
      state = AsyncValue.data(mapList);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Search MAP records
  Future<void> searchMap(String query) async {
    state = const AsyncValue.loading();
    try {
      final mapList = await _mapService.searchMap(query);
      state = AsyncValue.data(mapList);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Filter by sektor
  Future<void> filterBySektor(int sektor) async {
    state = const AsyncValue.loading();
    try {
      final mapList = await _mapService.getMapBySektor(sektor);
      state = AsyncValue.data(mapList);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Filter by kdbayar
  Future<void> filterByKdbayar(String kdbayar) async {
    state = const AsyncValue.loading();
    try {
      final mapList = await _mapService.getMapByKdbayar(kdbayar);
      state = AsyncValue.data(mapList);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadAllMap();
  }
}

/// MAP list provider
final mapListProvider = StateNotifierProvider<MapListNotifier, AsyncValue<List<MapModel>>>((ref) {
  final mapService = ref.read(mapServiceProvider);
  return MapListNotifier(mapService);
});