-- Canonical ProTip365 app tables.
--
-- RFP-205: keep the normal Supabase migration chain replayable for the live
-- app schema. Production already uses expected_shifts + shift_entries through
-- ProTip365Shared/src/lib/protipData.ts; this migration is intentionally
-- idempotent and does not drop or migrate production data.

CREATE TABLE IF NOT EXISTS public.users_profile (
    user_id UUID PRIMARY KEY,
    default_hourly_rate DECIMAL(10,2) DEFAULT 0,
    week_start INTEGER DEFAULT 0,
    target_tip_daily DECIMAL(10,2) DEFAULT 0,
    target_tip_weekly DECIMAL(10,2) DEFAULT 0,
    target_tip_monthly DECIMAL(10,2) DEFAULT 0,
    target_sales_daily DECIMAL(10,2) DEFAULT 0,
    target_sales_weekly DECIMAL(10,2) DEFAULT 0,
    target_sales_monthly DECIMAL(10,2) DEFAULT 0,
    target_hours_daily DECIMAL(10,2) DEFAULT 0,
    target_hours_weekly DECIMAL(10,2) DEFAULT 0,
    target_hours_monthly DECIMAL(10,2) DEFAULT 0,
    tip_target_percentage DECIMAL(10,2) DEFAULT 0,
    name TEXT,
    language VARCHAR(10) DEFAULT 'en',
    preferred_language VARCHAR(10),
    use_multiple_employers BOOLEAN DEFAULT false,
    default_employer_id UUID,
    has_variable_schedule BOOLEAN DEFAULT false,
    average_deduction_percentage DECIMAL(5,2) DEFAULT 0,
    default_alert_minutes INTEGER DEFAULT 60,
    onboarding_completed BOOLEAN DEFAULT false,
    security_type TEXT DEFAULT 'none',
    pin_code_hash TEXT,
    biometric_enabled BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_users_profile_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT users_profile_default_alert_minutes_check CHECK (default_alert_minutes IS NULL OR default_alert_minutes >= 0)
);

CREATE TABLE IF NOT EXISTS public.employers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    name TEXT NOT NULL,
    hourly_rate DECIMAL(10,2) DEFAULT 0,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_employers_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.expected_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    employer_id UUID,
    shift_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    expected_hours DECIMAL(5,2) NOT NULL,
    hourly_rate DECIMAL(10,2) NOT NULL,
    lunch_break_minutes INTEGER NOT NULL DEFAULT 0,
    status TEXT DEFAULT 'planned',
    alert_minutes INTEGER,
    sales_target DECIMAL(10,2),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_expected_shifts_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT fk_expected_shifts_employer_id FOREIGN KEY (employer_id) REFERENCES public.employers(id) ON DELETE SET NULL,
    CONSTRAINT expected_shifts_status_check CHECK (status IN ('planned', 'completed', 'missed')),
    CONSTRAINT expected_shifts_alert_minutes_check CHECK (alert_minutes IS NULL OR alert_minutes >= 0)
);

