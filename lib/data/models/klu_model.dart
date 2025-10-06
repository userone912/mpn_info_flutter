/// KLU (Klasifikasi Lapangan Usaha) model
/// Based on database table: klu (kode, nama, sektor)
class KluModel {
  final String kode;
  final String nama;
  final String sektor;

  const KluModel({
    required this.kode,
    required this.nama,
    required this.sektor,
  });

  factory KluModel.fromJson(Map<String, dynamic> json) {
    return KluModel(
      kode: _safeStringCast(json['kode']),
      nama: _safeStringCast(json['nama']),
      sektor: _safeStringCast(json['sektor']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kode': kode,
      'nama': nama,
      'sektor': sektor,
    };
  }

  /// Helper method to safely cast any value to String (handles Blob and other types)
  static String _safeStringCast(dynamic value) {
    if (value == null) return '';
    
    if (value is String) {
      return value;
    } else if (value is List<int>) {
      // Handle Blob data (binary data as List<int>)
      try {
        return String.fromCharCodes(value);
      } catch (e) {
        print('Error converting binary data to string: $e');
        return '';
      }
    } else {
      // For any other type, convert to string
      return value.toString();
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KluModel &&
        other.kode == kode &&
        other.nama == nama &&
        other.sektor == sektor;
  }

  @override
  int get hashCode {
    return Object.hash(kode, nama, sektor);
  }

  @override
  String toString() {
    return 'KluModel(kode: $kode, nama: $nama, sektor: $sektor)';
  }
}