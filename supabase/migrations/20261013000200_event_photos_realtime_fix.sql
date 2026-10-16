-- Galeri: daftarkan event_photos ke realtime publication + perbaiki URL dobel prefix.
-- Tanggal: 2026-10-13

-- 1. Stream gallery (.stream()) butuh tabel ini di publication supabase_realtime.
--    Tanpa ini, insert baru tidak memicu update grid secara live.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'event_photos'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.event_photos;
  END IF;
END $$;

-- 2. Baris lama menyimpan photo_url dengan prefix bucket ganda
--    (.../event-photos/event-photos/<period>/<file>) sehingga Image.network 404.
--    Normalkan ke satu prefix agar bisa dibuka dan dihapus.
UPDATE public.event_photos
SET photo_url = replace(
  photo_url,
  '/event-photos/event-photos/',
  '/event-photos/'
)
WHERE photo_url LIKE '%/event-photos/event-photos/%';
