// Global application state
let tablesMetadata = {};
let currentTable = "";
let currentEnumData = {};
let cachedFkOptions = {}; // Caches option lists to reduce network overhead
let formMode = "add"; // "add" or "edit"

document.addEventListener("DOMContentLoaded", () => {
    initNavigation();
    loadDashboardStats();
    loadTablesMetadata();
    initExplorerEvents();
    initQueryEvents();
    initProcedureEvents();
});

// -----------------------------------------
// Navigation & Routing Logic
// -----------------------------------------
function initNavigation() {
    const menuItems = document.querySelectorAll(".menu-item");
    const sections = document.querySelectorAll(".page-section");
    const pageTitle = document.getElementById("page-title");
    const pageSubtitle = document.getElementById("page-subtitle");

    const pageMeta = {
        "page-dashboard": { title: "לוח בקרה", subtitle: "מבט על של המערכת המאוחדת" },
        "page-explorer": { title: "סייר טבלאות", subtitle: "ניהול וביצוע פעולות CRUD על כל 16 הטבלאות" },
        "page-queries": { title: "שאילתות מערכת", subtitle: "הרצת שאילתות מורכבות משלב ב'" },
        "page-procedures": { title: "פונקציות ופרוצדורות", subtitle: "הפעלת תתי-תוכניות משלב ד' ומעקב אחר השפעתן" }
    };

    menuItems.forEach(item => {
        item.addEventListener("click", (e) => {
            e.preventDefault();
            const target = item.getAttribute("data-target");

            // Toggle active menu item
            menuItems.forEach(mi => mi.classList.remove("active"));
            item.classList.add("active");

            // Toggle active section
            sections.forEach(sec => {
                if (sec.id === target) {
                    sec.classList.add("active");
                } else {
                    sec.classList.remove("active");
                }
            });

            // Update Titles
            if (pageMeta[target]) {
                pageTitle.textContent = pageMeta[target].title;
                pageSubtitle.textContent = pageMeta[target].subtitle;
            }

            // Reload dashboard stats when navigation goes back to dashboard
            if (target === "page-dashboard") {
                loadDashboardStats();
            }
        });
    });
}

// Toast Notifications Helper
function showToast(message, type = "success") {
    const toast = document.getElementById("toast");
    const toastMsg = document.getElementById("toast-message");
    
    toast.className = `notification-toast ${type} show`;
    toastMsg.textContent = message;

    setTimeout(() => {
        toast.classList.remove("show");
    }, 4000);
}

// -----------------------------------------
// Dashboard Stats Loading
// -----------------------------------------
async function loadDashboardStats() {
    try {
        const fetchCount = async (tbl) => {
            const res = await fetch(`/api/table/${tbl}`);
            const data = await res.json();
            return data.rows ? data.rows.length : 0;
        };

        const tourists = await fetchCount("tourist");
        const restaurants = await fetchCount("restaurant");
        const apartments = await fetchCount("apartment");
        const bookings = await fetchCount("booking");

        document.getElementById("stat-tourists").textContent = tourists;
        document.getElementById("stat-restaurants").textContent = restaurants;
        document.getElementById("stat-apartments").textContent = apartments;
        document.getElementById("stat-bookings").textContent = bookings;
    } catch (err) {
        console.error("Error loading dashboard stats:", err);
    }
}

// -----------------------------------------
// Database Explorer (CRUD) Logic
// -----------------------------------------
async function loadTablesMetadata() {
    try {
        // Fetch enums first
        const enumRes = await fetch("/api/enums");
        currentEnumData = await enumRes.json();

        // Fetch tables meta
        const res = await fetch("/api/tables");
        tablesMetadata = await res.json();
        
        const select = document.getElementById("table-select");
        
        // Sort tables alphabetically by display label
        const sortedTables = Object.entries(tablesMetadata).sort((a, b) => 
            a[1].label.localeCompare(b[1].label)
        );

        sortedTables.forEach(([name, meta]) => {
            const opt = document.createElement("option");
            opt.value = name;
            opt.textContent = meta.label;
            select.appendChild(opt);
        });
    } catch (err) {
        showToast("שגיאה בטעינת מבנה הטבלאות: " + err.message, "error");
    }
}

