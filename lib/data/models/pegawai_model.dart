/// Pegawai (Employee) model for user management
/// Migrated from Qt pegawai table structure
class PegawaiModel {
  factory PegawaiModel.fromMap(Map<String, dynamic> map) {
    return PegawaiModel(
      kantor: map['kantor']?.toString() ?? '',
      nip: map['nip']?.toString() ?? '',
      nip2: map['nip2']?.toString(),
      nama: map['nama']?.toString() ?? '',
      pangkat: map['pangkat'] is int ? map['pangkat'] as int : int.tryParse(map['pangkat']?.toString() ?? '') ?? 0,
      seksi: map['nmseksi'] is int ? map['seksi'] as int : int.tryParse(map['seksi']?.toString() ?? '') ?? null,
      jabatan: map['jabatan'] is int ? map['jabatan'] as int : int.tryParse(map['jabatan']?.toString() ?? '') ?? 0,
      tahun: map['tahun'] is int ? map['tahun'] as int : int.tryParse(map['tahun']?.toString() ?? '') ?? 0,
      plh: map['plh']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kantor': kantor,
      'nip': nip,
      'nip2': nip2,
      'nama': nama,
      'pangkat': pangkat,
      'seksi': seksi,
      'jabatan': jabatan,
      'tahun': tahun,
      'plh': plh,
    };
  }
  final String kantor;
  final String nip;
  final String? nip2;
  final String nama;
  final int pangkat;
  final int? seksi;
  final int jabatan;
  final int tahun;
  final String? plh;

  const PegawaiModel({
    required this.kantor,
    required this.nip,
    this.nip2,
    required this.nama,
    required this.pangkat,
    this.seksi,
    required this.jabatan,
    required this.tahun,
    this.plh,
  });

  factory PegawaiModel.fromJson(Map<String, dynamic> json) {
    return PegawaiModel(
      kantor: json['kantor']?.toString() ?? '',
      nip: json['nip']?.toString() ?? '',
      nip2: json['nip2']?.toString(),
      nama: json['nama']?.toString() ?? '',
      pangkat: json['pangkat'] is int ? json['pangkat'] as int : int.tryParse(json['pangkat']?.toString() ?? '') ?? 0,
      seksi: json['seksi'] is int ? json['seksi'] as int : int.tryParse(json['seksi']?.toString() ?? '') ?? null,
      jabatan: json['jabatan'] is int ? json['jabatan'] as int : int.tryParse(json['jabatan']?.toString() ?? '') ?? 0,
      tahun: json['tahun'] is int ? json['tahun'] as int : int.tryParse(json['tahun']?.toString() ?? '') ?? 0,
      plh: json['plh']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  PegawaiModel copyWith({
    String? kantor,
    String? nip,
    String? nip2,
    String? nama,
    int? pangkat,
    int? seksi,
    int? jabatan,
    int? tahun,
    String? plh,
  }) {
    return PegawaiModel(
      kantor: kantor ?? this.kantor,
      nip: nip ?? this.nip,
      nip2: nip2 ?? this.nip2,
      nama: nama ?? this.nama,
      pangkat: pangkat ?? this.pangkat,
      seksi: seksi ?? this.seksi,
      jabatan: jabatan ?? this.jabatan,
      tahun: tahun ?? this.tahun,
      plh: plh ?? this.plh,
    );
  }

  /// Get jabatan display name based on jabatan code
  String get jabatanDisplayName {
    switch (jabatan) {
      case 1:
        return 'Kepala Kantor';
      case 2:
        return 'Kepala Seksi';
      case 3:
        return 'Account Representative';
      case 4:
        return 'Pelaksana';
      case 5:
        return 'Fungsional';
      default:
        return 'Tidak Diketahui';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PegawaiModel &&
        other.kantor == kantor &&
        other.nip == nip &&
        other.nip2 == nip2 &&
        other.nama == nama &&
        other.pangkat == pangkat &&
        other.seksi == seksi &&
        other.jabatan == jabatan &&
        other.tahun == tahun &&
        other.plh == plh;
  }

  @override
  int get hashCode {
    return Object.hash(
      kantor,
      nip,
      nip2,
      nama,
      pangkat,
      seksi,
      jabatan,
      tahun,
      plh,
    );
  }

  @override
  String toString() {
    return 'PegawaiModel(kantor: $kantor, nip: $nip, nama: $nama, jabatan: $jabatanDisplayName)';
  }
}