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

📥 Data Insertion Methods
We used at least 3 different methods to insert data into the database:

1. SQL INSERT Commands
Data was inserted manually using SQL INSERT statements
📸 Screenshot
2. Python / CSV Data Generation
Data was generated using scripts / CSV files and imported into the database
📸 Screenshot
3. External Tool (Mockaroo / Generatedata)
Large datasets were generated using an external tool
📸 Screenshot
Data Volume
Each table contains at least 500 records
Two tables contain at least 20,000 records
💾 Backup & Restore
A backup file was created for the database
The backup file includes the date of creation
The backup was successfully restored on another computer

📸 Screenshot of backup
![alt text](images/image-11.png)
📸 Screenshot of restore
c:\Users\user1\Downloads\combined_pgadmin.png
