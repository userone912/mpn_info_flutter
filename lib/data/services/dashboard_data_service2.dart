import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database_service.dart';

/// Dashboard data service for ppmpkmbo revenue aggregation
class DashboardDataService {


  // In-memory cache
  List<Map<String, dynamic>> _revenueCache = [];
  bool _isLoaded = false;
  // track last MAX(LAST_UPDATE) observed when we last loaded the revenue cache
  DateTime? _lastLoadedMaxUpdate;

  // Cube cache multi-dimensi (8 dimensi to include BLN_SETOR, MASA_PAJAK, KD_MAP, FLAG_PKPM, FLAG_BO, VOLUNTARY)
  Map<String, double> _cubeCache = {};
  // Separate cube for renpen (targets) so renpen can be rolled-up with the same
  // dimensional model if desired. Keys use the same 8-dim canonical order.
  Map<String, double> _renpenCube = {};
  Map<String, double> get renpenCube => _renpenCube;
  // canonical dimension order used for cube keys
  static const List<String> _dimOrder = [
    'KPPADM', // 0
    'THN_SETOR', // 1
    'BLN_SETOR', // 2
    'MASA_PAJAK', // 3
    'KD_MAP', // 4
    'FLAG_PKPM', // 5
    'FLAG_BO', // 6
    'VOLUNTARY', // 7
  ];

  // Statistik
  double _statSpmkp = 0.0;
  double _statPenerimaan = 0.0;
  double _statPBK = 0.0;
  double _statNetto = 0.0;
  double _statRenpen = 0.0;
  double _statPencapaian = 0.0;
  double _statPertumbuhan = 0.0;


  double get statSpmkp => _statSpmkp;
  double get statPenerimaan => _statPenerimaan;
  double get statPBK => _statPBK;
  double get statNetto => _statNetto;
  double get statRenpen => _statRenpen;
  double get statPencapaian => _statPencapaian;
  double get statPertumbuhan => _statPertumbuhan;

  // Monthly caches (dipertahankan untuk chart lama)
  List<Map<String, dynamic>> _monthlyFlagPkpmCache = [];
  List<Map<String, dynamic>> _monthlyFlagBoCache = [];
  List<Map<String, dynamic>> _monthlyVoluntaryCache = [];
  List<Map<String, dynamic>> _monthlyKdMapCache = [];

  List<Map<String, dynamic>> get monthlyFlagPkpmData =>
      List.unmodifiable(_monthlyFlagPkpmCache);
  List<Map<String, dynamic>> get monthlyFlagBoData =>
      List.unmodifiable(_monthlyFlagBoCache);
  List<Map<String, dynamic>> get monthlyVoluntaryData =>
      List.unmodifiable(_monthlyVoluntaryCache);
  List<Map<String, dynamic>> get monthlyKdMapData =>
      List.unmodifiable(_monthlyKdMapCache);

  /// Ambil cache dropdown filter
  Future<Map<String, List<String>>> getPenerimaanCache() async {
    final tahunRes = await DatabaseService.rawQuery(
      'SELECT DISTINCT THN_SETOR FROM ppmpkmbo ORDER BY THN_SETOR DESC',
      [],
    );
    final kdMapRes = await DatabaseService.rawQuery(
      'SELECT DISTINCT KD_MAP FROM ppmpkmbo ORDER BY KD_MAP',
      [],
    );
    final kdSetorRes = await DatabaseService.rawQuery(
      'SELECT DISTINCT KD_SETOR FROM ppmpkmbo ORDER BY KD_SETOR',
      [],
    );
    final voluntaryRes = await DatabaseService.rawQuery(
      'SELECT DISTINCT VOLUNTARY FROM ppmpkmbo ORDER BY VOLUNTARY',
      [],
    );
    final flagPkpmRes = await DatabaseService.rawQuery(
      'SELECT DISTINCT FLAG_PKPM FROM ppmpkmbo ORDER BY FLAG_PKPM',
      [],
    );
    final flagBoRes = await DatabaseService.rawQuery(
      'SELECT DISTINCT FLAG_BO FROM ppmpkmbo ORDER BY FLAG_BO',
      [],
    );
    return {
      'tahunOptions': tahunRes
          .map((row) => row['THN_SETOR'].toString())
          .where((v) => v.isNotEmpty)
          .toList(),
      'kdMapOptions': kdMapRes
          .map((row) => row['KD_MAP'].toString())
          .where((v) => v.isNotEmpty)
          .toList(),
      'kdSetorOptions': kdSetorRes
          .map((row) => row['KD_SETOR'].toString())
          .where((v) => v.isNotEmpty)
          .toList(),
      'voluntaryOptions': voluntaryRes
          .map((row) => row['VOLUNTARY'].toString())
          .where((v) => v.isNotEmpty)
          .toList(),
      'flagPkpmOptions': flagPkpmRes
          .map((row) => row['FLAG_PKPM'].toString())
          .where((v) => v.isNotEmpty)
          .toList(),
      'flagBoOptions': flagBoRes
          .map((row) => row['FLAG_BO'].toString())
          .where((v) => v.isNotEmpty)
          .toList(),
    };
  }

