import 'database_service.dart';

/// Dashboard data service for ppmpkmbo revenue aggregation
class DashboardDataService {
	/// Get cache for Data Penerimaan filter dropdowns
	Future<Map<String, List<String>>> getPenerimaanCache() async {
		// Query all unique values for dropdowns from ppmpkmbo
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
			'tahunOptions': tahunRes.map((row) => row['THN_SETOR'].toString()).where((v) => v.isNotEmpty).toList(),
			'kdMapOptions': kdMapRes.map((row) => row['KD_MAP'].toString()).where((v) => v.isNotEmpty).toList(),
			'kdSetorOptions': kdSetorRes.map((row) => row['KD_SETOR'].toString()).where((v) => v.isNotEmpty).toList(),
			'voluntaryOptions': voluntaryRes.map((row) => row['VOLUNTARY'].toString()).where((v) => v.isNotEmpty).toList(),
			'flagPkpmOptions': flagPkpmRes.map((row) => row['FLAG_PKPM'].toString()).where((v) => v.isNotEmpty).toList(),
			'flagBoOptions': flagBoRes.map((row) => row['FLAG_BO'].toString()).where((v) => v.isNotEmpty).toList(),
		};
	}
	/// Filter PKPMBO data for Data Penerimaan page
  /// 
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
			if (npwp != null && !(row['NPWP']?.toString().contains(npwp) ?? false)) return false;
			if (nama != null && !(row['NAMA']?.toString().toLowerCase().contains(nama.toLowerCase()) ?? false)) return false;
			if (kdMap != null && row['KD_MAP'] != kdMap) return false;
			if (kdSetor != null && row['KD_SETOR'] != kdSetor) return false;
			if (masaPajak != null && row['MASA_PAJAK'] != masaPajak) return false;
			if (tahunSetor != null && row['THN_SETOR'] != tahunSetor) return false;
			if (tglSetor != null && row['TGL_SETOR'] != null) {
				final rowDate = DateTime.tryParse(row['TGL_SETOR'].toString());
				if (rowDate == null || rowDate != tglSetor) return false;
			}
			if (ntpn != null && !(row['NTPN']?.toString().contains(ntpn) ?? false)) return false;
			if (noPbk != null && !(row['NO_PBK']?.toString().contains(noPbk) ?? false)) return false;
			if (voluntary != null && row['VOLUNTARY'] != voluntary) return false;
			if (flagPkpm != null && row['FLAG_PKPM'] != flagPkpm) return false;
			if (flagBo != null && row['FLAG_BO'] != flagBo) return false;
			if (source != null && !(row['SOURCE']?.toString().contains(source) ?? false)) return false;
			if (kantor != null && row['KPPADM'] != kantor) return false;
			return true;
		}).toList();
	}
	double _statSpmkp = 0.0;
	double get statSpmkp => _statSpmkp;
	// Statistics cache
	double _statPenerimaan = 0.0;
	double _statPBK = 0.0;
	double _statNetto = 0.0;
	double _statRenpen = 0.0;
	double _statPencapaian = 0.0;
	double _statPertumbuhan = 0.0;

	// Monthly Renpen cache: [{BLN_SETOR, total_target}]
	List<Map<String, dynamic>> _monthlyRenpenCache = [];
	List<Map<String, dynamic>> get monthlyRenpenData => List.unmodifiable(_monthlyRenpenCache);

	double get statPenerimaan => _statPenerimaan;
	double get statPBK => _statPBK;
	double get statNetto => _statNetto;
	double get statRenpen => _statRenpen;
	double get statPencapaian => _statPencapaian;
	double get statPertumbuhan => _statPertumbuhan;

	Future<void> loadStatistics(String kpp, String tahun) async {
		// Penerimaan
		final penerimaanRes = await DatabaseService.rawQuery(
			'SELECT SUM(JML_SETOR) as total FROM ppmpkmbo WHERE KPPADM = ? AND THN_SETOR = ?', [kpp, tahun],
		);
		_statPenerimaan = double.tryParse(penerimaanRes.first['total']?.toString() ?? '0') ?? 0.0;

		// PBK
		final pbkRes = await DatabaseService.rawQuery(
			"SELECT SUM(JML_SETOR) as total FROM ppmpkmbo WHERE NO_PBK IS NOT NULL AND NO_PBK != '' AND KPPADM = ? AND THN_SETOR = ?", [kpp, tahun],
		);
		_statPBK = double.tryParse(pbkRes.first['total']?.toString() ?? '0') ?? 0.0;

			// SPMKP
			final spmkpRes = await DatabaseService.rawQuery(
				'SELECT SUM(nominal) as total FROM spmkp WHERE kpp = ? AND tahun = ?', [kpp, tahun],
			);
			_statSpmkp = double.tryParse(spmkpRes.first['total']?.toString() ?? '0') ?? 0.0;
			_statNetto = _statPenerimaan - _statSpmkp;

		// Renpen
		final renpenRes = await DatabaseService.rawQuery(
			'SELECT SUM(target) as total FROM renpen WHERE kpp = ? AND tahun = ?', [kpp, tahun],
		);
		_statRenpen = double.tryParse(renpenRes.first['total']?.toString() ?? '0') ?? 0.0;

		// Pencapaian
		_statPencapaian = _statRenpen > 0 ? (_statPenerimaan / _statRenpen * 100) : 0.0;

		// Pertumbuhan: compare penerimaan current tahun vs last tahun
		final tahunInt = int.tryParse(tahun) ?? 0;
		final lastTahun = (tahunInt - 1).toString();
		final lastPenerimaanRes = await DatabaseService.rawQuery(
			'SELECT SUM(JML_SETOR) as total FROM ppmpkmbo WHERE KPPADM = ? AND THN_SETOR = ?', [kpp, lastTahun],
		);
		final lastPenerimaan = double.tryParse(lastPenerimaanRes.first['total']?.toString() ?? '0') ?? 0.0;
		_statPertumbuhan = lastPenerimaan > 0 ? ((_statPenerimaan - lastPenerimaan) / lastPenerimaan * 100) : 0.0;
	}
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

			/// Load and cache monthly Renpen data grouped by BLN_SETOR
			Future<void> loadMonthlyRenpenData(String kantorKode, [String? tahun]) async {
				String sql = '''
					SELECT BULAN AS BLN_SETOR, SUM(target) AS total_target
					FROM renpen
					WHERE kpp = ?''';
				List<dynamic> params = [kantorKode];
				if (tahun != null) {
					sql += ' AND tahun = ?';
					params.add(tahun);
				}
				sql += '''
					GROUP BY BULAN
					ORDER BY BULAN
				''';
				final result = await DatabaseService.rawQuery(sql, params);
				_monthlyRenpenCache = result;
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
	Future<void> loadRevenueData(String kantorKode, [String? tahun]) async {
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
			_monthlyRenpenCache.clear();
		}
}
