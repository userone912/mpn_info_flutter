import 'package:json_annotation/json_annotation.dart';

part 'kantor_model.g.dart';

/// Model for Kantor (Office/Branch) reference data
@JsonSerializable()
class KantorModel {
  final String kode;
  final String nama;
  final String alamat;
  final String kota;
  final String? telepon;
  final String? fax;
  final String? kepala;
  final String? region;

  const KantorModel({
    required this.kode,
    required this.nama,
    required this.alamat,
    required this.kota,
    this.telepon,
    this.fax,
    this.kepala,
    this.region,
  });

  factory KantorModel.fromJson(Map<String, dynamic> json) => _$KantorModelFromJson(json);
  Map<String, dynamic> toJson() => _$KantorModelToJson(this);

  /// Create from CSV row (mimicking Qt legacy CSV import)
  factory KantorModel.fromCsv(List<String> csvRow) {
    try {
      return KantorModel(
        kode: csvRow.isNotEmpty ? csvRow[0].trim() : '',
        nama: csvRow.length > 1 ? csvRow[1].trim() : '',
        alamat: csvRow.length > 2 ? csvRow[2].trim() : '',
        kota: csvRow.length > 3 ? csvRow[3].trim() : '',
        telepon: csvRow.length > 4 && csvRow[4].isNotEmpty ? csvRow[4].trim() : null,
        fax: csvRow.length > 5 && csvRow[5].isNotEmpty ? csvRow[5].trim() : null,
        kepala: csvRow.length > 6 && csvRow[6].isNotEmpty ? csvRow[6].trim() : null,
        region: csvRow.length > 7 && csvRow[7].isNotEmpty ? csvRow[7].trim() : null,
      );
    } catch (e) {
      print('Error parsing Kantor CSV row: $e');
      rethrow;
    }
  }

  @override
  String toString() => 'KantorModel(kode: $kode, nama: $nama, kota: $kota)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KantorModel && runtimeType == other.runtimeType && kode == other.kode;

  @override
  int get hashCode => kode.hashCode;
}
