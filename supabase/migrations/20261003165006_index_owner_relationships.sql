CREATE INDEX IF NOT EXISTS expected_shifts_employer_owner_idx ON public.expected_shifts(employer_id,user_id);
CREATE INDEX IF NOT EXISTS shift_entries_shift_owner_idx ON public.shift_entries(shift_id,user_id);
CREATE INDEX IF NOT EXISTS users_profile_employer_owner_idx ON public.users_profile(default_employer_id,user_id);
