class SeksiModel {
  final int? id;
  final String kode;
  final String nama;
  final int tipe;
  final String telp;
  final String kantor;

  SeksiModel({this.id, required this.kode, required this.nama, required this.tipe, required this.telp, required this.kantor});

  SeksiModel copyWith({int? id, String? kode, String? nama, int? tipe, String? telp}) {
    return SeksiModel(
      id: id ?? this.id,
      kode: kode ?? this.kode,
      nama: nama ?? this.nama,
      tipe: tipe ?? this.tipe,
      telp: telp ?? this.telp,
      kantor: this.kantor,
    );
  }

  factory SeksiModel.fromMap(Map<String, dynamic> map) {
    String parseStringField(dynamic value) {
      if (value is String) return value;
      if (value is List<int>) return String.fromCharCodes(value);
      return value?.toString() ?? '';
    }
    return SeksiModel(
      id: map['id'] as int?,
      kode: parseStringField(map['kode']),
      nama: parseStringField(map['nama']),
      tipe: map['tipe'] is int ? map['tipe'] as int : int.tryParse(map['tipe']?.toString() ?? '') ?? 0,
      telp: parseStringField(map['telp']),
      kantor: parseStringField(map['kantor']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kode': kode,
      'nama': nama,
      'tipe': tipe,
      'telp': telp,
      'kantor': kantor,
    };
  }
}
