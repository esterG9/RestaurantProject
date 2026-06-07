CREATE OR REPLACE PROCEDURE update_host_apartment_prices(
    p_host_id INT,
    p_percent NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
    new_price NUMERIC;
BEGIN

    IF p_percent <= 0 THEN
        RAISE EXCEPTION 'Percent must be positive';
    END IF;

    FOR rec IN
        SELECT apartment_id,
               price_per_night
        FROM apartment
        WHERE host_id = p_host_id
    LOOP

        new_price :=
            rec.price_per_night +
            (rec.price_per_night * p_percent / 100);

        UPDATE apartment
        SET price_per_night = new_price
        WHERE apartment_id = rec.apartment_id;

    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in update_host_apartment_prices: %', SQLERRM;
END;

$$;

/*לפני:
SELECT apartment_id,
       title,
       price_per_night
FROM apartment
WHERE host_id = 997169711;
קריאה:
CALL update_host_apartment_prices(997169711, 5);