CREATE TABLE IF NOT EXISTS public.shift_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_id UUID NOT NULL,
    user_id UUID NOT NULL,
    actual_start_time TIME NOT NULL,
    actual_end_time TIME NOT NULL,
    actual_hours DECIMAL(5,2) NOT NULL,
    sales DECIMAL(10,2) DEFAULT 0,
    tips DECIMAL(10,2) DEFAULT 0,
    cash_out DECIMAL(10,2) DEFAULT 0,
    other DECIMAL(10,2) DEFAULT 0,
    hourly_rate DECIMAL(10,2),
    gross_income DECIMAL(10,2),
    total_income DECIMAL(10,2),
    net_income DECIMAL(10,2),
    deduction_percentage DECIMAL(5,2),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_shift_entries_shift_id FOREIGN KEY (shift_id) REFERENCES public.expected_shifts(id) ON DELETE CASCADE,
    CONSTRAINT fk_shift_entries_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT shift_entries_shift_id_key UNIQUE (shift_id)
);

ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS default_hourly_rate DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS week_start INTEGER DEFAULT 0;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS target_tip_daily DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS target_tip_weekly DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS target_tip_monthly DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS target_sales_daily DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS target_sales_weekly DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS target_sales_monthly DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS target_hours_daily DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS target_hours_weekly DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS target_hours_monthly DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS tip_target_percentage DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS language VARCHAR(10) DEFAULT 'en';
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(10);
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS use_multiple_employers BOOLEAN DEFAULT false;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS default_employer_id UUID;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS has_variable_schedule BOOLEAN DEFAULT false;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS average_deduction_percentage DECIMAL(5,2) DEFAULT 0;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS default_alert_minutes INTEGER DEFAULT 60;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT false;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS security_type TEXT DEFAULT 'none';
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS pin_code_hash TEXT;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS biometric_enabled BOOLEAN DEFAULT false;
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.users_profile ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE public.employers ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE public.employers ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.employers ADD COLUMN IF NOT EXISTS hourly_rate DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.employers ADD COLUMN IF NOT EXISTS active BOOLEAN DEFAULT true;
ALTER TABLE public.employers ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.employers ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE public.expected_shifts ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE public.expected_shifts ADD COLUMN IF NOT EXISTS employer_id UUID;
ALTER TABLE public.expected_shifts ADD COLUMN IF NOT EXISTS shift_date DATE;
ALTER TABLE public.expected_shifts ADD COLUMN IF NOT EXISTS start_time TIME;
ALTER TABLE public.expected_shifts ADD COLUMN IF NOT EXISTS end_time TIME;
ALTER TABLE public.expected_shifts ADD COLUMN IF NOT EXISTS expected_hours DECIMAL(5,2);
ALTER TABLE public.expected_shifts ADD COLUMN IF NOT EXISTS hourly_rate DECIMAL(10,2);
ALTER TABLE public.expected_shifts ADD COLUMN IF NOT EXISTS lunch_break_minutes INTEGER DEFAULT 0;
ALTER TABLE public.expected_shifts ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'planned';
ALTER TABLE public.expected_shifts ADD COLUMN IF NOT EXISTS alert_minutes INTEGER;
ALTER TABLE public.expected_shifts ADD COLUMN IF NOT EXISTS sales_target DECIMAL(10,2);
ALTER TABLE public.expected_shifts ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE public.expected_shifts ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.expected_shifts ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE public.shift_entries ADD COLUMN IF NOT EXISTS shift_id UUID;
ALTER TABLE public.shift_entries ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE public.shift_entries ADD COLUMN IF NOT EXISTS actual_start_time TIME;
ALTER TABLE public.shift_entries ADD COLUMN IF NOT EXISTS actual_end_time TIME;
ALTER TABLE public.shift_entries ADD COLUMN IF NOT EXISTS actual_hours DECIMAL(5,2);
ALTER TABLE public.shift_entries ADD COLUMN IF NOT EXISTS sales DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.shift_entries ADD COLUMN IF NOT EXISTS tips DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.shift_entries ADD COLUMN IF NOT EXISTS cash_out DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.shift_entries ADD COLUMN IF NOT EXISTS other DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.shift_entries ADD COLUMN IF NOT EXISTS hourly_rate DECIMAL(10,2);
ALTER TABLE public.shift_entries ADD COLUMN IF NOT EXISTS gross_income DECIMAL(10,2);
ALTER TABLE public.shift_entries ADD COLUMN IF NOT EXISTS total_income DECIMAL(10,2);
ALTER TABLE public.shift_entries ADD COLUMN IF NOT EXISTS net_income DECIMAL(10,2);
ALTER TABLE public.shift_entries ADD COLUMN IF NOT EXISTS deduction_percentage DECIMAL(5,2);
ALTER TABLE public.shift_entries ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE public.shift_entries ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.shift_entries ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_users_profile_user_id'
          AND conrelid = 'public.users_profile'::regclass
    ) THEN
        ALTER TABLE public.users_profile
        ADD CONSTRAINT fk_users_profile_user_id
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_users_profile_default_employer'
          AND conrelid = 'public.users_profile'::regclass
    ) THEN
        ALTER TABLE public.users_profile
        ADD CONSTRAINT fk_users_profile_default_employer
        FOREIGN KEY (default_employer_id) REFERENCES public.employers(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_employers_user_id'
          AND conrelid = 'public.employers'::regclass
    ) THEN
        ALTER TABLE public.employers
        ADD CONSTRAINT fk_employers_user_id
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_expected_shifts_user_id'
          AND conrelid = 'public.expected_shifts'::regclass
    ) THEN
        ALTER TABLE public.expected_shifts
        ADD CONSTRAINT fk_expected_shifts_user_id
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_expected_shifts_employer_id'
          AND conrelid = 'public.expected_shifts'::regclass
    ) THEN
        ALTER TABLE public.expected_shifts
        ADD CONSTRAINT fk_expected_shifts_employer_id
        FOREIGN KEY (employer_id) REFERENCES public.employers(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_shift_entries_shift_id'
          AND conrelid = 'public.shift_entries'::regclass
    ) THEN
        ALTER TABLE public.shift_entries
        ADD CONSTRAINT fk_shift_entries_shift_id
        FOREIGN KEY (shift_id) REFERENCES public.expected_shifts(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fk_shift_entries_user_id'
          AND conrelid = 'public.shift_entries'::regclass
    ) THEN
        ALTER TABLE public.shift_entries
        ADD CONSTRAINT fk_shift_entries_user_id
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'shift_entries_shift_id_key'
          AND conrelid = 'public.shift_entries'::regclass
    ) THEN
        ALTER TABLE public.shift_entries
        ADD CONSTRAINT shift_entries_shift_id_key UNIQUE (shift_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'expected_shifts_status_check'
          AND conrelid = 'public.expected_shifts'::regclass
    ) THEN
        ALTER TABLE public.expected_shifts
        ADD CONSTRAINT expected_shifts_status_check
        CHECK (status IN ('planned', 'completed', 'missed'));
    END IF;

    ALTER TABLE public.expected_shifts DROP CONSTRAINT IF EXISTS expected_shifts_alert_minutes_check;
    ALTER TABLE public.expected_shifts
    ADD CONSTRAINT expected_shifts_alert_minutes_check
    CHECK (alert_minutes IS NULL OR alert_minutes >= 0);

    ALTER TABLE public.users_profile DROP CONSTRAINT IF EXISTS check_default_alert_minutes;
    ALTER TABLE public.users_profile DROP CONSTRAINT IF EXISTS users_profile_default_alert_minutes_check;
    ALTER TABLE public.users_profile
    ADD CONSTRAINT users_profile_default_alert_minutes_check
    CHECK (default_alert_minutes IS NULL OR default_alert_minutes >= 0);