function initExplorerEvents() {
    const tableSelect = document.getElementById("table-select");
    const btnAddRecord = document.getElementById("btn-add-record");
    const btnCloseModal = document.getElementById("btn-close-modal");
    const btnCancelModal = document.getElementById("btn-cancel-modal");
    const btnSaveRecord = document.getElementById("btn-save-record");

    tableSelect.addEventListener("change", (e) => {
        currentTable = e.target.value;
        if (currentTable) {
            btnAddRecord.disabled = false;
            loadTableData(currentTable);
        }
    });

    btnAddRecord.addEventListener("click", () => {
        openCrudModal("add");
    });

    btnCloseModal.addEventListener("click", closeCrudModal);
    btnCancelModal.addEventListener("click", closeCrudModal);
    btnSaveRecord.addEventListener("click", saveRecord);
}

// Fetch and display rows in table
async function loadTableData(tableName) {
    const container = document.getElementById("explorer-table-container");
    container.innerHTML = `<div class="table-placeholder"><i class="fa-solid fa-spinner fa-spin placeholder-icon"></i><p>טוען נתונים מהשרת...</p></div>`;
    
    document.getElementById("explorer-info-bar").style.display = "none";

    try {
        const res = await fetch(`/api/table/${tableName}`);
        const data = await res.json();

        if (data.error) {
            container.innerHTML = `<div class="table-placeholder"><i class="fa-solid fa-triangle-exclamation placeholder-icon console-error"></i><p>שגיאה בטעינת הנתונים: ${data.error}</p></div>`;
            return;
        }

        const meta = tablesMetadata[tableName];
        const rows = data.rows;

        // Show record counts and details
        document.getElementById("explorer-info-bar").style.display = "flex";
        document.getElementById("record-count-label").textContent = `סה"כ רשומות: ${rows.length}`;
        
        const suggestedLabel = document.getElementById("suggested-id-label");
        if (data.suggested_id) {
            suggestedLabel.style.display = "inline-block";
            suggestedLabel.textContent = `מזהה מוצע לרשומה חדשה: ${data.suggested_id}`;
            suggestedLabel.dataset.suggested = data.suggested_id;
        } else {
            suggestedLabel.style.display = "none";
        }

        if (rows.length === 0) {
            container.innerHTML = `
                <div class="table-placeholder">
                    <i class="fa-solid fa-folder-open placeholder-icon"></i>
                    <p>הטבלה ריקה, לא נמצאו רשומות התואמות לתנאי.</p>
                </div>`;
            return;
        }

        // Build Table header
        let html = `<table><thead><tr>`;
        meta.columns.forEach(col => {
            html += `<th>${col.label}</th>`;
        });
        html += `<th>פעולות</th></tr></thead><tbody>`;

        // Build Table rows
        rows.forEach(row => {
            html += `<tr>`;
            meta.columns.forEach(col => {
                const val = row[col.name];
                
                // Mapped FK value check
                const fkDisplayKey = `_fk_${col.name}_display`;
                let displayVal = val;
                
                if (row[fkDisplayKey] !== undefined && row[fkDisplayKey] !== null) {
                    displayVal = row[fkDisplayKey]; // Show name instead of ID
                } else if (val === true) {
                    displayVal = "כן (True)";
                } else if (val === false) {
                    displayVal = "לא (False)";
                } else if (val === null || val === "") {
                    displayVal = `<span style="color:var(--text-muted); font-style:italic;">NULL</span>`;
                } else if (col.type === "date" && val) {
                    // format date nicely
                    displayVal = val.split("T")[0];
                }

                html += `<td>${displayVal}</td>`;
            });

            // Action buttons (JSON encode row data for click handles)
            const rowStr = encodeURIComponent(JSON.stringify(row));
            html += `
                <td class="action-cell">
                    <button class="icon-btn icon-edit" onclick="editRow('${rowStr}')" title="עריכה ועדכון">
                        <i class="fa-solid fa-pen-to-square"></i>
                    </button>
                    <button class="icon-btn icon-delete" onclick="deleteRow('${rowStr}')" title="מחיקה">
                        <i class="fa-solid fa-trash-can"></i>
                    </button>
                </td></tr>`;
        });

        html += `</tbody></table>`;
        container.innerHTML = html;

    } catch (err) {
        container.innerHTML = `<div class="table-placeholder"><i class="fa-solid fa-triangle-exclamation placeholder-icon console-error"></i><p>שגיאה בחיבור לשרת: ${err.message}</p></div>`;
    }
}

