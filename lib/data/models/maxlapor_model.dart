/// Model for Max Lapor (Reporting Due Date) reference data
class MaxLaporModel {
  final int bulan;      // Month (0-11, 0 = annual)
  final int tahun;      // Year
  final String? pph;    // PPh reporting due date
  final String? ppn;    // PPN reporting due date
  final String? pphOp;  // PPh Orang Pribadi reporting due date
  final String? pphBdn; // PPh Badan reporting due date

  const MaxLaporModel({
    required this.bulan,
    required this.tahun,
    this.pph,
    this.ppn,
    this.pphOp,
    this.pphBdn,
  });

  factory MaxLaporModel.fromCsv(List<String> row) {
    if (row.length < 6) {
      print('Invalid CSV row for MaxLaporModel: $row');
      throw Exception('CSV row must have at least 6 columns');
    }
    
    try {
      return MaxLaporModel(
        bulan: int.parse(row[0].trim()),
        tahun: int.parse(row[1].trim()),
        pph: row[2].trim().isEmpty ? null : row[2].trim(),
        ppn: row[3].trim().isEmpty ? null : row[3].trim(),
        pphOp: row[4].trim().isEmpty ? null : row[4].trim(),
        pphBdn: row[5].trim().isEmpty ? null : row[5].trim(),
      );
    } catch (e) {
      print('Error parsing MaxLaporModel from CSV: $e');
      rethrow;
    }
  }

  /// Get month name in Indonesian
  String get bulanNama {
    if (bulan == 0) return 'Tahunan';
    const monthNames = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return bulan > 0 && bulan < monthNames.length ? monthNames[bulan] : 'Unknown';
  }

  /// Get display name for period
  String get displayPeriod => bulan == 0 ? 'Tahunan $tahun' : '$bulanNama $tahun';

  @override
  String toString() => 'MaxLaporModel(bulan: $bulan, tahun: $tahun, pph: $pph, ppn: $ppn, pphOp: $pphOp, pphBdn: $pphBdn)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaxLaporModel &&
          runtimeType == other.runtimeType &&
          bulan == other.bulan &&
          tahun == other.tahun &&
          pph == other.pph &&
          ppn == other.ppn &&
          pphOp == other.pphOp &&
          pphBdn == other.pphBdn;

  @override
  int get hashCode => 
      bulan.hashCode ^ 
      tahun.hashCode ^ 
      pph.hashCode ^ 
      ppn.hashCode ^ 
      pphOp.hashCode ^ 
      pphBdn.hashCode;
}