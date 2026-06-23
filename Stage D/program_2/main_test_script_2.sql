DO $$
DECLARE
    v_test_tourist_id INT := 358; -- נניח שאנחנו בודקים את תייר מספר 358
    v_calculated_avg NUMERIC(3,2);
BEGIN
    RAISE NOTICE '=================== RUNNING MAIN SCRIPT 1 ===================';
    
    -- 1. זימון הפונקציה הראשונה וקבלת הערך המוחזר
    v_calculated_avg := public.fn_get_tourist_average_rating(v_test_tourist_id);
    RAISE NOTICE 'The average rating given by Tourist ID % is: %', v_test_tourist_id, v_calculated_avg;
    
    RAISE NOTICE '-----------------------------------------------------------';
    
    -- 2. זימון הפרוצדורה הראשונה עם פרמטר של מינימום 2 הזמנות לקבלת הטבה
    CALL public.sp_reward_loyal_tourists(72);
    
    RAISE NOTICE '=================== SCRIPT 1 EXECUTED SUCCESSFULLY ===================';
END $$;
