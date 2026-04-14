import csv
import random
from datetime import datetime, timedelta

# פונקציה ליצירת תאריך אקראי בין 2023 ל-2025
def random_date():
    start_date = datetime(2023, 1, 1)
    end_date = datetime(2025, 12, 31)
    days_between = (end_date - start_date).days
    return (start_date + timedelta(days=random.randint(0, days_between))).strftime('%Y-%m-%d')

filename = 'booking_data_20k.csv'

with open(filename, 'w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    
    # כותרות לפי מבנה הטבלה ב-SQL
    writer.writerow(["Booking_ID", "Booking_Date", "Num_Of_People", "Status", "Tourist_ID", "Rest_ID"])
    
    for i in range(1, 20001):
        writer.writerow([
            i,                                      # Booking_ID (מספר רץ)
            random_date(),                          # תאריך אקראי
            random.randint(1, 12),                  # כמות אנשים (אילוץ > 0)
            random.choice(['Confirmed', 'Pending', 'Cancelled']), # סטטוס
            random.randint(1, 500),                 # מקשר ל-500 תיירים שיצרת ב-Mockaroo
            random.randint(1, 500)                  # מקשר ל-500 מסעדות שיצרת ב-Mockaroo
        ])

print(f"File {filename} created successfully with 20,000 rows.")