END $$;

CREATE INDEX IF NOT EXISTS idx_users_profile_default_employer_id ON public.users_profile(default_employer_id);
CREATE INDEX IF NOT EXISTS idx_users_profile_security ON public.users_profile(user_id, security_type);
CREATE INDEX IF NOT EXISTS idx_employers_user_id ON public.employers(user_id);
CREATE INDEX IF NOT EXISTS idx_employers_active ON public.employers(user_id, active) WHERE active = true;
CREATE INDEX IF NOT EXISTS idx_expected_shifts_user_id ON public.expected_shifts(user_id);
CREATE INDEX IF NOT EXISTS idx_expected_shifts_employer_id ON public.expected_shifts(employer_id);
CREATE INDEX IF NOT EXISTS idx_expected_shifts_date ON public.expected_shifts(shift_date);
CREATE INDEX IF NOT EXISTS idx_expected_shifts_status ON public.expected_shifts(status);
CREATE INDEX IF NOT EXISTS idx_expected_shifts_user_date ON public.expected_shifts(user_id, shift_date DESC);
CREATE INDEX IF NOT EXISTS idx_expected_shifts_alert_lookup
ON public.expected_shifts(user_id, shift_date, start_time, alert_minutes)
WHERE alert_minutes IS NOT NULL AND status = 'planned';
CREATE INDEX IF NOT EXISTS idx_shift_entries_user_id ON public.shift_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_shift_entries_shift_id ON public.shift_entries(shift_id);

ALTER TABLE public.users_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expected_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shift_entries ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
    policy_name TEXT;
BEGIN
    FOREACH policy_name IN ARRAY ARRAY[
        'Users can view own profile',
        'Users can insert own profile',
        'Users can update own profile',
        'Users can delete own profile'
    ] LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.users_profile', policy_name);
    END LOOP;

    FOREACH policy_name IN ARRAY ARRAY[
        'Users can view own employers',
        'Users can create own employers',
        'Users can insert own employers',
        'Users can update own employers',
        'Users can delete own employers',
        'employers_policy'
    ] LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.employers', policy_name);
    END LOOP;

    FOREACH policy_name IN ARRAY ARRAY[
        'Users can view own expected shifts',
        'Users can create own expected shifts',
        'Users can insert own expected shifts',
        'Users can update own expected shifts',
        'Users can delete own expected shifts'
    ] LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.expected_shifts', policy_name);
    END LOOP;

    FOREACH policy_name IN ARRAY ARRAY[
        'Users can view own shift entries',
        'Users can create own shift entries',
        'Users can insert own shift entries',
        'Users can update own shift entries',
        'Users can delete own shift entries'
    ] LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.shift_entries', policy_name);
    END LOOP;
END $$;

CREATE POLICY "Users can view own profile" ON public.users_profile
    FOR SELECT TO authenticated
    USING ((SELECT auth.uid()) = user_id);
