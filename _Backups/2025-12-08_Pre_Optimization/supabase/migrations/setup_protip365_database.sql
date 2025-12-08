-- ProTip365 Database Setup Script
-- Run this script in your Supabase SQL editor to create the necessary tables and secure them

-- Create employers table
CREATE TABLE IF NOT EXISTS employers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    hourly_rate DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create shifts table
CREATE TABLE IF NOT EXISTS shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    employer_id UUID REFERENCES employers(id) ON DELETE SET NULL,
    shift_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    expected_hours DECIMAL(5,2) NOT NULL,
    lunch_break_minutes INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create shift_income table
CREATE TABLE IF NOT EXISTS shift_income (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_id UUID REFERENCES shifts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    actual_hours DECIMAL(5,2) NOT NULL,
    sales DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    tips DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    cash_out DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    other DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    actual_start_time TIME,
    actual_end_time TIME,
    shift_date DATE NOT NULL,
    employer_id UUID REFERENCES employers(id) ON DELETE SET NULL,
    hourly_rate DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    lunch_break_minutes INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create v_shift_income view
CREATE OR REPLACE VIEW v_shift_income AS
SELECT 
    si.id,
    si.shift_id,
    si.user_id,
    si.actual_hours,
    si.sales,
    si.tips,
    si.cash_out,
    si.other,
    si.actual_start_time,
    si.actual_end_time,
    si.shift_date,
    si.employer_id,
    si.hourly_rate,
    si.lunch_break_minutes,
    si.status,
    si.created_at,
    si.updated_at,
    e.name as employer_name,
    -- Calculate total income
    (si.sales + si.tips + si.other - si.cash_out) as total_income,
    -- Calculate hourly wage
    CASE 
        WHEN si.actual_hours > 0 THEN 
            (si.sales + si.tips + si.other - si.cash_out) / si.actual_hours
        ELSE 0
    END as hourly_wage,
    -- Calculate base pay
    (si.hourly_rate * si.actual_hours) as base_pay,
    -- Calculate tip percentage
    CASE 
        WHEN si.sales > 0 THEN 
            (si.tips / si.sales) * 100
        ELSE 0
    END as tip_percentage
FROM shift_income si
LEFT JOIN employers e ON si.employer_id = e.id;

-- Enable RLS on all tables
ALTER TABLE employers ENABLE ROW LEVEL SECURITY;
ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_income ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for employers table
CREATE POLICY "Users can view their own employers" ON employers
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own employers" ON employers
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own employers" ON employers
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own employers" ON employers
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for shifts table
CREATE POLICY "Users can view their own shifts" ON shifts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own shifts" ON shifts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own shifts" ON shifts
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own shifts" ON shifts
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for shift_income table
CREATE POLICY "Users can view their own shift income" ON shift_income
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own shift income" ON shift_income
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own shift income" ON shift_income
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own shift income" ON shift_income
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policy for v_shift_income view
CREATE POLICY "Users can view their own shift income data" ON v_shift_income
    FOR SELECT USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_employers_user_id ON employers(user_id);
CREATE INDEX IF NOT EXISTS idx_shifts_user_id ON shifts(user_id);
CREATE INDEX IF NOT EXISTS idx_shifts_employer_id ON shifts(employer_id);
CREATE INDEX IF NOT EXISTS idx_shifts_date ON shifts(shift_date);
CREATE INDEX IF NOT EXISTS idx_shift_income_user_id ON shift_income(user_id);
CREATE INDEX IF NOT EXISTS idx_shift_income_shift_id ON shift_income(shift_id);
CREATE INDEX IF NOT EXISTS idx_shift_income_employer_id ON shift_income(employer_id);
CREATE INDEX IF NOT EXISTS idx_shift_income_date ON shift_income(shift_date);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update updated_at
CREATE TRIGGER update_employers_updated_at BEFORE UPDATE ON employers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shifts_updated_at BEFORE UPDATE ON shifts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shift_income_updated_at BEFORE UPDATE ON shift_income
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert some sample data for testing (optional)
INSERT INTO employers (id, user_id, name, hourly_rate, active) VALUES
    (gen_random_uuid(), auth.uid(), 'Big John Bar', 15.00, true),
    (gen_random_uuid(), auth.uid(), 'The Place to Eat', 14.00, true),
    (gen_random_uuid(), auth.uid(), 'El Paso Bar', 16.00, true)
ON CONFLICT DO NOTHING;