// -----------------------------------------
// CRUD Modals and Options Load
// -----------------------------------------
async function openCrudModal(mode, rowData = null) {
    formMode = mode;
    const meta = tablesMetadata[currentTable];
    const modal = document.getElementById("record-modal");
    const modalTitle = document.getElementById("modal-title");
    const inputsGrid = document.getElementById("modal-inputs-grid");
    
    modalTitle.textContent = mode === "add" ? `הוספת רשומה חדשה - ${meta.label}` : `עדכון רשומה - ${meta.label}`;
    inputsGrid.innerHTML = "";

    // Show suggested next ID if available
    const suggestedId = document.getElementById("suggested-id-label").dataset.suggested;

    // Load FK option data in parallel
    const fkPromises = [];
    const fkCols = Object.keys(meta.fk);
    
    // For review table, ensure both restaurant and apartment options are preloaded for dynamic dropdowns
    if (currentTable === "review") {
        ["restaurant", "apartment"].forEach(tbl => {
            if (!cachedFkOptions[tbl]) {
                fkPromises.push(
                    fetch(`/api/options/${tbl}`)
                        .then(res => res.json())
                        .then(options => {
                            cachedFkOptions[tbl] = options;
                        })
                        .catch(e => console.error("Error loading options:", e))
                );
            }
        });
    }

    fkCols.forEach(fkCol => {
        const targetTable = meta.fk[fkCol].table;
        if (!cachedFkOptions[targetTable]) {
            fkPromises.push(
                fetch(`/api/options/${targetTable}`)
                    .then(res => res.json())
                    .then(options => {
                        cachedFkOptions[targetTable] = options;
                    })
                    .catch(e => console.error("Error loading FK options:", e))
            );
        }
    });

    if (fkPromises.length > 0) {
        inputsGrid.innerHTML = `<div style="grid-column: 1/-1; text-align:center; padding: 20px;"><i class="fa-solid fa-spinner fa-spin"></i> טוען רשימת מפתחות זרים...</div>`;
        await Promise.all(fkPromises);
        inputsGrid.innerHTML = "";
    }

    // Generate fields dynamically
    meta.columns.forEach(col => {
        const formGroup = document.createElement("div");
        formGroup.className = "form-group";
        
        let labelHtml = `<label for="field-${col.name}">${col.label}`;
        if (col.required && !col.identity) {
            labelHtml += ` <span class="required-marker">*</span>`;
        }
        labelHtml += `:</label>`;
        formGroup.innerHTML = labelHtml;

        let inputHtml = "";

        // Check if field is Primary Key
        const isPk = meta.pk.includes(col.name);

        // Define form control depending on schema types
        if (col.identity) {
            // Identity columns are auto-generated by DB, read-only
            inputHtml = `<input type="text" id="field-${col.name}" name="${col.name}" placeholder="מיוצר אוטומטית ע&quot;י בסיס הנתונים" disabled class="input-disabled">`;
        } 
        else if (col.name === "booking_type" && currentTable === "review") {
            // Render booking_type as dropdown in review form
            inputHtml = `
                <select id="field-${col.name}" name="${col.name}">
                    <option value="">-- בחר סוג הזמנה --</option>
                    <option value="restaurant">מסעדה (Restaurant)</option>
                    <option value="apartment">דירה (Apartment)</option>
                </select>`;
        }
        else if (col.name === "review_object_id") {
            // Auto-managed review_object_id is disabled/readonly for users
            inputHtml = `<input type="text" id="field-${col.name}" name="${col.name}" placeholder="מיוצר אוטומטית ע&quot;י המערכת" disabled class="input-disabled">`;
        }
        else if (meta.fk[col.name]) {
            // Foreign key dropdown selector (names instead of IDs)
            const targetTable = meta.fk[col.name].table;
            const options = cachedFkOptions[targetTable] || [];
            
            inputHtml = `<select id="field-${col.name}" name="${col.name}" ${isPk && mode === "edit" ? "disabled" : ""}>`;
            inputHtml += `<option value="">-- בחר ${col.label} --</option>`;
            options.forEach(opt => {
                // For composite keys or single values
                const valStr = typeof opt.value === 'object' ? JSON.stringify(opt.value) : opt.value;
                inputHtml += `<option value='${valStr}'>${opt.label}</option>`;
            });
            inputHtml += `</select>`;
        } 
        else if (col.name === "property_type" && currentEnumData.property_type) {
            // property_type enum dropdown
            inputHtml = `<select id="field-${col.name}" name="${col.name}">`;
            inputHtml += `<option value="">-- בחר סוג נכס --</option>`;
            currentEnumData.property_type.forEach(val => {
                inputHtml += `<option value="${val}">${val}</option>`;
            });
            inputHtml += `</select>`;
        }
        else if (col.name === "name" && currentTable === "amenities" && currentEnumData.amenity_type) {
            // amenity name enum dropdown
            inputHtml = `<select id="field-${col.name}" name="${col.name}">`;
            inputHtml += `<option value="">-- בחר שם שירות --</option>`;
            currentEnumData.amenity_type.forEach(val => {
                inputHtml += `<option value="${val}">${val}</option>`;
            });
            inputHtml += `</select>`;
        }
        else if (col.type === "date") {
            inputHtml = `<input type="date" id="field-${col.name}" name="${col.name}" ${isPk && mode === "edit" ? "readonly" : ""}>`;
        } 
        else if (col.type === "int") {
            // Prepopulate PK with suggested ID on add
            let defaultVal = "";
            if (isPk && mode === "add" && suggestedId) {
                defaultVal = suggestedId;
            }
            inputHtml = `<input type="number" id="field-${col.name}" name="${col.name}" value="${defaultVal}" ${isPk && mode === "edit" ? "readonly" : ""}>`;
        }
        else if (col.type === "boolean" || col.type === "bool") {
            inputHtml = `
                <select id="field-${col.name}" name="${col.name}">
                    <option value="">-- בחר --</option>
                    <option value="true">כן (True)</option>
                    <option value="false">לא (False)</option>
                </select>`;
        }
        else {
            // Default text/varchar input
            inputHtml = `<input type="text" id="field-${col.name}" name="${col.name}" ${isPk && mode === "edit" ? "readonly" : ""}>`;
        }

        // If this is a PK and we are in Edit mode, or if it is a PK input, add lookup helper
        // requirement: "בזמן עדכון (update) - המשתמש ימלא את המפתח והמערכת תביא את יתר השדות ואז משם מעדכנים"
        if (isPk && mode === "add") {
            // We can also allow them to trigger lookup in ADD mode if they want to turn it into an update
            formGroup.innerHTML += `
                <div style="display:flex; gap: 8px; align-items:center;">
                    ${inputHtml}
                    <button type="button" class="btn btn-secondary" onclick="loadDataByKey()" style="padding:8px 12px; font-size:12px;" title="טעינת שדות רשומה לפי המפתח שהוקלד">
                        <i class="fa-solid fa-cloud-arrow-down"></i> טען לפי מפתח
                    </button>
                </div>`;
        } else {
            formGroup.innerHTML += inputHtml;
        }
        
        inputsGrid.appendChild(formGroup);
    });

    // Add event listener to booking_type to update rest_or_apartment_id options dynamically
    if (currentTable === "review") {
        const bookingTypeSelect = document.getElementById("field-booking_type");
        if (bookingTypeSelect) {
            bookingTypeSelect.addEventListener("change", updateRestOrApartmentSelect);
        }
    }

    // If edit mode and rowData supplied, fill inputs
    if (mode === "edit" && rowData) {
        fillFormFields(rowData);
    }

    modal.classList.add("open");
}

