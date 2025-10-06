# Sample CSV Files for MPN-Info Flutter

This directory contains sample CSV files for testing the database import functions in MPN-Info Flutter application.

## New Consolidated Import Method (Recommended)

### Update Database (Single Button)
The new **"Update Database"** button scans a selected directory for all CSV files and imports them automatically. This is similar to the "Update Referensi" workflow and provides better user experience.

**Key Features:**
- Scans directory for SEKSI-{KODE}.csv, PEGAWAI-{KODE}.csv, USER.csv, SPMKP-{KODE}-{YEAR}.csv
- Validates {KODE_KANTOR} against `settings.kantor.kode` (Qt legacy behavior)
- Rejects files with mismatched office codes
- Imports all valid files in one operation
- Provides comprehensive success/error summary

**How to Use:**
1. **Copy all CSV files to a single directory** (e.g., test_import_directory/)
2. **Navigate to Database → Update Database**
3. **Select the directory containing CSV files**
4. **Review import results**

## Individual Import Methods (Legacy)

You can still import files individually using the specific import functions.

## File Descriptions

### 1. SEKSI-001.csv (Import Seksi)
**Purpose**: Import office section/division data
**Format**: ID;KANTOR;TIPE;NAMA;KODE;TELP
**Fields**:
- ID: Unique identifier for the section
- KANTOR: Office code (3 digits)
- TIPE: Section type (0-8, see SeksiTypes enum)
- NAMA: Section name
- KODE: Section code (2 digits)
- TELP: Phone number

**Key Qt Legacy Behaviors**:
- Filename must be: SEKSI-{KODE_KANTOR}.csv  
- Deletes existing data: WHERE kantor='{KODE_KANTOR}'
- KANTOR field in each row must match filename KODE_KANTOR

**Section Types**:
- 0: Kepala Kantor (Office Head)
- 1: Subbagian Umum (General Affairs)
- 2: Pengolahan Data dan Informasi (Data Processing)
- 3: Pelayanan (Service)
- 4: Penagihan (Collection)
- 5: Pengawasan dan Konsultasi Pelayanan (Service Supervision)
- 6: Pengawasan dan Konsultasi Pengawasan (Audit Supervision)
- 7: Ekstensifikasi Perpajakan (Tax Extensification)
- 8: Pemeriksaan dan Kepatuhan Internal (Internal Audit)

### 2. PEGAWAI-001.csv (Import Pegawai)
**Purpose**: Import employee data
**Format**: KANTOR;NIP;NIP2;NAMA;SEKSI;PANGKAT;JABATAN;TAHUN
**Fields**:
- KANTOR: Office code (3 digits)
- NIP: Employee ID number (9 digits)
- NIP2: Alternative employee ID
- NAMA: Full name
- SEKSI: Section ID (references SEKSI table)
- PANGKAT: Rank level (0-4)
- JABATAN: Position type (0-6, see JabatanTypes enum)
- TAHUN: Year

**Key Qt Legacy Behaviors**:
- Filename must be: PEGAWAI-{KODE_KANTOR}.csv
- Deletes existing data: WHERE kantor='{KODE_KANTOR}' 
- KANTOR field in each row must match filename KODE_KANTOR

**Position Types**:
- 0: Kepala Kantor (Office Head)
- 1: Kepala Seksi (Section Head)
- 2: Fungsional Pemeriksa (Functional Auditor)
- 3: Operator Console (Console Operator)
- 4: Account Representative Pelayanan (Service AR)
- 5: Account Representative Pengawasan (Audit AR)
- 6: Pelaksana (Executor)

### 3. USER.csv (Import User)
**Purpose**: Import user accounts
**Format**: ID;USERNAME;PASSWORD;FULLNAME;GROUP
**Fields**:
- ID: Unique user identifier
- USERNAME: Login username
- PASSWORD: Login password (will be encrypted)
- FULLNAME: Full display name
- GROUP: User group level (0-2)

**User Groups**:
- 0: Administrator (full access)
- 1: User (normal access)
- 2: Guest (limited access)

### 4. SPMKP-001-2024.csv (Import SPMKP)
**Purpose**: Import revenue monitoring data (Surat Penetapan Masa Keluar Pajak)
**Format**: NPWP;KPP;CABANG;KDMAP;BULAN;TAHUN;NOMINAL
**Fields**:
- NPWP: Taxpayer identification number (9 digits)
- KPP: Tax office code (3 digits)
- CABANG: Branch code (3 digits)
- KDMAP: Tax type code (6 digits)
- BULAN: Month (1-12)
- TAHUN: Year (4 digits)
- NOMINAL: Amount (decimal number)

**Key Qt Legacy Behaviors**:
- Filename must be: SPMKP-{KODE_KANTOR}-{TAHUN}.csv
- Deletes existing data: WHERE admin='{KODE_KANTOR}' AND tahun={TAHUN}
- Admin field comes from filename, not CSV data

**Common Tax Type Codes (KDMAP)**:
- 411126: PPh Pasal 21 (Income Tax Article 21)
- 411211: PPh Pasal 25 (Income Tax Article 25)
- 411128: PPh Pasal 26 (Income Tax Article 26)

## How to Use

1. **Start the MPN-Info Flutter application**
2. **Login with administrator credentials**
3. **Navigate to Database menu**
4. **Select the appropriate import function**:
   - Import Seksi → Select SEKSI-001.csv
   - Import Pegawai → Select PEGAWAI-001.csv
   - Import User → Select USER.csv
   - Import SPMKP → Select SPMKP-001-2024.csv

## File Naming Conventions

- **Seksi files**: Must be named `SEKSI-{OFFICE_CODE}.csv` (e.g., SEKSI-001.csv)
- **Pegawai files**: Must be named `PEGAWAI-{OFFICE_CODE}.csv` (e.g., PEGAWAI-001.csv)
- **User files**: Can be named `USER.csv` or similar
- **SPMKP files**: Must be named `SPMKP-{KODE_KANTOR}-{TAHUN}.csv` (e.g., SPMKP-001-2024.csv)

## Notes

- All CSV files use semicolon (;) as delimiter
- Date format: DD/MM/YYYY
- Decimal numbers use dot (.) as decimal separator
- Text fields with spaces are allowed (no quotes needed)
- First line must contain the exact header format as specified

## Testing Sequence

1. Import Seksi first (creates sections)
2. Import Pegawai second (references sections)
3. Import User (creates user accounts)
4. Import SPMKP (creates revenue data)

This sequence ensures proper foreign key relationships between tables.