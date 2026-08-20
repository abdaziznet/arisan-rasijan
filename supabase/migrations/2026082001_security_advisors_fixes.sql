-- Migration: Fix security advisor warnings on SECURITY DEFINER functions and search path
-- Date: 2026-08-20

-- 1. Fix handle_new_user search path and revoke public access
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = public
AS $function$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (new.id, COALESCE(new.raw_user_meta_data->>'full_name', ''));
  RETURN new;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC;

-- 2. Revoke execute from public on other SECURITY DEFINER functions and grant to necessary roles
REVOKE EXECUTE ON FUNCTION public.is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

REVOKE EXECUTE ON FUNCTION public.get_gathering_vote_tally(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_gathering_vote_tally(uuid) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.fn_allocate_payment_to_fund() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fn_allocate_payment_to_fund() TO authenticated;

REVOKE EXECUTE ON FUNCTION public.fn_check_gathering_voting_complete() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fn_check_gathering_voting_complete() TO authenticated;

REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM PUBLIC;

-- 3. Revoke execute on notify_gathering_vote_opened trigger function
REVOKE EXECUTE ON FUNCTION public.notify_gathering_vote_opened() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.notify_gathering_vote_opened() TO authenticated;