function updateRestOrApartmentSelect() {
    const bookingTypeSelect = document.getElementById("field-booking_type");
    const targetSelect = document.getElementById("field-rest_or_apartment_id");
    if (!bookingTypeSelect || !targetSelect) return;
    
    const bookingType = bookingTypeSelect.value;
    const previousVal = targetSelect.value;
    
    targetSelect.innerHTML = `<option value="">-- בחר מסעדה או דירה --</option>`;
    
    if (bookingType === "restaurant" || bookingType === "apartment") {
        const options = cachedFkOptions[bookingType] || [];
        options.forEach(opt => {
            const optElem = document.createElement("option");
            optElem.value = typeof opt.value === 'object' ? JSON.stringify(opt.value) : opt.value;
            optElem.textContent = opt.label;
            targetSelect.appendChild(optElem);
        });
    }
    
    if (previousVal) {
        targetSelect.value = previousVal;
    }
}

function fillFormFields(data) {
    const meta = tablesMetadata[currentTable];
    meta.columns.forEach(col => {
        const input = document.getElementById(`field-${col.name}`);
        if (!input) return;

        let val = data[col.name];
        
        if (col.type === "date" && val) {
            val = val.split("T")[0]; // extract date format
        }

        if (input.tagName === "SELECT") {
            // For boolean
            if (val === true) val = "true";
            if (val === false) val = "false";
            
            // Set value
            input.value = val !== null ? val.toString() : "";
        } else {
            input.value = val !== null ? val : "";
        }
    });

    // For review table, we must update the dependent dropdown options
    if (currentTable === "review") {
        updateRestOrApartmentSelect();
        const targetSelect = document.getElementById("field-rest_or_apartment_id");
        if (targetSelect && data["rest_or_apartment_id"] !== undefined && data["rest_or_apartment_id"] !== null) {
            targetSelect.value = data["rest_or_apartment_id"].toString();
        }
    }
}

