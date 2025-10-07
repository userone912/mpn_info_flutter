-- ================================================================
-- PKM UPDATE TABLE SCHEMA
-- Unified table design for all 4 CSV header patterns found in update folder
-- ================================================================

-- ANALYSIS OF CSV PATTERNS:
-- 
-- Pattern 1 - Standard PKM Format (8 files):
-- KD_KANWIL,KPPADM,NPWP,"NO PBK",NTPN,"TGL SETOR","THN SETOR","BLN SETOR","THN PAJAK","MASA PAJAK","JML SETOR","KODE MAP","KODE SETOR","ID SBR DATA"
-- Files: PKM Aktivitas Penegakan Hukum, PKM Aktivitas Pengawasan, PKM Lainnya, 
--        PKM WRA Edukasi, PKM WRA Pemeriksaan, PKM WRA Penegakan Hukum, PKM WRA Pengawasan
--
-- Pattern 2 - PKM Pemeriksaan Format (1 file):
-- KD_KANWIL,KPPADM,NPWP,"NO PRODUK HUKUM","NO PBK",NTPN,"TGL SETOR","THN SETOR","BLN SETOR","THN PAJAK","MASA PAJAK","JML SETOR","KODE MAP","KODE SETOR","ID SBR DATA"
-- Files: PKM Aktivitas Pemeriksaan 2025 (has extra "NO PRODUK HUKUM" column)
--
-- Pattern 3 - PKM Penagihan Format (1 file):
-- KD_KANWIL,KPPADM,NPWP,"NO PBK",NTPN,"TGL SETOR","THN SETOR","BLN SETOR","THN PAJAK","MASA PAJAK","JML SETOR","KODE MAP","KODE SETOR","FLAG SKP","ID SBR DATA"
-- Files: PKM Aktivitas Penagihan 2025 (has extra "FLAG SKP" column)
--
-- Pattern 4 - PPM/SPMKP Format (2 files):
-- KD_KANWIL,KPPADM,NPWP,"NO PBK",NTPN,"TGL SETOR","THN SETOR","BLN SETOR","THN PAJAK","MASA PAJAK","JML SETOR","KODE MAP","KODE SETOR",ID_SBR_DATA
-- Files: PPM_Bruto_2025, SPMKP_2025 (Note: ID_SBR_DATA without quotes)

-- ================================================================
-- UNIFIED TABLE SCHEMA
-- ================================================================

CREATE TABLE pkm_update (
    -- Primary key
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    
    -- Core columns (present in all 4 patterns)
    kd_kanwil TEXT NOT NULL,                -- Regional office code
    kppadm TEXT NOT NULL,                   -- Administrative office code  
    npwp TEXT NOT NULL,                     -- Taxpayer identification number
    no_pbk TEXT NOT NULL,                   -- PBK number
    ntpn TEXT NOT NULL,                     -- Tax payment slip number
    tgl_setor TEXT NOT NULL,                -- Payment date
    thn_setor TEXT NOT NULL,                -- Payment year
    bln_setor TEXT NOT NULL,                -- Payment month
    thn_pajak TEXT NOT NULL,                -- Tax year
    masa_pajak TEXT NOT NULL,               -- Tax period
    jml_setor REAL NOT NULL,                -- Payment amount
    kode_map TEXT NOT NULL,                 -- MAP code
    kode_setor TEXT NOT NULL,               -- Deposit code
    id_sbr_data TEXT NOT NULL,              -- Data source ID
    
    -- Optional columns (pattern-specific)
    no_produk_hukum TEXT,                   -- Legal product number (Pattern 2: PKM Pemeriksaan only)
    flag_skp TEXT,                          -- SKP flag (Pattern 3: PKM Penagihan only)
    
    -- Metadata columns for tracking and management
    file_source TEXT NOT NULL,             -- Original filename for traceability
    file_type TEXT NOT NULL,               -- Pattern type: 'standard', 'pemeriksaan', 'penagihan', 'ppm_spmkp'
    import_batch TEXT,                      -- Batch identifier for bulk imports
    
    -- Audit columns
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- ================================================================
-- INDEXES FOR PERFORMANCE
-- ================================================================

-- Primary search columns
CREATE INDEX idx_pkm_update_npwp ON pkm_update(npwp);
CREATE INDEX idx_pkm_update_tgl_setor ON pkm_update(tgl_setor);
CREATE INDEX idx_pkm_update_kd_kanwil ON pkm_update(kd_kanwil);

-- Pattern and source tracking
CREATE INDEX idx_pkm_update_file_type ON pkm_update(file_type);
CREATE INDEX idx_pkm_update_file_source ON pkm_update(file_source);
CREATE INDEX idx_pkm_update_import_batch ON pkm_update(import_batch);

-- Tax period queries
CREATE INDEX idx_pkm_update_thn_pajak ON pkm_update(thn_pajak);
CREATE INDEX idx_pkm_update_masa_pajak ON pkm_update(masa_pajak);
CREATE INDEX idx_pkm_update_period ON pkm_update(thn_pajak, masa_pajak);

-- Amount-based queries
CREATE INDEX idx_pkm_update_jml_setor ON pkm_update(jml_setor);

-- Composite indexes for common query patterns
CREATE INDEX idx_pkm_update_npwp_period ON pkm_update(npwp, thn_pajak, masa_pajak);
CREATE INDEX idx_pkm_update_kanwil_period ON pkm_update(kd_kanwil, thn_pajak, masa_pajak);

-- ================================================================
-- FILE TYPE DEFINITIONS
-- ================================================================

-- file_type values:
-- 'standard'     - Standard PKM format (8 files)
-- 'pemeriksaan'  - PKM Pemeriksaan with NO_PRODUK_HUKUM
-- 'penagihan'    - PKM Penagihan with FLAG_SKP  
-- 'ppm_spmkp'    - PPM_Bruto and SPMKP files

-- ================================================================
-- USAGE NOTES
-- ================================================================

-- 1. All files share the same 13 core columns, making unified storage feasible
-- 2. Optional columns (no_produk_hukum, flag_skp) are NULL for patterns that don't include them
-- 3. file_source preserves original filename for audit and troubleshooting
-- 4. file_type enables pattern-specific processing and validation
-- 5. import_batch allows grouping of files imported together
-- 6. Indexes support efficient querying by taxpayer, time period, and office