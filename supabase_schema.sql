-- ============================================================================
-- SMARTTEST V. 1.2 - SUPABASE POSTGRESQL DATABASE SCHEMA
-- Sekolah: SMP NEGERI 1 MESUJI MAKMUR
-- Kompatibel penuh dengan Supabase REST API & Realtime Webhooks
-- ============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TABEL: SISWA
CREATE TABLE IF NOT EXISTS public.siswa (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    no_peserta VARCHAR(50) UNIQUE NOT NULL,
    nisn VARCHAR(20),
    nama VARCHAR(150) NOT NULL,
    kelas VARCHAR(20) NOT NULL,
    ruang VARCHAR(50) DEFAULT 'Ruang 01',
    status_ujian VARCHAR(50) DEFAULT 'Belum Mulai',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_siswa_no_peserta ON public.siswa(no_peserta);
CREATE INDEX IF NOT EXISTS idx_siswa_kelas ON public.siswa(kelas);
CREATE INDEX IF NOT EXISTS idx_siswa_ruang ON public.siswa(ruang);

-- 3. TABEL: GURU / PENGAWAS
CREATE TABLE IF NOT EXISTS public.guru (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nama VARCHAR(150) NOT NULL,
    nip VARCHAR(50),
    mapel VARCHAR(100) DEFAULT 'Pengawas Ujian',
    role VARCHAR(30) DEFAULT 'guru',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed Akun Pengawas Resmi
INSERT INTO public.guru (username, password_hash, nama, nip, mapel, role)
VALUES 
    ('admin', 'admin123', 'INDRA EFENDI, S.Kom.', '198501012010011001', 'Administrator Ujian', 'admin'),
    ('indra', '12', 'Indra Efendi, S. Kom.', '198501012010011001', 'Pengawas Ujian', 'guru')
ON CONFLICT (username) DO NOTHING;

-- 4. TABEL: JADWAL UJIAN
CREATE TABLE IF NOT EXISTS public.jadwal (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    token VARCHAR(30) UNIQUE NOT NULL,
    mapel VARCHAR(100) NOT NULL,
    kelas VARCHAR(50) NOT NULL,
    tanggal DATE NOT NULL DEFAULT CURRENT_DATE,
    jam_mulai VARCHAR(10) NOT NULL DEFAULT '07:30',
    durasi INTEGER NOT NULL DEFAULT 90,
    link_soal TEXT NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'Aktif',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_jadwal_token ON public.jadwal(token);
CREATE INDEX IF NOT EXISTS idx_jadwal_status ON public.jadwal(status);

-- 5. TABEL: LOG PELANGGARAN REALTIME (ANTI-CHEAT)
CREATE TABLE IF NOT EXISTS public.pelanggaran (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nama_siswa VARCHAR(150) NOT NULL,
    no_peserta VARCHAR(50) NOT NULL,
    kelas VARCHAR(30),
    mapel VARCHAR(100),
    jenis TEXT NOT NULL,
    total INTEGER DEFAULT 1,
    status VARCHAR(30) DEFAULT 'PERINGATAN',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pelanggaran_no_peserta ON public.pelanggaran(no_peserta);
CREATE INDEX IF NOT EXISTS idx_pelanggaran_created_at ON public.pelanggaran(created_at DESC);

-- 6. TABEL: PRESENSI PESERTA UJIAN
CREATE TABLE IF NOT EXISTS public.presensi (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    no_peserta VARCHAR(50) NOT NULL,
    nama VARCHAR(150) NOT NULL,
    kelas VARCHAR(30),
    mapel VARCHAR(100),
    status VARCHAR(50) DEFAULT 'Sedang Mengerjakan',
    device_info TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_presensi_no_peserta ON public.presensi(no_peserta);

-- 7. TABEL: BROADCAST PENGUMUMAN & RALAT SOAL
CREATE TABLE IF NOT EXISTS public.broadcast (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pesan TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. TABEL: TEGURAN LANGSUNG DARI PENGAWAS KE LAYAR SISWA
CREATE TABLE IF NOT EXISTS public.peringatan_siswa (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    no_peserta VARCHAR(50) NOT NULL,
    pesan TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_peringatan_siswa_target ON public.peringatan_siswa(no_peserta, is_read);

-- 9. TABEL: PENGATURAN UMUM SEKOLAH
CREATE TABLE IF NOT EXISTS public.pengaturan (
    key VARCHAR(50) PRIMARY KEY,
    value JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO public.pengaturan (key, value)
VALUES 
    ('sekolah', '"SMP NEGERI 1 MESUJI MAKMUR"'),
    ('kepala_sekolah', '"Lila Kartika Widya Sari, S. Pd."'),
    ('nip_kepala_sekolah', '"197705052005012013"'),
    ('kartu_config', '{"barcodeType": "barcode", "namaUjian": "ASESMEN SUMATIF AKHIR SEMESTER (ASAS)", "tahunAjaran": "TAHUN AJARAN 2026/2027"}')
ON CONFLICT (key) DO NOTHING;

-- 10. ENABLE ROW LEVEL SECURITY (RLS) & PUBLIC ACCESS POLICIES
ALTER TABLE public.siswa ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guru ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jadwal ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pelanggaran ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.presensi ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broadcast ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.peringatan_siswa ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pengaturan ENABLE ROW LEVEL SECURITY;

-- Allow anon public read/write for SmartTest client
CREATE POLICY "Public Read All" ON public.siswa FOR SELECT USING (true);
CREATE POLICY "Public Insert All" ON public.siswa FOR INSERT WITH CHECK (true);
CREATE POLICY "Public Update All" ON public.siswa FOR UPDATE USING (true);

CREATE POLICY "Public Guru Read" ON public.guru FOR SELECT USING (true);
CREATE POLICY "Public Guru Update" ON public.guru FOR ALL USING (true);

CREATE POLICY "Public Jadwal All" ON public.jadwal FOR ALL USING (true);
CREATE POLICY "Public Pelanggaran All" ON public.pelanggaran FOR ALL USING (true);
CREATE POLICY "Public Presensi All" ON public.presensi FOR ALL USING (true);
CREATE POLICY "Public Broadcast All" ON public.broadcast FOR ALL USING (true);
CREATE POLICY "Public Peringatan All" ON public.peringatan_siswa FOR ALL USING (true);
CREATE POLICY "Public Pengaturan All" ON public.pengaturan FOR ALL USING (true);

-- 11. ENABLE REALTIME UNTUK MONITORING PENGAWAS
ALTER PUBLICATION supabase_realtime ADD TABLE public.pelanggaran;
ALTER PUBLICATION supabase_realtime ADD TABLE public.presensi;
ALTER PUBLICATION supabase_realtime ADD TABLE public.broadcast;
ALTER PUBLICATION supabase_realtime ADD TABLE public.peringatan_siswa;
