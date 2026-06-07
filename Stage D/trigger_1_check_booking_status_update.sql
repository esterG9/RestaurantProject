CREATE OR REPLACE FUNCTION check_booking_status_update_func()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.status NOT IN ('Pending', 'Confirmed', 'Cancelled', 'Completed') THEN
        RAISE EXCEPTION 'Invalid booking status: %', NEW.status;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS check_booking_status_update ON booking;

CREATE TRIGGER check_booking_status_update
BEFORE UPDATE
ON booking
FOR EACH ROW
EXECUTE FUNCTION check_booking_status_update_func();

/*
בדיקה:
UPDATE booking
SET status = 'InvalidStatus'
WHERE booking_id = 1;
*/