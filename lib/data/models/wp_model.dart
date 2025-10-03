/// WP (Wajib Pajak / Taxpayer) model
/// Migrated from Qt wp table structure
class WpModel {
  final int id;
  final String? npwp;
  final String? nama;
  final String? alamat;
  final String? kelurahan;
  final String? kecamatan;
  final String? kabupaten;
  final String? provinsi;
  final String? kodePos;
  final String? telepon;
  final String? email;
  final int? jenisWp;
  final int? statusWp;
  final String? keterangan;
  final int? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WpModel({
    required this.id,
    this.npwp,
    this.nama,
    this.alamat,
    this.kelurahan,
    this.kecamatan,
    this.kabupaten,
    this.provinsi,
    this.kodePos,
    this.telepon,
    this.email,
    this.jenisWp,
    this.statusWp,
    this.keterangan,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory WpModel.fromJson(Map<String, dynamic> json) {
    return WpModel(
      id: json['id'] as int,
      npwp: json['npwp'] as String?,
      nama: json['nama'] as String?,
      alamat: json['alamat'] as String?,
      kelurahan: json['kelurahan'] as String?,
      kecamatan: json['kecamatan'] as String?,
      kabupaten: json['kabupaten'] as String?,
      provinsi: json['provinsi'] as String?,
      kodePos: json['kode_pos'] as String?,
      telepon: json['telepon'] as String?,
      email: json['email'] as String?,
      jenisWp: json['jenis_wp'] as int?,
      statusWp: json['status_wp'] as int?,
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
      'npwp': npwp,
      'nama': nama,
      'alamat': alamat,
      'kelurahan': kelurahan,
      'kecamatan': kecamatan,
      'kabupaten': kabupaten,
      'provinsi': provinsi,
      'kode_pos': kodePos,
      'telepon': telepon,
      'email': email,
      'jenis_wp': jenisWp,
      'status_wp': statusWp,
      'keterangan': keterangan,
      'user_id': userId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  WpModel copyWith({
    int? id,
    String? npwp,
    String? nama,
    String? alamat,
    String? kelurahan,
    String? kecamatan,
    String? kabupaten,
    String? provinsi,
    String? kodePos,
    String? telepon,
    String? email,
    int? jenisWp,
    int? statusWp,
    String? keterangan,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WpModel(
      id: id ?? this.id,
      npwp: npwp ?? this.npwp,
      nama: nama ?? this.nama,
      alamat: alamat ?? this.alamat,
      kelurahan: kelurahan ?? this.kelurahan,
      kecamatan: kecamatan ?? this.kecamatan,
      kabupaten: kabupaten ?? this.kabupaten,
      provinsi: provinsi ?? this.provinsi,
      kodePos: kodePos ?? this.kodePos,
      telepon: telepon ?? this.telepon,
      email: email ?? this.email,
      jenisWp: jenisWp ?? this.jenisWp,
      statusWp: statusWp ?? this.statusWp,
      keterangan: keterangan ?? this.keterangan,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted NPWP display
  String get formattedNpwp {
    if (npwp == null || npwp!.length < 15) return npwp ?? '';
    return '${npwp!.substring(0, 2)}.${npwp!.substring(2, 5)}.${npwp!.substring(5, 8)}.${npwp!.substring(8, 9)}-${npwp!.substring(9, 12)}.${npwp!.substring(12, 15)}';
  }

  /// Get jenis WP display name
  String get jenisWpDisplayName {
    switch (jenisWp) {
      case 1:
        return 'Badan';
      case 2:
        return 'Orang Pribadi';
      case 3:
        return 'Bendahara';
      case 4:
        return 'BUT (Bentuk Usaha Tetap)';
      default:
        return 'Tidak Diketahui';
    }
  }

  /// Get status WP display name
  String get statusWpDisplayName {
    switch (statusWp) {
      case 1:
        return 'Aktif';
      case 2:
        return 'Non-Aktif';
      case 3:
        return 'Cabut';
      default:
        return 'Tidak Diketahui';
    }
  }

  /// Get full address concatenated
  String get fullAddress {
    final parts = [
      alamat,
      kelurahan,
      kecamatan,
      kabupaten,
      provinsi,
      kodePos,
    ].where((part) => part != null && part.isNotEmpty).join(', ');
    return parts;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WpModel &&
        other.id == id &&
        other.npwp == npwp &&
        other.nama == nama &&
        other.alamat == alamat &&
        other.kelurahan == kelurahan &&
        other.kecamatan == kecamatan &&
        other.kabupaten == kabupaten &&
        other.provinsi == provinsi &&
        other.kodePos == kodePos &&
        other.telepon == telepon &&
        other.email == email &&
        other.jenisWp == jenisWp &&
        other.statusWp == statusWp &&
        other.keterangan == keterangan &&
        other.userId == userId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      npwp,
      nama,
      alamat,
      kelurahan,
      kecamatan,
      kabupaten,
      provinsi,
      kodePos,
      telepon,
      email,
      jenisWp,
      statusWp,
      keterangan,
      userId,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'WpModel(id: $id, npwp: $formattedNpwp, nama: $nama, jenis: $jenisWpDisplayName)';
  }
}