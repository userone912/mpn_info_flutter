/// Pegawai (Employee) model for user management
/// Migrated from Qt pegawai table structure
class PegawaiModel {
  final int id;
  final String? nip;
  final String? nama;
  final String? username;
  final String? password;
  final int? jabatan;
  final int? seksi;
  final String? email;
  final String? telepon;
  final String? alamat;
  final DateTime? tanggalLahir;
  final String? tempatLahir;
  final int? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PegawaiModel({
    required this.id,
    this.nip,
    this.nama,
    this.username,
    this.password,
    this.jabatan,
    this.seksi,
    this.email,
    this.telepon,
    this.alamat,
    this.tanggalLahir,
    this.tempatLahir,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory PegawaiModel.fromJson(Map<String, dynamic> json) {
    return PegawaiModel(
      id: json['id'] as int,
      nip: json['nip'] as String?,
      nama: json['nama'] as String?,
      username: json['username'] as String?,
      password: json['password'] as String?,
      jabatan: json['jabatan'] as int?,
      seksi: json['seksi'] as int?,
      email: json['email'] as String?,
      telepon: json['telepon'] as String?,
      alamat: json['alamat'] as String?,
      tanggalLahir: json['tanggal_lahir'] != null 
          ? DateTime.parse(json['tanggal_lahir'] as String)
          : null,
      tempatLahir: json['tempat_lahir'] as String?,
      status: json['status'] as int?,
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
      'nip': nip,
      'nama': nama,
      'username': username,
      'password': password,
      'jabatan': jabatan,
      'seksi': seksi,
      'email': email,
      'telepon': telepon,
      'alamat': alamat,
      'tanggal_lahir': tanggalLahir?.toIso8601String(),
      'tempat_lahir': tempatLahir,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  PegawaiModel copyWith({
    int? id,
    String? nip,
    String? nama,
    String? username,
    String? password,
    int? jabatan,
    int? seksi,
    String? email,
    String? telepon,
    String? alamat,
    DateTime? tanggalLahir,
    String? tempatLahir,
    int? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PegawaiModel(
      id: id ?? this.id,
      nip: nip ?? this.nip,
      nama: nama ?? this.nama,
      username: username ?? this.username,
      password: password ?? this.password,
      jabatan: jabatan ?? this.jabatan,
      seksi: seksi ?? this.seksi,
      email: email ?? this.email,
      telepon: telepon ?? this.telepon,
      alamat: alamat ?? this.alamat,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      tempatLahir: tempatLahir ?? this.tempatLahir,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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

  /// Check if employee is active
  bool get isActive => status == 1;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PegawaiModel &&
        other.id == id &&
        other.nip == nip &&
        other.nama == nama &&
        other.username == username &&
        other.password == password &&
        other.jabatan == jabatan &&
        other.seksi == seksi &&
        other.email == email &&
        other.telepon == telepon &&
        other.alamat == alamat &&
        other.tanggalLahir == tanggalLahir &&
        other.tempatLahir == tempatLahir &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      nip,
      nama,
      username,
      password,
      jabatan,
      seksi,
      email,
      telepon,
      alamat,
      tanggalLahir,
      tempatLahir,
      status,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'PegawaiModel(id: $id, nip: $nip, nama: $nama, jabatan: $jabatanDisplayName)';
  }
}