CREATE POLICY "Users can insert own profile" ON public.users_profile
    FOR INSERT TO authenticated
    WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "Users can update own profile" ON public.users_profile
    FOR UPDATE TO authenticated
    USING ((SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "Users can delete own profile" ON public.users_profile
    FOR DELETE TO authenticated
    USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can view own employers" ON public.employers
    FOR SELECT TO authenticated
    USING ((SELECT auth.uid()) = user_id);
CREATE POLICY "Users can insert own employers" ON public.employers
    FOR INSERT TO authenticated
    WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "Users can update own employers" ON public.employers
    FOR UPDATE TO authenticated
    USING ((SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "Users can delete own employers" ON public.employers
    FOR DELETE TO authenticated
    USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can view own expected shifts" ON public.expected_shifts
    FOR SELECT TO authenticated
    USING ((SELECT auth.uid()) = user_id);
CREATE POLICY "Users can insert own expected shifts" ON public.expected_shifts
    FOR INSERT TO authenticated
    WITH CHECK (
        (SELECT auth.uid()) = user_id
        AND (
            employer_id IS NULL
            OR EXISTS (
                SELECT 1
                FROM public.employers e
                WHERE e.id = employer_id
                  AND e.user_id = (SELECT auth.uid())
            )
        )
    );
CREATE POLICY "Users can update own expected shifts" ON public.expected_shifts
    FOR UPDATE TO authenticated
    USING ((SELECT auth.uid()) = user_id)
    WITH CHECK (
        (SELECT auth.uid()) = user_id
        AND (
            employer_id IS NULL
            OR EXISTS (
                SELECT 1
                FROM public.employers e
                WHERE e.id = employer_id
                  AND e.user_id = (SELECT auth.uid())
            )
        )
    );
CREATE POLICY "Users can delete own expected shifts" ON public.expected_shifts
    FOR DELETE TO authenticated
    USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can view own shift entries" ON public.shift_entries
    FOR SELECT TO authenticated
    USING ((SELECT auth.uid()) = user_id);
CREATE POLICY "Users can insert own shift entries" ON public.shift_entries
    FOR INSERT TO authenticated
    WITH CHECK (
        (SELECT auth.uid()) = user_id
        AND EXISTS (
            SELECT 1
            FROM public.expected_shifts es
            WHERE es.id = shift_id
              AND es.user_id = (SELECT auth.uid())
        )
    );
CREATE POLICY "Users can update own shift entries" ON public.shift_entries
    FOR UPDATE TO authenticated
    USING ((SELECT auth.uid()) = user_id)
    WITH CHECK (
        (SELECT auth.uid()) = user_id
        AND EXISTS (
            SELECT 1
            FROM public.expected_shifts es
            WHERE es.id = shift_id
              AND es.user_id = (SELECT auth.uid())
        )
    );
CREATE POLICY "Users can delete own shift entries" ON public.shift_entries
    FOR DELETE TO authenticated
    USING ((SELECT auth.uid()) = user_id);

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.users_profile TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.employers TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.expected_shifts TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.shift_entries TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.users_profile TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.employers TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.expected_shifts TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.shift_entries TO service_role;

COMMENT ON TABLE public.users_profile IS 'User profile and app preferences for ProTip365.';
COMMENT ON TABLE public.employers IS 'User-owned employer records for ProTip365.';
COMMENT ON TABLE public.expected_shifts IS 'Source of truth for planned ProTip365 shifts used by the mobile app.';
COMMENT ON TABLE public.shift_entries IS 'Source of truth for completed shift earnings linked one-to-one to expected_shifts.';
COMMENT ON COLUMN public.users_profile.tip_target_percentage IS 'DEPRECATED: use target_tip_daily, target_tip_weekly, and target_tip_monthly.';
COMMENT ON COLUMN public.users_profile.default_employer_id IS 'Default employer selected by user for quick shift entry forms.';
COMMENT ON COLUMN public.users_profile.average_deduction_percentage IS 'Default deduction percentage copied into shift_entries for net income snapshots.';
COMMENT ON COLUMN public.expected_shifts.shift_date IS 'Calendar date for the planned shift.';
COMMENT ON COLUMN public.expected_shifts.alert_minutes IS 'Optional nonnegative alert lead time in minutes.';
COMMENT ON COLUMN public.expected_shifts.sales_target IS 'Optional per-shift sales target; NULL uses the user default target.';
COMMENT ON COLUMN public.shift_entries.hourly_rate IS 'Snapshot of hourly rate at time of entry creation.';
COMMENT ON COLUMN public.shift_entries.gross_income IS 'Calculated gross pay snapshot.';
COMMENT ON COLUMN public.shift_entries.total_income IS 'Total earnings snapshot.';
COMMENT ON COLUMN public.shift_entries.net_income IS 'Estimated net income snapshot after deductions.';
COMMENT ON COLUMN public.shift_entries.deduction_percentage IS 'Snapshot of average deduction percentage used for net income calculation.';
