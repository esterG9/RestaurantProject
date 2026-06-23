CREATE OR REPLACE FUNCTION host_revenue_report(p_host_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    total_revenue NUMERIC := 0;

    cur_bookings CURSOR FOR
        SELECT ab.total_price
        FROM apartmentbooking ab
        JOIN apartment a ON ab.apartment_id = a.apartment_id
        WHERE a.host_id = p_host_id;
BEGIN
    OPEN cur_bookings;

    LOOP
        FETCH cur_bookings INTO rec;
        EXIT WHEN NOT FOUND;

        IF rec.total_price IS NOT NULL THEN
            total_revenue := total_revenue + rec.total_price;
        END IF;
    END LOOP;

    CLOSE cur_bookings;

    RETURN total_revenue;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error in host_revenue_report: %', SQLERRM;
END;
$$;

/*
בדיקה:
SELECT host_revenue_report(101503157);
*/