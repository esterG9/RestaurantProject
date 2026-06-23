CREATE TABLE IF NOT EXISTS tourist_tenth_review (
    tourist_id INT PRIMARY KEY,
    tenth_review_date DATE DEFAULT CURRENT_DATE
);

CREATE OR REPLACE FUNCTION add_tourist_after_10_reviews_func()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    review_count INT;
BEGIN
    SELECT COUNT(*)
    INTO review_count
    FROM review
    WHERE tourist_id = NEW.tourist_id;

    IF review_count >= 10 THEN
        INSERT INTO tourist_tenth_review (
            tourist_id,
            tenth_review_date
        )
        VALUES (
            NEW.tourist_id,
            CURRENT_DATE
        )
        ON CONFLICT (tourist_id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS add_tourist_after_10_reviews ON review;

CREATE TRIGGER add_tourist_after_10_reviews
AFTER INSERT
ON review
FOR EACH ROW
EXECUTE FUNCTION add_tourist_after_10_reviews_func();