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
