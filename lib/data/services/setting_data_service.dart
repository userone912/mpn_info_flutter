import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/seksi_model.dart';
import '../models/pegawai_model.dart';
import 'database_service.dart';

/// Centralized settings data service that loads all management data at startup
class SettingDataService {
  /// Get office code from database settings table
  static Future<String> getOfficeCodeFromDatabase() async {
    try {
      final result = await DatabaseService.query(
        'settings',
        where: '`key` = ?',
        whereArgs: ['kantor.kode'],
        limit: 1,
      );
      if (result.isNotEmpty) {
        return result.first['value']?.toString() ?? '';
      }
      return '';
    } catch (e) {
      return '';
    }
  }
  /// Add new Seksi record to database and refresh cache
  Future<int> addSeksi(SeksiModel seksi) async {
  final kantor = await SettingDataService.getOfficeCodeFromDatabase();
    final insertId = await DatabaseService.rawQuery(
      'INSERT INTO seksi (kode, nama, tipe, telp, kantor) VALUES (?, ?, ?, ?, ?)',
      [seksi.kode, seksi.nama, seksi.tipe, seksi.telp, kantor],
    );
    await refreshSeksiData();
    if (insertId.isNotEmpty && insertId.first['insertId'] != null) {
      return insertId.first['insertId'] as int? ?? 0;
    }
    return 0;
  }

  /// Update Seksi record in database and refresh cache
  Future<int> updateSeksi(SeksiModel seksi) async {
  final kantor = await SettingDataService.getOfficeCodeFromDatabase();
    final count = await DatabaseService.rawQuery(
      'UPDATE seksi SET kode = ?, nama = ?, tipe = ?, telp = ?, kantor = ? WHERE id = ?',
      [seksi.kode, seksi.nama, seksi.tipe, seksi.telp, kantor, seksi.id],
    );
    await refreshSeksiData();
    if (count.isNotEmpty && count.first['affectedRows'] != null) {
      return count.first['affectedRows'] as int? ?? 0;
    }
    return 0;
  }

  /// Delete Seksi record from database and refresh cache
  Future<int> deleteSeksi(int id) async {
    final count = await DatabaseService.rawQuery(
      'DELETE FROM seksi WHERE id = ?',
      [id],
    );
    await refreshSeksiData();
    if (count.isNotEmpty && count.first['affectedRows'] != null) {
      return count.first['affectedRows'] as int? ?? 0;
    }
    return 0;
  }

  /// Add new Pegawai record to database and refresh cache
  Future<int> addPegawai(PegawaiModel pegawai) async {
    final kantor = await SettingDataService.getOfficeCodeFromDatabase();
    final insertId = await DatabaseService.rawQuery(
      'INSERT INTO pegawai (kantor, nip, nip2, nama, seksi, jabatan) VALUES (?, ?, ?, ?)',
      [kantor, pegawai.nip, pegawai.nip2, pegawai.nama, pegawai.seksi, pegawai.jabatan],
    );
    await refreshPegawaiData();
    if (insertId.isNotEmpty && insertId.first['insertId'] != null) {
      return insertId.first['insertId'] as int? ?? 0;
    }
    return 0;
  }

  /// Update Pegawai record in database and refresh cache
  Future<int> updatePegawai(PegawaiModel pegawai) async {
    final kantor = await SettingDataService.getOfficeCodeFromDatabase();
    // Note: id is not present in PegawaiModel, so update by nip (assuming nip is unique)
    final count = await DatabaseService.rawQuery(
      'UPDATE pegawai SET kantor = ?, nip = ?, nip2 = ?, nama = ?, seksi = ?, jabatan = ? WHERE nip = ?',
      [kantor, pegawai.nip, pegawai.nip2, pegawai.nama, pegawai.seksi, pegawai.jabatan, pegawai.nip],
    );
    await refreshPegawaiData();
    if (count.isNotEmpty && count.first['affectedRows'] != null) {
      return count.first['affectedRows'] as int? ?? 0;
    }
    return 0;
  }

  /// Delete Pegawai record from database and refresh cache
  Future<int> deletePegawai(String nip) async {
    final count = await DatabaseService.rawQuery(
      'DELETE FROM pegawai WHERE nip = ?',
      [nip],
    );
    await refreshPegawaiData();
    if (count.isNotEmpty && count.first['affectedRows'] != null) {
      return count.first['affectedRows'] as int? ?? 0;
    }
    return 0;
  }
  // In-memory storage
  List<SeksiModel> _seksiData = [];
  List<PegawaiModel> _pegawaiData = [];
  // List<UserModel> _userData = [];
  // List<SettingsModel> _settingsData = [];

