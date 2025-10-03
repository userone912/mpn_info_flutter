import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

import '../constants/app_constants.dart';
import '../constants/app_enums.dart';

/// Common utility functions for MPN-Info Flutter application
/// Migrated from Qt common.h and common.cpp files
class CommonUtils {
  // Lists for Indonesian administrative data
  static const List<String> _groupList = [
    'Administrator',
    'User',
    'Guest',
  ];

  static const List<String> _jabatanList = [
    'Kepala Kantor',
    'Kepala Seksi',
    'Fungsional Pemeriksa',
    'Operator Console',
    'Account Representative Pelayanan',
    'Account Representative Pengawasan',
    'Pelaksana',
  ];

  static const List<String> _pangkatList = [
    'I/a - Juru Muda',
    'I/b - Juru Muda Tingkat I',
    'I/c - Juru',
    'I/d - Juru Tingkat I',
    'II/a - Pengatur Muda',
    'II/b - Pengatur Muda Tingkat I',
    'II/c - Pengatur',
    'II/d - Pengatur Tingkat I',
    'III/a - Penata Muda',
    'III/b - Penata Muda Tingkat I',
    'III/c - Penata',
    'III/d - Penata Tingkat I',
    'IV/a - Pembina',
    'IV/b - Pembina Tingkat I',
    'IV/c - Pembina Utama Muda',
    'IV/d - Pembina Utama Madya',
    'IV/e - Pembina Utama',
  ];

  static const List<String> _seksiList = [
    'Kepala Kantor',
    'Subbagian Umum',
    'Pengolahan Data dan Informasi',
    'Pelayanan',
    'Penagihan',
    'Pengawasan dan Konsultasi Pelayanan',
    'Pengawasan dan Konsultasi Pengawasan',
    'Ekstensifikasi Perpajakan',
    'Pemeriksaan dan Kepatuhan Internal',
  ];

  static const List<String> _sektorList = [
    'Pertanian, Kehutanan, dan Perikanan',
    'Pertambangan dan Penggalian',
    'Industri Pengolahan',
    'Pengadaan Listrik, Gas, Uap, dan AC',
    'Pengadaan Air',
    'Konstruksi',
    'Perdagangan Besar dan Eceran',
    'Transportasi dan Pergudangan',
    'Penyediaan Akomodasi dan Makan Minum',
    'Informasi dan Komunikasi',
    'Jasa Keuangan dan Asuransi',
    'Real Estate',
    'Jasa Profesional, Ilmiah, dan Teknis',
    'Jasa Persewaan dan Sewa Guna',
    'Administrasi Pemerintahan',
    'Jasa Pendidikan',
    'Jasa Kesehatan dan Kegiatan Sosial',
    'Jasa Lainnya',
  ];

  /// Get group name by index
  static String getGroupName(int index) {
    if (index >= 0 && index < _groupList.length) {
      return _groupList[index];
    }
    return 'Unknown';
  }

  /// Get all group names
  static List<String> getGroupList() => List.from(_groupList);

  /// Get position name by index
  static String getJabatanName(int index) {
    if (index >= 0 && index < _jabatanList.length) {
      return _jabatanList[index];
    }
    return 'Unknown';
  }

  /// Get all position names
  static List<String> getJabatanList() => List.from(_jabatanList);

  /// Get rank name by index
  static String getPangkatName(int index) {
    if (index >= 0 && index < _pangkatList.length) {
      return _pangkatList[index];
    }
    return 'Unknown';
  }

  /// Get all rank names
  static List<String> getPangkatList() => List.from(_pangkatList);

  /// Get section name by index
  static String getSeksiName(int index) {
    if (index >= 0 && index < _seksiList.length) {
      return _seksiList[index];
    }
    return 'Unknown';
  }

  /// Get all section names
  static List<String> getSeksiList() => List.from(_seksiList);

  /// Get sector name by index
  static String getSektorName(int index) {
    if (index >= 0 && index < _sektorList.length) {
      return _sektorList[index];
    }
    return 'Unknown';
  }

  /// Get all sector names
  static List<String> getSektorList() => List.from(_sektorList);

  /// Convert month name to integer
  static int monthNameToInt(String monthName) {
    final index = AppConstants.indonesianMonths.indexOf(monthName);
    return index >= 0 ? index + 1 : 1;
  }

