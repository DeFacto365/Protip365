-- Check the actual structure of shift_income table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'shift_income' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Also check if the table exists
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('shift_income', 'shifts', 'employers');