  /// Delete disk cache file for given kantorKode and tahun. Returns true if deleted.
  Future<bool> deleteDiskCache(String kantorKode, String? tahun) async {
    try {
      final file = await _cacheFileFor(kantorKode, tahun);
      if (await file.exists()) {
        await file.delete();
        print('Deleted cache file: ${file.path}');
        return true;
      } else {
        print('Cache file not found for $kantorKode/$tahun');
        return false;
      }
    } catch (e) {
      print('Error deleting cache for $kantorKode/$tahun: $e');
      return false;
    }
  }

  /// Delete all cache files under the mpn_cache directory and return number deleted.
  Future<int> clearAllDiskCaches() async {
    try {
      final baseDir = await getApplicationSupportDirectory();
      final dirPath = p.join(baseDir.path, 'mpn_cache');
      final dir = Directory(dirPath);
      if (!await dir.exists()) return 0;
      int deleted = 0;
      await for (final entity in dir.list()) {
        if (entity is File) {
          try {
            await entity.delete();
            deleted++;
            print('Deleted cache file: ${entity.path}');
          } catch (e) {
            print('Failed to delete ${entity.path}: $e');
          }
        }
      }
      return deleted;
    } catch (e) {
      print('Error clearing all cache files: $e');
      return 0;
    }
  }

  /// Filter PKPMBO untuk Data Penerimaan
  List<Map<String, dynamic>> filterPenerimaanData({
    String? npwp,
    String? nama,
    String? kdMap,
    String? kdSetor,
    String? masaPajak,
    int? tahunSetor,
    DateTime? tglSetor,
    String? ntpn,
    String? noPbk,
    String? voluntary,
    String? flagPkpm,
    String? flagBo,
    String? source,
    String? kantor,
  }) {
    if (!_isLoaded) return [];
    return _revenueCache.where((row) {
      if (npwp != null &&
          !(row['NPWP']?.toString().contains(npwp) ?? false)) return false;
      if (nama != null &&
          !(row['NAMA']?.toString().toLowerCase().contains(nama.toLowerCase()) ??
              false)) return false;
      if (kdMap != null && row['KD_MAP'] != kdMap) return false;
      if (kdSetor != null && row['KD_SETOR'] != kdSetor) return false;
      if (masaPajak != null && row['MASA_PAJAK'] != masaPajak) return false;
      if (tahunSetor != null && row['THN_SETOR'] != tahunSetor) return false;
      if (tglSetor != null && row['TGL_SETOR'] != null) {
        final rowDate = DateTime.tryParse(row['TGL_SETOR'].toString());
        if (rowDate == null || rowDate != tglSetor) return false;
      }
      if (ntpn != null && !(row['NTPN']?.toString().contains(ntpn) ?? false))
        return false;
      if (noPbk != null && !(row['NO_PBK']?.toString().contains(noPbk) ?? false))
        return false;
      if (voluntary != null && row['VOLUNTARY'] != voluntary) return false;
      if (flagPkpm != null && row['FLAG_PKPM'] != flagPkpm) return false;
      if (flagBo != null && row['FLAG_BO'] != flagBo) return false;
      if (source != null && !(row['SOURCE']?.toString().contains(source) ?? false))
        return false;
      if (kantor != null && row['KPPADM'] != kantor) return false;
      return true;
    }).toList();
  }

