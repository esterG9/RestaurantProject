import os
import sys
import webbrowser
import threading
import time
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
import psycopg2
import psycopg2.extras
from dotenv import load_dotenv

# Load env variables if available
load_dotenv()

app = Flask(__name__, static_folder='static')
CORS(app)

# Database connection configuration
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_USER = os.getenv("DB_USER_SECRET", "esterG")
DB_PASS = os.getenv("DB_PASSWORD_SECRET", "esterG65")
DB_NAME = "IntegratedDB"  # The integrated database with 16 tables

def get_db_connection():
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME,
        cursor_factory=psycopg2.extras.RealDictCursor
    )
    conn.autocommit = True
    return conn

# Metadata mapping for the 16 tables
TABLES_METADATA = {
    "country": {
        "label": "Country (מדינות)",
        "pk": ["country_id"],
        "columns": [
            {"name": "country_id", "type": "int", "label": "Country ID", "required": True, "identity": False},
            {"name": "country_name", "type": "varchar", "label": "Country Name", "required": True, "identity": False}
        ],
        "fk": {},
        "display_col": "country_name"
    },
    "city": {
        "label": "City (ערים)",
        "pk": ["city_id"],
        "columns": [
            {"name": "city_id", "type": "int", "label": "City ID", "required": True, "identity": False},
            {"name": "city_name", "type": "varchar", "label": "City Name", "required": True, "identity": False},
            {"name": "country_id", "type": "int", "label": "Country", "required": True, "identity": False}
        ],
        "fk": {
            "country_id": {"table": "country", "display": "country_name"}
        },
        "display_col": "city_name"
    },
    "location": {
        "label": "Location (מיקומים)",
        "pk": ["location_id"],
        "columns": [
            {"name": "location_id", "type": "int", "label": "Location ID", "required": False, "identity": True},
            {"name": "address", "type": "varchar", "label": "Address", "required": True, "identity": False},
            {"name": "latitude", "type": "numeric", "label": "Latitude", "required": False, "identity": False},
            {"name": "longitude", "type": "numeric", "label": "Longitude", "required": False, "identity": False},
            {"name": "city_id", "type": "int", "label": "City", "required": False, "identity": False}
        ],
        "fk": {
            "city_id": {"table": "city", "display": "city_name"}
        },
        "display_col": "address"
    },
    "host": {
        "label": "Host (מארחים)",
        "pk": ["host_id"],
        "columns": [
            {"name": "host_id", "type": "int", "label": "Host ID", "required": True, "identity": False},
            {"name": "first_name", "type": "varchar", "label": "First Name", "required": True, "identity": False},
            {"name": "last_name", "type": "varchar", "label": "Last Name", "required": True, "identity": False},
            {"name": "phone", "type": "varchar", "label": "Phone", "required": True, "identity": False},
            {"name": "email", "type": "varchar", "label": "Email", "required": True, "identity": False},
            {"name": "country", "type": "varchar", "label": "Country Name", "required": True, "identity": False},
            {"name": "host_since", "type": "date", "label": "Host Since", "required": False, "identity": False}
        ],
        "fk": {},
        "display_col": "first_name || ' ' || last_name"
    },
    "tourist": {
        "label": "Tourist (תיירים)",
        "pk": ["tourist_id"],
        "columns": [
            {"name": "tourist_id", "type": "int", "label": "Tourist ID", "required": True, "identity": False},
            {"name": "first_name", "type": "varchar", "label": "First Name", "required": True, "identity": False},
            {"name": "last_name", "type": "varchar", "label": "Last Name", "required": True, "identity": False},
            {"name": "email", "type": "varchar", "label": "Email", "required": True, "identity": False},
            {"name": "phone", "type": "varchar", "label": "Phone", "required": True, "identity": False},
            {"name": "language", "type": "varchar", "label": "Language", "required": False, "identity": False},
            {"name": "password", "type": "varchar", "label": "Password", "required": False, "identity": False},
            {"name": "birthday", "type": "date", "label": "Birthday", "required": False, "identity": False},
            {"name": "user_name", "type": "varchar", "label": "Username", "required": False, "identity": False},
            {"name": "passport_number", "type": "varchar", "label": "Passport Number", "required": False, "identity": False},
            {"name": "country_id", "type": "int", "label": "Country", "required": False, "identity": False}
        ],
        "fk": {
            "country_id": {"table": "country", "display": "country_name"}
        },
        "display_col": "first_name || ' ' || last_name"
    },
    "restaurant": {
        "label": "Restaurant (מסעדות)",
        "pk": ["rest_id"],
        "columns": [
            {"name": "rest_id", "type": "int", "label": "Restaurant ID", "required": True, "identity": False},
            {"name": "rest_name", "type": "varchar", "label": "Restaurant Name", "required": True, "identity": False},
            {"name": "cuisine_type", "type": "varchar", "label": "Cuisine Type", "required": True, "identity": False},
            {"name": "phone_number", "type": "varchar", "label": "Phone Number", "required": True, "identity": False},
            {"name": "average_price", "type": "numeric", "label": "Average Price", "required": True, "identity": False},
            {"name": "location_id", "type": "int", "label": "Location", "required": True, "identity": False},
            {"name": "review_object_id", "type": "int", "label": "Review Object ID", "required": False, "identity": False}
        ],
        "fk": {
            "location_id": {"table": "location", "display": "address"},
            "review_object_id": {
                "table": "review_object",
                "display": "COALESCE((SELECT r.rest_name FROM restaurant r WHERE r.review_object_id = {alias}.review_object_id), (SELECT a.title FROM apartment a WHERE a.review_object_id = {alias}.review_object_id), 'Object ' || {alias}.review_object_id)"
            }
        },
        "display_col": "rest_name"
    },
    "booking": {
        "label": "Booking (הזמנות כללי)",
        "pk": ["booking_id"],
        "columns": [
            {"name": "booking_id", "type": "int", "label": "Booking ID", "required": True, "identity": False},
            {"name": "booking_date", "type": "date", "label": "Booking Date", "required": True, "identity": False},
            {"name": "status", "type": "varchar", "label": "Status", "required": True, "identity": False},
            {"name": "tourist_id", "type": "int", "label": "Tourist", "required": True, "identity": False},
            {"name": "payment_status", "type": "varchar", "label": "Payment Status", "required": False, "identity": False}
        ],
        "fk": {
            "tourist_id": {"table": "tourist", "display": "first_name || ' ' || last_name"}
        },
        "display_col": "booking_date || ' (ID: ' || booking_id || ')'"
    },
    "restaurantbooking": {
        "label": "Restaurant Booking (הזמנות מסעדה)",
        "pk": ["booking_id", "rest_id"],
        "columns": [
            {"name": "booking_id", "type": "int", "label": "Booking Date (ID)", "required": True, "identity": False},
            {"name": "rest_id", "type": "int", "label": "Restaurant", "required": True, "identity": False},
            {"name": "num_of_people", "type": "int", "label": "Number of People", "required": True, "identity": False}
        ],
        "fk": {
            "booking_id": {"table": "booking", "display": "booking_date"},
            "rest_id": {"table": "restaurant", "display": "rest_name"}
        },
        "display_col": "'Booking ID: ' || booking_id"
    },
    "apartment": {
        "label": "Apartment (דירות)",
        "pk": ["apartment_id"],
        "columns": [
            {"name": "apartment_id", "type": "int", "label": "Apartment ID", "required": False, "identity": True},
            {"name": "title", "type": "varchar", "label": "Title", "required": True, "identity": False},
            {"name": "description", "type": "text", "label": "Description", "required": True, "identity": False},
            {"name": "price_per_night", "type": "numeric", "label": "Price Per Night", "required": True, "identity": False},
            {"name": "max_guests", "type": "int", "label": "Max Guests", "required": True, "identity": False},
            {"name": "bathrooms", "type": "int", "label": "Bathrooms", "required": True, "identity": False},
            {"name": "bedrooms", "type": "int", "label": "Bedrooms", "required": True, "identity": False},
            {"name": "property_type", "type": "varchar", "label": "Property Type", "required": True, "identity": False},
            {"name": "location_id", "type": "int", "label": "Location", "required": True, "identity": False},
            {"name": "host_id", "type": "int", "label": "Host", "required": True, "identity": False},
            {"name": "review_object_id", "type": "int", "label": "Review Object ID", "required": False, "identity": False}
        ],
        "fk": {
            "location_id": {"table": "location", "display": "address"},
            "host_id": {"table": "host", "display": "first_name || ' ' || last_name"},
            "review_object_id": {
                "table": "review_object",
                "display": "COALESCE((SELECT r.rest_name FROM restaurant r WHERE r.review_object_id = {alias}.review_object_id), (SELECT a.title FROM apartment a WHERE a.review_object_id = {alias}.review_object_id), 'Object ' || {alias}.review_object_id)"
            }
        },
        "display_col": "title"
    },
    "apartmentbooking": {
        "label": "Apartment Booking (הזמנות דירה)",
        "pk": ["booking_id", "apartment_id"],
        "columns": [
            {"name": "booking_id", "type": "int", "label": "Booking Date (ID)", "required": True, "identity": False},
            {"name": "apartment_id", "type": "int", "label": "Apartment", "required": True, "identity": False},
            {"name": "check_in_date", "type": "date", "label": "Check In Date", "required": True, "identity": False},
            {"name": "check_out_date", "type": "date", "label": "Check Out Date", "required": True, "identity": False},
            {"name": "total_price", "type": "numeric", "label": "Total Price", "required": True, "identity": False},
            {"name": "number_of_guests", "type": "int", "label": "Number of Guests", "required": True, "identity": False}
        ],
        "fk": {
            "booking_id": {"table": "booking", "display": "booking_date"},
            "apartment_id": {"table": "apartment", "display": "title"}
        },
        "display_col": "'Booking ID: ' || booking_id"
    },
    "amenities": {
        "label": "Amenities (שירותים/מתקנים)",
        "pk": ["amenity_id"],
        "columns": [
            {"name": "amenity_id", "type": "int", "label": "Amenity ID", "required": False, "identity": True},
            {"name": "name", "type": "varchar", "label": "Amenity Name", "required": True, "identity": False}
        ],
        "fk": {},
        "display_col": "name"
    },
    "have": {
        "label": "Apartment Amenities (מתקנים בדירה)",
        "pk": ["amenity_id", "apartment_id"],
        "columns": [
            {"name": "amenity_id", "type": "int", "label": "Amenity", "required": True, "identity": False},
            {"name": "apartment_id", "type": "int", "label": "Apartment", "required": True, "identity": False}
        ],
        "fk": {
            "amenity_id": {"table": "amenities", "display": "name"},
            "apartment_id": {"table": "apartment", "display": "title"}
        },
        "display_col": "'Amenity: ' || amenity_id || ', Apartment: ' || apartment_id"
    },
    "apartmentphotos": {
        "label": "Apartment Photos (תמונות דירה)",
        "pk": ["photo_id"],
        "columns": [
            {"name": "photo_id", "type": "int", "label": "Photo ID", "required": False, "identity": True},
            {"name": "photo_url", "type": "text", "label": "Photo URL", "required": True, "identity": False},
            {"name": "caption", "type": "varchar", "label": "Caption", "required": False, "identity": False},
            {"name": "is_main_photo", "type": "boolean", "label": "Is Main Photo", "required": False, "identity": False},
            {"name": "apartment_id", "type": "int", "label": "Apartment", "required": True, "identity": False}
        ],
        "fk": {
            "apartment_id": {"table": "apartment", "display": "title"}
        },
        "display_col": "caption"
    },
    "review": {
        "label": "Review (חוות דעת כללי)",
        "pk": ["review_id"],
        "columns": [
            {"name": "review_id", "type": "int", "label": "Review ID", "required": False, "identity": True},
            {"name": "rating", "type": "int", "label": "Rating (0-5)", "required": True, "identity": False},
            {"name": "comment", "type": "text", "label": "Comment", "required": True, "identity": False},
            {"name": "review_date", "type": "date", "label": "Review Date", "required": False, "identity": False},
            {"name": "booking_type", "type": "varchar", "label": "Booking Type (restaurant/apartment)", "required": True, "identity": False},
            {"name": "tourist_id", "type": "int", "label": "Tourist", "required": True, "identity": False},
            {"name": "rest_or_apartment_id", "type": "int", "label": "Rest/Apartment ID", "required": True, "identity": False},
            {"name": "review_object_id", "type": "int", "label": "Review Object ID", "required": False, "identity": False}
        ],
        "fk": {
            "tourist_id": {"table": "tourist", "display": "first_name || ' ' || last_name"},
            "review_object_id": {
                "table": "review_object",
                "display": "COALESCE((SELECT r.rest_name FROM restaurant r WHERE r.review_object_id = {alias}.review_object_id), (SELECT a.title FROM apartment a WHERE a.review_object_id = {alias}.review_object_id), 'Object ' || {alias}.review_object_id)"
            },
            "rest_or_apartment_id": {
                "table": "review_object",
                "display": "CASE WHEN {table}.booking_type = 'restaurant' THEN (SELECT r.rest_name FROM restaurant r WHERE r.rest_id = {table}.rest_or_apartment_id) WHEN {table}.booking_type = 'apartment' THEN (SELECT a.title FROM apartment a WHERE a.apartment_id = {table}.rest_or_apartment_id) ELSE NULL END",
                "no_join": True
            }
        },
        "display_col": "comment"
    },
    "apartmentreview": {
        "label": "Apartment Review (חוות דעת דירה)",
        "pk": ["review_id"],
        "columns": [
            {"name": "review_id", "type": "int", "label": "General Review ID", "required": True, "identity": False},
            {"name": "cleanlinessrating", "type": "int", "label": "Cleanliness Rating", "required": True, "identity": False},
            {"name": "locationrating", "type": "int", "label": "Location Rating", "required": True, "identity": False},
            {"name": "valuerating", "type": "int", "label": "Value Rating", "required": True, "identity": False}
        ],
        "fk": {
            "review_id": {"table": "review", "display": "comment"}
        },
        "display_col": "'Review ID: ' || review_id"
    },
    "review_object": {
        "label": "Review Object (אובייקטים לביקורת)",
        "pk": ["review_object_id"],
        "columns": [
            {"name": "review_object_id", "type": "int", "label": "Review Object ID", "required": False, "identity": True}
        ],
        "fk": {},
        "display_col": "COALESCE((SELECT r.rest_name FROM restaurant r WHERE r.review_object_id = review_object.review_object_id), (SELECT a.title FROM apartment a WHERE a.review_object_id = review_object.review_object_id), 'Object ' || review_object.review_object_id)"
    }
}