// Requirement: Autofill other fields after user types/fills primary key
async function loadDataByKey() {
    const meta = tablesMetadata[currentTable];
    const pk_cols = meta["pk"];
    
    // Build query params of PK values typed
    const params = new URLSearchParams();
    let missingPk = false;

    for (let col of pk_cols) {
        const input = document.getElementById(`field-${col}`);
        if (!input || !input.value) {
            missingPk = true;
            break;
        }
        params.append(col, input.value);
    }

    if (missingPk) {
        showToast("אנא הזן את כל שדות מפתח הברזל (Primary Key) כדי לטעון נתונים", "error");
        return;
    }

    try {
        const res = await fetch(`/api/table/${currentTable}/get-by-key?${params.toString()}`);
        const data = await res.json();

        if (data.error) {
            showToast("מפתח לא נמצא בבסיס הנתונים: רשומה חדשה תיווצר", "info");
            return;
        }

        // Found! Fill remaining fields and switch mode to edit
        fillFormFields(data);
        formMode = "edit";
        
        // Disable PK inputs since we are updating now
        pk_cols.forEach(col => {
            const input = document.getElementById(`field-${col}`);
            if (input) {
                if (input.tagName === "SELECT") input.disabled = true;
                else input.readOnly = true;
            }
        });
        
        document.getElementById("modal-title").textContent = `עדכון רשומה (זוהה לפי מפתח) - ${meta.label}`;
        showToast("נתוני הרשומה נטענו בהצלחה. המצב שונה לעריכה/עדכון.", "success");
    } catch (err) {
        showToast("שגיאה בטעינת נתונים: " + err.message, "error");
    }
}

function closeCrudModal() {
    const modal = document.getElementById("record-modal");
    modal.classList.remove("open");
}

// Triggered when row edit button clicked
window.editRow = function(encodedRow) {
    const row = JSON.parse(decodeURIComponent(encodedRow));
    openCrudModal("edit", row);
};

// Triggered when row delete button clicked
window.deleteRow = function(encodedRow) {
    const row = JSON.parse(decodeURIComponent(encodedRow));
    const meta = tablesMetadata[currentTable];
    
    // Build human readable identity
    let info = "";
    meta.pk.forEach(col => {
        info += `${col}: ${row[col]} `;
    });

    if (confirm(`האם אתה בטוח שברצונך למחוק את הרשומה הבאה?\n(${info})`)) {
        deleteRecord(row);
    }
};

async function saveRecord() {
    const meta = tablesMetadata[currentTable];
    const form = document.getElementById("record-form");
    const formData = new FormData(form);
    
    const data = {};
    
    // Map form entries
    meta.columns.forEach(col => {
        // Skip disabled identity columns on add/edit
        if (col.identity && formMode === "add") return;
        
        const input = document.getElementById(`field-${col.name}`);
        if (!input) return;

        let val = input.value;
        
        // Format data type
        if (val === "" || val === undefined) {
            val = null;
        } else if (col.type === "int") {
            val = parseInt(val, 10);
        } else if (col.type === "numeric") {
            val = parseFloat(val);
        } else if (col.type === "boolean" || col.type === "bool") {
            val = val === "true";
        }
        
        data[col.name] = val;
    });

    // If column was disabled in DOM (e.g. PK in edit mode), include it from dataset
    if (formMode === "edit") {
        meta.pk.forEach(pk => {
            const input = document.getElementById(`field-${pk}`);
            if (input && input.disabled) {
                // If it is select we need its value
                let val = input.value;
                if (meta.columns.find(c => c.name === pk).type === "int") {
                    val = parseInt(val, 10);
                }
                data[pk] = val;
            } else if (input && input.readOnly) {
                let val = input.value;
                if (meta.columns.find(c => c.name === pk).type === "int") {
                    val = parseInt(val, 10);
                }
                data[pk] = val;
            }
        });
    }

    try {
        const method = formMode === "add" ? "POST" : "PUT";
        const res = await fetch(`/api/table/${currentTable}`, {
            method: method,
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(data)
        });
        
        const result = await res.json();
        
        if (result.error) {
            showToast("שגיאה בשמירה: " + result.error, "error");
            return;
        }

        showToast(formMode === "add" ? "הרשומה התווספה בהצלחה" : "הרשומה עודכנה בהצלחה", "success");
        closeCrudModal();
        loadTableData(currentTable);
    } catch (err) {
        showToast("שגיאה בחיבור לשרת: " + err.message, "error");
    }
}

