CREATE OR REPLACE FUNCTION public.fn_get_tourist_average_rating(p_tourist_id INT)
RETURNS NUMERIC AS $$
DECLARE
    -- א. הגדרת Explicit Cursor מותאם בלי התלות ב-booking_id
    cur_reviews CURSOR FOR 
        SELECT r.rating 
        FROM public.review r
        WHERE r.tourist_id = p_tourist_id; -- חיבור ישיר לתייר בטבלת הביקורות המאוחדת
        
    -- ב. שימוש ברשומה (Record) כדי להחזיק את נתוני השורה
    r_review RECORD;
    
    v_total_rating INT := 0;
    v_review_count INT := 0;
    v_avg_rating NUMERIC(3,2) := 0.00;
BEGIN
    -- בדיקה מוקדמת אם התייר בכלל קיים במערכת
    IF NOT EXISTS (SELECT 1 FROM public.tourist WHERE tourist_id = p_tourist_id) THEN
        -- ו. שימוש ב-Exception מותאם אישית
        RAISE EXCEPTION 'Tourist with ID % does not exist in the system.', p_tourist_id;
    END IF;

    -- ה. פתיחה וריצה בלולאה (Loop) על ה-Cursor המפורש
    OPEN cur_reviews;
    LOOP
        FETCH cur_reviews INTO r_review;
        EXIT WHEN NOT FOUND; -- תנאי יציאה מהלולאה
        
        v_total_rating := v_total_rating + r_review.rating;
        v_review_count := v_review_count + 1;
    END LOOP;
    CLOSE cur_reviews;

    -- ד. הסתעפות (IF-ELSE) וטיפול במצב שאין ביקורות
    IF v_review_count = 0 THEN
        RAISE EXCEPTION 'This tourist (ID %) has not submitted any reviews yet.', p_tourist_id;
    ELSE
        v_avg_rating := ROUND(v_total_rating::NUMERIC / v_review_count, 2);
    END IF;

    RETURN v_avg_rating;

EXCEPTION
    -- ו. תפיסת החריגות והדפסת הודעה מסודרת למשתמש
    WHEN OTHERS THEN
        RAISE EXCEPTION 'An error occurred in fn_get_tourist_average_rating: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

/*
SELECT review_id, rating FROM public.review WHERE tourist_id = 358;
*/
