📊 DB Project – Stage A
🍽️ Ordering Restaurants System

👩‍💻 Submitted by
Idit Cohen - 329194229
Ester Garada - 214881229

📑 Table of Contents
    Introduction
    System Screens
    Database Design (ERD + DSD)
    Design Decisions
    Data Insertion Methods
    Backup & Restore

📌 Introduction
This system is designed to provide users with information about restaurants and allow them to interact with the system after logging in.

The system enables users to:
    Search for restaurants by city, country, restaurant name, or personal profile preferences
    View restaurant details such as name, description, address, cuisine type, and average price
    Make reservations (bookings)
    Write feedback and reviews for restaurants
The goal of the system is to create an easy and efficient platform for users to explore restaurants, make reservations, and share their experiences.

🖥️ System Screens
The system includes 4 main screens:

Login / Register Screen
    Allows users to log in or create a new account
    
![alt text](images/image-4.png)

Profile Setup Screen
    Users enter personal details such as country, age, and preferences
    
![alt text](images/image-5.png)

Home Screen (Navigation Dashboard)
    Main screen after login
    Includes navigation bar:
        Home
        Search by Location
        Search by Name
        Search by Profile
        
![alt text](images/image-2.png)  

![alt text](images/image-6.png)

Search & Restaurant Interaction Screen
    Displays restaurant results
    Allows users to:
        View restaurant details
        Make reservations
        Leave feedback
        
![alt text](images/image-7.png)

![alt text](images/image-8.png)

![alt text](images/image-9.png)



🔗 Link to AI Studio:
https://aistudio.google.com/apps/c8450de9-342a-45b4-97ab-09c26e8ec42a?showPreview=true&showAssistant=true


🗄️ Database Design
ERD Diagram

📸 ![alt text](images/image-10.png)

DSD Diagram

📸 ![alt text](images/image-1.png)


⚙️ Design Decisions
During the design process, the following decisions were made:

The system includes more than 6 entities:
Tourist
Restaurant
Booking
Feedback
Rating
City
Country
The database includes important DATE fields such as:
Booking_Date
Feedback_Date
The database was normalized to at least 3NF to prevent redundancy and ensure data consistency
Relationships were defined using foreign keys to maintain data integrity
Constraints were added (such as UNIQUE fields for email and phone) to ensure valid and realistic data

📜 SQL Scripts
1. Create Tables Script

This file contains all SQL commands required to create the database tables based on the designed schema (ERD & DSD).
It defines tables, primary keys, foreign keys, and constraints.

🔗[create_table.sql](init-db/create_table.sql)

2. Drop Tables Script

This file includes SQL commands to safely delete all tables from the database in the correct order, preventing dependency errors between tables.

🔗 [dropTables.sql](init-db/dropTables.sql)

3. Insert Data Script

This file contains SQL INSERT statements used to populate the database with initial data for all tables.

🔗 [insertTables.sql](init-db/insertTables.sql)

4. Select Queries Script

This file includes SELECT queries that retrieve and display all data from the database tables, used for testing and verification.

🔗 [selectAll.sql](init-db/selectAll.sql)

## Data Population Methods

In this project, data was populated using three different methods:

1. **Python Script Generation**
   A Python script was used to generate large-scale synthetic data (e.g., 20,000 booking records). The script creates realistic randomized values and exports them into CSV files.

   ![alt text](images/15.png)

3. **External Data Generation Tool (Mockaroo)**
   The Mockaroo website was used to generate structured and realistic datasets for related tables (such as tourists and restaurants).

   ![alt text](images/13.jpeg)

   ![alt text](images/17.png)

5. **Bulk Import Using CSV (COPY command)**
   The generated CSV files (from Python) were loaded into the database using the SQL `COPY` command for efficient bulk insertion.

   ![alt text](images/16.png)

💾 Backup & Restore

 A backup file was created for the database
 The backup file includes the date of creation
 The backup was successfully restored on another computer
 
