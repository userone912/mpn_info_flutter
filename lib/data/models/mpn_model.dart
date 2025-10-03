/// MPN (Monitoring Pelaporan Pajak Negara) model
/// Migrated from Qt mpn table structure
class MpnModel {
  final int id;
  final String? kdMpn;
  final String? nomor;
  final DateTime? tanggal;
  final double? nilai;
  final int? kdKpp;
  final String? npwp;
  final String? nama;
  final int? kdMap;
  final String? uraian;
  final String? keterangan;
  final int? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MpnModel({
    required this.id,
    this.kdMpn,
    this.nomor,
    this.tanggal,
    this.nilai,
    this.kdKpp,
    this.npwp,
    this.nama,
    this.kdMap,
    this.uraian,
    this.keterangan,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory MpnModel.fromJson(Map<String, dynamic> json) {
    return MpnModel(
      id: json['id'] as int,
      kdMpn: json['kd_mpn'] as String?,
      nomor: json['nomor'] as String?,
      tanggal: json['tanggal'] != null 
          ? DateTime.parse(json['tanggal'] as String)
          : null,
      nilai: (json['nilai'] as num?)?.toDouble(),
      kdKpp: json['kd_kpp'] as int?,
      npwp: json['npwp'] as String?,
      nama: json['nama'] as String?,
      kdMap: json['kd_map'] as int?,
      uraian: json['uraian'] as String?,
      keterangan: json['keterangan'] as String?,
      userId: json['user_id'] as int?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kd_mpn': kdMpn,
      'nomor': nomor,
      'tanggal': tanggal?.toIso8601String(),
      'nilai': nilai,
      'kd_kpp': kdKpp,
      'npwp': npwp,
      'nama': nama,
      'kd_map': kdMap,
      'uraian': uraian,
      'keterangan': keterangan,
      'user_id': userId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  MpnModel copyWith({
    int? id,
    String? kdMpn,
    String? nomor,
    DateTime? tanggal,
    double? nilai,
    int? kdKpp,
    String? npwp,
    String? nama,
    int? kdMap,
    String? uraian,
    String? keterangan,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MpnModel(
      id: id ?? this.id,
      kdMpn: kdMpn ?? this.kdMpn,
      nomor: nomor ?? this.nomor,
      tanggal: tanggal ?? this.tanggal,
      nilai: nilai ?? this.nilai,
      kdKpp: kdKpp ?? this.kdKpp,
      npwp: npwp ?? this.npwp,
      nama: nama ?? this.nama,
      kdMap: kdMap ?? this.kdMap,
      uraian: uraian ?? this.uraian,
      keterangan: keterangan ?? this.keterangan,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MpnModel &&
        other.id == id &&
        other.kdMpn == kdMpn &&
        other.nomor == nomor &&
        other.tanggal == tanggal &&
        other.nilai == nilai &&
        other.kdKpp == kdKpp &&
        other.npwp == npwp &&
        other.nama == nama &&
        other.kdMap == kdMap &&
        other.uraian == uraian &&
        other.keterangan == keterangan &&
        other.userId == userId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      kdMpn,
      nomor,
      tanggal,
      nilai,
      kdKpp,
      npwp,
      nama,
      kdMap,
      uraian,
      keterangan,
      userId,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'MpnModel(id: $id, nomor: $nomor, npwp: $npwp, nama: $nama, nilai: $nilai)';
  }
}