ALTER TABLE public.employers ADD CONSTRAINT employers_valid_rate CHECK (hourly_rate>=0 AND hourly_rate<'Infinity'::numeric);
ALTER TABLE public.expected_shifts ADD CONSTRAINT expected_shifts_valid_amounts CHECK (
 expected_hours BETWEEN 0 AND 24 AND hourly_rate>=0 AND hourly_rate<'Infinity'::numeric
 AND lunch_break_minutes BETWEEN 0 AND 1440);
ALTER TABLE public.shift_entries ADD CONSTRAINT shift_entries_valid_amounts CHECK (
 actual_hours BETWEEN 0 AND 24
 AND (hourly_rate IS NULL OR (hourly_rate>=0 AND hourly_rate<'Infinity'::numeric))
 AND (tips IS NULL OR (tips>=0 AND tips<'Infinity'::numeric))
 AND (sales IS NULL OR (sales>=0 AND sales<'Infinity'::numeric))
 AND (deduction_percentage IS NULL OR deduction_percentage BETWEEN 0 AND 100));
