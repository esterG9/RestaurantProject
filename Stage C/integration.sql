ALTER TABLE tourist RENAME TO tourist1;
ALTER TABLE booking RENAME TO booking1;

ALTER TABLE tourist1
ADD COLUMN IF NOT EXISTS passport_number VARCHAR(20);
ALTER TABLE tourist1 ADD COLUMN temp_country VARCHAR(50);
-- 1. הפיכת שדות ייחודיים אצלך לאופציונליים זמנית כדי שנוכל להכניס את התיירים של חברתך
ALTER TABLE tourist1 ALTER COLUMN language DROP NOT NULL;
ALTER TABLE tourist1 ALTER COLUMN password DROP NOT NULL;
ALTER TABLE tourist1 ALTER COLUMN birthday DROP NOT NULL;
ALTER TABLE tourist1 ALTER COLUMN User_Name DROP NOT NULL;

-- 2. הוספת עמודת דרכון מהטבלה של חברתך אל הטבלה שלך
ALTER TABLE tourist1 ADD COLUMN Passport_Number VARCHAR(20);
INSERT INTO tourist1 (Tourist_ID, First_Name, Last_Name, Phone, Email, Passport_Number, temp_country)
SELECT 
    Tourist_ID, 
    First_Name, 
    Last_Name, 
    Phone, 
    Email, 
    Passport_Number,
    Country -- שם המדינה כפי שמופיע אצל חברתך
FROM TOURIST;

DROP TABLE TOURIST; -- מחיקת הטבלה הישנה של חברתך
ALTER TABLE tourist1 RENAME TO TOURIST; -- שינוי השם של 


WITH unique_missing_cities AS (
    SELECT DISTINCT TRIM(l.City) AS Missing_City
    FROM LOCATION l
    LEFT JOIN CITY c ON UPPER(TRIM(l.City)) = UPPER(TRIM(c.City_Name))
    WHERE c.City_ID IS NULL AND l.City IS NOT NULL
),
max_id AS (
    SELECT COALESCE(MAX(City_ID), 0) AS current_max FROM CITY
)
INSERT INTO CITY (City_ID, City_Name, Country_ID)
SELECT 
    m.current_max + ROW_NUMBER() OVER (), 
    u.Missing_City,
    1 -- קוד מדינה כברירת מחדל מתוך טבלת COUNTRY שלך
FROM unique_missing_cities u
CROSS JOIN max_id m;

UPDATE LOCATION l
SET City_ID = c.City_ID
FROM CITY c
WHERE UPPER(TRIM(l.City)) = UPPER(TRIM(c.City_Name));

ALTER TABLE LOCATION DROP COLUMN City;
ALTER TABLE LOCATION DROP COLUMN Country;

-- 1. הוספת עמודת הקישור החדשה לטבלת המסעדות
ALTER TABLE RESTAURANT ADD COLUMN Location_ID INT REFERENCES LOCATION(Location_ID);

-- 2. ביטול אילוץ ה-NOT NULL מעמודת ה-City_ID הישנה במסעדות (כדי שנוכל לשחרר אותה בהמשך)
ALTER TABLE RESTAURANT ALTER COLUMN City_ID DROP NOT NULL;

INSERT INTO LOCATION (Address, City_ID)
SELECT Address, City_ID
FROM RESTAURANT;

UPDATE RESTAURANT r
SET Location_ID = l.Location_ID
FROM LOCATION l
WHERE r.Address = l.Address AND r.City_ID = l.City_ID;

-- 1. מחיקת עמודת הכתובת הישנה מהמסעדות
ALTER TABLE RESTAURANT DROP COLUMN Address;

-- 2. מחיקת עמודת העיר הישנה מהמסעדות
ALTER TABLE RESTAURANT DROP COLUMN City_ID;

-- 3. הגדרת עמודת המיקום החדשה כ-NOT NULL (כדי להבטיח שלכל מסעדה יש מיקום)
ALTER TABLE RESTAURANT ALTER COLUMN Location_ID SET NOT NULL;

ALTER TABLE booking1
ALTER COLUMN booking_id DROP IDENTITY IF EXISTS;

UPDATE booking1
SET booking_id = booking_id + 20000;

ALTER TABLE booking1
ADD COLUMN payment_status VARCHAR(50);

ALTER TABLE booking1
DROP COLUMN IF EXISTS num_of_people;

ALTER TABLE booking1
DROP COLUMN IF EXISTS rest_id;

INSERT INTO booking1 (booking_id, booking_date, status, tourist_id, payment_status)
SELECT 
    booking_id, 
    booking_date, 
    booking_status::VARCHAR, -- המרת הסטטוס של חברתך מטקסט קשיח לטקסט חופשי שמתאים לך
    tourist_id, 
    payment_status::VARCHAR  -- הפסיק המיותר הוסר מכאן!
FROM booking
WHERE booking_id <= 20000;   -- לקיחת רק ההזמנות המקוריות של חברתך (הדירות)

-- 1. מחיקת טבלת האב הישנה של חברתך (המידע שלה כבר שמור בבטחה אצלך)
DROP TABLE IF EXISTS booking CASCADE;

-- 2. שינוי שם הטבלה המאוחדת שלך מ-booking1 לשם הרשמי BOOKING
ALTER TABLE booking1 RENAME TO booking;


