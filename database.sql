-- Enable uuid-ossp extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ══════════════════════════════════════════════
-- 1. DROP EXISTING TABLES (IF ANY)
-- ══════════════════════════════════════════════
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_before ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_deleted ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.handle_delete_user();
DROP FUNCTION IF EXISTS public.auto_confirm_user_email();
DROP FUNCTION IF EXISTS public.get_user_role() CASCADE;
DROP FUNCTION IF EXISTS public.admin_create_user(text, text, text, text, text, uuid, int, text);

DROP TABLE IF EXISTS public.pengumuman CASCADE;
DROP TABLE IF EXISTS public.nilai CASCADE;
DROP TABLE IF EXISTS public.pengumpulan_tugas CASCADE;
DROP TABLE IF EXISTS public.tugas CASCADE;
DROP TABLE IF EXISTS public.materi CASCADE;
DROP TABLE IF EXISTS public.krs CASCADE;
DROP TABLE IF EXISTS public.jadwal CASCADE;
DROP TABLE IF EXISTS public.kelas CASCADE;
DROP TABLE IF EXISTS public.mata_kuliah CASCADE;
DROP TABLE IF EXISTS public.dosen CASCADE;
DROP TABLE IF EXISTS public.mahasiswa CASCADE;
DROP TABLE IF EXISTS public.semester CASCADE;
DROP TABLE IF EXISTS public.program_studi CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- ══════════════════════════════════════════════
-- 2. CREATE TABLES
-- ══════════════════════════════════════════════

-- Users Profile Table (linked to auth.users)
CREATE TABLE public.users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL UNIQUE,
  role text NOT NULL CHECK (role IN ('admin', 'dosen', 'mahasiswa')),
  nama text NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Program Studi Table
