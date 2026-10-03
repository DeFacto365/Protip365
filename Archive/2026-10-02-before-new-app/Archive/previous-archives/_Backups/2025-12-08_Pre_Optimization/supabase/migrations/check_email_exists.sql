-- Function to check if an email exists in auth.users
-- This needs to be run in Supabase SQL Editor as it accesses auth schema

CREATE OR REPLACE FUNCTION public.check_email_exists(check_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM auth.users
    WHERE email = check_email
  );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.check_email_exists(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_email_exists(TEXT) TO anon;