  // Loading states
  bool _isSeksiLoaded = false;
  bool _isPegawaiLoaded = false;
  // bool _isUserLoaded = false;
  // bool _isSettingsLoaded = false;
  bool _isLoading = false;

  // Getters
  List<SeksiModel> get seksiData => List.unmodifiable(_seksiData);
  List<PegawaiModel> get pegawaiData => List.unmodifiable(_pegawaiData);
  // List<UserModel> get userData => List.unmodifiable(_userData);
  // List<SettingsModel> get settingsData => List.unmodifiable(_settingsData);

  bool get isSeksiLoaded => _isSeksiLoaded;
  bool get isPegawaiLoaded => _isPegawaiLoaded;
  // bool get isUserLoaded => _isUserLoaded;
  // bool get isSettingsLoaded => _isSettingsLoaded;
  bool get isLoading => _isLoading;

  /// Load all management data at startup
  Future<void> loadAllSettingData() async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      await Future.wait([
        loadSeksiData(),
        loadPegawaiData(),
        // loadUsers(),
        // loadSettings(),
      ]);
      print('Settings data loaded: Seksi=${_seksiData.length}, Pegawai=${_pegawaiData.length}');
    } catch (e) {
      print('Error loading settings data: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Load Seksi data
  Future<void> loadSeksiData() async {
    try {
      final result = await DatabaseService.rawQuery('SELECT * FROM seksi ORDER BY kode');
      _seksiData = result.map((json) => SeksiModel.fromMap(json)).toList();
      _isSeksiLoaded = true;
      print('Loaded ${_seksiData.length} Seksi records');
    } catch (e) {
      print('Error loading Seksi data: $e');
      _seksiData = [];
      _isSeksiLoaded = false;
      rethrow;
    }
  }

  /// Load Pegawai data
  Future<void> loadPegawaiData() async {
    try {
      final result = await DatabaseService.rawQuery('SELECT a.kantor, a.nip, a.nip2, a.nama, a.seksi, a.jabatan, b.nama as nmseksi FROM pegawai a left join seksi b on a.seksi=b.id ORDER BY nip');
      _pegawaiData = result.map((json) => PegawaiModel.fromMap(json)).toList();
      _isPegawaiLoaded = true;
      print('Loaded ${_pegawaiData.length} Pegawai records');
    } catch (e) {
      print('Error loading Pegawai data: $e');
      _pegawaiData = [];
      _isPegawaiLoaded = false;
      rethrow;
    }
  }

  // TODO: Implement loadUsers() and loadSettings() when models are available

  /// Refresh Seksi data
  Future<void> refreshSeksiData() async {
    _isSeksiLoaded = false;
    await loadSeksiData();
  }

  /// Refresh Pegawai data
  Future<void> refreshPegawaiData() async {
    _isPegawaiLoaded = false;
    await loadPegawaiData();
  }

  // TODO: Add refreshUsersData() and refreshSettingsData() when models are available

  /// Filter Seksi data
  List<SeksiModel> filterSeksiData({String? searchQuery}) {
    if (!_isSeksiLoaded) return [];
    var filtered = _seksiData;
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      filtered = filtered.where((seksi) =>
        seksi.kode.toLowerCase().contains(query) ||
        seksi.nama.toLowerCase().contains(query)
      ).toList();
    }
    return filtered;
  }

  /// Filter Pegawai data
  List<PegawaiModel> filterPegawaiData({String? searchQuery}) {
    if (!_isPegawaiLoaded) return [];
    var filtered = _pegawaiData;
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();
      filtered = filtered.where((pegawai) =>
        pegawai.nip.toLowerCase().contains(query) ||
        pegawai.nama.toLowerCase().contains(query)
      ).toList();
    }
    return filtered;
  }

  /// Clear all cached data
  void clearCache() {
    _seksiData.clear();
    _pegawaiData.clear();
    _isSeksiLoaded = false;
    _isPegawaiLoaded = false;
    // _userData.clear();
    // _settingsData.clear();
    // _isUserLoaded = false;
    // _isSettingsLoaded = false;
  }
}

/// Global settings data service provider
final settingDataServiceProvider = Provider<SettingDataService>((ref) => SettingDataService());

/// State notifier for managing settings data loading state
class SettingDataNotifier extends StateNotifier<AsyncValue<void>> {
  final SettingDataService _service;
  SettingDataNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadData();
  }
  Future<void> _loadData() async {
    try {
      await _service.loadAllSettingData();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadData();
  }
  bool get isDataReady => state.hasValue && _service.isSeksiLoaded && _service.isPegawaiLoaded;
}

/// Provider for settings data loading state
final settingDataProvider = StateNotifierProvider<SettingDataNotifier, AsyncValue<void>>((ref) {
  final service = ref.read(settingDataServiceProvider);
  return SettingDataNotifier(service);
});
