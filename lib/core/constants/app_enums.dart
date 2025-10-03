/// Enums for MPN-Info Flutter application
/// Migrated from Qt define.h file

/// Database connection types
enum DatabaseType {
  unknown,
  mysql,
  sqlite,
  postgresql,
  oracle,
  odbc,
}

/// Database status for updates
enum DatabaseStatus {
  needUpdate,
  upToDate,
  tooNew,
}

/// User groups and permissions
enum UserGroup {
  unknown(-1),
  administrator(0),
  user(1),
  guest(2);

  const UserGroup(this.value);
  final int value;

  static UserGroup fromValue(int value) {
    return UserGroup.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserGroup.unknown,
    );
  }
}

/// Employee position types (Jabatan)
enum JabatanType {
  unknown(-1),
  kepalaKantor(0),
  kepalaSeksi(1),
  fungsionalPemeriksa(2),
  operatorConsole(3),
  accountRepresentativePelayanan(4),
  accountRepresentativePengawasan(5),
  pelaksana(6);

  const JabatanType(this.value);
  final int value;

  static JabatanType fromValue(int value) {
    return JabatanType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => JabatanType.unknown,
    );
  }
}

/// Section types (Seksi)
enum SeksiType {
  unknown(-1),
  kepalaKantor(0),
  subbagianUmum(1),
  pengolahanDataDanInformasi(2),
  pelayanan(3),
  penagihan(4),
  pengawasanDanKonsultasiPelayanan(5),
  pengawasanDanKonsultasiPengawasan(6),
  ekstensifikasiPerpajakan(7),
  pemeriksaanDanKepatuhanInternal(8);

  const SeksiType(this.value);
  final int value;

  static SeksiType fromValue(int value) {
    return SeksiType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SeksiType.unknown,
    );
  }
}

/// Data sources for payments and reports
enum DataSource {
  mpn(1),      // Modul Penerimaan Negara
  spm(2),      // Surat Perintah Membayar
  manual(4);   // Manual entry

  const DataSource(this.value);
  final int value;

  static DataSource fromValue(int value) {
    return DataSource.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DataSource.mpn,
    );
  }
}

/// MPN (Modul Penerimaan Negara) types
enum MpnType {
  idr(1),    // Indonesian Rupiah
  usd(2),    // US Dollar
  pbb(3);    // Pajak Bumi dan Bangunan

  const MpnType(this.value);
  final int value;

  static MpnType fromValue(int value) {
    return MpnType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MpnType.idr,
    );
  }
}

/// Import error types
enum ImportError {
  noError,
  fileNotExist,
  invalidFilename,
  cannotOpenFile,
  invalidHeader,
  insertError,
  contentColumnError,
  contentError,
  splitError,
  invalidNipPegawai,
  kantorAdminError,
}

/// Import data types
enum ImportDataType {
  total,
  delete,
  success,
  kodeKppDiffer,
}

/// Download error types
enum DownloadError {
  noError,
  notLoggedIn,
  busy,
  canceled,
  invalidArguments,
  connectionError,
  downloadDirectoryError,
  fileError,
  timeout,
  linkError,
  messageError,
  cannotAccess,
}

/// Download status types
enum DownloadStatus {
  queue,
  downloading,
  importing,
  updating,
  done,
  error,
}

/// Due date types for tax obligations (Jatuh Tempo)
enum JatuhTempoType {
  unknown(-1),
  potPut(0),                    // Potong/Pungut
  potPutTahunanOp(1),          // Potong/Pungut Tahunan Orang Pribadi
  potPutTahunanBadan(2),       // Potong/Pungut Tahunan Badan
  pph(3),                      // Pajak Penghasilan
  ppn(4),                      // Pajak Pertambahan Nilai
  pphOp(5),                    // PPh Orang Pribadi
  pphBadan(6);                 // PPh Badan

  const JatuhTempoType(this.value);
  final int value;

  static JatuhTempoType fromValue(int value) {
    return JatuhTempoType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => JatuhTempoType.unknown,
    );
  }
}

/// Notification types
enum NotifyType {
  birthday(0),     // Employee birthday notifications
  pembayaran(1),   // Payment notifications
  pelaporan(2);    // Reporting notifications

  const NotifyType(this.value);
  final int value;

  static NotifyType fromValue(int value) {
    return NotifyType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotifyType.birthday,
    );
  }
}

/// SPMKP data sources
enum SpmkpSource {
  kppn(1),      // Kantor Pelayanan Perbendaharaan Negara
  sidjp(2),     // Sistem Informasi Direktorat Jenderal Pajak
  dashboard(3); // Dashboard system

  const SpmkpSource(this.value);
  final int value;

  static SpmkpSource fromValue(int value) {
    return SpmkpSource.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SpmkpSource.kppn,
    );
  }
}

/// SPMPP data sources
enum SpmppSource {
  kppn(1);      // Kantor Pelayanan Perbendaharaan Negara

  const SpmppSource(this.value);
  final int value;

  static SpmppSource fromValue(int value) {
    return SpmppSource.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SpmppSource.kppn,
    );
  }
}

/// Document types for PK/PM
enum PkPmType {
  pk(1),    // Pemeriksaan Kantor
  pm(2);    // Pemeriksaan Mendalam

  const PkPmType(this.value);
  final int value;

  static PkPmType fromValue(int value) {
    return PkPmType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PkPmType.pk,
    );
  }
}

/// Export database error types
enum ExportDatabaseError {
  noError,
  cannotOpen,
}

/// Spreadsheet save error types
enum SpreadsheetSaveError {
  noError,
  fileError,
}

/// Local database import error types
enum ImportLocalDatabaseError {
  noError,
  invalidArguments,
  loginError,
  kantorAdminError,
}