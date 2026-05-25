ALTER TABLE tourist RENAME TO tourist1;
ALTER TABLE booking RENAME TO booking1;

ALTER TABLE tourist1
ADD COLUMN IF NOT EXISTS passport_number VARCHAR(20);

ALTER TABLE booking1
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(50);

ALTER TABLE TOURIST1 ALTER COLUMN language DROP NOT NULL;

-- הסרת שדות הטקסט החופשי של עיר ומדינה מהטבלה של חברתך
ALTER TABLE LOCATION DROP COLUMN City;
ALTER TABLE LOCATION DROP COLUMN Country;

-- הוספת מפתח זר המקשר לעיר מהטבלה שלך
ALTER TABLE LOCATION ADD COLUMN CityID INT;
ALTER TABLE LOCATION ADD CONSTRAINT fk_location_city 
    FOREIGN KEY (CityID) REFERENCES CITY(City_ID);
    
-- (אופציונלי) הגדרת השדה כ-NOT NULL לאחר שיוך הנתונים
-- ALTER TABLE LOCATION ALTER COLUMN CityID SET NOT NULL;

ALTER TABLE BOOKING1 DROP COLUMN Rest_ID;
ALTER TABLE BOOKING1 DROP COLUMN Num_Of_People;

CREATE TABLE RESTAURANTBOOKING
(
  Booking_ID INT NOT NULL,
  Num_Of_People INT NOT NULL,
  Rest_ID INT NOT NULL,
  
  PRIMARY KEY (Booking_ID),
  -- מפתח זר שמקשר לטבלת ה-BOOKING המרכזית שלך
  FOREIGN KEY (Booking_ID) REFERENCES BOOKING1(Booking_ID) ON DELETE CASCADE,
  -- מפתח זר למסעדות שלך
  FOREIGN KEY (Rest_ID) REFERENCES RESTAURANT(Rest_ID),
  -- האילוץ המקורי שלך על כמות האנשים
  CONSTRAINT chk_num_people CHECK (Num_Of_People > 0)
);

ALTER TABLE APARTMENTBOOKING 
  ALTER COLUMN Booking_ID TYPE INT;

  DELETE FROM APARTMENTBOOKING 
WHERE Booking_ID NOT IN (SELECT Booking_ID FROM BOOKING1);

ALTER TABLE APARTMENTBOOKING 
  ADD CONSTRAINT fk_apartment_to_my_booking1 
  FOREIGN KEY (Booking_ID) REFERENCES BOOKING1(Booking_ID) ON DELETE CASCADE;

  ALTER TABLE review
ADD COLUMN IF NOT EXISTS review_title VARCHAR(100);

ALTER TABLE tourist1
ALTER COLUMN language DROP NOT NULL;

ALTER TABLE tourist1
ALTER COLUMN password DROP NOT NULL;

ALTER TABLE tourist1
ALTER COLUMN birthday DROP NOT NULL;

ALTER TABLE tourist1
ALTER COLUMN user_name DROP NOT NULL;

WITH numbered_tourists AS (
    SELECT
        t.*,
        ROW_NUMBER() OVER (ORDER BY t.tourist_id) + 500 AS new_tourist_id
    FROM tourist t
)
INSERT INTO tourist1 (
    tourist_id,
    first_name,
    last_name,
    email,
    phone,
    passport_number
)
SELECT
    new_tourist_id,
    first_name,
    last_name,

    CASE
        WHEN EXISTS (
            SELECT 1
            FROM tourist1 t1
            WHERE t1.email = numbered_tourists.email
        )
        THEN
            SPLIT_PART(email, '@', 1)
            || '_' || new_tourist_id
            || '@' ||
            SPLIT_PART(email, '@', 2)
        ELSE email
    END,

    CASE
        WHEN EXISTS (
            SELECT 1
            FROM tourist1 t1
            WHERE t1.phone = numbered_tourists.phone
        )
        THEN phone || '_' || new_tourist_id
        ELSE phone
    END,

    passport_number
FROM numbered_tourists
ON CONFLICT DO NOTHING;

DROP TABLE IF EXISTS tourist_id_map;

CREATE TABLE tourist_id_map AS
SELECT DISTINCT ON (t.tourist_id)
    t.tourist_id AS old_tourist_id,
    t1.tourist_id AS new_tourist_id
FROM tourist t
JOIN tourist1 t1
    ON t1.passport_number = t.passport_number
ORDER BY t.tourist_id, t1.tourist_id;

-- 5. העברת הנתונים מ-booking אל booking1
WITH numbered_bookings AS (
    SELECT
        b.*,
        ROW_NUMBER() OVER (ORDER BY b.booking_id) + 19923 AS new_booking_id
    FROM booking b
)
INSERT INTO booking1 (
    booking_id,
    booking_date,
    status,
    tourist_id,
    payment_status
)
SELECT
    nb.new_booking_id,
    nb.booking_date,
    nb.booking_status::VARCHAR,
    m.new_tourist_id,
    nb.payment_status::VARCHAR
FROM numbered_bookings nb
JOIN tourist_id_map m
    ON nb.tourist_id = m.old_tourist_id
WHERE NOT EXISTS (
    SELECT 1
    FROM booking1 b1
    WHERE b1.booking_id = nb.new_booking_id
);

DROP TABLE IF EXISTS booking_id_map;

CREATE TABLE booking_id_map AS
WITH numbered_bookings AS (
    SELECT
        b.booking_id AS old_booking_id,
        ROW_NUMBER() OVER (ORDER BY b.booking_id) + 19923 AS new_booking_id
    FROM booking b
)
SELECT *
FROM numbered_bookings;