async function deleteRecord(row) {
    const meta = tablesMetadata[currentTable];
    const data = {};
    
    meta.pk.forEach(pk => {
        data[pk] = row[pk];
    });

    try {
        const res = await fetch(`/api/table/${currentTable}`, {
            method: "DELETE",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(data)
        });
        
        const result = await res.json();
        
        if (result.error) {
            showToast("שגיאה במחיקה: " + result.error, "error");
            return;
        }

        showToast("הרשומה נמחקה בהצלחה", "success");
        loadTableData(currentTable);
    } catch (err) {
        showToast("שגיאה בחיבור לשרת: " + err.message, "error");
    }
}

// -----------------------------------------
// Stage B Queries Logic
// -----------------------------------------
function initQueryEvents() {
    const querySelect = document.getElementById("query-select");
    querySelect.addEventListener("change", renderQueryInputs);
}

function renderQueryInputs(e) {
    const queryId = e.target.value;
    const panel = document.getElementById("query-inputs-panel");
    const form = document.getElementById("query-params-form");
    
    form.innerHTML = "";
    panel.style.display = "none";
    
    let inputsHtml = "";
    
    if (queryId === "query1") {
        // Search by country
        inputsHtml = `
            <div class="form-group">
                <label for="param-country">שם מדינה (לדוגמה: Albania):</label>
                <input type="text" id="param-country" value="Albania" required>
            </div>`;
    } 
    else if (queryId === "query3") {
        // Search reviews of restaurant
        inputsHtml = `
            <div class="form-group">
                <label for="param-restaurant">שם מסעדה (לדוגמה: Jayo):</label>
                <input type="text" id="param-restaurant" value="Jayo" required>
            </div>`;
    }
    else if (queryId === "query5") {
        // Bookings in month/year
        inputsHtml = `
            <div class="form-group">
                <label for="param-year">שנה:</label>
                <input type="number" id="param-year" value="2025" min="2000" max="2100" required>
            </div>
            <div class="form-group">
                <label for="param-month">חודש (1-12):</label>
                <input type="number" id="param-month" value="1" min="1" max="12" required>
            </div>`;
    }

    if (inputsHtml) {
        form.innerHTML = inputsHtml + `<button type="submit" class="btn btn-accent" style="height:41px;"><i class="fa-solid fa-play"></i> הרץ שאילתה</button>`;
        panel.style.display = "block";
        
        form.onsubmit = (evt) => {
            evt.preventDefault();
            runSelectedQuery(queryId);
        };
    } else {
        // No parameters needed, execute immediately
        runSelectedQuery(queryId);
    }
}

