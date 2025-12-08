-- Add snapshot fields to shift_entries table to preserve financial data
-- This prevents historical data corruption when hourly rates or deduction percentages change

-- Add columns to shift_entries table
ALTER TABLE shift_entries
ADD COLUMN IF NOT EXISTS hourly_rate DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS gross_income DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS total_income DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS net_income DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS deduction_percentage DECIMAL(5,2);

-- Add comments to explain the purpose of these fields
COMMENT ON COLUMN shift_entries.hourly_rate IS 'Snapshot of hourly rate at time of entry creation';
COMMENT ON COLUMN shift_entries.gross_income IS 'Calculated gross pay (actual_hours × hourly_rate)';
COMMENT ON COLUMN shift_entries.total_income IS 'Total earnings (gross_income + tips + other - cash_out)';
COMMENT ON COLUMN shift_entries.net_income IS 'Estimated net income after deductions (total_income × (1 - deduction_percentage/100))';
COMMENT ON COLUMN shift_entries.deduction_percentage IS 'Snapshot of average deduction percentage used for net income calculation';

-- Backfill existing entries with calculated values from expected_shifts
UPDATE shift_entries se
SET
    hourly_rate = es.hourly_rate,
    gross_income = se.actual_hours * es.hourly_rate,
    total_income = (se.actual_hours * es.hourly_rate) + se.tips + se.other - se.cash_out,
    net_income = ((se.actual_hours * es.hourly_rate) + se.tips + se.other - se.cash_out) * 0.7, -- Assume 30% deduction for backfill
    deduction_percentage = 30.0
FROM expected_shifts es
WHERE se.shift_id = es.id
AND se.hourly_rate IS NULL;

-- Log the backfill results
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO updated_count
    FROM shift_entries
    WHERE hourly_rate IS NOT NULL;

    RAISE NOTICE 'Backfilled % shift_entries with income snapshot fields', updated_count;
END $$;
