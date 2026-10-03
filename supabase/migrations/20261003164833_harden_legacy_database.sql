-- Preserve existing legacy dollar amounts; this is not the new app's cents-based store.
DO $$
DECLARE t text; p record;
BEGIN
 FOR t IN SELECT tablename FROM pg_tables WHERE schemaname='public' LOOP
  EXECUTE format('REVOKE ALL ON TABLE public.%I FROM anon, authenticated', t);
 END LOOP;
 FOR p IN SELECT tablename, policyname FROM pg_policies WHERE schemaname='public' LOOP
  EXECUTE format('DROP POLICY %I ON public.%I',p.policyname,p.tablename);
 END LOOP;
 FOREACH t IN ARRAY ARRAY['users_profile','employers','expected_shifts','shift_entries','achievements','alerts'] LOOP
  EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated',t);
  EXECUTE format('CREATE POLICY owner_select ON public.%I FOR SELECT TO authenticated USING ((select auth.uid()) = user_id)',t);
  EXECUTE format('CREATE POLICY owner_insert ON public.%I FOR INSERT TO authenticated WITH CHECK ((select auth.uid()) = user_id)',t);
  EXECUTE format('CREATE POLICY owner_update ON public.%I FOR UPDATE TO authenticated USING ((select auth.uid()) = user_id) WITH CHECK ((select auth.uid()) = user_id)',t);
  EXECUTE format('CREATE POLICY owner_delete ON public.%I FOR DELETE TO authenticated USING ((select auth.uid()) = user_id)',t);
 END LOOP;
 FOREACH t IN ARRAY ARRAY['user_subscriptions','security_audit_log'] LOOP
  EXECUTE format('GRANT SELECT ON public.%I TO authenticated',t);
  EXECUTE format('CREATE POLICY owner_select ON public.%I FOR SELECT TO authenticated USING ((select auth.uid()) = user_id)',t);
 END LOOP;
END $$;
CREATE POLICY backend_only ON public.password_reset_tokens TO service_role USING (true) WITH CHECK (true);
CREATE POLICY backend_only ON public.performance_baseline TO service_role USING (true) WITH CHECK (true);
REVOKE USAGE ON SCHEMA monitoring FROM authenticated, anon;
REVOKE ALL ON ALL TABLES IN SCHEMA monitoring FROM authenticated, anon;
CREATE INDEX IF NOT EXISTS employers_user_id_idx ON public.employers(user_id);
CREATE INDEX IF NOT EXISTS password_reset_tokens_user_id_idx ON public.password_reset_tokens(user_id);
CREATE INDEX IF NOT EXISTS users_profile_default_employer_id_idx ON public.users_profile(default_employer_id);
ALTER TABLE public.employers ADD CONSTRAINT employers_id_owner_key UNIQUE(id,user_id);
ALTER TABLE public.expected_shifts ADD CONSTRAINT expected_shifts_id_owner_key UNIQUE(id,user_id);
ALTER TABLE public.expected_shifts ADD CONSTRAINT expected_shifts_employer_owner_fk FOREIGN KEY(employer_id,user_id) REFERENCES public.employers(id,user_id);
ALTER TABLE public.shift_entries ADD CONSTRAINT shift_entries_shift_owner_fk FOREIGN KEY(shift_id,user_id) REFERENCES public.expected_shifts(id,user_id) ON DELETE CASCADE;
ALTER TABLE public.users_profile ADD CONSTRAINT users_profile_employer_owner_fk FOREIGN KEY(default_employer_id,user_id) REFERENCES public.employers(id,user_id);
CREATE OR REPLACE FUNCTION public.get_calendar_shifts(p_user_id uuid,p_start_date date,p_end_date date)
RETURNS TABLE(shift_date date,shift_count bigint,total_hours numeric,total_tips numeric,total_sales numeric,has_completed boolean)
LANGUAGE sql STABLE SECURITY INVOKER SET search_path=pg_catalog,public AS $$
 SELECT s.shift_date,count(*),sum(coalesce(e.actual_hours,s.expected_hours)),
 sum(coalesce(e.tips,0)),sum(coalesce(e.sales,0)),bool_or(s.status='completed' OR e.id IS NOT NULL)
 FROM public.expected_shifts s LEFT JOIN public.shift_entries e ON e.shift_id=s.id AND e.user_id=s.user_id
 WHERE s.user_id=p_user_id AND s.shift_date BETWEEN p_start_date AND p_end_date GROUP BY s.shift_date ORDER BY s.shift_date
$$;
CREATE OR REPLACE FUNCTION public.get_recent_shifts(p_user_id uuid,p_days integer DEFAULT 30)
RETURNS TABLE(id uuid,shift_date date,hours numeric,hourly_rate numeric,sales numeric,tips numeric,employer_id uuid,status text)
LANGUAGE sql STABLE SECURITY INVOKER SET search_path=pg_catalog,public AS $$
 SELECT s.id,s.shift_date,coalesce(e.actual_hours,s.expected_hours),coalesce(e.hourly_rate,s.hourly_rate),
 coalesce(e.sales,0),coalesce(e.tips,0),s.employer_id,s.status
 FROM public.expected_shifts s LEFT JOIN public.shift_entries e ON e.shift_id=s.id AND e.user_id=s.user_id
 WHERE s.user_id=p_user_id AND s.shift_date >= CURRENT_DATE - p_days ORDER BY s.shift_date DESC
$$;
CREATE OR REPLACE FUNCTION public.delete_account() RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,public AS $$
DECLARE owner_id uuid := auth.uid();
BEGIN
 IF owner_id IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
 DELETE FROM public.shift_entries WHERE user_id=owner_id;
 DELETE FROM public.expected_shifts WHERE user_id=owner_id;
 DELETE FROM public.achievements WHERE user_id=owner_id;
 DELETE FROM public.alerts WHERE user_id=owner_id;
 DELETE FROM public.password_reset_tokens WHERE user_id=owner_id;
 DELETE FROM public.user_subscriptions WHERE user_id=owner_id;
 DELETE FROM public.security_audit_log WHERE user_id=owner_id;
 DELETE FROM public.users_profile WHERE user_id=owner_id;
 DELETE FROM public.employers WHERE user_id=owner_id;
END $$;
CREATE OR REPLACE FUNCTION public.handle_new_user_safe() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,public AS $$
BEGIN
 INSERT INTO public.users_profile(user_id,name,preferred_language)
 VALUES(NEW.id,coalesce(NEW.raw_user_meta_data->>'name',''),
 CASE WHEN NEW.raw_user_meta_data->>'preferred_language' IN ('en','fr','es')
 THEN NEW.raw_user_meta_data->>'preferred_language' ELSE 'en' END)
 ON CONFLICT(user_id) DO NOTHING;
 RETURN NEW;
END $$;
ALTER FUNCTION public.check_email_exists(text) SET search_path=pg_catalog;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC,anon;
REVOKE EXECUTE ON FUNCTION public.check_email_exists(text),public.handle_new_user_safe(),public.log_security_event(text,uuid,jsonb) FROM authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO service_role;
GRANT EXECUTE ON FUNCTION public.get_calendar_shifts(uuid,date,date),public.get_recent_shifts(uuid,integer),public.delete_account(),public.check_password_strength(text),public.is_common_password(text) TO authenticated;