async function runSelectedQuery(queryId) {
    const container = document.getElementById("query-result-container");
    container.innerHTML = `<div class="table-placeholder"><i class="fa-solid fa-spinner fa-spin placeholder-icon"></i><p>מריץ שאילתה מול בסיס הנתונים...</p></div>`;

    const params = {};
    if (queryId === "query1") {
        params.country = document.getElementById("param-country").value;
    } else if (queryId === "query3") {
        params.restaurant = document.getElementById("param-restaurant").value;
    } else if (queryId === "query5") {
        params.year = document.getElementById("param-year").value;
        params.month = document.getElementById("param-month").value;
    }

    try {
        const res = await fetch("/api/queries/run", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({ query_id: queryId, params: params })
        });
        
        const data = await res.json();
        
        if (data.error) {
            container.innerHTML = `<div class="table-placeholder"><i class="fa-solid fa-triangle-exclamation placeholder-icon console-error"></i><p>שגיאה בהרצת השאילתה: ${data.error}</p></div>`;
            return;
        }

        if (data.length === 0) {
            container.innerHTML = `<div class="table-placeholder"><i class="fa-solid fa-database placeholder-icon"></i><p>השאילתה הושלמה בהצלחה, אך לא חזרו שורות נתונים.</p></div>`;
            return;
        }

        // Build result table dynamically based on returning JSON keys
        const columns = Object.keys(data[0]);
        let html = `<table><thead><tr>`;
        columns.forEach(col => {
            html += `<th>${col}</th>`;
        });
        html += `</tr></thead><tbody>`;

        data.forEach(row => {
            html += `<tr>`;
            columns.forEach(col => {
                let val = row[col];
                if (val && typeof val === "string" && val.includes("T00:00:00")) {
                    val = val.split("T")[0];
                }
                html += `<td>${val !== null ? val : ""}</td>`;
            });
            html += `</tr>`;
        });

        html += `</tbody></table>`;
        container.innerHTML = html;

    } catch (err) {
        container.innerHTML = `<div class="table-placeholder"><i class="fa-solid fa-triangle-exclamation placeholder-icon console-error"></i><p>שגיאה בחיבור לשרת: ${err.message}</p></div>`;
    }
}

// -----------------------------------------
// Stage D Stored Procedures & Functions Logic
// -----------------------------------------
function initProcedureEvents() {
    const procSelect = document.getElementById("proc-select");
    const btnRunProc = document.getElementById("btn-run-proc");
    
    procSelect.addEventListener("change", renderProcedureInputs);
    btnRunProc.addEventListener("click", runSelectedProcedure);
}

function renderProcedureInputs(e) {
    const procId = e.target.value;
    const formContainer = document.getElementById("proc-form-container");
    const form = document.getElementById("proc-params-form");
    
    form.innerHTML = "";
    formContainer.style.display = "none";
    document.getElementById("proc-effect-container").style.display = "none";
    
    let inputsHtml = "";
    
    if (procId === "func_host_revenue") {
        inputsHtml = `
            <div class="form-group">
                <label for="proc-host-id">מזהה מארח (Host ID) (לדוגמה: 1):</label>
                <input type="number" id="proc-host-id" value="1" required style="width:100%;">
            </div>`;
    } 
    else if (procId === "proc_update_prices") {
        inputsHtml = `
            <div class="form-group" style="margin-bottom:15px;">
                <label for="proc-host-id">מזהה מארח (Host ID) (לדוגמה: 1):</label>
                <input type="number" id="proc-host-id" value="1" required style="width:100%;">
            </div>
            <div class="form-group">
                <label for="proc-percent">אחוז עדכון מחיר (לדוגמה: 5 עבור 5%+):</label>
                <input type="number" id="proc-percent" value="5" step="0.1" required style="width:100%;">
            </div>`;
    }
    else if (procId === "func_tourist_rating") {
        inputsHtml = `
            <div class="form-group">
                <label for="proc-tourist-id">מזהה תייר (Tourist ID) (לדוגמה: 358):</label>
                <input type="number" id="proc-tourist-id" value="358" required style="width:100%;">
            </div>`;
    }
    else if (procId === "proc_reward_tourists") {
        inputsHtml = `
            <div class="form-group">
                <label for="proc-min-bookings">מינימום הזמנות לקבלת הטבה (לדוגמה: 2):</label>
                <input type="number" id="proc-min-bookings" value="2" required style="width:100%;">
            </div>`;
    }

    if (inputsHtml) {
        form.innerHTML = inputsHtml;
        formContainer.style.display = "block";
    }
}

