DO $$
BEGIN
    RAISE NOTICE 'Starting Main Program 1';
    RAISE NOTICE 'This program checks host revenue and updates apartment prices';
END $$;


-- Step 1: show host apartments before update
SELECT apartment_id,
       title,
       price_per_night
FROM apartment
WHERE host_id = 1
ORDER BY apartment_id;


-- Step 2: calculate host revenue
SELECT host_revenue_report(1) AS total_host_revenue;


-- Step 3: update apartment prices of this host by 5 percent
CALL update_host_apartment_prices(1, 5);


-- Step 4: show host apartments after update
SELECT apartment_id,
       title,
       price_per_night
FROM apartment
WHERE host_id = 1
ORDER BY apartment_id;


DO $$
BEGIN
    RAISE NOTICE 'Main Program 1 finished successfully';
END $$;