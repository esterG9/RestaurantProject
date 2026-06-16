CREATE OR REPLACE PROCEDURE public.sp_reward_loyal_tourists(p_min_bookings INT)
AS $$
DECLARE
    -- ג. שימוש ב-Implicit Cursor בתוך לולאת FOR למעבר על רשומות
    v_tourist_record RECORD;
    v_updated_count INT := 0;
BEGIN
    RAISE NOTICE 'Starting loyalty reward program update...';

    -- לולאה שעוברת על תיירים שעומדים בקריטריון
    FOR v_tourist_record IN 
        SELECT t.tourist_id, t.first_name, t.last_name, COUNT(b.booking_id) AS booking_count
        FROM public.tourist t
        JOIN public.booking b ON t.tourist_id = b.tourist_id
        GROUP BY t.tourist_id, t.first_name, t.last_name
        HAVING COUNT(b.booking_id) >= p_min_bookings
    LOOP
        -- ד. הסתעפויות (IF-THEN) בתוך הלולאה
        IF v_tourist_record.booking_count >= 5 THEN
            RAISE NOTICE 'Tourist % % (ID: %) is a VIP customer with % bookings.', 
                v_tourist_record.first_name, v_tourist_record.last_name, v_tourist_record.tourist_id, v_tourist_record.booking_count;
        ELSE
            RAISE NOTICE 'Tourist % % (ID: %) is a Regular customer with % bookings.', 
                v_tourist_record.first_name, v_tourist_record.last_name, v_tourist_record.tourist_id, v_tourist_record.booking_count;
        END IF;
        
        v_updated_count := v_updated_count + 1;
    END LOOP;
    

    RAISE NOTICE 'Loyalty reward program compilation completed. Total analyzed: %', v_updated_count;
    
    -- הערה: בגלל שפרוצדורה מאפשרת ניהול טרנזקציות, בסוף הפעולה מתבצע ה-COMMIT אוטומטית או ידנית
    COMMIT;
END;
$$ LANGUAGE plpgsql;

/*

קריאה:
CALL public.sp_reward_loyal_tourists(72);
*/