async function runSelectedProcedure() {
    const procId = document.getElementById("proc-select").value;
    const consoleBox = document.getElementById("proc-console-output");
    const effectContainer = document.getElementById("proc-effect-container");
    const effectTitle = document.getElementById("proc-effect-title");
    const effectTableWrapper = document.getElementById("proc-effect-table-wrapper");

    consoleBox.innerHTML = `<span class="console-info">Connecting to database and compiling call...</span>\n`;
    effectContainer.style.display = "none";

    const params = {};
    if (procId === "func_host_revenue") {
        params.host_id = document.getElementById("proc-host-id").value;
    } else if (procId === "proc_update_prices") {
        params.host_id = document.getElementById("proc-host-id").value;
        params.percent = document.getElementById("proc-percent").value;
    } else if (procId === "func_tourist_rating") {
        params.tourist_id = document.getElementById("proc-tourist-id").value;
    } else if (procId === "proc_reward_tourists") {
        params.min_bookings = document.getElementById("proc-min-bookings").value;
    }

    try {
        const res = await fetch("/api/procedures/run", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({ proc_id: procId, params: params })
        });
        
        const data = await res.json();
        
        if (data.error) {
            consoleBox.innerHTML += `<span class="console-error">PL/SQL Execution Error:\n${data.error}</span>`;
            showToast("הרצת הפרוצדורה נכשלה", "error");
            return;
        }

        // Print output to simulated console
        let consoleText = `<span class="console-success">Transaction Successful (COMMIT).</span>\n\n`;

        if (procId === "func_host_revenue" || procId === "func_tourist_rating") {
            consoleText += `<span class="console-log">Returned output:</span>\n`;
            consoleText += `<span class="console-info">${data.output_label} = </span><strong style="color:#FFF;">${data.value}</strong>`;
            consoleBox.innerHTML = consoleText;
            showToast("הפונקציה הורצה בהצלחה", "success");
        } 
        else if (procId === "proc_update_prices") {
            consoleText += `<span class="console-log">${data.message}</span>\n`;
            consoleBox.innerHTML = consoleText;
            showToast("הפרוצדורה הורצה בהצלחה", "success");

            // Build dynamic side by side table showing before/after prices
            effectTitle.textContent = `השפעת המחיר עבור מארח ${params.host_id} (לפני מול אחרי)`;
            effectContainer.style.display = "block";

            let tableHtml = `
                <div class="effect-grid">
                    <div class="effect-panel before">
                        <h5>לפני עדכון המחירים:</h5>
                        <table><thead><tr><th>ID</th><th>שם דירה</th><th>מחיר ללילה</th></tr></thead><tbody>`;
            
            data.before.forEach(item => {
                tableHtml += `<tr><td>${item.apartment_id}</td><td>${item.title}</td><td>₪${parseFloat(item.price_per_night).toFixed(2)}</td></tr>`;
            });
            
            tableHtml += `</tbody></table></div>`;
            
            tableHtml += `
                    <div class="effect-panel after">
                        <h5>לאחר עדכון המחירים (+${params.percent}%):</h5>
                        <table><thead><tr><th>ID</th><th>שם דירה</th><th>מחיר חדש ללילה</th></tr></thead><tbody>`;
            
            data.after.forEach(item => {
                tableHtml += `<tr><td>${item.apartment_id}</td><td>${item.title}</td><td>₪${parseFloat(item.price_per_night).toFixed(2)}</td></tr>`;
            });
            
            tableHtml += `</tbody></table></div></div>`;
            effectTableWrapper.innerHTML = tableHtml;
        }
        else if (procId === "proc_reward_tourists") {
            // Logs of VIP status
            consoleText += `<span class="console-log">Server Notice Logs:</span>\n`;
            consoleText += `<span class="console-comment">${data.logs || "-- No Notice Outputs --"}</span>\n`;
            consoleBox.innerHTML = consoleText;
            showToast("תוכנית ההטבות עודכנה בהצלחה", "success");

            // Build table showing tourists matching parameters and their status
            effectTitle.textContent = `תיירים נאמנים שנותחו במערכת (מינימום ${params.min_bookings} הזמנות)`;
            effectContainer.style.display = "block";

            let tableHtml = `
                <table><thead><tr>
                    <th>מזהה תייר</th>
                    <th>שם פרטי</th>
                    <th>שם משפחה</th>
                    <th>כמות הזמנות</th>
                    <th>סטטוס לקוח</th>
                </tr></thead><tbody>`;
                
            data.tourists.forEach(t => {
                const badgeColor = t.status === "VIP Customer" ? "var(--color-danger)" : "var(--color-accent)";
                tableHtml += `
                    <tr>
                        <td>${t.tourist_id}</td>
                        <td>${t.first_name}</td>
                        <td>${t.last_name}</td>
                        <td><strong>${t.booking_count}</strong></td>
                        <td><span class="badge" style="background-color:rgba(255,255,255,0.05); color:${badgeColor}; border-color:${badgeColor};">${t.status}</span></td>
                    </tr>`;
            });

            tableHtml += `</tbody></table>`;
            effectTableWrapper.innerHTML = tableHtml;
        }

    } catch (err) {
        consoleBox.innerHTML += `<span class="console-error">Network Connection Error:\n${err.message}</span>`;
    }
}
