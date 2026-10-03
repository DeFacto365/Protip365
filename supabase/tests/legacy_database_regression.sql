BEGIN;
INSERT INTO auth.users(id) VALUES ('00000000-0000-4000-8000-000000000001'),('00000000-0000-4000-8000-000000000002');
INSERT INTO public.users_profile(user_id) VALUES ('00000000-0000-4000-8000-000000000001'),('00000000-0000-4000-8000-000000000002');
INSERT INTO public.employers(id,user_id,name,hourly_rate) VALUES
('00000000-0000-4000-8000-000000000011','00000000-0000-4000-8000-000000000001','audit fixture',15),
('00000000-0000-4000-8000-000000000012','00000000-0000-4000-8000-000000000002','audit fixture',15);
INSERT INTO public.expected_shifts(id,user_id,employer_id,shift_date,start_time,end_time,expected_hours,hourly_rate) VALUES
('00000000-0000-4000-8000-000000000021','00000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000011',current_date,'21:00','02:00',5,15),
('00000000-0000-4000-8000-000000000022','00000000-0000-4000-8000-000000000002','00000000-0000-4000-8000-000000000012',current_date,'12:00','17:00',5,15);
INSERT INTO public.shift_entries(shift_id,user_id,actual_start_time,actual_end_time,actual_hours,tips,sales)
VALUES('00000000-0000-4000-8000-000000000021','00000000-0000-4000-8000-000000000001','21:00','02:00',5,0,100);
UPDATE public.users_profile SET default_employer_id='00000000-0000-4000-8000-000000000011' WHERE user_id='00000000-0000-4000-8000-000000000001';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000001',true);
DO $$
DECLARE n bigint; hours numeric; tips numeric;
BEGIN
 SELECT count(*) INTO n FROM public.employers WHERE id IN ('00000000-0000-4000-8000-000000000011','00000000-0000-4000-8000-000000000012');
 IF n<>1 THEN RAISE EXCEPTION 'RLS isolation failed'; END IF;
 SELECT total_hours,total_tips INTO hours,tips FROM public.get_calendar_shifts(auth.uid(),current_date,current_date);
 IF hours<>5 OR tips<>0 THEN RAISE EXCEPTION 'Calendar totals failed'; END IF;
 SELECT count(*) INTO n FROM public.get_recent_shifts(auth.uid(),30) WHERE id='00000000-0000-4000-8000-000000000021';
 IF n<>1 THEN RAISE EXCEPTION 'Recent shifts failed'; END IF;
 BEGIN
  UPDATE public.expected_shifts SET employer_id='00000000-0000-4000-8000-000000000012' WHERE id='00000000-0000-4000-8000-000000000021';
  RAISE EXCEPTION 'Cross-owner employer accepted';
 EXCEPTION WHEN foreign_key_violation THEN NULL; END;
 BEGIN
  UPDATE public.shift_entries SET shift_id='00000000-0000-4000-8000-000000000022' WHERE shift_id='00000000-0000-4000-8000-000000000021';
  RAISE EXCEPTION 'Cross-owner shift accepted';
 EXCEPTION WHEN foreign_key_violation THEN NULL; END;
 BEGIN
  UPDATE public.employers SET user_id='00000000-0000-4000-8000-000000000002' WHERE id='00000000-0000-4000-8000-000000000011';
  RAISE EXCEPTION 'Owner reassignment accepted';
 EXCEPTION WHEN insufficient_privilege THEN NULL; END;
 IF has_table_privilege('authenticated','public.user_subscriptions','INSERT')
 OR has_table_privilege('authenticated','public.security_audit_log','INSERT')
 OR has_table_privilege('authenticated','public.password_reset_tokens','SELECT')
 OR has_table_privilege('authenticated','public.employers','TRUNCATE')
 OR has_table_privilege('anon','public.employers','SELECT')
 OR has_function_privilege('authenticated','public.check_email_exists(text)','EXECUTE')
 THEN RAISE EXCEPTION 'Forbidden privilege remains'; END IF;
 BEGIN
  UPDATE public.shift_entries SET tips=-1 WHERE user_id=auth.uid();
  RAISE EXCEPTION 'Negative tips accepted';
 EXCEPTION WHEN check_violation THEN NULL; END;
 BEGIN
  UPDATE public.shift_entries SET tips='NaN'::numeric WHERE user_id=auth.uid();
  RAISE EXCEPTION 'NaN tips accepted';
 EXCEPTION WHEN check_violation THEN NULL; END;
 BEGIN
  UPDATE public.expected_shifts SET expected_hours=25 WHERE user_id=auth.uid();
  RAISE EXCEPTION 'Invalid hours accepted';
 EXCEPTION WHEN check_violation THEN NULL; END;
 PERFORM public.delete_account();
 IF EXISTS(SELECT 1 FROM public.employers WHERE user_id=auth.uid()) THEN RAISE EXCEPTION 'Account cleanup failed'; END IF;
END $$;
RESET ROLE;
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.employers WHERE id='00000000-0000-4000-8000-000000000012') THEN RAISE EXCEPTION 'Other owner deleted'; END IF;
END $$;
SELECT 'PASS: isolation, owner checks, protected writes, overnight/zero tips, RPC totals, account cleanup; fixtures rolled back' AS result;
ROLLBACK;
