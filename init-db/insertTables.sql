-- ======================================================
-- insertTables.sql - אכלוס נתונים ב-3 שיטות שונות
-- ======================================================

-- שיטה 1: הכנסה ידנית (Direct SQL Inserts)
-- משמש עבור טבלאות תשתית קטנות
INSERT INTO COUNTRY (Country_ID, Country_Name) VALUES (1, 'Israel');
INSERT INTO COUNTRY (Country_ID, Country_Name) VALUES (2, 'USA');
INSERT INTO COUNTRY (Country_ID, Country_Name) VALUES (3, 'France');

INSERT INTO CITY (City_ID, City_Name, Country_ID) VALUES (1, 'Tel Aviv', 1);
INSERT INTO CITY (City_ID, City_Name, Country_ID) VALUES (2, 'New York', 2);
INSERT INTO CITY (City_ID, City_Name, Country_ID) VALUES (3, 'Paris', 3);

-- שיטה 2: שימוש באתר חיצוני (Mockaroo)
-- הערה למרצה: הקבצים עבור טבלאות TOURIST, RESTAURANT ו-FEEDBACK
-- נוצרו באתר Mockaroo ונמצאים בתיקיית mockarooFiles.
-- יש להריץ את הקבצים: tourist_insert.sql, restaurant_insert.sql, feedback_insert.sql.

-- שיטה 3: שימוש בתכנות (Python) וייבוא קבצי CSV
-- הערה למרצה: קבצי ה-CSV עבור הטבלאות הגדולות (20,000 רשומות) נוצרו ע"י 
-- סקריפטים בפייתון הנמצאים בתיקיית Programming.

-- טעינת נתוני הזמנות (20,000 רשומות)
COPY BOOKING(Booking_ID, Booking_Date, Num_Of_People, Status, Tourist_ID, Rest_ID)
FROM '/docker-entrypoint-initdb.d/DataImportFiles/booking_data_20k.csv'
DELIMITER ','
CSV HEADER;

-- טעינת נתוני דירוגים (20,000 רשומות)
COPY RATING(rate_num, rating_type, degree, Feedback_ID)
FROM '/docker-entrypoint-initdb.d/DataImportFiles/ratings_data_20k.csv'
DELIMITER ','
CSV HEADER;

-- סוף קובץ הכנסת נתונים