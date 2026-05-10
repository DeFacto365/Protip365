-- Remove public email existence oracle. Auth flows must use generic responses.
DROP FUNCTION IF EXISTS public.check_email_exists(TEXT);