  /// Get Indonesian month name by index (1-12)
  static String getIndonesianMonthName(int month) {
    if (month >= 1 && month <= 12) {
      return AppConstants.indonesianMonths[month - 1];
    }
    return AppConstants.indonesianMonths[0];
  }

  /// Format NPWP with proper formatting (XX.XXX.XXX.X-XXX.XXX)
  static String formatNpwp(String npwp, [String? kpp, String? cabang]) {
    if (npwp.isEmpty) return '';
    
    // Remove any existing formatting
    String cleanNpwp = npwp.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (kpp != null && cabang != null) {
      // If KPP and Cabang are provided separately
      cleanNpwp = cleanNpwp.padLeft(9, '0');
      String cleanKpp = kpp.replaceAll(RegExp(r'[^0-9]'), '').padLeft(3, '0');
      String cleanCabang = cabang.replaceAll(RegExp(r'[^0-9]'), '').padLeft(3, '0');
      
      if (cleanNpwp.length >= 9) {
        return '${cleanNpwp.substring(0, 2)}.${cleanNpwp.substring(2, 5)}.${cleanNpwp.substring(5, 8)}.${cleanNpwp.substring(8, 9)}-$cleanKpp.$cleanCabang';
      }
    } else {
      // Format complete NPWP
      cleanNpwp = cleanNpwp.padLeft(15, '0');
      if (cleanNpwp.length >= 15) {
        return '${cleanNpwp.substring(0, 2)}.${cleanNpwp.substring(2, 5)}.${cleanNpwp.substring(5, 8)}.${cleanNpwp.substring(8, 9)}-${cleanNpwp.substring(9, 12)}.${cleanNpwp.substring(12, 15)}';
      }
    }
    
    return npwp;
  }

  /// Format tax certificate number (Ketetapan)
  static String formatKetetapan(String noSk) {
    if (noSk.isEmpty || noSk == '000000000000000') return '';
    
    String clean = noSk.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length >= 15) {
      return '${clean.substring(0, 3)}-${clean.substring(3, 6)}.${clean.substring(6, 9)}.${clean.substring(9, 12)}.${clean.substring(12, 15)}';
    }
    
