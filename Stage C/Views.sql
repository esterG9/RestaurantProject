host_properties_summary
CREATE VIEW public.host_properties_summary AS
SELECT 
    h.host_id,
    h.first_name || ' ' || h.last_name AS host_name,
    h.email AS host_email,
    a.apartment_id,
    a.title AS apartment_title,
    a.property_type,
    a.price_per_night,
    COALESCE(AVG(ar.locationrating), 0) AS avg_location_rating
FROM 
    public.host h
JOIN 
    public.apartment a ON h.host_id = a.host_id
LEFT JOIN 
    public.review r ON a.review_object_id = r.review_object_id AND r.booking_type = 'apartment'
LEFT JOIN 
    public.apartmentreview ar ON r.review_id = ar.review_id
GROUP BY 
    h.host_id, h.first_name, h.last_name, h.email, a.apartment_id, a.title, a.property_type, a.price_per_night;


-- שליפת נכסי יוקרה שקיבלו דירוג מיקום ממוצע של 4 ומעלה
SELECT host_name, apartment_title, price_per_night, avg_location_rating
FROM public.host_properties_summary
WHERE price_per_night > 150.00 AND avg_location_rating >= 4.0
ORDER BY price_per_night DESC;


  *שאילתה בסיכום נתונים אגרגטיבי על המבט – מציאת כמות הנכסים והמחיר הממוצע ללילה עבור כל מארח.
   
   הצגת סך הנכסים והמחיר הממוצע ללילה לכל מארח במערכת
    SELECT host_id, host_name, COUNT(apartment_id) AS total_properties, ROUND(AVG(price_per_night), 2) AS avg_host_price
    FROM public.host_properties_summary
    GROUP BY host_id, host_name
    ORDER BY total_properties DESC;

    CREATE VIEW public.restaurant_bookings_details AS
SELECT 
    r.rest_id,
    r.rest_name,
    r.cuisine_type,
    b.booking_id,
    b.booking_date,
    b.status AS booking_status, -- סטטוס ההזמנה (למשל Confirmed, Cancelled, Completed)
    rb.num_of_people
FROM 
    public.restaurant r
JOIN 
    public.restaurantbooking rb ON r.rest_id = rb.rest_id
JOIN 
    public.booking b ON rb.booking_id = b.booking_id;


    -- הצגת הזמנות מאושרות לקבוצות גדולות במסעדות איטלקיות
SELECT booking_id, rest_name, booking_date, num_of_people
FROM public.restaurant_bookings_details
WHERE cuisine_type = 'Italian' 
  AND booking_status = 'Confirmed' 
  AND num_of_people > 4
ORDER BY booking_date ASC;


-- מציאת ימי הפעילות העמוסים ביותר לכל מסעדה (לפי סך סועדים מצטבר)
SELECT 
    rest_name,
    booking_date,
    COUNT(booking_id) AS total_bookings,
    SUM(num_of_people) AS total_diners
FROM 
    public.restaurant_bookings_details
WHERE 
    booking_status != 'Cancelled'
GROUP BY 
    rest_name, booking_date
ORDER BY 
    total_diners DESC
