-- Migration: Revoke authenticated role execute permission on system trigger functions
-- Date: 2026-08-20

REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM authenticated;
