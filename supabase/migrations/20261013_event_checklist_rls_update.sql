-- ============================================================
-- 20261013: Update RLS policies for event_checklist
-- Adds admin INSERT, UPDATE, and DELETE permissions.
-- ============================================================

-- Ensure row level security is enabled
ALTER TABLE public.event_checklist ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS event_checklist_admin_insert ON public.event_checklist;
DROP POLICY IF EXISTS event_checklist_admin_update ON public.event_checklist;
DROP POLICY IF EXISTS event_checklist_admin_delete ON public.event_checklist;

-- Insert policy: only admin can insert agenda items
CREATE POLICY "event_checklist_admin_insert"
  ON public.event_checklist FOR INSERT
  WITH CHECK (public.is_admin());

-- Update policy: only admin can modify agenda items
CREATE POLICY "event_checklist_admin_update"
  ON public.event_checklist FOR UPDATE
  USING (public.is_admin());

-- Delete policy: only admin can delete agenda items
CREATE POLICY "event_checklist_admin_delete"
  ON public.event_checklist FOR DELETE
  USING (public.is_admin());


