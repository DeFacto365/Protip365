-- Check the actual columns in shift_income table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'shift_income' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Also check shifts table columns for reference
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'shifts' 
AND table_schema = 'public'
ORDER BY ordinal_position;
