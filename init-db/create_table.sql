CREATE TABLE COUNTRY
(
  Country_ID INT NOT NULL,
  Country_Name VARCHAR(100) NOT NULL,
  
  PRIMARY KEY (Country_ID),
  UNIQUE (Country_Name)
);

CREATE TABLE CITY
(
  City_ID INT NOT NULL,
  City_Name VARCHAR(100) NOT NULL,
  Country_ID INT NOT NULL,
  
  PRIMARY KEY (City_ID),
  FOREIGN KEY (Country_ID) REFERENCES COUNTRY(Country_ID),
  UNIQUE (City_Name, Country_ID)
);

CREATE TABLE TOURIST
(
  Tourist_ID INT NOT NULL,
  First_Name VARCHAR(100) NOT NULL,
  Last_Name VARCHAR(100) NOT NULL,
  Email VARCHAR(100) NOT NULL,
  Phone VARCHAR(30) NOT NULL,
  language VARCHAR(100) NOT NULL,
  password VARCHAR(100) NOT NULL,
  birthday DATE NOT NULL,
  User_Name VARCHAR(100) NOT NULL,
  
  PRIMARY KEY (Tourist_ID),
  UNIQUE (Email),
  UNIQUE (Phone),
  UNIQUE (User_Name),
  CHECK (birthday < CURRENT_DATE)
);

CREATE TABLE RESTAURANT
(
  Rest_ID INT NOT NULL,
  Rest_Name VARCHAR(100) NOT NULL,
  Address VARCHAR(200) NOT NULL,
  Cuisine_Type VARCHAR(50) NOT NULL,
  Phone_Number VARCHAR(20) NOT NULL,
  Average_Price NUMERIC(6,2) NOT NULL,
  City_ID INT NOT NULL,
  
  PRIMARY KEY (Rest_ID),
  FOREIGN KEY (City_ID) REFERENCES CITY(City_ID),
  UNIQUE (Phone_Number),
  CHECK (Average_Price > 0)
);

CREATE TABLE BOOKING
(
  Booking_ID INT NOT NULL,
  Booking_Date DATE NOT NULL,
  Num_Of_People INT NOT NULL,
  Status VARCHAR(50) NOT NULL,
  Tourist_ID INT NOT NULL,
  Rest_ID INT NOT NULL,
  
  PRIMARY KEY (Booking_ID),
  FOREIGN KEY (Tourist_ID) REFERENCES TOURIST(Tourist_ID),
  FOREIGN KEY (Rest_ID) REFERENCES RESTAURANT(Rest_ID),
  CHECK (Num_Of_People > 0)
);

CREATE TABLE FEEDBACK
(
  Feedback_ID INT NOT NULL,
  Feedback_Date DATE NOT NULL,
  Review_Title VARCHAR(100), 
  Comment VARCHAR(1000),
  Tourist_ID INT NOT NULL,
  Rest_ID INT NOT NULL,
  
  PRIMARY KEY (Feedback_ID),
  FOREIGN KEY (Tourist_ID) REFERENCES TOURIST(Tourist_ID),
  FOREIGN KEY (Rest_ID) REFERENCES RESTAURANT(Rest_ID)
);

CREATE TABLE RATING
(
  rate_num INT NOT NULL,
  rating_type VARCHAR(50) NOT NULL,
  degree INT NOT NULL,
  Feedback_ID INT NOT NULL,
  
  PRIMARY KEY (rate_num, Feedback_ID),
  FOREIGN KEY (Feedback_ID) REFERENCES FEEDBACK(Feedback_ID),
  CHECK (degree >= 1 AND degree <= 5)
);