    return noSk;
  }

  /// Format date as DD/MM/YYYY
  static String formatDate(int year, int month, int day) {
    try {
      final date = DateTime(year, month, day);
      return DateFormat(AppConstants.displayDateFormat).format(date);
    } catch (e) {
      return '$day/$month/$year';
    }
  }

  /// Format currency in Indonesian format (Rp 1.000.000,00)
  static String formatCurrency(double amount, {bool showSymbol = true}) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: showSymbol ? AppConstants.currencySymbol : '',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Format large numbers with Indonesian thousand separator
  static String formatNumber(double number, {int decimalPlaces = 0}) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    if (decimalPlaces > 0) {
      formatter.minimumFractionDigits = decimalPlaces;
      formatter.maximumFractionDigits = decimalPlaces;
    }
    return formatter.format(number);
  }

  /// Split NPWP into components (NPWP, KPP, Cabang)
  static List<String> splitNpwp(String npwp) {
    String clean = npwp.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (clean.length >= 15) {
      return [
        clean.substring(0, 9),   // NPWP
        clean.substring(9, 12),  // KPP
        clean.substring(12, 15), // Cabang
      ];
    } else if (clean.length >= 9) {
      return [
        clean.substring(0, 9),   // NPWP
        clean.length > 9 ? clean.substring(9, min(12, clean.length)) : '000',  // KPP
        clean.length > 12 ? clean.substring(12, min(15, clean.length)) : '000', // Cabang
      ];
    }
    
    return [clean.padLeft(9, '0'), '000', '000'];
  }

  /// Validate NPWP format and check digit
  static bool isNpwpValid(String npwp) {
    final parts = splitNpwp(npwp);
    final npwpPart = parts[0];
    
    if (npwpPart.length != 9) return false;
    
    // Basic validation - check if all digits
    if (!RegExp(r'^\d+$').hasMatch(npwpPart)) return false;
    
    // Check digit validation (simplified)
    // In practice, NPWP has a more complex check digit algorithm
    return npwpPart != '000000000';
  }

  /// Parse CSV line considering quoted fields
  static List<String> csvSplit(String line, {String separator = ','}) {
    List<String> result = [];
    StringBuffer current = StringBuffer();
    bool inQuotes = false;
    
    for (int i = 0; i < line.length; i++) {
      String char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == separator && !inQuotes) {
        result.add(current.toString().trim());
        current.clear();
      } else {
        current.write(char);
      }
    }
    
    result.add(current.toString().trim());
    return result;
  }

  /// Convert list to CSV format
  static String toCsv(List<String> list, {String separator = ','}) {
    return list.map((item) {
      if (item.contains(separator) || item.contains('"') || item.contains('\n')) {
        return '"${item.replaceAll('"', '""')}"';
      }
      return item;
    }).join(separator);
  }

  /// Parse date string to DateTime
  static DateTime? stringToDate(String dateString) {
    if (dateString.isEmpty) return null;
    
    try {
      // Try various date formats
      List<String> formats = [
        'yyyy-MM-dd',
        'dd/MM/yyyy',
        'MM/dd/yyyy',
        'yyyyMMdd',
        'dd-MM-yyyy',
      ];
      
      for (String format in formats) {
        try {
          return DateFormat(format).parse(dateString);
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      // If all formats fail, return null
    }
    
    return null;
  }

  /// Encrypt string using simple encryption
  static String encryptString(String value) {
    if (value.isEmpty) return '';
    
    final bytes = utf8.encode(value);
    final digest = sha256.convert(bytes);
    return base64.encode(digest.bytes);
  }

  /// Generate random string
  static String randomString(int length, {bool caseSensitive = true}) {
    const chars = 'abcdefghijklmnopqrstuvwxyz';
    const upperChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    
    String pool = chars + numbers;
    if (caseSensitive) {
      pool += upperChars;
    }
    
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => pool.codeUnitAt(random.nextInt(pool.length)))
    );
  }

  /// Convert download size to human readable format
  static String formatDownloadSize(int bytes) {
    if (bytes <= 0) return '0 B';
    
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(i > 0 ? 1 : 0)} ${suffixes[i]}';
  }

  /// Convert download status enum to readable string
  static String getDownloadStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.queue:
        return 'Antrian';
      case DownloadStatus.downloading:
        return 'Mengunduh';
      case DownloadStatus.importing:
        return 'Mengimpor';
      case DownloadStatus.updating:
        return 'Memperbarui';
      case DownloadStatus.done:
        return 'Selesai';
      case DownloadStatus.error:
        return 'Error';
    }
  }

  /// Parse double from Indonesian format string
  static double parseIndonesianNumber(String text, {String thousandSep = '.', String decimalSep = ','}) {
    if (text.isEmpty) return 0.0;
    
    // Remove thousand separators and replace decimal separator
    String cleaned = text
        .replaceAll(thousandSep, '')
        .replaceAll(decimalSep, '.');
    
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Calculate late payment penalty months
  static int calculateLatePenaltyMonths(DateTime paymentDate, DateTime dueDate, int masa, int tahun, int jenisType) {
    if (paymentDate.isBefore(dueDate) || paymentDate.isAtSameMomentAs(dueDate)) {
      return 0;
    }
    
    // Calculate months difference
    int months = (paymentDate.year - dueDate.year) * 12 + (paymentDate.month - dueDate.month);
    
    // Adjust for day of month
    if (paymentDate.day > dueDate.day) {
      months++;
    }
    
    return months > 0 ? months : 0;
  }

  /// Calculate late reporting penalty
  static double calculateLateReportingPenalty(String jenisType, int masa, int tahun) {
    // Simplified penalty calculation
    // In practice, this would have complex business rules
    const basePhase = 1000000.0; // 1 million IDR base penalty
    
    switch (jenisType.toLowerCase()) {
      case 'pph':
        return basePhase;
      case 'ppn':
        return basePhase * 5;
      case 'pphop':
        return basePhase * 0.5;
      case 'pphbdn':
        return basePhase * 2;
      default:
        return basePhase;
    }
  }

  /// Create directory path if it doesn't exist
  static bool createDirectory(String path) {
    // This would be implemented using dart:io Directory
    // For web platform, this might not be applicable
    return true; // Placeholder
  }

  /// Remove directory and its contents
  static bool removeDirectory(String path) {
    // This would be implemented using dart:io Directory
    // For web platform, this might not be applicable
    return true; // Placeholder
  }
}