🔗 Backup File:
[Open Backup File](https://github.com/esterG9/RestaurantProject/blob/main/restaurant_backup_14_04_26%20(1))

📸 Screenshot of backup
![alt text](images/image-11.png)
📸 Screenshot of restore
![alt text](images/combined_pgadmin.png)

DSD diagram from pgAdmin

![alt text](images/inage-12.jpeg)

step b
```sql
--1.שאילתת חיפוש מסעדה על פי מיקום
- שיטה ראשונה
SELECT r.Rest_Name, r.Address, c.City_Name, co.Country_Name
FROM RESTAURANT r
JOIN CITY c ON r.City_ID = c.City_ID
JOIN COUNTRY co ON c.Country_ID = co.Country_ID
WHERE TRIM(co.Country_Name) LIKE 'Albania'
ORDER BY r.Rest_Name;

-- שיטה שניה

SELECT 
    r.Rest_Name, 
    r.Address, 
    (SELECT c.City_Name FROM CITY c WHERE c.City_ID = r.City_ID) AS City_Name,
    (SELECT co.Country_Name FROM COUNTRY co 
     JOIN CITY ci ON co.Country_ID = ci.Country_ID 
     WHERE ci.City_ID = r.City_ID) AS Country_Name
FROM RESTAURANT r
WHERE r.City_ID IN (
    SELECT c.City_ID FROM CITY c WHERE c.Country_ID = (
        SELECT co.Country_ID FROM COUNTRY co WHERE TRIM(co.Country_Name) = 'Albania'
    )
)
ORDER BY r.Rest_Name;

```

![alt text](images/Query_result1.png)

```sql

--2.שאילתת חיפוש מסעדה על פי דירוג
-- שיטה ראשונה

SELECT r.Rest_Name, r.Cuisine_Type, r.Average_Price
FROM RESTAURANT r
WHERE EXISTS (
    SELECT 1 
    FROM FEEDBACK f
    JOIN RATING ra ON f.Feedback_ID = ra.Feedback_ID
    WHERE f.Rest_ID = r.Rest_ID AND ra.degree = 5
)
ORDER BY r.Average_Price DESC;

-- שיטה שניה

SELECT Rest_Name, Cuisine_Type, Average_Price
FROM RESTAURANT
WHERE Rest_ID IN (
    SELECT f.Rest_ID
    FROM FEEDBACK f
    JOIN RATING ra ON f.Feedback_ID = ra.Feedback_ID
    WHERE ra.degree = 5
)
ORDER BY Average_Price DESC;
```

![alt text](images/Query_result2.png)

```sql

--3.שאילתה להצגת ביקורות למסעדה מהחדשות לישנות
-- שיטה ראשונה

SELECT
    f.Feedback_ID,
    res.Rest_Name,
    t.First_Name,
    t.Last_Name,
    f.Feedback_Date,
    f.Review_Title,
    f.Comment
FROM FEEDBACK f
JOIN RESTAURANT res
    ON f.Rest_ID = res.Rest_ID
JOIN TOURIST t
    ON f.Tourist_ID = t.Tourist_ID
WHERE res.Rest_Name = 'Jayo'
ORDER BY f.Feedback_Date DESC;


-- שיטה שניה

SELECT
    f.Feedback_ID,

    (SELECT res.Rest_Name
     FROM RESTAURANT res
     WHERE res.Rest_ID = f.Rest_ID) AS Rest_Name,

    (SELECT t.First_Name
     FROM TOURIST t
     WHERE t.Tourist_ID = f.Tourist_ID) AS First_Name,

    (SELECT t.Last_Name
     FROM TOURIST t
     WHERE t.Tourist_ID = f.Tourist_ID) AS Last_Name,

    f.Feedback_Date,
    f.Review_Title,
    f.Comment
FROM FEEDBACK f
WHERE f.Rest_ID IN (
    SELECT res.Rest_ID
    FROM RESTAURANT res
    WHERE res.Rest_Name = 'Jayo'
)
ORDER BY f.Feedback_Date DESC;
```

```sql


--4.הצגת מספר הזמנות לכל תייר
-- שיטה ראשונה
SELECT
    t.Tourist_ID,
    t.First_Name,
    t.Last_Name,
    COUNT(b.Booking_ID) AS Num_Of_Bookings
FROM TOURIST t
LEFT JOIN BOOKING b
    ON t.Tourist_ID = b.Tourist_ID
GROUP BY
    t.Tourist_ID, t.First_Name, t.Last_Name
ORDER BY Num_Of_Bookings DESC;

-- שיטה שניה
SELECT
    t.Tourist_ID,
    t.First_Name,
    t.Last_Name,

    (SELECT COUNT(*)
     FROM BOOKING b
     WHERE b.Tourist_ID = t.Tourist_ID) AS Num_Of_Bookings

FROM TOURIST t
ORDER BY Num_Of_Bookings DESC;
```

```sql

--5.השאילתה מציגה את מספר ההזמנות שבוצעו בחודש ושנה מסוימים
SELECT 
    Booking_ID,
    Booking_Date,
    Num_Of_People,
    Status,
    Tourist_ID
FROM BOOKING
WHERE EXTRACT(YEAR FROM Booking_Date) = 2025
  AND EXTRACT(MONTH FROM Booking_Date) = 1
ORDER BY Booking_Date;
```
```sql

--6.מי הם 5 התיירים הכי פעילים שביצעו הכי הרבה הזמנות מאושרות
SELECT 
    t.First_Name, 
    t.Last_Name, 
    t.Email, 
    COUNT(b.Booking_ID) AS Total_Confirmed_Bookings,
    MAX(b.Booking_Date) AS Last_Booking_Date
FROM TOURIST t
JOIN BOOKING b ON t.Tourist_ID = b.Tourist_ID
WHERE b.Status = 'Confirmed'
GROUP BY t.Tourist_ID, t.First_Name, t.Last_Name, t.Email
HAVING COUNT(b.Booking_ID) > 1
ORDER BY Total_Confirmed_Bookings DESC
LIMIT 5;
```

```sql

--7.הזמנות שבוטלו
SELECT
    b.Booking_ID,
    b.Booking_Date,
    b.Num_Of_People,
    b.Status,
    t.First_Name,
    t.Last_Name,
    r.Rest_Name
FROM BOOKING b
JOIN TOURIST t
    ON b.Tourist_ID = t.Tourist_ID
JOIN RESTAURANT r
    ON b.Rest_ID = r.Rest_ID
WHERE b.Status = 'Cancelled'
ORDER BY b.Booking_Date DESC;
```

```sql

--8.הצגת המסעדה הכי זולה בכל עיר ולכל סוג מטבח
SELECT
    c.City_Name,
    r.Cuisine_Type,
    r.Rest_Name,
    r.Average_Price
FROM RESTAURANT r
JOIN CITY c
    ON r.City_ID = c.City_ID
WHERE r.Average_Price = (
    SELECT MIN(r2.Average_Price)
    FROM RESTAURANT r2
    WHERE r2.City_ID = r.City_ID
      AND r2.Cuisine_Type = r.Cuisine_Type
)
ORDER BY
    c.City_Name,
    r.Cuisine_Type,
    r.Rest_Name;
```

```sql

--1.שאילתה מוחקת את ההזמנות שהושלמו או בוטלו לתייר שכתובת המייל שלו היא 'cwessell5@skype.com'
DELETE FROM BOOKING
WHERE TRIM(Status) IN ('Confirmed', 'Cancelled')
  AND Tourist_ID = (
    SELECT Tourist_ID 
    FROM TOURIST 
    WHERE TRIM(Email) = 'cwessell5@skype.com'
);

```
```sql
--2.שאילתה מוחקת דירוגים גרועים למסעדה ספציפית
DELETE FROM RATING
WHERE degree = 1 
  AND Feedback_ID IN (
    SELECT Feedback_ID 
    FROM FEEDBACK 
    WHERE Rest_ID IN (
        SELECT Rest_ID 
        FROM RESTAURANT 
        WHERE TRIM(Rest_Name) = 'Jayo'
    )
);
```
```sql

--3.שאילתה שמוחקת מסעדות שלא הוזמנו בהם הזמנות
DELETE FROM RESTAURANT
WHERE Rest_ID NOT IN (
    SELECT DISTINCT Rest_ID 
    FROM BOOKING
);
```
