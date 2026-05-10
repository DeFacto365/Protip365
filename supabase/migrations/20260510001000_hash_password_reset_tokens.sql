-- Existing plaintext reset tokens cannot be safely transformed because the raw
-- token may already have been exposed. Invalidate them and require future code
-- to store only token hashes.
DELETE FROM public.password_reset_tokens;

ALTER TABLE public.password_reset_tokens
  DROP CONSTRAINT IF EXISTS password_reset_tokens_token_key;

DROP INDEX IF EXISTS public.idx_password_reset_tokens_token;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'password_reset_tokens'
      AND column_name = 'token'
  ) THEN
    ALTER TABLE public.password_reset_tokens RENAME COLUMN token TO token_hash;
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS password_reset_tokens_token_hash_key
  ON public.password_reset_tokens(token_hash);

CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_token_hash
  ON public.password_reset_tokens(token_hash);