  /// Load statistik
  Future<void> loadStatistics(String kpp, String tahun) async {
    final penerimaanRes = await DatabaseService.rawQuery(
      'SELECT SUM(JML_SETOR) as total FROM ppmpkmbo WHERE KPPADM = ? AND THN_SETOR = ?',
      [kpp, tahun],
    );
    _statPenerimaan =
        double.tryParse(penerimaanRes.first['total']?.toString() ?? '0') ?? 0.0;

    final pbkRes = await DatabaseService.rawQuery(
      "SELECT SUM(JML_SETOR) as total FROM ppmpkmbo WHERE NO_PBK IS NOT NULL AND NO_PBK != '' AND KPPADM = ? AND THN_SETOR = ?",
      [kpp, tahun],
    );
    _statPBK = double.tryParse(pbkRes.first['total']?.toString() ?? '0') ?? 0.0;

    final spmkpRes = await DatabaseService.rawQuery(
      'SELECT SUM(nominal) as total FROM spmkp WHERE kpp = ? AND tahun = ?',
      [kpp, tahun],
    );
    _statSpmkp =
        double.tryParse(spmkpRes.first['total']?.toString() ?? '0') ?? 0.0;
    _statNetto = _statPenerimaan - _statSpmkp;

    final renpenRes = await DatabaseService.rawQuery(
      'SELECT SUM(target) as total FROM renpen WHERE kpp = ? AND tahun = ?',
      [kpp, tahun],
    );
    _statRenpen =
        double.tryParse(renpenRes.first['total']?.toString() ?? '0') ?? 0.0;

    _statPencapaian =
        _statRenpen > 0 ? (_statPenerimaan / _statRenpen * 100) : 0.0;

    final tahunInt = int.tryParse(tahun) ?? 0;
    final lastTahun = (tahunInt - 1).toString();
    final lastPenerimaanRes = await DatabaseService.rawQuery(
      'SELECT SUM(JML_SETOR) as total FROM ppmpkmbo WHERE KPPADM = ? AND THN_SETOR = ?',
      [kpp, lastTahun],
    );
    final lastPenerimaan =
        double.tryParse(lastPenerimaanRes.first['total']?.toString() ?? '0') ??
            0.0;
    _statPertumbuhan = lastPenerimaan > 0
        ? ((_statPenerimaan - lastPenerimaan) / lastPenerimaan * 100)
        : 0.0;
  }

