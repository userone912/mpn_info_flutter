/// Model for Jatuh Tempo Pembayaran (Payment Due Date) reference data
class JatuhTempoModel {
  final int bulan;      // Month (0-11, 0 = annual)
  final int tahun;      // Year
  final String? potput; // Pemotongan/Pemungutan due date
  final String? pph;    // PPh due date
  final String? ppn;    // PPN due date
  final String? pphOp;  // PPh Orang Pribadi due date
  final String? pphBdn; // PPh Badan due date

  const JatuhTempoModel({
    required this.bulan,
    required this.tahun,
    this.potput,
    this.pph,
    this.ppn,
    this.pphOp,
    this.pphBdn,
  });

  factory JatuhTempoModel.fromCsv(List<String> row) {
    if (row.length < 7) {
      print('Invalid CSV row for JatuhTempoModel: $row');
      throw Exception('CSV row must have at least 7 columns');
    }
    
    try {
      return JatuhTempoModel(
        bulan: int.parse(row[0].trim()),
        tahun: int.parse(row[1].trim()),
        potput: row[2].trim().isEmpty ? null : row[2].trim(),
        pph: row[3].trim().isEmpty ? null : row[3].trim(),
        ppn: row[4].trim().isEmpty ? null : row[4].trim(),
        pphOp: row[5].trim().isEmpty ? null : row[5].trim(),
        pphBdn: row[6].trim().isEmpty ? null : row[6].trim(),
      );
    } catch (e) {
      print('Error parsing JatuhTempoModel from CSV: $e');
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
  String toString() => 'JatuhTempoModel(bulan: $bulan, tahun: $tahun, potput: $potput, pph: $pph, ppn: $ppn, pphOp: $pphOp, pphBdn: $pphBdn)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JatuhTempoModel &&
          runtimeType == other.runtimeType &&
          bulan == other.bulan &&
          tahun == other.tahun &&
          potput == other.potput &&
          pph == other.pph &&
          ppn == other.ppn &&
          pphOp == other.pphOp &&
          pphBdn == other.pphBdn;

  @override
  int get hashCode => 
      bulan.hashCode ^ 
      tahun.hashCode ^ 
      potput.hashCode ^ 
      pph.hashCode ^ 
      ppn.hashCode ^ 
      pphOp.hashCode ^ 
      pphBdn.hashCode;
}