class SeksiModel {
  final int? id;
  final String kantor;
  final String nama;
  final int tipe;

  SeksiModel({this.id, required this.kantor, required this.nama, required this.tipe});

  SeksiModel copyWith({int? id, String? kantor, String? nama, int? tipe, String? telp}) {
    return SeksiModel(
      id: id ?? this.id,
      kantor: kantor ?? this.kantor,
      nama: nama ?? this.nama,
      tipe: tipe ?? this.tipe,
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
      kantor: parseStringField(map['kantor']),
      nama: parseStringField(map['nama']),
      tipe: map['tipe'] is int ? map['tipe'] as int : int.tryParse(map['tipe']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kantor': kantor,
      'nama': nama,
      'tipe': tipe,
    };
  }
}
