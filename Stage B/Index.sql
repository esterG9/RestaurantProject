/*
  1. יצירת אינדקס לשיפור חיפוש הזמנות לפי משתמש ומניעת סריקה מלאה של הטבלה
  Table: BOOKING
  Column: Tourist_ID
*/

-- לפני האינדקס
EXPLAIN ANALYZE
SELECT *
FROM BOOKING
WHERE Tourist_ID = 1;

-- יצירת האינדקס
CREATE INDEX idx_booking_tourist
ON BOOKING(Tourist_ID);

-- אחרי האינדקס
EXPLAIN ANALYZE
SELECT *
FROM BOOKING
WHERE Tourist_ID = 1;


/*
  2. יצירת אינדקס לשיפור חיפוש מסעדות לפי עיר ואפשור גישה מהירה לנתונים
  Table: RESTAURANT
  Column: City_ID
*/

-- לפני האינדקס
EXPLAIN ANALYZE
SELECT *
FROM RESTAURANT
WHERE City_ID = 5;

-- יצירת האינדקס
CREATE INDEX idx_rest_city
ON RESTAURANT(City_ID);

-- אחרי האינדקס
EXPLAIN ANALYZE
SELECT *
FROM RESTAURANT
WHERE City_ID = 5;


/*
  3. יצירת אינדקס לשיפור חיפוש ביקורות לפי מסעדה ואפשור גישה מהירה לנתונים
  Table: FEEDBACK
  Column: Rest_ID
*/

-- לפני האינדקס
EXPLAIN ANALYZE
SELECT *
FROM FEEDBACK
WHERE Rest_ID = 1;

-- יצירת האינדקס
CREATE INDEX idx_feedback_rest
ON FEEDBACK(Rest_ID);

-- אחרי האינדקס
EXPLAIN ANALYZE
SELECT *
FROM FEEDBACK
WHERE Rest_ID = 1;