  /// Load revenue data dan bangun cube cache
  Future<void> loadRevenueData(String kantorKode, [String? tahun]) async {
    print('Loading revenue data for $kantorKode, $tahun (checking MAX(LAST_UPDATE) before querying)');
    // First ask the DB for MAX(LAST_UPDATE) to avoid expensive full table queries when not necessary
    final yearClause = (tahun != null) ? 'AND THN_SETOR = ?' : '';
    final paramsCheck = [kantorKode];
    if (tahun != null) paramsCheck.add(tahun);
    DateTime? dbMax;
    try {
      final maxRes = await DatabaseService.rawQuery(
        'SELECT MAX(LAST_UPDATE) as max_update FROM ppmpkmbo WHERE KPPADM = ? $yearClause',
        paramsCheck,
      );
      final s = maxRes.isNotEmpty ? (maxRes.first['max_update']?.toString() ?? '') : '';
      if (s.isNotEmpty) dbMax = DateTime.tryParse(s);
    } catch (e) {
      dbMax = null;
    }

      // If not loaded yet (fresh start), try to load cube cache from disk if it's valid
      if (!_isLoaded) {
        try {
          final loadedFromDisk = await _tryLoadCubeCacheFromDiskIfValid(kantorKode, tahun, dbMax);
          if (loadedFromDisk) {
            print('Loaded cube cache from disk; skipping DB full reload for $kantorKode/$tahun');
            return;
          }
        } catch (e) {
          // ignore disk load errors and fall back to DB
        }
      }
    // If DB MAX(LAST_UPDATE) is not after our last loaded marker, try to load from disk cache and skip raw query
    if (_lastLoadedMaxUpdate != null && dbMax != null && !dbMax.isAfter(_lastLoadedMaxUpdate!)) {
      final loadedFromDisk = await _tryLoadCubeCacheFromDiskIfValid(kantorKode, tahun, dbMax);
      if (loadedFromDisk || _isLoaded) {
      print('Skipping full revenue query: DB not newer (dbMax=${dbMax.toIso8601String()}, lastLoaded=${_lastLoadedMaxUpdate!.toIso8601String()})');
        return;
      }
      // if disk load failed, fall through to fetch from DB
    }

    final sql = '''
      SELECT KPPADM, THN_SETOR, BLN_SETOR, MASA_PAJAK, KD_MAP, FLAG_PKPM, FLAG_BO, VOLUNTARY, JML_SETOR AS total_setor, LAST_UPDATE
      FROM ppmpkmbo
      WHERE KPPADM = ?
      ${tahun != null ? 'AND THN_SETOR = ?' : ''}
    ''';
    final params = [kantorKode];
    if (tahun != null) params.add(tahun);

    _revenueCache = await DatabaseService.rawQuery(sql, params);
    _isLoaded = true;

    // compute max LAST_UPDATE observed in the loaded rows and store as the cache marker
    try {
      DateTime? maxUpdate;
      for (final r in _revenueCache) {
        final s = r['LAST_UPDATE']?.toString();
        if (s == null || s.isEmpty) continue;
        final dt = DateTime.tryParse(s);
        if (dt == null) continue;
        if (maxUpdate == null || dt.isAfter(maxUpdate)) maxUpdate = dt;
      }
      _lastLoadedMaxUpdate = maxUpdate;
    } catch (e) {
      // if any parsing issue, clear marker so subsequent ensure will reload
      _lastLoadedMaxUpdate = null;
    }

    // Populate RENPEN cube from renpen table
    _renpenCube.clear();
    final renpenParams = [kantorKode];
    if (tahun != null) renpenParams.add(tahun);
    final renpenRows = await DatabaseService.rawQuery(
      'SELECT bulan, kdmap, nip, target FROM renpen WHERE kpp = ?' + (tahun != null ? ' AND tahun = ?' : ''),
      renpenParams,
    );
    for (final row in renpenRows) {
      final bln = row['bulan']?.toString() ?? 'ALL';
      final kdmap = row['kdmap']?.toString() ?? 'ALL';
      final nip = row['nip']?.toString() ?? 'ALL';
      final key = '$bln|$kdmap|$nip';
      final value = (row['target'] as num?)?.toDouble() ?? 0.0;
      _renpenCube[key] = (_renpenCube[key] ?? 0.0) + value;
    }

    await _buildCubeCache();
    // persist cube cache to disk for faster startup next time
    try {
      await _saveCubeCacheToDisk(kantorKode, tahun);
    } catch (e) {
      // non-fatal: ignore disk errors
      print('Warning: failed to persist cube cache: $e');
    }
  }

  /// Ensure revenue cache is up-to-date by comparing MAX(LAST_UPDATE) in DB
  /// with the cached `_lastLoadedMaxUpdate`. Only reloads if they differ.
  Future<void> ensureRevenueData(String kantorKode, [String? tahun]) async {
    final yearClause = (tahun != null) ? 'AND THN_SETOR = ?' : '';
    final params = [kantorKode];
    if (tahun != null) params.add(tahun);

    final res = await DatabaseService.rawQuery(
      'SELECT MAX(LAST_UPDATE) as max_update FROM ppmpkmbo WHERE KPPADM = ? $yearClause',
      params,
    );

    DateTime? dbMax;
    try {
      final s = res.isNotEmpty ? (res.first['max_update']?.toString() ?? '') : '';
      if (s.isNotEmpty) dbMax = DateTime.tryParse(s);
    } catch (e) {
      dbMax = null;
    }

    // If not loaded yet, try to load cached cube from disk if it is still valid
    if (!_isLoaded) {
      final loadedFromDisk = await _tryLoadCubeCacheFromDiskIfValid(kantorKode, tahun, dbMax);
      if (loadedFromDisk) return;
    }

    // If we haven't loaded yet, or DB max_update is after our in-memory marker, reload
    if (!_isLoaded || (_lastLoadedMaxUpdate == null && dbMax != null) ||
        (dbMax != null && _lastLoadedMaxUpdate != null && dbMax.isAfter(_lastLoadedMaxUpdate!)) ||
        (dbMax == null && _lastLoadedMaxUpdate == null && !_isLoaded)) {
      await loadRevenueData(kantorKode, tahun);
    } else {
      print('Revenue data up-to-date for $kantorKode, $tahun (dbMax=${dbMax?.toIso8601String()})');
    }
  }

