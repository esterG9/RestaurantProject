-- ROLLBACK DEMO

-- Step 1: First screenshot - show data before update
SELECT
    Booking_ID,
    Booking_Date,
    Status
FROM BOOKING
WHERE Booking_Date < CURRENT_DATE
  AND Status = 'Confirmed'
ORDER BY Booking_ID;

-- Step 2: Begin transaction and execute update
BEGIN;

UPDATE BOOKING
SET Status = 'Completed'
WHERE Booking_Date < CURRENT_DATE
  AND Status = 'Confirmed';

-- Step 3: Second screenshot - show data was temporarily updated
SELECT
    Booking_ID,
    Booking_Date,
    Status
FROM BOOKING
WHERE Booking_Date < CURRENT_DATE
ORDER BY Booking_ID;

-- Step 4: Rollback the transaction
ROLLBACK;

-- Step 5: Third screenshot - show data has been restored
SELECT
    Booking_ID,
    Booking_Date,
    Status
FROM BOOKING
WHERE Booking_Date < CURRENT_DATE
ORDER BY Booking_ID;



-- COMMIT DEMO

-- Step 1: First screenshot - show original data
SELECT
    r.Rest_ID,
    r.Rest_Name,
    r.Average_Price,
    c.City_Name
FROM RESTAURANT r
JOIN CITY c ON r.City_ID = c.City_ID
WHERE c.City_Name = 'Fier'
ORDER BY r.Rest_ID;

-- Step 2: Begin transaction and execute update
BEGIN;

UPDATE RESTAURANT
SET Average_Price = Average_Price * 1.10
WHERE City_ID IN (
    SELECT City_ID
    FROM CITY
    WHERE City_Name = 'Fier'
);

-- Step 3: Second screenshot - show the updated prices
SELECT
    r.Rest_ID,
    r.Rest_Name,
    r.Average_Price,
    c.City_Name
FROM RESTAURANT r
JOIN CITY c ON r.City_ID = c.City_ID
WHERE c.City_Name = 'Fier'
ORDER BY r.Rest_ID;

-- Step 4: Commit the transaction to save changes
COMMIT;

-- Step 5: Third screenshot - show data remains updated after commit
SELECT
    r.Rest_ID,
    r.Rest_Name,
    r.Average_Price,
    c.City_Name
FROM RESTAURANT r
JOIN CITY c ON r.City_ID = c.City_ID
WHERE c.City_Name = 'Fier'
ORDER BY r.Rest_ID;