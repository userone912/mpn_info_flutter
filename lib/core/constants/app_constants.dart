/// App-wide constants for MPN-Info Flutter application
/// Migrated from Qt define.h file

class AppConstants {
    // Database Configuration
  static const String databaseName = 'data.db';
  static const int databaseVersion = 1;
  static const String databasePassword = 'mpninfo';

  // Database Table Names
  static const String tableUsers = 'users';
  static const String tableSeksi = 'seksi';
  static const String tablePegawai = 'pegawai';
  static const String tableSpmkp = 'spmkp';
  static const String tableWp = 'wp';
  static const String tableMpn = 'mpn';
  static const String tableSettings = 'settings';

  // Application Information
  static const String appName = 'MPN-Info';
  static const String appVersion = '1.0.0';
  static const String appDescription = '';
  
  // Database Configuration
  static const String defaultDatabaseName = 'mpninfo';
  static const String sqliteFileName = 'data.db';
  static const String databaseVersionKey = 'db.version';
  static const String serverName = 'MPNInfo';
  
  // Default Values
  static const int defaultSqlPort = 3306;
  static const String defaultSqlUsername = 'root';
  static const String defaultSqlPassword = '';
  static const int loginTryLimit = 3;
  static const int updatePort = 7566;
  
  // Settings Keys
  static const String lastVersionKey = 'lastVersion';
  static const String lastUserKey = 'lastUser';
  static const String downloadDirKey = 'downloadDir';
  static const String downloadTimeoutKey = 'downloadTimeout';
  static const String allowMultiClientKey = 'multiClient';
  static const String defaultPaperSizeKey = 'paperSize';
  static const String debugKey = 'debug';
  
  // Database Settings
  static const String databaseTypeKey = 'Database/type';
  static const String databaseHostKey = 'Database/host';
  static const String databasePortKey = 'Database/port';
  static const String databaseNameKey = 'Database/name';
  static const String databaseEncryptedKey = 'Database/encrypt';
  static const String databaseAuthKey = 'Database/auth';
  
  // Network Settings
  static const String networkUseProxyKey = 'Network/useProxy';
  static const String networkProxyHostKey = 'Network/proxyHost';
  static const String networkProxyPortKey = 'Network/proxyPort';
  static const String networkProxyAuthKey = 'Network/proxyAuth';
  
  // Server Settings - Office Information
  static const String kantorKodeKey = 'kantor.kode';
  static const String kantorWpjKey = 'kantor.wpj';
  static const String kantorKpKey = 'kantor.kp';
  static const String kantorAlamatKey = 'kantor.alamat';
  static const String kantorTeleponKey = 'kantor.telepon';
  static const String kantorKotaKey = 'kantor.kota';
  
  // App Portal Settings
  static const String appPortalAutoLoginKey = 'AppPortal/autoLogin';
  static const String appPortalRememberKey = 'AppPortal/remember';
  static const String appPortalHostKey = 'AppPortal/host';
  static const String appPortalAuthKey = 'AppPortal/auth';
  
  // Asset Paths
  static const String imagesPath = 'assets/images/';
  static const String iconsPath = 'assets/icons/';
  static const String dataPath = 'assets/data/';
  static const String mapsPath = 'assets/maps/';
  
  // Image Resources (equivalent to Qt resources)
  static const String logoIcon = '${imagesPath}logo-medium.png';
  static const String logoBigIcon = '${imagesPath}logo-medium.png';
  static const String logoMediumIcon = '${imagesPath}logo-medium.png';
  static const String authIcon = '${imagesPath}auth.png';
  static const String databaseIcon = '${imagesPath}db.png';
  static const String pegawaiIcon = '${imagesPath}pegawai.png';
  static const String userIcon = '${imagesPath}user.png';
  static const String settingsIcon = '${imagesPath}settings.png';
  static const String infoIcon = '${imagesPath}info.png';
  static const String exitIcon = '${imagesPath}exit.png';
  static const String searchIcon = '${imagesPath}search.png';
  static const String addIcon = '${imagesPath}add.png';
  static const String removeIcon = '${imagesPath}remove.png';
  static const String copyIcon = '${imagesPath}copy.png';
  static const String downloadIcon = '${imagesPath}download.png';
  
  // Date and Time Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'dd/MM/yyyy';
  static const String monthYearFormat = 'MM/yyyy';
  
  // Currency and Number Formats
  static const String currencySymbol = 'Rp';
  static const String thousandSeparator = '.';
  static const String decimalSeparator = ',';
  
  // Indonesian Months
  static const List<String> indonesianMonths = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];
  
  // Indonesian Month Abbreviations
  static const List<String> indonesianMonthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  // CSV Import Headers (from Qt application)
  static const String seksiHeaderFormat = 'ID;KANTOR;TIPE;NAMA;KODE;TELP';
  static const String pegawaiHeaderFormat = 'KANTOR;NIP;NIP2;NAMA;SEKSI;PANGKAT;JABATAN;TAHUN';
  static const String userHeaderFormat = 'ID;USERNAME;PASSWORD;FULLNAME;GROUP';
  static const String spmkpHeaderFormat = 'NPWP;KPP;CABANG;KDMAP;BULAN;TAHUN;NOMINAL';
  static const String renpenHeaderFormat = 'KPP;NIP;KDMAP;BULAN;TAHUN;TARGET';
  static const String assignKluHeaderFormat = 'NPWP;KPP;CABANG;KLU';
  static const String assignPjHeaderFormat = 'NPWP;KPP;CABANG;NIP';

  // File name patterns (STRICT: Exact format for folder scanning)
  static const String seksiFilePattern = 'SEKSI-{KODE_KANTOR}.csv';
  static const String pegawaiFilePattern = 'PEGAWAI-{KODE_KANTOR}.csv';
  static const String userFilePattern = 'USER-{KODE_KANTOR}.csv';
  static const String spmkpFilePattern = 'SPMKP-{KODE_KANTOR}-{TAHUN}.csv';
  static const String renpenFilePattern = 'RENPEN-{KODE_KPP}-{TAHUN}.csv';
  static const String assignKluFilePattern = 'ASSIGNKLU-{KODE_KPP}.csv';
  static const String assignPjFilePattern = 'ASSIGNPJ-{KODE_KPP}.csv';

  // Import Error Messages
  static const String importErrorOpenFile = 'File tidak dapat dibuka';
  static const String importErrorHeader = 'Nama header tidak sesuai dengan format yang diharapkan';
  static const String importErrorFilename = 'Nama file tidak sesuai dengan format yang diharapkan';
  static const String importErrorContent = 'Data dalam file tidak valid';
  static const String importErrorOfficeCode = 'Kode kantor tidak sesuai';
  static const String importSuccess = 'File berhasil diimport';
}