-- 1. הגדרת booking_id כמפתח ראשי של הטבלה (במידה והוא עוד לא הוגדר ככזה)
ALTER TABLE restaurantbooking ADD PRIMARY KEY (booking_id);

-- 2. יצירת החיבור הרשמי (הקשר) לטבלת האב המאוחדת
ALTER TABLE restaurantbooking 
ADD CONSTRAINT fk_restaurant_booking 
FOREIGN KEY (booking_id) REFERENCES booking(booking_id);

ALTER TABLE apartmentbooking 
ADD CONSTRAINT fk_apartment_booking 
FOREIGN KEY (booking_id) REFERENCES booking(booking_id);

ALTER TABLE FEEDBACK ADD COLUMN rating_type VARCHAR(50);
ALTER TABLE FEEDBACK ADD COLUMN degree INT CHECK (degree >= 1 AND degree <= 5);


-- 1. ביטול חובת ה-Booking_ID (שיהיה אפשר להכניס פידבק ללא הזמנת דירה)
ALTER TABLE REVIEW ALTER COLUMN Booking_ID DROP NOT NULL;

-- 2. יצירת עמודת התייר בטבלת REVIEW
ALTER TABLE REVIEW ADD COLUMN Tourist_ID INT REFERENCES TOURIST(Tourist_ID);

-- 3. יצירת עמודת המסעדה בטבלת REVIEW
ALTER TABLE REVIEW ADD COLUMN Rest_ID INT REFERENCES RESTAURANT(Rest_ID);



-- 1. ניתוק זמני של המפתח הזר כדי ש-PostgreSQL ירשה לנו לשנות את ה-IDs
ALTER TABLE RATING DROP CONSTRAINT rating_feedback_id_fkey; 
-- הערה: אם שם האילוץ אצלך שונה, המערכת תגיד לך. זה השם הסטנדרטי לפי ה-DDL ששלחת.

-- 2. הוספת 20,000 לכל ה-IDs בטבלת הפידבקים
UPDATE FEEDBACK 
SET Feedback_ID = Feedback_ID + 20000;

-- 3. הוספת 20,000 לכל ה-IDs בטבלת הרייטינג (כדי שימשיכו להתאים בדיוק!)
UPDATE RATING 
SET Feedback_ID = Feedback_ID + 20000;

-- 4. החזרת המפתח הזר למקומו כדי לשמור על קשר תקין ומאובטח
ALTER TABLE RATING 
ADD CONSTRAINT rating_feedback_id_fkey 
FOREIGN KEY (Feedback_ID) REFERENCES FEEDBACK(Feedback_ID);

ALTER TABLE public.tourist ADD COLUMN country_id INT;
UPDATE public.tourist t
SET country_id = c.country_id
FROM public.country c
WHERE LOWER(TRIM(t.temp_country)) = LOWER(TRIM(c.country_name));
-- הערה: אם בטבלת country לשדה של שם המדינה קוראים country ולא country_name, שני את ה-c.country_name בסוף ל-c.country.
ALTER TABLE public.tourist DROP COLUMN temp_country;
ALTER TABLE public.tourist 
ADD CONSTRAINT fk_tourist_country 
FOREIGN KEY (country_id) 
REFERENCES public.country(country_id);


CREATE TABLE IF NOT EXISTS public.review_merge (
    review_id INTEGER GENERATED ALWAYS AS IDENTITY
    PRIMARY KEY,

    rating INTEGER NOT NULL
        CHECK (rating >= 0 AND rating <= 5),

    comment TEXT NOT NULL,

    review_date DATE DEFAULT CURRENT_DATE,

    booking_type VARCHAR(20) NOT NULL
        CHECK (booking_type IN ('restaurant', 'apartment')),

    tourist_id INTEGER NOT NULL,

    rest_or_apartment_id INTEGER NOT NULL,

    CONSTRAINT fk_review_tourist
        FOREIGN KEY (tourist_id)
        REFERENCES public.tourist(tourist_id)
);

ALTER TABLE IF EXISTS public.review_merge
    OWNER TO "esterG";

    TRUNCATE TABLE public.review_merge RESTART IDENTITY;

INSERT INTO public.review_merge
(
    rating,
    comment,
    review_date,
    booking_type,
    tourist_id,
    rest_or_apartment_id
)
SELECT
    r.rating,
    r.comment,
    r.review_date,

    CASE
        WHEN r.tourist_id IS NULL AND r.rest_id IS NULL THEN 'apartment'
        ELSE 'restaurant'
    END AS booking_type,

    CASE
        WHEN r.tourist_id IS NULL AND r.rest_id IS NULL THEN b.tourist_id
        ELSE r.tourist_id
    END AS tourist_id,

    CASE
        WHEN r.tourist_id IS NULL AND r.rest_id IS NULL THEN ab.apartment_id
        ELSE r.rest_id
    END AS rest_or_apartment_id

FROM public.review r
LEFT JOIN public.booking b
    ON r.booking_id = b.booking_id
LEFT JOIN public.apartmentbooking ab
    ON r.booking_id = ab.booking_id;


    ALTER TABLE public.apartmentreview
DROP CONSTRAINT apartmentreview_review_id_fkey;

ALTER TABLE public.apartmentreview
ADD CONSTRAINT apartmentreview_review_id_fkey
FOREIGN KEY (review_id)
REFERENCES public.review_merge(review_id);
DROP TABLE public.review;
ALTER TABLE public.review_merge
RENAME TO review;