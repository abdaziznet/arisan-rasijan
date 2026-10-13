-- Galeri: izinkan hapus baris event_photos untuk pemilik foto atau admin.
-- Tanpa policy DELETE, delete() kena blokir RLS diam-diam (0 baris),
-- storage terhapus tapi baris DB tertinggal sehingga grid tidak update.
-- Tanggal: 2026-10-13

CREATE POLICY "event_photos_delete_owner_or_admin"
ON public.event_photos
FOR DELETE
TO authenticated
USING (
  uploaded_by = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  )
);
