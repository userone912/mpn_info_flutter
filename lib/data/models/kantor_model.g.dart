// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kantor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KantorModel _$KantorModelFromJson(Map<String, dynamic> json) => KantorModel(
      kode: json['kode'] as String,
      nama: json['nama'] as String,
      alamat: json['alamat'] as String,
      kota: json['kota'] as String,
      telepon: json['telepon'] as String?,
      fax: json['fax'] as String?,
      kepala: json['kepala'] as String?,
      region: json['region'] as String?,
    );

Map<String, dynamic> _$KantorModelToJson(KantorModel instance) =>
    <String, dynamic>{
      'kode': instance.kode,
      'nama': instance.nama,
      'alamat': instance.alamat,
      'kota': instance.kota,
      'telepon': instance.telepon,
      'fax': instance.fax,
      'kepala': instance.kepala,
      'region': instance.region,
    };