CREATE TABLE public.program_studi (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kode text NOT NULL UNIQUE,
  nama text NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Semester Akademik Table
CREATE TABLE public.semester (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nama text NOT NULL UNIQUE, -- e.g., "Ganjil 2026/2027"
  status boolean DEFAULT false NOT NULL, -- true if active
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Mahasiswa Table
CREATE TABLE public.mahasiswa (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE UNIQUE,
  nim text NOT NULL UNIQUE,
  program_studi_id uuid REFERENCES public.program_studi(id) ON DELETE SET NULL,
  angkatan integer NOT NULL,
  alamat text,
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Dosen Table
CREATE TABLE public.dosen (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE UNIQUE,
  nidn text NOT NULL UNIQUE,
  alamat text,
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Mata Kuliah Table
CREATE TABLE public.mata_kuliah (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kode text NOT NULL UNIQUE,
  nama text NOT NULL,
  sks integer NOT NULL CHECK (sks > 0 AND sks <= 6),
  program_studi_id uuid REFERENCES public.program_studi(id) ON DELETE CASCADE,
  semester_id uuid REFERENCES public.semester(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Kelas Table
CREATE TABLE public.kelas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nama text NOT NULL, -- e.g. "TI-A", "TI-B"
  mata_kuliah_id uuid NOT NULL REFERENCES public.mata_kuliah(id) ON DELETE CASCADE,
  dosen_id uuid NOT NULL REFERENCES public.dosen(id) ON DELETE CASCADE,
  kuota integer NOT NULL CHECK (kuota > 0),
  created_at timestamptz DEFAULT now() NOT NULL,
  UNIQUE(nama, mata_kuliah_id)
);

-- Jadwal Kuliah Table
CREATE TABLE public.jadwal (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kelas_id uuid NOT NULL REFERENCES public.kelas(id) ON DELETE CASCADE UNIQUE,
  hari text NOT NULL CHECK (hari IN ('Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu')),
  jam_mulai time NOT NULL,
  jam_selesai time NOT NULL,
  ruangan text NOT NULL,
  semester_id uuid NOT NULL REFERENCES public.semester(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now() NOT NULL,
  CHECK (jam_mulai < jam_selesai)
);

-- KRS Table
CREATE TABLE public.krs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  mahasiswa_id uuid NOT NULL REFERENCES public.mahasiswa(id) ON DELETE CASCADE,
  jadwal_id uuid NOT NULL REFERENCES public.jadwal(id) ON DELETE CASCADE,
  semester_id uuid NOT NULL REFERENCES public.semester(id) ON DELETE CASCADE,
  status text NOT NULL CHECK (status IN ('draft', 'menunggu', 'disetujui', 'ditolak')) DEFAULT 'draft',
  created_at timestamptz DEFAULT now() NOT NULL,
  UNIQUE(mahasiswa_id, jadwal_id)
);

-- Materi Kuliah Table
CREATE TABLE public.materi (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kelas_id uuid NOT NULL REFERENCES public.kelas(id) ON DELETE CASCADE,
  dosen_id uuid NOT NULL REFERENCES public.dosen(id) ON DELETE CASCADE,
  judul text NOT NULL,
  tipe_file text NOT NULL CHECK (tipe_file IN ('pdf', 'word', 'ppt', 'video', 'gambar', 'link')),
  url_file text NOT NULL, -- Path to Supabase Storage or external link
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Tugas Table
CREATE TABLE public.tugas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kelas_id uuid NOT NULL REFERENCES public.kelas(id) ON DELETE CASCADE,
  dosen_id uuid NOT NULL REFERENCES public.dosen(id) ON DELETE CASCADE,
  judul text NOT NULL,
  deskripsi text,
  deadline timestamptz NOT NULL,
  url_file text, -- Optional template/instruction file path
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Pengumpulan Tugas Table
CREATE TABLE public.pengumpulan_tugas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tugas_id uuid NOT NULL REFERENCES public.tugas(id) ON DELETE CASCADE,
  mahasiswa_id uuid NOT NULL REFERENCES public.mahasiswa(id) ON DELETE CASCADE,
  file_jawaban text NOT NULL, -- Path to Supabase Storage
  nilai numeric CHECK (nilai >= 0 AND nilai <= 100),
  komentar text,
  waktu_kumpul timestamptz DEFAULT now() NOT NULL,
  UNIQUE(tugas_id, mahasiswa_id)
);

-- Nilai Akhir Table
CREATE TABLE public.nilai (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  mahasiswa_id uuid NOT NULL REFERENCES public.mahasiswa(id) ON DELETE CASCADE,
  kelas_id uuid NOT NULL REFERENCES public.kelas(id) ON DELETE CASCADE,
  nilai_tugas numeric CHECK (nilai_tugas >= 0 AND nilai_tugas <= 100),
  nilai_uts numeric CHECK (nilai_uts >= 0 AND nilai_uts <= 100),
  nilai_uas numeric CHECK (nilai_uas >= 0 AND nilai_uas <= 100),
  nilai_akhir numeric CHECK (nilai_akhir >= 0 AND nilai_akhir <= 100),
  grade text CHECK (grade IN ('A', 'B', 'C', 'D', 'E')),
  created_at timestamptz DEFAULT now() NOT NULL,
  UNIQUE(mahasiswa_id, kelas_id)
);

-- Pengumuman Table
CREATE TABLE public.pengumuman (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kelas_id uuid REFERENCES public.kelas(id) ON DELETE CASCADE, -- NULL for general announcements
  judul text NOT NULL,
  isi text NOT NULL,
  dibuat_oleh uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now() NOT NULL
);

-- ══════════════════════════════════════════════
-- 3. TRIGGERS & SYNC FUNCTIONS
-- ══════════════════════════════════════════════

-- User role function helper for RLS
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS text AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

-- Trigger to auto-confirm new user emails
CREATE OR REPLACE FUNCTION public.auto_confirm_user_email()
RETURNS trigger AS $$
BEGIN
  new.email_confirmed_at := now();
  new.confirmed_at := now();
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created_before
  BEFORE INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.auto_confirm_user_email();

-- Trigger to sync auth.users with public.users and role-specific tables
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  v_role text;
  v_nama text;
  v_nim text;
  v_nidn text;
  v_program_studi_id uuid;
  v_angkatan int;
  v_alamat text;
BEGIN
  v_role := coalesce(new.raw_user_meta_data->>'role', 'mahasiswa');
  v_nama := coalesce(new.raw_user_meta_data->>'nama', '');
  v_nim := new.raw_user_meta_data->>'nim';
  v_nidn := new.raw_user_meta_data->>'nidn';
  v_angkatan := (new.raw_user_meta_data->>'angkatan')::int;
  v_alamat := new.raw_user_meta_data->>'alamat';
  
  -- Insert into public.users
  INSERT INTO public.users (id, email, role, nama)
  VALUES (new.id, new.email, v_role, v_nama);
  
  -- Insert into role-specific tables
  IF v_role = 'mahasiswa' THEN
    IF new.raw_user_meta_data->>'program_studi_id' IS NOT NULL THEN
      v_program_studi_id := (new.raw_user_meta_data->>'program_studi_id')::uuid;
    END IF;

    INSERT INTO public.mahasiswa (user_id, nim, program_studi_id, angkatan, alamat)
    VALUES (new.id, v_nim, v_program_studi_id, v_angkatan, v_alamat);
  ELSIF v_role = 'dosen' THEN
    INSERT INTO public.dosen (user_id, nidn, alamat)
    VALUES (new.id, v_nidn, v_alamat);
  END IF;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger on user delete
CREATE OR REPLACE FUNCTION public.handle_delete_user()
RETURNS trigger AS $$
BEGIN
  DELETE FROM public.users WHERE id = old.id;
  RETURN old;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_deleted
  AFTER DELETE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_delete_user();

-- Admin user creation RPC function
CREATE OR REPLACE FUNCTION public.admin_create_user(
  p_email text,
  p_password text,
  p_role text,
  p_nama text,
  p_nim_or_nidn text,
  p_program_studi_id uuid,
  p_angkatan int,
  p_alamat text
) RETURNS uuid AS $$
DECLARE
  v_user_id uuid;
  v_encrypted_pw text;
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admins can create users.';
  END IF;

  v_user_id := gen_random_uuid();
  v_encrypted_pw := extensions.crypt(p_password, extensions.gen_salt('bf'));

  -- Insert into auth.users
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    phone_confirmed_at,
    recovery_sent_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    v_user_id,
    'authenticated',
    'authenticated',
    p_email,
    v_encrypted_pw,
    now(),
    now(),
    null,
    null,
    '{"provider": "email", "providers": ["email"]}',
    json_build_object(
      'role', p_role,
      'nama', p_nama,
      'nidn', CASE WHEN p_role = 'dosen' THEN p_nim_or_nidn ELSE null END,
      'nim', CASE WHEN p_role = 'mahasiswa' THEN p_nim_or_nidn ELSE null END,
      'program_studi_id', p_program_studi_id,
      'angkatan', p_angkatan,
      'alamat', p_alamat
    ),
    now(),
    now(),
    '',
    '',
    '',
    ''
  );

  -- Create identity for the user
  INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_user_id,
    json_build_object('sub', v_user_id, 'email', p_email),
    'email',
    v_user_id::text,
    null,
    now(),
    now()
  );

  RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin user deletion RPC function
CREATE OR REPLACE FUNCTION public.admin_delete_user(
  p_user_id uuid
) RETURNS void AS $$
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admins can delete users.';
  END IF;

  DELETE FROM auth.users WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ══════════════════════════════════════════════
-- 4. ENABLE ROW LEVEL SECURITY (RLS)
-- ══════════════════════════════════════════════
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.program_studi ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.semester ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mahasiswa ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dosen ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mata_kuliah ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kelas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jadwal ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.krs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.materi ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tugas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pengumpulan_tugas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nilai ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pengumuman ENABLE ROW LEVEL SECURITY;

-- ══════════════════════════════════════════════
-- 5. RLS POLICIES
-- ══════════════════════════════════════════════

-- Helper Policy: Admins have full access to everything
CREATE POLICY "Admins full access users" ON public.users TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');
CREATE POLICY "Admins full access program_studi" ON public.program_studi TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');
CREATE POLICY "Admins full access semester" ON public.semester TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');
CREATE POLICY "Admins full access mahasiswa" ON public.mahasiswa TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');
CREATE POLICY "Admins full access dosen" ON public.dosen TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');
CREATE POLICY "Admins full access mata_kuliah" ON public.mata_kuliah TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');
CREATE POLICY "Admins full access kelas" ON public.kelas TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');
CREATE POLICY "Admins full access jadwal" ON public.jadwal TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');
CREATE POLICY "Admins full access krs" ON public.krs TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');
CREATE POLICY "Admins full access materi" ON public.materi TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');
CREATE POLICY "Admins full access tugas" ON public.tugas TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');
CREATE POLICY "Admins full access pengumpulan_tugas" ON public.pengumpulan_tugas TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');
CREATE POLICY "Admins full access nilai" ON public.nilai TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');
CREATE POLICY "Admins full access pengumuman" ON public.pengumuman TO authenticated USING (public.get_user_role() = 'admin') WITH CHECK (public.get_user_role() = 'admin');

-- Users Policies
CREATE POLICY "Users read self or other profiles" ON public.users FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users update self profile" ON public.users FOR UPDATE TO authenticated USING (id = auth.uid());

-- Program Studi & Semester Policies
CREATE POLICY "Anyone read program_studi" ON public.program_studi FOR SELECT USING (true);
CREATE POLICY "Anyone read semester" ON public.semester FOR SELECT TO authenticated USING (true);

-- Mahasiswa Policies
CREATE POLICY "Anyone read mahasiswa" ON public.mahasiswa FOR SELECT TO authenticated USING (true);
CREATE POLICY "Mahasiswa update self" ON public.mahasiswa FOR UPDATE TO authenticated USING (user_id = auth.uid());

-- Dosen Policies
CREATE POLICY "Anyone read dosen" ON public.dosen FOR SELECT TO authenticated USING (true);
CREATE POLICY "Dosen update self" ON public.dosen FOR UPDATE TO authenticated USING (user_id = auth.uid());

-- Mata Kuliah Policies
CREATE POLICY "Anyone read mata_kuliah" ON public.mata_kuliah FOR SELECT TO authenticated USING (true);

-- Kelas Policies
CREATE POLICY "Anyone read kelas" ON public.kelas FOR SELECT TO authenticated USING (true);

-- Jadwal Policies
CREATE POLICY "Anyone read jadwal" ON public.jadwal FOR SELECT TO authenticated USING (true);

-- KRS Policies
CREATE POLICY "Mahasiswa read self KRS" ON public.krs FOR SELECT TO authenticated USING (
  mahasiswa_id IN (SELECT id FROM public.mahasiswa WHERE user_id = auth.uid())
);
CREATE POLICY "Mahasiswa insert self KRS" ON public.krs FOR INSERT TO authenticated WITH CHECK (
  mahasiswa_id IN (SELECT id FROM public.mahasiswa WHERE user_id = auth.uid())
);
CREATE POLICY "Mahasiswa update self KRS" ON public.krs FOR UPDATE TO authenticated USING (
  mahasiswa_id IN (SELECT id FROM public.mahasiswa WHERE user_id = auth.uid()) AND status = 'draft'
) WITH CHECK (
  mahasiswa_id IN (SELECT id FROM public.mahasiswa WHERE user_id = auth.uid()) AND status = 'draft'
);
CREATE POLICY "Mahasiswa delete self KRS" ON public.krs FOR DELETE TO authenticated USING (
  mahasiswa_id IN (SELECT id FROM public.mahasiswa WHERE user_id = auth.uid()) AND status = 'draft'
);
CREATE POLICY "Dosen read KRS of classes they teach" ON public.krs FOR SELECT TO authenticated USING (
  jadwal_id IN (
    SELECT j.id FROM public.jadwal j 
    JOIN public.kelas k ON j.kelas_id = k.id 
    JOIN public.dosen d ON k.dosen_id = d.id 
    WHERE d.user_id = auth.uid()
  )
);

-- Materi Policies
CREATE POLICY "Anyone read materi" ON public.materi FOR SELECT TO authenticated USING (true);
CREATE POLICY "Dosen full access to class materi" ON public.materi TO authenticated 
  USING (dosen_id IN (SELECT id FROM public.dosen WHERE user_id = auth.uid()))
  WITH CHECK (dosen_id IN (SELECT id FROM public.dosen WHERE user_id = auth.uid()));

-- Tugas Policies
CREATE POLICY "Anyone read tugas" ON public.tugas FOR SELECT TO authenticated USING (true);
CREATE POLICY "Dosen full access to class tugas" ON public.tugas TO authenticated 
  USING (dosen_id IN (SELECT id FROM public.dosen WHERE user_id = auth.uid()))
  WITH CHECK (dosen_id IN (SELECT id FROM public.dosen WHERE user_id = auth.uid()));

-- Pengumpulan Tugas Policies
CREATE POLICY "Student read self submission" ON public.pengumpulan_tugas FOR SELECT TO authenticated USING (
  mahasiswa_id IN (SELECT id FROM public.mahasiswa WHERE user_id = auth.uid())
);
CREATE POLICY "Student insert self submission" ON public.pengumpulan_tugas FOR INSERT TO authenticated WITH CHECK (
  mahasiswa_id IN (SELECT id FROM public.mahasiswa WHERE user_id = auth.uid())
);
CREATE POLICY "Student update self submission" ON public.pengumpulan_tugas FOR UPDATE TO authenticated USING (
  mahasiswa_id IN (SELECT id FROM public.mahasiswa WHERE user_id = auth.uid())
) WITH CHECK (
  mahasiswa_id IN (SELECT id FROM public.mahasiswa WHERE user_id = auth.uid())
);
CREATE POLICY "Dosen read class submissions" ON public.pengumpulan_tugas FOR SELECT TO authenticated USING (
  tugas_id IN (
    SELECT t.id FROM public.tugas t
    JOIN public.kelas k ON t.kelas_id = k.id
    JOIN public.dosen d ON k.dosen_id = d.id
    WHERE d.user_id = auth.uid()
  )
);
CREATE POLICY "Dosen grade class submissions" ON public.pengumpulan_tugas FOR UPDATE TO authenticated USING (
  tugas_id IN (
    SELECT t.id FROM public.tugas t
    JOIN public.kelas k ON t.kelas_id = k.id
    JOIN public.dosen d ON k.dosen_id = d.id
    WHERE d.user_id = auth.uid()
  )
) WITH CHECK (
  tugas_id IN (
    SELECT t.id FROM public.tugas t
    JOIN public.kelas k ON t.kelas_id = k.id
    JOIN public.dosen d ON k.dosen_id = d.id
    WHERE d.user_id = auth.uid()
  )
);

-- Nilai Policies
CREATE POLICY "Mahasiswa view self grades" ON public.nilai FOR SELECT TO authenticated USING (
  mahasiswa_id IN (SELECT id FROM public.mahasiswa WHERE user_id = auth.uid())
);
CREATE POLICY "Dosen manage grades" ON public.nilai TO authenticated USING (
  kelas_id IN (
    SELECT k.id FROM public.kelas k
    JOIN public.dosen d ON k.dosen_id = d.id
    WHERE d.user_id = auth.uid()
  )
) WITH CHECK (
  kelas_id IN (
    SELECT k.id FROM public.kelas k
    JOIN public.dosen d ON k.dosen_id = d.id
    WHERE d.user_id = auth.uid()
  )
);

-- Pengumuman Policies
CREATE POLICY "Anyone read announcements" ON public.pengumuman FOR SELECT TO authenticated USING (true);
CREATE POLICY "Dosen manage class announcements" ON public.pengumuman TO authenticated USING (
  kelas_id IS NOT NULL AND kelas_id IN (
    SELECT k.id FROM public.kelas k
    JOIN public.dosen d ON k.dosen_id = d.id
    WHERE d.user_id = auth.uid()
  )
) WITH CHECK (
  kelas_id IS NOT NULL AND kelas_id IN (
    SELECT k.id FROM public.kelas k
    JOIN public.dosen d ON k.dosen_id = d.id
    WHERE d.user_id = auth.uid()
  )
);

-- ══════════════════════════════════════════════
-- 6. SEED DATA (PRODI & SEMESTER DEFAULT)
-- ══════════════════════════════════════════════
INSERT INTO public.program_studi (id, kode, nama) VALUES
  ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'TI', 'Teknik Informatika'),
  ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 'SI', 'Sistem Informasi'),
  ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a13', 'TE', 'Teknik Elektro')
ON CONFLICT (kode) DO NOTHING;

INSERT INTO public.semester (id, nama, status) VALUES
  ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Semester Ganjil 2026/2027', true),
  ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a12', 'Semester Genap 2026/2027', false)
ON CONFLICT (nama) DO NOTHING;

-- Admin reset password RPC function
CREATE OR REPLACE FUNCTION public.admin_reset_password(
  p_user_id uuid,
  p_new_password text
) RETURNS void AS $$
BEGIN
  -- Cek apakah pemanggil adalah admin
  IF NOT EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admins can reset passwords.';
  END IF;

  UPDATE auth.users
  SET 
    encrypted_password = extensions.crypt(p_new_password, extensions.gen_salt('bf')),
    updated_at = now()
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ══════════════════════════════════════════════
-- 7. SEED ADMIN USER
-- ══════════════════════════════════════════════
DO $$
DECLARE
  v_admin_id uuid := 'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a10';
  v_admin_email text := 'admin@gmail.com';
  v_admin_pw text := 'admin123';
  v_encrypted_pw text;
BEGIN
  -- Clean up existing admin if any, so that everything is fresh and the trigger fires!
  DELETE FROM auth.users WHERE email = v_admin_email;

  v_encrypted_pw := extensions.crypt(v_admin_pw, extensions.gen_salt('bf'));

  -- Insert into auth.users
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    phone_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    v_admin_id,
    'authenticated',
    'authenticated',
    v_admin_email,
    v_encrypted_pw,
    now(),
    now(),
    '{"provider": "email", "providers": ["email"]}',
    '{"role": "admin", "nama": "Administrator Utama"}',
    now(),
    now(),
    '',
    '',
    '',
    ''
  );

  -- Insert into auth.identities
  INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_admin_id,
    json_build_object('sub', v_admin_id, 'email', v_admin_email),
    'email',
    v_admin_id::text,
    null,
    now(),
    now()
  );
END $$;
