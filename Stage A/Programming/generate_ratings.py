import csv
import random

# שם הקובץ שיווצר
filename = 'ratings_data_20k.csv'

with open(filename, 'w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    
    # כותרות לפי מבנה הטבלה ב-SQL
    writer.writerow(["rate_num", "rating_type", "degree", "Feedback_ID"])
    
    for i in range(1, 20001):
        writer.writerow([
            i,                                      # rate_num (מספר רץ)
            random.choice(['Service', 'Food', 'Cleanliness']), # סוג דירוג
            random.randint(1, 5),                   # ציון (אילוץ 1-5)
            random.randint(1, 500)                  # מקשר ל-500 פידבקים שיצרת ב-Mockaroo
        ])

print(f"File {filename} created successfully with 20,000 rows.")