# Serve Frontend SPA
@app.route('/')
def index():
    return send_from_directory(app.static_folder, 'index.html')

@app.route('/<path:path>')
def static_proxy(path):
    return send_from_directory(app.static_folder, path)

# API: Get List of Tables Metadata
@app.route('/api/tables', methods=['GET'])
def get_tables():
    return jsonify(TABLES_METADATA)

# API: Get enum values for options (like property_type, amenity_type)
@app.route('/api/enums', methods=['GET'])
def get_enums():
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Query property_type values
        cur.execute("SELECT enumlabel FROM pg_enum JOIN pg_type ON pg_enum.enumtypid = pg_type.oid WHERE typname = 'property_type';")
        prop_types = [r['enumlabel'] for r in cur.fetchall()]
        
        # Query amenity_type values
        cur.execute("SELECT enumlabel FROM pg_enum JOIN pg_type ON pg_enum.enumtypid = pg_type.oid WHERE typname = 'amenity_type';")
        amenity_types = [r['enumlabel'] for r in cur.fetchall()]
        
        cur.close()
        return jsonify({
            "property_type": prop_types,
            "amenity_type": amenity_types
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if conn:
            conn.close()

# API: Get Options list for FK selectors
@app.route('/api/options/<table_name>', methods=['GET'])
def get_table_options(table_name):
    if table_name not in TABLES_METADATA:
        return jsonify({"error": "Table not found"}), 404
    
    meta = TABLES_METADATA[table_name]
    pk_cols = meta["pk"]
    display_col = meta["display_col"]
    
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        pk_str = ", ".join(pk_cols)
        query = f"SELECT {pk_str}, ({display_col})::text AS display_label FROM {table_name} ORDER BY display_label;"
        cur.execute(query)
        rows = cur.fetchall()
        cur.close()
        
        # Build options dictionary format
        options = []
        for r in rows:
            pk_val = {col: r[col] for col in pk_cols}
            if len(pk_cols) == 1:
                pk_val = r[pk_cols[0]]
            options.append({
                "value": pk_val,
                "label": r["display_label"]
            })
            
        return jsonify(options)
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if conn:
            conn.close()

# API: Read Table Content (with FK names mapped via JOIN)
@app.route('/api/table/<table_name>', methods=['GET'])
def get_table_data(table_name):
    if table_name not in TABLES_METADATA:
        return jsonify({"error": "Table not found"}), 404
        
    meta = TABLES_METADATA[table_name]
    columns = [c["name"] for c in meta["columns"]]
    fk_mappings = meta["fk"]
    
    # Constructing Joined Query
    select_parts = [f"t.{c}" for c in columns]
    join_parts = []
    
    for i, (fk_col, fk_info) in enumerate(fk_mappings.items()):
        fk_table = fk_info["table"]
        fk_display = fk_info["display"]
        alias = f"join_{i}"
        
        if fk_info.get("no_join", False):
            fk_display_expr = fk_display.replace("{table}", "t")
            select_parts.append(f"({fk_display_expr})::text AS _fk_{fk_col}_display")
            continue
            
        # Find PK of target table
        target_pk = TABLES_METADATA[fk_table]["pk"][0]
        
        join_parts.append(f"LEFT JOIN {fk_table} {alias} ON t.{fk_col} = {alias}.{target_pk}")
        
        if "{alias}" in fk_display:
            fk_display_expr = fk_display.replace("{alias}", alias)
            select_parts.append(f"({fk_display_expr})::text AS _fk_{fk_col}_display")
        else:
            select_parts.append(f"({alias}.{fk_display})::text AS _fk_{fk_col}_display")
        
    select_clause = ", ".join(select_parts)
    join_clause = " ".join(join_parts)
    
    # Default order by PK descending to show newest first
    order_clause = ", ".join([f"t.{col} DESC" for col in meta["pk"]])
    
    query = f"SELECT {select_clause} FROM {table_name} t {join_clause} ORDER BY {order_clause} LIMIT 1000;"
    
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(query)
        rows = cur.fetchall()
        
        # Get actual total count of rows in the table
        cur.execute(f"SELECT COUNT(*) AS total_count FROM {table_name};")
        total_count = cur.fetchone()["total_count"]
        
        # Get count and suggest next ID for insertion
        suggested_id = None
        if len(meta["pk"]) == 1:
            pk_col = meta["pk"][0]
            col_meta = next(c for c in meta["columns"] if c["name"] == pk_col)
            if not col_meta.get("identity", False):
                cur.execute(f"SELECT COALESCE(MAX({pk_col}), 0) + 1 AS next_id FROM {table_name};")
                suggested_id = cur.fetchone()["next_id"]
                
        cur.close()
        return jsonify({
            "rows": rows,
            "suggested_id": suggested_id,
            "total_count": total_count
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if conn:
            conn.close()

# API: Fetch single record by key (for update auto-loading)
@app.route('/api/table/<table_name>/get-by-key', methods=['GET'])
def get_by_key(table_name):
    if table_name not in TABLES_METADATA:
        return jsonify({"error": "Table not found"}), 404
        
    meta = TABLES_METADATA[table_name]
    pk_cols = meta["pk"]
    
    # Build where clause
    where_parts = []
    values = []
    for col in pk_cols:
        val = request.args.get(col)
        if val is None:
            return jsonify({"error": f"Missing key column parameter: {col}"}), 400
        where_parts.append(f"{col} = %s")
        values.append(val)
        
    where_clause = " AND ".join(where_parts)
    query = f"SELECT * FROM {table_name} WHERE {where_clause};"
    
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(query, values)
        row = cur.fetchone()
        cur.close()
        
        if not row:
            return jsonify({"error": "Record not found"}), 404
            
        return jsonify(row)
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if conn:
            conn.close()

# API: Insert Record
@app.route('/api/table/<table_name>', methods=['POST'])
def insert_data(table_name):
    if table_name not in TABLES_METADATA:
        return jsonify({"error": "Table not found"}), 404
        
    meta = TABLES_METADATA[table_name]
    data = request.json
    
    cols = []
    vals = []
    placeholders = []
    
    for c in meta["columns"]:
        if c["identity"]:
            continue  # Let database generate identity column values
        val = data.get(c["name"])
        
        # Handle nullable empty values
        if val == "" or val is None:
            if c["required"]:
                return jsonify({"error": f"Column {c['name']} is required"}), 400
            val = None
            
        cols.append(c["name"])
        vals.append(val)
        placeholders.append("%s")
        
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Auto-generate or lookup review_object_id
        if table_name in ["restaurant", "apartment"]:
            cur.execute("INSERT INTO review_object DEFAULT VALUES RETURNING review_object_id;")
            generated_ro_id = cur.fetchone()["review_object_id"]
            if "review_object_id" in cols:
                idx = cols.index("review_object_id")
                vals[idx] = generated_ro_id
            else:
                cols.append("review_object_id")
                vals.append(generated_ro_id)
                placeholders.append("%s")
        elif table_name == "review":
            booking_type = data.get("booking_type")
            rest_or_apt_id = data.get("rest_or_apartment_id")
            if booking_type and rest_or_apt_id:
                if booking_type == "restaurant":
                    cur.execute("SELECT review_object_id FROM restaurant WHERE rest_id = %s;", (rest_or_apt_id,))
                else:
                    cur.execute("SELECT review_object_id FROM apartment WHERE apartment_id = %s;", (rest_or_apt_id,))
                row = cur.fetchone()
                ro_id = row["review_object_id"] if row else None
                if ro_id:
                    if "review_object_id" in cols:
                        idx = cols.index("review_object_id")
                        vals[idx] = ro_id
                    else:
                        cols.append("review_object_id")
                        vals.append(ro_id)
                        placeholders.append("%s")
                        
        cols_str = ", ".join(cols)
        placeholders_str = ", ".join(placeholders)
        query = f"INSERT INTO {table_name} ({cols_str}) VALUES ({placeholders_str});"
        
        cur.execute(query, vals)
        conn.commit()
        cur.close()
        return jsonify({"success": True, "message": "Record inserted successfully"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if conn:
            conn.close()

# API: Update Record
@app.route('/api/table/<table_name>', methods=['PUT'])
def update_data(table_name):
    if table_name not in TABLES_METADATA:
        return jsonify({"error": "Table not found"}), 404
        
    meta = TABLES_METADATA[table_name]
    data = request.json
    
    set_parts = []
    vals = []
    
    # Generate sets for non-pk and non-identity columns
    for c in meta["columns"]:
        if c["name"] in meta["pk"] or c["identity"]:
            continue
            
        val = data.get(c["name"])
        if val == "" or val is None:
            if c["required"]:
                return jsonify({"error": f"Column {c['name']} is required"}), 400
            val = None
            
        set_parts.append(f"{c['name']} = %s")
        vals.append(val)
        
    # Generate where clause for pk columns
    where_parts = []
    for pk in meta["pk"]:
        val = data.get(pk)
        if val is None or val == "":
            return jsonify({"error": f"Primary key column {pk} is required for update"}), 400
        where_parts.append(f"{pk} = %s")
        vals.append(val)
        
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Auto-update review_object_id for review updates if booking_type/rest_or_apartment_id changed
        if table_name == "review":
            booking_type = data.get("booking_type")
            rest_or_apt_id = data.get("rest_or_apartment_id")
            if booking_type and rest_or_apt_id:
                if booking_type == "restaurant":
                    cur.execute("SELECT review_object_id FROM restaurant WHERE rest_id = %s;", (rest_or_apt_id,))
                else:
                    cur.execute("SELECT review_object_id FROM apartment WHERE apartment_id = %s;", (rest_or_apt_id,))
                row = cur.fetchone()
                ro_id = row["review_object_id"] if row else None
                if ro_id:
                    col_names_in_sets = [c["name"] for c in meta["columns"] if c["name"] not in meta["pk"] and not c["identity"]]
                    if "review_object_id" in col_names_in_sets:
                        val_idx = col_names_in_sets.index("review_object_id")
                        vals[val_idx] = ro_id
                        
        set_clause = ", ".join(set_parts)
        where_clause = " AND ".join(where_parts)
        query = f"UPDATE {table_name} SET {set_clause} WHERE {where_clause};"
        
        cur.execute(query, vals)
        conn.commit()
        cur.close()
        return jsonify({"success": True, "message": "Record updated successfully"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if conn:
            conn.close()

# API: Delete Record
@app.route('/api/table/<table_name>', methods=['DELETE'])
def delete_data(table_name):
    if table_name not in TABLES_METADATA:
        return jsonify({"error": "Table not found"}), 404
        
    meta = TABLES_METADATA[table_name]
    data = request.json or request.args
    
    where_parts = []
    vals = []
    
    for pk in meta["pk"]:
        val = data.get(pk)
        if val is None or val == "":
            return jsonify({"error": f"Primary key column {pk} is required for delete"}), 400
        where_parts.append(f"{pk} = %s")
        vals.append(val)
        
    where_clause = " AND ".join(where_parts)
    query = f"DELETE FROM {table_name} WHERE {where_clause};"
    
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(query, vals)
        conn.commit()
        cur.close()
        return jsonify({"success": True, "message": "Record deleted successfully"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if conn:
            conn.close()

# API: Run Stage B Queries
@app.route('/api/queries/run', methods=['POST'])
def run_query():
    data = request.json
    query_id = data.get("query_id")
    params = data.get("params", {})
    
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Implement the 8 queries from Stage B
        if query_id == "query1":
            # Search restaurant by country name
            country_name = params.get("country", "").strip()
            sql = """
                SELECT r.rest_name, l.address, c.city_name, co.country_name
                FROM restaurant r
                JOIN location l ON r.location_id = l.location_id
                JOIN city c ON l.city_id = c.city_id
                JOIN country co ON c.country_id = co.country_id
                WHERE TRIM(co.country_name) ILIKE %s
                ORDER BY r.rest_name;
            """
            cur.execute(sql, (f"%{country_name}%",))
            
        elif query_id == "query2":
            # Search restaurant by rating 5
            sql = """
                SELECT r.rest_name, r.cuisine_type, r.average_price
                FROM restaurant r
                WHERE EXISTS (
                    SELECT 1 
                    FROM review f
                    WHERE f.review_object_id = r.review_object_id AND f.rating = 5
                )
                ORDER BY r.average_price DESC;
            """
            cur.execute(sql)
            
        elif query_id == "query3":
            # Show reviews of a restaurant from newest to oldest
            rest_name = params.get("restaurant", "").strip()
            sql = """
                SELECT
                    f.review_id,
                    res.rest_name,
                    t.first_name,
                    t.last_name,
                    f.review_date,
                    f.comment
                FROM review f
                JOIN restaurant res ON f.review_object_id = res.review_object_id
                JOIN tourist t ON f.tourist_id = t.tourist_id
                WHERE res.rest_name ILIKE %s
                ORDER BY f.review_date DESC;
            """
            cur.execute(sql, (f"%{rest_name}%",))
            
        elif query_id == "query4":
            # Count bookings per tourist
            sql = """
                SELECT
                    t.tourist_id,
                    t.first_name,
                    t.last_name,
                    COUNT(b.booking_id) AS num_of_bookings
                FROM tourist t
                LEFT JOIN booking b ON t.tourist_id = b.tourist_id
                GROUP BY t.tourist_id, t.first_name, t.last_name
                ORDER BY num_of_bookings DESC;
            """
            cur.execute(sql)
            
        elif query_id == "query5":
            # Count bookings in month/year
            year = int(params.get("year", 2025))
            month = int(params.get("month", 1))
            sql = """
                SELECT 
                    booking_id,
                    booking_date,
                    status,
                    tourist_id,
                    payment_status
                FROM booking
                WHERE EXTRACT(YEAR FROM booking_date) = %s
                  AND EXTRACT(MONTH FROM booking_date) = %s
                ORDER BY booking_date;
            """
            cur.execute(sql, (year, month))
            
        elif query_id == "query6":
            # Top 5 active tourists with confirmed bookings
            sql = """
                SELECT 
                    t.first_name, 
                    t.last_name, 
                    t.email, 
                    COUNT(b.booking_id) AS total_confirmed_bookings,
                    MAX(b.booking_date) AS last_booking_date
                FROM tourist t
                JOIN booking b ON t.tourist_id = b.tourist_id
                WHERE b.status = 'Confirmed'
                GROUP BY t.tourist_id, t.first_name, t.last_name, t.email
                HAVING COUNT(b.booking_id) > 1
                ORDER BY total_confirmed_bookings DESC
                LIMIT 5;
            """
            cur.execute(sql)
            
        elif query_id == "query7":
            # Cancelled bookings with tourist and restaurant/apartment info
            sql = """
                SELECT
                    b.booking_id,
                    b.booking_date,
                    b.status,
                    t.first_name,
                    t.last_name
                FROM booking b
                JOIN tourist t ON b.tourist_id = t.tourist_id
                WHERE b.status = 'Cancelled'
                ORDER BY b.booking_date DESC;
            """
            cur.execute(sql)
            
        elif query_id == "query8":
            # Cheapest restaurant in city/cuisine
            sql = """
                SELECT
                    c.city_name,
                    r.cuisine_type,
                    r.rest_name,
                    r.average_price
                FROM restaurant r
                JOIN location l ON r.location_id = l.location_id
                JOIN city c ON l.city_id = c.city_id
                WHERE r.average_price = (
                    SELECT MIN(r2.average_price)
                    FROM restaurant r2
                    JOIN location l2 ON r2.location_id = l2.location_id
                    JOIN city c2 ON l2.city_id = c2.city_id
                    WHERE c2.city_id = c.city_id
                      AND r2.cuisine_type = r.cuisine_type
                )
                ORDER BY c.city_name, r.cuisine_type, r.rest_name;
            """
            cur.execute(sql)
            
        else:
            return jsonify({"error": "Unknown query ID"}), 400
            
        rows = cur.fetchall()
        cur.close()
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if conn:
            conn.close()

# API: Execute Stage D Stored Procedures / Functions
@app.route('/api/procedures/run', methods=['POST'])
def run_procedure():
    data = request.json
    proc_id = data.get("proc_id")
    params = data.get("params", {})
    
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        result = {}
        
        if proc_id == "func_host_revenue":
            # host_revenue_report(p_host_id)
            host_id = int(params.get("host_id"))
            cur.execute("SELECT host_revenue_report(%s) AS revenue;", (host_id,))
            revenue = cur.fetchone()["revenue"]
            result = {
                "success": True,
                "output_label": f"Host {host_id} Total Revenue",
                "value": str(revenue)
            }
            
        elif proc_id == "proc_update_prices":
            # update_host_apartment_prices(p_host_id, p_percentage)
            host_id = int(params.get("host_id"))
            percentage = float(params.get("percent"))
            
            # Fetch apartments before
            cur.execute("SELECT apartment_id, title, price_per_night FROM apartment WHERE host_id = %s ORDER BY apartment_id;", (host_id,))
            before = cur.fetchall()
            
            # Call procedure
            cur.execute("CALL update_host_apartment_prices(%s, %s);", (host_id, percentage))
            conn.commit()
            
            # Fetch apartments after
            cur.execute("SELECT apartment_id, title, price_per_night FROM apartment WHERE host_id = %s ORDER BY apartment_id;", (host_id,))
            after = cur.fetchall()
            
            result = {
                "success": True,
                "message": f"Updated apartment prices for host {host_id} by {percentage}%.",
                "before": before,
                "after": after
            }
            
        elif proc_id == "func_tourist_rating":
            # fn_get_tourist_average_rating(p_tourist_id)
            tourist_id = int(params.get("tourist_id"))
            cur.execute("SELECT fn_get_tourist_average_rating(%s) AS avg_rating;", (tourist_id,))
            rating = cur.fetchone()["avg_rating"]
            result = {
                "success": True,
                "output_label": f"Tourist {tourist_id} Average Rating Given",
                "value": str(rating)
            }
            
        elif proc_id == "proc_reward_tourists":
            # sp_reward_loyal_tourists(p_min_bookings)
            min_bookings = int(params.get("min_bookings"))
            
            # Since standard notices raise in procedures can be captured, we fetch notices
            cur.execute("CALL sp_reward_loyal_tourists(%s);", (min_bookings,))
            conn.commit()
            
            notices = conn.notices
            notices_text = "\n".join(notices)
            
            # We can also fetch the loyal tourists to show in a table
            cur.execute("""
                SELECT t.tourist_id, t.first_name, t.last_name, COUNT(b.booking_id) AS booking_count,
                       CASE WHEN COUNT(b.booking_id) >= 5 THEN 'VIP Customer' ELSE 'Regular Customer' END AS status
                FROM tourist t
                JOIN booking b ON t.tourist_id = b.tourist_id
                GROUP BY t.tourist_id, t.first_name, t.last_name
                HAVING COUNT(b.booking_id) >= %s
                ORDER BY booking_count DESC;
            """, (min_bookings,))
            tourists = cur.fetchall()
            
            result = {
                "success": True,
                "message": f"Loyalty reward program executed for minimum {min_bookings} bookings.",
                "logs": notices_text,
                "tourists": tourists
            }
            
        else:
            return jsonify({"error": "Unknown routine ID"}), 400
            
        cur.close()
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if conn:
            conn.close()

# Auto-open browser
def open_browser():
    time.sleep(1.5)
    webbrowser.open("http://localhost:5000")

if __name__ == "__main__":
    # Start browser auto-opener thread
    threading.Thread(target=open_browser, daemon=True).start()
    
    print("--------------------------------------------------")
    print(" Restaurant Database GUI system running on:")
    print(" http://localhost:5000")
    print(" Press Ctrl+C to terminate.")
    print("--------------------------------------------------")
    
    app.run(host="localhost", port=5000, debug=True, use_reloader=False)
