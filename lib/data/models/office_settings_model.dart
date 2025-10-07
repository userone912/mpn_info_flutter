/// Model for Office Settings (Pengaturan Kantor)
class OfficeSettingsModel {
  final String kode;
  final String wpj;
  final String kp;
  final String alamat;
  final String telepon;
  final String kota;

  OfficeSettingsModel({
    required this.kode,
    required this.wpj,
    required this.kp,
    required this.alamat,
    required this.telepon,
    required this.kota,
  });

  factory OfficeSettingsModel.fromMap(Map<String, dynamic> map) {
    return OfficeSettingsModel(
      kode: map['kode'] ?? '',
      wpj: map['wpj'] ?? '',
      kp: map['kp'] ?? '',
      alamat: map['alamat'] ?? '',
      telepon: map['telepon'] ?? '',
      kota: map['kota'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kode': kode,
      'wpj': wpj,
      'kp': kp,
      'alamat': alamat,
      'telepon': telepon,
      'kota': kota,
    };
  }
}
