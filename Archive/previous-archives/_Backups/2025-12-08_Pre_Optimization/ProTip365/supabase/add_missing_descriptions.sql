-- Add descriptions to existing tables that don't have them
COMMENT ON TABLE public.employers IS 'Stores employer/workplace information for users';
COMMENT ON TABLE public.shifts IS 'Stores work shift records with hours, tips, and sales data';
COMMENT ON TABLE public.users_profile IS 'Main user profile with settings, preferences, and targets';

-- Check if entries table exists, if not create it
CREATE TABLE IF NOT EXISTS public.entries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    employer_id UUID REFERENCES public.employers(id) ON DELETE SET NULL,
    entry_date DATE NOT NULL,
    sales DECIMAL(10,2) DEFAULT 0,
    tips DECIMAL(10,2) DEFAULT 0,
    hourly_rate DECIMAL(10,2) DEFAULT 0,
    cash_out DECIMAL(10,2) DEFAULT 0,
    other DECIMAL(10,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add description for entries table
COMMENT ON TABLE public.entries IS 'Stores quick income entries without hours for tip tracking';

-- Create indexes for entries table if they don't exist
CREATE INDEX IF NOT EXISTS idx_entries_user_id ON public.entries(user_id);
CREATE INDEX IF NOT EXISTS idx_entries_entry_date ON public.entries(entry_date DESC);
CREATE INDEX IF NOT EXISTS idx_entries_employer_id ON public.entries(employer_id);

-- Enable RLS on entries table
ALTER TABLE public.entries ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for entries table
DROP POLICY IF EXISTS "Users can view own entries" ON public.entries;
CREATE POLICY "Users can view own entries" ON public.entries
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own entries" ON public.entries;
CREATE POLICY "Users can insert own entries" ON public.entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own entries" ON public.entries;
CREATE POLICY "Users can update own entries" ON public.entries
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own entries" ON public.entries;
CREATE POLICY "Users can delete own entries" ON public.entries
    FOR DELETE USING (auth.uid() = user_id);

-- Now verify ALL tables exist with descriptions
SELECT
    table_name,
    COALESCE(obj_description(pgc.oid, 'pg_class'), 'No description') as description,
    CASE
        WHEN table_name IN ('users_profile', 'employers', 'shifts', 'entries',
                           'achievements', 'alerts', 'user_subscriptions')
        THEN '✅ Required'
        ELSE '⚠️ Extra'
    END as status
FROM information_schema.tables t
LEFT JOIN pg_class pgc ON pgc.relname = t.table_name
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
AND table_name NOT LIKE '%_id_seq'
ORDER BY
    CASE
        WHEN table_name IN ('users_profile', 'employers', 'shifts', 'entries',
                           'achievements', 'alerts', 'user_subscriptions')
        THEN 0
        ELSE 1
    END,
    table_name;