  /// Return cache file for given kantorKode and tahun. Uses working directory. Consider using path_provider for platform-safe storage.
  /// Return cache file for given kantorKode and tahun located in the
  /// platform application support directory under a `mpn_cache` subfolder.
  /// This uses `path_provider` so the app user doesn't need to know the file location.
  Future<File> _cacheFileFor(String kantorKode, String? tahun) async {
    final safeTahun = (tahun == null || tahun.isEmpty) ? 'ALL' : tahun;
    final baseDir = await getApplicationSupportDirectory();
    final dirPath = p.join(baseDir.path, 'mpn_cache');
    final fileName = 'mpninfo_${kantorKode}_$safeTahun.cache';
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      try {
        await dir.create(recursive: true);
      } catch (_) {}
    }
    return File(p.join(dirPath, fileName));
  }

  Future<void> _saveCubeCacheToDisk(String kantorKode, String? tahun) async {
    final file = await _cacheFileFor(kantorKode, tahun);
    final payload = <String, dynamic>{
      'last_update': _lastLoadedMaxUpdate?.toIso8601String(),
      'cube': _cubeCache,
      'monthlyFlagPkpm': _monthlyFlagPkpmCache,
      'monthlyFlagBo': _monthlyFlagBoCache,
      'monthlyVoluntary': _monthlyVoluntaryCache,
      'monthlyKdMap': _monthlyKdMapCache,
  // 'monthlyRenpen': _monthlyRenpenCache, // removed
    };

    // write compressed JSON atomically: write to temp file then rename
  final tmpFile = File('${file.path}.tmp');
    try {
      final jsonStr = jsonEncode(payload);
      final bytes = utf8.encode(jsonStr);
      final compressed = gzip.encode(bytes);
      await tmpFile.writeAsBytes(compressed, flush: true);
      // replace target atomically
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      await tmpFile.rename(file.path);
    } finally {
      if (await tmpFile.exists()) {
        try {
          await tmpFile.delete();
        } catch (_) {}
      }
    }
  }

  /// Attempt to load cube cache from disk if the saved last_update is >= dbMax.
  /// Returns true if cache was loaded and is usable.
  Future<bool> _tryLoadCubeCacheFromDiskIfValid(String kantorKode, String? tahun, DateTime? dbMax) async {
    try {
  final file = await _cacheFileFor(kantorKode, tahun);
  if (!await file.exists()) return false;
  final bytes = await file.readAsBytes();
  final decoded = gzip.decode(bytes);
  final content = utf8.decode(decoded);
  final Map<String, dynamic> obj = jsonDecode(content);
      final saved = obj['last_update'] as String?;
      DateTime? savedDt;
      if (saved != null && saved.isNotEmpty) {
        savedDt = DateTime.tryParse(saved);
      }

      // if dbMax exists and savedDt exists and savedDt < dbMax, cached cube is stale
      if (dbMax != null && savedDt != null && savedDt.isBefore(dbMax)) return false;

      // otherwise load cube and monthly caches
      final Map<String, dynamic> cubeObj = Map<String, dynamic>.from(obj['cube'] ?? {});
      _cubeCache = cubeObj.map((k, v) => MapEntry(k, (v as num).toDouble()));

      _monthlyFlagPkpmCache = (obj['monthlyFlagPkpm'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
      _monthlyFlagBoCache = (obj['monthlyFlagBo'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
      _monthlyVoluntaryCache = (obj['monthlyVoluntary'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
      _monthlyKdMapCache = (obj['monthlyKdMap'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
  // _monthlyRenpenCache removed

      _lastLoadedMaxUpdate = savedDt;
      _isLoaded = true;
      print('Loaded cube cache from disk for $kantorKode/$tahun (last_update=${savedDt?.toIso8601String()})');
      return true;
    } catch (e) {
      print('Warning: failed to load cube cache from disk: $e');
      return false;
    }
  }

  /// Build cube multi-dimensi 6 kolom dengan helper CubeKey
  Future<void> _buildCubeCache() async {
    _cubeCache.clear();
    _renpenCube.clear();

    for (var row in _revenueCache) {
      final dims = [
        row['KPPADM']?.toString() ?? 'ALL',
        row['THN_SETOR']?.toString() ?? 'ALL',
        row['BLN_SETOR']?.toString() ?? 'ALL',
        row['MASA_PAJAK']?.toString() ?? 'ALL',
        row['KD_MAP']?.toString() ?? 'ALL',
        row['FLAG_PKPM']?.toString() ?? 'ALL',
        row['FLAG_BO']?.toString() ?? 'ALL',
        row['VOLUNTARY']?.toString() ?? 'ALL',
      ];

      // iterate all subsets of the 8 dims
      for (int mask = 0; mask < (1 << 8); mask++) {
        List<String> keyParts = [];
        for (int i = 0; i < 8; i++) {
          keyParts.add((mask & (1 << i)) != 0 ? dims[i] : 'ALL');
        }
        final keyStr = keyParts.join('|');
        _cubeCache[keyStr] = (_cubeCache[keyStr] ?? 0) + (row['total_setor'] as num? ?? 0);
      }
    }

    // Helper function untuk akses aman key
    List<Map<String, dynamic>> _buildMonthlyCache(int monthIndex, int labelIndex, String label) {
      // Ambil hanya entry rollup canonical: semua dim selain monthIndex/labelIndex harus 'ALL'.
      final Map<String, double> aggMap = {};
      for (final e in _cubeCache.entries) {
        final parts = e.key.split('|');
        // pastikan key memiliki cukup bagian
        if (parts.length <= monthIndex || parts.length <= labelIndex) continue;
        final monthVal = parts[monthIndex];
        final labelVal = parts[labelIndex];
        if (monthVal == 'ALL' || labelVal == 'ALL') continue;

        // cek apakah semua dim lain adalah 'ALL' (periksa semua 8 parts)
        var othersAreAll = true;
        for (int j = 0; j < 8; j++) {
          if (j == monthIndex || j == labelIndex) continue;
          if (parts[j] != 'ALL') {
            othersAreAll = false;
            break;
          }
        }
        if (!othersAreAll) continue;

        final key = monthVal + '|' + labelVal;
        aggMap[key] = (aggMap[key] ?? 0) + e.value;
      }

      return aggMap.entries.map((e) {
        final keyParts = e.key.split('|');
        return {
          'BLN_SETOR': keyParts[0],
          label: keyParts[1],
          'total_setor': e.value,
        };
      }).toList();
    }

  _monthlyFlagPkpmCache = _buildMonthlyCache(2, 5, 'FLAG_PKPM');
  _monthlyFlagBoCache = _buildMonthlyCache(2, 6, 'FLAG_BO');
  _monthlyVoluntaryCache = _buildMonthlyCache(2, 7, 'VOLUNTARY');
  _monthlyKdMapCache = _buildMonthlyCache(2, 4, 'KD_MAP');
  
  // Build monthlyRenpen cache (no KD_MAP filter, handled in chart widget)
  await _buildMonthlyRenpenCache();

}

  Future<void> _buildMonthlyRenpenCache({List<String>? selectedKdmap}) async {
    // Aggregasi dari _renpenCube: group by BLN_SETOR, optional filter KD_MAP
    final Map<String, double> aggMap = {};
    for (final entry in _renpenCube.entries) {
      final parts = entry.key.split('|'); // key: BLN_SETOR|KD_MAP|NIP
      if (parts.length < 3) continue;
      final bln = parts[0];
      final kdmap = parts[1];
      // Filter KD_MAP jika diberikan
      if (selectedKdmap == null || selectedKdmap.isEmpty || selectedKdmap.contains(kdmap)) {
        aggMap[bln] = (aggMap[bln] ?? 0.0) + entry.value;
      }
    }
    // _monthlyRenpenCache removed; use renpenCube directly for RENPEN aggregation
    print('Renpen Cube cache built with ${_renpenCube.length} entries.');
    print('Isi _monthlyData: ${_monthlyFlagPkpmCache}');
  }

  /// Query cube fleksibel
  double queryCube({
    String kpp = 'ALL',
    String tahun = 'ALL',
    String bln = 'ALL',
    String masaPajak = 'ALL',
    String kdMap = 'ALL',
    String flagPkpm = 'ALL',
    String flagBo = 'ALL',
    String voluntary = 'ALL',
  }) {
    final key = [kpp, tahun, bln, masaPajak, kdMap, flagPkpm, flagBo, voluntary].join('|');
    return _cubeCache[key] ?? 0.0;
  }

  /// Generic aggregation helper for charting
  ///
  /// xAxis: column name used as X-axis (one of `_dimOrder`),
  /// groupBy: optional column name used as series grouping (one of `_dimOrder`) or null for single series,
  /// filters: map of column -> value to apply as WHERE filters (these columns will be fixed in the key)
  ///
  /// Returns a List of maps, one per distinct xAxis value. Each map contains the xAxis value under key 'x'
  /// and one key per group value containing the aggregated sum. Example:
  /// [{ 'x': '1', 'PKM': 123.0, 'PPM': 456.0 }, ...]
  List<Map<String, dynamic>> aggregateForChart({
    required String xAxis,
    String? groupBy,
    Map<String, String>? filters,
  }) {
    filters ??= {};

    // validate columns
    if (!_dimOrder.contains(xAxis)) {
      throw ArgumentError('Unknown xAxis column: $xAxis');
    }
    if (groupBy != null && !_dimOrder.contains(groupBy)) {
      throw ArgumentError('Unknown groupBy column: $groupBy');
    }

    // helper to check a revenue row against filters
    bool rowMatchesFilters(Map<String, dynamic> row) {
      for (final entry in filters!.entries) {
        final k = entry.key;
        final v = entry.value;
        if (!row.containsKey(k) || row[k]?.toString() != v) return false;
      }
      return true;
    }

    // collect distinct x values and group values from _revenueCache (respecting filters)
    final Set<String> xValues = {};
    final Set<String> groupValues = {};
    for (final row in _revenueCache) {
      if (!rowMatchesFilters(row)) continue;
      final xv = row[xAxis]?.toString() ?? 'ALL';
      xValues.add(xv);
      if (groupBy != null) {
        final gv = row[groupBy]?.toString() ?? 'ALL';
        groupValues.add(gv);
      }
    }

    // If filters include xAxis or groupBy, respect only that value
    if (filters.containsKey(xAxis)) {
      xValues.clear();
      xValues.add(filters[xAxis]!);
    }
    if (groupBy != null && filters.containsKey(groupBy)) {
      groupValues.clear();
      groupValues.add(filters[groupBy]!);
    }

    // If groupBy is null, use empty group list with single TOTAL key
    final List<String> groups = groupBy == null ? ['TOTAL'] : groupValues.toList();

    // sort xValues reasonably: if BLN_SETOR numeric, sort as int; otherwise lexicographic
    final List<String> sortedX = xValues.toList();
    if (xAxis == 'BLN_SETOR') {
      sortedX.sort((a, b) => int.tryParse(a)?.compareTo(int.tryParse(b) ?? 0) ?? a.compareTo(b));
    } else {
      sortedX.sort();
    }

    // Build result: for each x and each group, construct exact 8-part key and read _cubeCache
    final List<Map<String, dynamic>> result = [];
    for (final xv in sortedX) {
      final Map<String, dynamic> rowOut = {'x': xv};
      for (final gv in groups) {
        // build key parts
        final List<String> parts = List.filled(_dimOrder.length, 'ALL');
        for (int i = 0; i < _dimOrder.length; i++) {
          final col = _dimOrder[i];
          if (col == xAxis) {
            parts[i] = xv;
          } else if (groupBy != null && col == groupBy) {
            parts[i] = gv;
          } else if (filters.containsKey(col)) {
            parts[i] = filters[col]!;
          } else {
            parts[i] = 'ALL';
          }
        }
        final key = parts.join('|');
        final value = _cubeCache[key] ?? 0.0;
        final outKey = groupBy == null ? 'value' : gv;
        rowOut[outKey] = value;
      }
      result.add(rowOut);
    }

    return result;
  }

  /// Return monthly dataset rows for a given dataset name ('PKPM' or 'VOLUNTARY').
  /// If filters is null or empty, returns the precomputed monthly cache for performance.
  /// Otherwise uses the cube via aggregateForChart to produce the same row shape as
  /// the legacy monthly caches: one row per (BLN_SETOR, group) with total_setor.
  /// Return monthly dataset rows for a given dataset name ('PKPM' or 'VOLUNTARY').
  /// Supports filters where each value may be a String or List<String> (OR semantics per-dimension).
  /// AND semantics apply across different filter dimensions (i.e. FLAG_BO in [A,B] AND KD_MAP in [X,Y]).
  List<Map<String, dynamic>> monthlyDataForDataset(String dataset, {Map<String, dynamic>? filters}) {
    final ds = dataset.toUpperCase();
    final String flagKey = ds == 'PKPM' ? 'FLAG_PKPM' : 'VOLUNTARY';
    if (filters == null || filters.isEmpty) {
      return ds == 'PKPM' ? monthlyFlagPkpmData : monthlyVoluntaryData;
    }

    // Convert filters values to sets for quick membership tests. Ignore empty values.
    final Map<String, Set<String>> allowed = {};
    for (final entry in filters.entries) {
      final key = entry.key;
      final val = entry.value;
      if (val is List) {
        final s = val.map((v) => v?.toString() ?? '').where((v) => v.isNotEmpty).toSet();
        if (s.isNotEmpty) allowed[key] = s;
      } else {
        final s = val?.toString() ?? '';
        if (s.isNotEmpty) allowed[key] = {s};
      }
    }

    if (allowed.isEmpty) return [];

    // Indices for x axis and group
    final xIndex = _dimOrder.indexOf('BLN_SETOR');
    final groupIndex = _dimOrder.indexOf(flagKey);

    final Map<String, double> accMap = {};
    final Map<String, Map<String, Set<String>>> metaSets = {};

    // Single pass: inspect cube entries and accept those where:
    // - parts[xIndex] != 'ALL' and parts[groupIndex] != 'ALL'
    // - for each other dim j: if allowed contains dimName -> parts[j] must be one of allowed[dimName]
    //   else parts[j] must be 'ALL' (ensures we only use the canonical rollup for unspecified dims)
    for (final e in _cubeCache.entries) {
      final parts = e.key.split('|');
      if (parts.length != _dimOrder.length) continue;
      final bln = parts[xIndex];
      final grp = parts[groupIndex];
      if (bln == 'ALL' || grp == 'ALL') continue;

      var ok = true;
      for (int j = 0; j < parts.length; j++) {
        if (j == xIndex || j == groupIndex) continue;
        final dimName = _dimOrder[j];
        if (allowed.containsKey(dimName)) {
          if (!allowed[dimName]!.contains(parts[j])) {
            ok = false;
            break;
          }
        } else {
          if (parts[j] != 'ALL') {
            ok = false;
            break;
          }
        }
      }
      if (!ok) continue;

      final key = '$bln|$grp';
      accMap[key] = (accMap[key] ?? 0.0) + e.value;
      final m = metaSets.putIfAbsent(key, () => {});
      // store metadata sets for filter dims
      for (final fk in allowed.keys) {
        final idx = _dimOrder.indexOf(fk);
        if (idx >= 0 && idx < parts.length) {
          m.putIfAbsent(fk, () => <String>{}).add(parts[idx]);
        }
      }
    }

    final List<Map<String, dynamic>> mapped = [];
    accMap.forEach((k, v) {
      final parts = k.split('|');
      final bln = parts[0];
      final grp = parts.length > 1 ? parts[1] : '';
      final entry = <String, dynamic>{
        'BLN_SETOR': bln,
        flagKey: grp == 'value' ? '' : grp,
        'total_setor': v,
      };
      final m = metaSets[k];
      if (m != null) {
        if (m.containsKey('FLAG_BO')) entry['FLAG_BO'] = m['FLAG_BO']!.toList().join(',');
        if (m.containsKey('KD_MAP')) entry['KD_MAP'] = m['KD_MAP']!.toList().join(',');
      }
      mapped.add(entry);
    });

    // sort by BLN_SETOR then group for stable output
    mapped.sort((a, b) {
      final ai = int.tryParse(a['BLN_SETOR']?.toString() ?? '') ?? 0;
      final bi = int.tryParse(b['BLN_SETOR']?.toString() ?? '') ?? 0;
      final c = ai.compareTo(bi);
      if (c != 0) return c;
      return (a[flagKey]?.toString() ?? '').compareTo(b[flagKey]?.toString() ?? '');
    });

    return mapped;
  }

  /// Clear cache
  void clearCache() {
    _revenueCache.clear();
    _isLoaded = false;
    _lastLoadedMaxUpdate = null;
  // _monthlyRenpenCache removed
    _monthlyFlagPkpmCache.clear();
    _monthlyFlagBoCache.clear();
    _monthlyVoluntaryCache.clear();
    _monthlyKdMapCache.clear();
    _cubeCache.clear();
    _renpenCube.clear();
  }
}
