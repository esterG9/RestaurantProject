--1.אילוץ על מספר אנשים להזמנה לפחות 1 והכמות לא תעלה על 20
ALTER TABLE BOOKING 
ADD CONSTRAINT chk_num_people_range 
CHECK (Num_Of_People > 0 AND Num_Of_People <= 20);
--בדיקה
INSERT INTO BOOKING (Booking_ID, Tourist_ID, Rest_ID, Booking_Date, Num_Of_People, Status)
VALUES (999999, 1, 1, '2026-05-04', 25, 'Confirmed'); 

--2. או סימנים ידועיםאילוץ על מספר הטלפון של המסעדה חייב להיות מספרים בלבד
ALTER TABLE RESTAURANT 
ADD CONSTRAINT chk_rest_phone_numeric 
CHECK (Phone_Number ~ '^[0-9+\-]+$');
-- בדיקה
UPDATE RESTAURANT 
SET Phone_Number = 'Call-Me-Now' 
WHERE Rest_ID = (SELECT MIN(Rest_ID) FROM RESTAURANT);

--3.אילוץ על תאריך המשוב לא יהיה בעתיד
ALTER TABLE FEEDBACK 
ADD CONSTRAINT chk_feedback_not_future 
CHECK (Feedback_Date <= CURRENT_DATE);
--בדיקה
INSERT INTO FEEDBACK (Feedback_ID, Feedback_Date, Review_Title, Comment, Tourist_ID, Rest_ID)
VALUES (888888, '2028-01-01', 'Future Meal', 'The food was great in the future!', 1, 1);

