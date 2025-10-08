import 'database_service.dart';

/// Dashboard data service for ppmpkmbo revenue aggregation
class DashboardDataService {
	// Cache for bar chart grouped by BLN_SETOR and FLAG_PKPM
	List<Map<String, dynamic>> _monthlyFlagPkpmCache = [];
	// Cache for bar chart grouped by BLN_SETOR and FLAG_BO
	List<Map<String, dynamic>> _monthlyFlagBoCache = [];
	// Cache for bar chart grouped by BLN_SETOR and VOLUNTARY
	List<Map<String, dynamic>> _monthlyVoluntaryCache = [];

		/// Load and cache monthly revenue data grouped by BLN_SETOR and FLAG_PKPM
		Future<void> loadMonthlyFlagPkpmData(String kantorKode, [String? tahun]) async {
			String sql = '''
				SELECT BLN_SETOR, FLAG_PKPM, SUM(JML_SETOR) AS total_setor
				FROM ppmpkmbo
				WHERE KPPADM = ?''';
			List<dynamic> params = [kantorKode];
			if (tahun != null) {
				sql += ' AND THN_SETOR = ?';
				params.add(tahun);
			}
			sql += '''
				GROUP BY BLN_SETOR, FLAG_PKPM
				ORDER BY BLN_SETOR, FLAG_PKPM
			''';
			final result = await DatabaseService.rawQuery(sql, params);
			_monthlyFlagPkpmCache = result;
		}

		/// Load and cache monthly revenue data grouped by BLN_SETOR and FLAG_BO
		Future<void> loadMonthlyFlagBoData(String kantorKode, [String? tahun]) async {
			String sql = '''
				SELECT BLN_SETOR, FLAG_BO, SUM(JML_SETOR) AS total_setor
				FROM ppmpkmbo
				WHERE KPPADM = ?''';
			List<dynamic> params = [kantorKode];
			if (tahun != null) {
				sql += ' AND THN_SETOR = ?';
				params.add(tahun);
			}
			sql += '''
				GROUP BY BLN_SETOR, FLAG_BO
				ORDER BY BLN_SETOR, FLAG_BO
			''';
			final result = await DatabaseService.rawQuery(sql, params);
			_monthlyFlagBoCache = result;
		}

		/// Load and cache monthly revenue data grouped by BLN_SETOR and VOLUNTARY
		Future<void> loadMonthlyVoluntaryData(String kantorKode, [String? tahun]) async {
			String sql = '''
				SELECT BLN_SETOR, VOLUNTARY, SUM(JML_SETOR) AS total_setor
				FROM ppmpkmbo
				WHERE KPPADM = ?''';
			List<dynamic> params = [kantorKode];
			if (tahun != null) {
				sql += ' AND THN_SETOR = ?';
				params.add(tahun);
			}
			sql += '''
				GROUP BY BLN_SETOR, VOLUNTARY
				ORDER BY BLN_SETOR, VOLUNTARY
			''';
			final result = await DatabaseService.rawQuery(sql, params);
			_monthlyVoluntaryCache = result;
		}

	/// Get cached monthly revenue data grouped by BLN_SETOR and FLAG_PKPM
	List<Map<String, dynamic>> get monthlyFlagPkpmData => List.unmodifiable(_monthlyFlagPkpmCache);
	/// Get cached monthly revenue data grouped by BLN_SETOR and FLAG_BO
	List<Map<String, dynamic>> get monthlyFlagBoData => List.unmodifiable(_monthlyFlagBoCache);
	/// Get cached monthly revenue data grouped by BLN_SETOR and VOLUNTARY
	List<Map<String, dynamic>> get monthlyVoluntaryData => List.unmodifiable(_monthlyVoluntaryCache);
	// In-memory cache for aggregated data
	List<Map<String, dynamic>> _revenueCache = [];
	bool _isLoaded = false;

	/// Load and cache revenue data at startup
	Future<void> loadRevenueData(String kantorKode) async {
		// Query ppmpkmbo, filter by KPPADM, group and aggregate
		final result = await DatabaseService.rawQuery(
			'''
			SELECT MASA_PAJAK, KD_MAP, FLAG_PKPM, FLAG_BO, VOLUNTARY, SUM(JML_SETOR) AS total_setor
			FROM ppmpkmbo
			WHERE KPPADM = ?
			GROUP BY MASA_PAJAK, KD_MAP, FLAG_PKPM, FLAG_BO, VOLUNTARY
			ORDER BY MASA_PAJAK, KD_MAP
			'''
			, [kantorKode]
		);
		_revenueCache = result;
		_isLoaded = true;
	}

	/// Get cached revenue data
	List<Map<String, dynamic>> get revenueData => List.unmodifiable(_revenueCache);

	/// Filter cached data by year, masa_pajak, kd_map, etc.
	List<Map<String, dynamic>> filterRevenueData({
		String? masaPajak,
		String? kdMap,
		String? flagPkpm,
		String? flagBo,
		String? voluntary,
	}) {
		if (!_isLoaded) return [];
		return _revenueCache.where((row) {
			if (masaPajak != null && row['MASA_PAJAK'] != masaPajak) return false;
			if (kdMap != null && row['KD_MAP'] != kdMap) return false;
			if (flagPkpm != null && row['FLAG_PKPM'] != flagPkpm) return false;
			if (flagBo != null && row['FLAG_BO'] != flagBo) return false;
			if (voluntary != null && row['VOLUNTARY'] != voluntary) return false;
			return true;
		}).toList();
	}

	/// Clear cache (if needed)
	void clearCache() {
		_revenueCache.clear();
		_isLoaded = false;
	}
}
