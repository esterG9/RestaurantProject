CREATE OR REPLACE FUNCTION check_apartment_price_func()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.price_per_night <= 0 THEN
        RAISE EXCEPTION 'Apartment price must be positive';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS check_apartment_price ON apartment;

CREATE TRIGGER check_apartment_price
BEFORE INSERT OR UPDATE
ON apartment
FOR EACH ROW
EXECUTE FUNCTION check_apartment_price_func();

/*
בדיקה:
UPDATE apartment
SET price_per_night = 0
WHERE apartment_id = 457;

/*
