/// MAP (Mapping Kode Akun Pajak) model
/// Based on database table: map (kdmap, kdbayar, sektor, uraian)
class MapModel {
  final String kdmap;
  final String kdbayar;
  final int sektor;
  final String uraian;

  const MapModel({
    required this.kdmap,
    required this.kdbayar,
    required this.sektor,
    required this.uraian,
  });

  factory MapModel.fromJson(Map<String, dynamic> json) {
    return MapModel(
      kdmap: _safeStringCast(json['kdmap']),
      kdbayar: _safeStringCast(json['kdbayar']),
      sektor: json['sektor'] is int ? json['sektor'] : int.tryParse(json['sektor']?.toString() ?? '0') ?? 0,
      uraian: _safeStringCast(json['uraian']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kdmap': kdmap,
      'kdbayar': kdbayar,
      'sektor': sektor,
      'uraian': uraian,
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

  /// Get sektor display name for better readability
  String get sektorDisplay {
    switch (sektor) {
      case 1:
        return 'PPh';
      case 2:
        return 'PPN';
      case 3:
        return 'PBB';
      default:
        return 'Lainnya';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapModel &&
        other.kdmap == kdmap &&
        other.kdbayar == kdbayar &&
        other.sektor == sektor &&
        other.uraian == uraian;
  }

  @override
  int get hashCode {
    return Object.hash(kdmap, kdbayar, sektor, uraian);
  }

  @override
  String toString() {
    return 'MapModel(kdmap: $kdmap, kdbayar: $kdbayar, sektor: $sektor, uraian: $uraian)';
  }
}