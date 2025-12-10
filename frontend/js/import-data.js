/**
 * Import Data Page JavaScript
 */

document.addEventListener('DOMContentLoaded', () => {
    // Check authentication
    if (!Utils.isLoggedIn()) {
        window.location.href = 'login.html';
        return;
    }

    // Initialize user info
    Utils.initUserInfo();

    // Setup event listeners
    setupEventListeners();
});

/**
 * Setup event listeners
 */
function setupEventListeners() {
    document.getElementById('logoutBtn').addEventListener('click', Utils.logout);
    document.getElementById('importForm').addEventListener('submit', handleImport);
}

/**
 * Download device template CSV
 */
function downloadDeviceTemplate() {
    const csv = `device_unique_id,type_name,brand_name,model,serial_number,purchase_date,warranty_period,notes
DEV001,Desktop,Dell,OptiPlex 7090,SN123456789,2024-01-15,36,Computer lab desktop
DEV002,Laptop,HP,EliteBook 840 G8,SN987654321,2024-02-20,24,Faculty laptop
DEV003,Projector,Epson,EB-X05,SN456789123,2023-12-10,12,Classroom projector
DEV004,Monitor,Samsung,S24R350,SN654321987,2024-03-05,24,Lab monitor
DEV005,Printer,Canon,PIXMA G3020,SN321654987,2023-11-25,12,Office printer`;

    downloadCSV(csv, 'devices_template.csv');
}

/**
 * Download room template CSV
 */
function downloadRoomTemplate() {
    const csv = `room_number,room_name,building,floor,capacity
101,Computer Lab 1,Main Building,1,40
102,Computer Lab 2,Main Building,1,35
201,Conference Room A,Main Building,2,20
301,Faculty Office 1,Main Building,3,5
B101,Seminar Room,Building B,1,50`;

    downloadCSV(csv, 'rooms_template.csv');
}

/**
 * Download installation history template CSV
 */
function downloadInstallationTemplate() {
    const csv = `device_unique_id,room_number,installation_date,installation_time,installer_name,installer_id,withdrawal_date,withdrawal_time,withdrawer_name,withdrawer_id,data_entry_by,status,notes
DEV001,101,2024-01-15,10:30:00,John Doe,EMP001,,,,,Admin User,active,Initial installation
DEV002,102,2024-02-20,14:00:00,Jane Smith,EMP002,2024-06-15,16:30:00,Mike Johnson,EMP003,Admin User,withdrawn,Moved to another room
DEV003,201,2024-03-10,09:00:00,Robert Lee,EMP004,,,,,Admin User,active,Conference room setup
DEV004,101,2023-12-01,11:15:00,Sarah Chen,EMP005,2024-05-20,13:45:00,Tom Wilson,EMP006,Admin User,withdrawn,Replaced with new model
DEV005,B101,2024-04-05,15:20:00,David Brown,EMP007,,,,,Admin User,active,Seminar room installation`;

    downloadCSV(csv, 'installations_template.csv');
}

/**
 * Helper function to download CSV
 */
function downloadCSV(content, filename) {
    const blob = new Blob([content], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.click();
    window.URL.revokeObjectURL(url);
}

/**
 * Handle import form submission
 */
async function handleImport(e) {
    e.preventDefault();

    const importType = document.getElementById('importType').value;
    const fileInput = document.getElementById('csvFile');
    const skipDuplicates = document.getElementById('skipDuplicates').checked;

    if (!fileInput.files[0]) {
        Utils.showAlert('Please select a CSV file', 'error');
        return;
    }

    const file = fileInput.files[0];

    // Read CSV file
    const reader = new FileReader();
    reader.onload = async (event) => {
        const csvContent = event.target.result;
        const rows = parseCSV(csvContent);

        if (rows.length < 2) {
            Utils.showAlert('CSV file is empty or invalid', 'error');
            return;
        }

        // Show progress
        document.getElementById('importProgress').style.display = 'block';
        document.getElementById('importResults').style.display = 'none';

        if (importType === 'devices') {
            await importDevices(rows, skipDuplicates);
        } else if (importType === 'rooms') {
            await importRooms(rows, skipDuplicates);
        } else if (importType === 'installations') {
            await importInstallations(rows, skipDuplicates);
        }
    };

    reader.readAsText(file);
}

/**
 * Parse CSV content
 */
function parseCSV(csv) {
    const lines = csv.split('\n').filter(line => line.trim());
    return lines.map(line => {
        // Simple CSV parser (handles basic cases)
        const values = [];
        let current = '';
        let inQuotes = false;

        for (let i = 0; i < line.length; i++) {
            const char = line[i];
            if (char === '"') {
                inQuotes = !inQuotes;
            } else if (char === ',' && !inQuotes) {
                values.push(current.trim());
                current = '';
            } else {
                current += char;
            }
        }
        values.push(current.trim());
        return values;
    });
}

/**
 * Import devices from CSV
 */
async function importDevices(rows, skipDuplicates) {
    const headers = rows[0];
    const dataRows = rows.slice(1);

    let successCount = 0;
    let errorCount = 0;
    let skippedCount = 0;
    const errors = [];

    // Get device types and brands first
    const metadataResult = await Utils.apiRequest('/metadata.php');

    if (!metadataResult.success) {
        Utils.showAlert('Failed to load device types and brands', 'error');
        document.getElementById('importProgress').style.display = 'none';
        return;
    }

    let types = metadataResult.data.types;
    let brands = metadataResult.data.brands;

    for (let i = 0; i < dataRows.length; i++) {
        const row = dataRows[i];
        updateProgress((i + 1) / dataRows.length * 100, `Processing row ${i + 1} of ${dataRows.length}...`);

        // Map CSV columns to data object
        const deviceData = {
            device_unique_id: row[0],
            type_name: row[1],
            brand_name: row[2],
            model: row[3] || null,
            serial_number: row[4] || null,
            purchase_date: row[5] || null,
            warranty_period: row[6] || null,
            notes: row[7] || null
        };

        // Find or create type_id
        let type = types.find(t => t.type_name.toLowerCase() === deviceData.type_name.toLowerCase());
        
        if (!type && deviceData.type_name) {
            // Create new device type
            const createTypeResult = await Utils.apiRequest('/metadata.php', {
                method: 'POST',
                body: JSON.stringify({
                    type: 'device_type',
                    type_name: deviceData.type_name,
                    description: `Auto-created from CSV import`
                })
            });

            if (createTypeResult.success) {
                type = {
                    type_id: createTypeResult.data.type_id,
                    type_name: deviceData.type_name
                };
                types.push(type);
            } else {
                errors.push(`Row ${i + 2}: Failed to create device type "${deviceData.type_name}": ${createTypeResult.message}`);
                errorCount++;
                continue;
            }
        }

        // Find or create brand_id
        let brand = brands.find(b => b.brand_name.toLowerCase() === deviceData.brand_name.toLowerCase());
        
        if (!brand && deviceData.brand_name) {
            // Create new brand
            const createBrandResult = await Utils.apiRequest('/metadata.php', {
                method: 'POST',
                body: JSON.stringify({
                    type: 'brand',
                    brand_name: deviceData.brand_name
                })
            });

            if (createBrandResult.success) {
                brand = {
                    brand_id: createBrandResult.data.brand_id,
                    brand_name: deviceData.brand_name
                };
                brands.push(brand);
            } else {
                errors.push(`Row ${i + 2}: Failed to create brand "${deviceData.brand_name}": ${createBrandResult.message}`);
                errorCount++;
                continue;
            }
        }

        const payload = {
            device_unique_id: deviceData.device_unique_id,
            type_id: type.type_id,
            brand_id: brand.brand_id,
            model: deviceData.model,
            serial_number: deviceData.serial_number,
            purchase_date: deviceData.purchase_date,
            warranty_period: deviceData.warranty_period,
            notes: deviceData.notes
        };

        // Try to create device
        const result = await Utils.apiRequest(CONFIG.ENDPOINTS.DEVICES, {
            method: 'POST',
            body: JSON.stringify(payload)
        });

        if (result.success) {
            successCount++;
        } else {
            if (skipDuplicates && result.message.includes('already exists')) {
                skippedCount++;
            } else {
                errors.push(`Row ${i + 2}: ${result.message}`);
                errorCount++;
            }
        }

        // Small delay to avoid overwhelming the server
        await new Promise(resolve => setTimeout(resolve, 100));
    }

    showResults(successCount, errorCount, skippedCount, errors);
}

/**
 * Import rooms from CSV
 */
async function importRooms(rows, skipDuplicates) {
    const headers = rows[0];
    const dataRows = rows.slice(1);

    let successCount = 0;
    let errorCount = 0;
    let skippedCount = 0;
    const errors = [];

    for (let i = 0; i < dataRows.length; i++) {
        const row = dataRows[i];
        updateProgress((i + 1) / dataRows.length * 100, `Processing row ${i + 1} of ${dataRows.length}...`);

        const roomData = {
            room_number: row[0],
            room_name: row[1],
            building: row[2] || null,
            floor: row[3] || null,
            capacity: row[4] || null
        };

        const result = await Utils.apiRequest(CONFIG.ENDPOINTS.ROOMS, {
            method: 'POST',
            body: JSON.stringify(roomData)
        });

        if (result.success) {
            successCount++;
        } else {
            if (skipDuplicates && result.message.includes('already exists')) {
                skippedCount++;
            } else {
                errors.push(`Row ${i + 2}: ${result.message}`);
                errorCount++;
            }
        }

        await new Promise(resolve => setTimeout(resolve, 100));
    }

    showResults(successCount, errorCount, skippedCount, errors);
}

/**
 * Import installation history from CSV
 */
async function importInstallations(rows, skipDuplicates) {
    const headers = rows[0];
    const dataRows = rows.slice(1);

    let successCount = 0;
    let errorCount = 0;
    let skippedCount = 0;
    const errors = [];

    for (let i = 0; i < dataRows.length; i++) {
        const row = dataRows[i];
        updateProgress((i + 1) / dataRows.length * 100, `Processing row ${i + 1} of ${dataRows.length}...`);

        // First, get device_id from device_unique_id
        const deviceResult = await Utils.apiRequest(`${CONFIG.ENDPOINTS.DEVICES}?device_unique_id=${encodeURIComponent(row[0])}`);
        
        if (!deviceResult.success || deviceResult.data.length === 0) {
            errors.push(`Row ${i + 2}: Device "${row[0]}" not found`);
            errorCount++;
            continue;
        }

        const device = deviceResult.data[0];

        // Get room_id from room_number
        const roomsResult = await Utils.apiRequest(CONFIG.ENDPOINTS.ROOMS);
        if (!roomsResult.success) {
            errors.push(`Row ${i + 2}: Failed to load rooms`);
            errorCount++;
            continue;
        }

        const room = roomsResult.data.find(r => r.room_number === row[1]);
        if (!room) {
            errors.push(`Row ${i + 2}: Room "${row[1]}" not found`);
            errorCount++;
            continue;
        }

        // Build installation data
        const installationData = {
            device_id: device.device_id,
            room_id: room.room_id,
            installation_date: row[2] || null,
            installation_time: row[3] || null,
            installer_name: row[4] || null,
            installer_id: row[5] || null,
            withdrawal_date: row[6] || null,
            withdrawal_time: row[7] || null,
            withdrawer_name: row[8] || null,
            withdrawer_id: row[9] || null,
            data_entry_by: row[10] || null,
            status: row[11] || 'active',
            notes: row[12] || null
        };

        // Create installation record
        const result = await Utils.apiRequest(CONFIG.ENDPOINTS.INSTALLATIONS, {
            method: 'POST',
            body: JSON.stringify(installationData)
        });

        if (result.success) {
            successCount++;
        } else {
            if (skipDuplicates && result.message.includes('already exists')) {
                skippedCount++;
            } else {
                errors.push(`Row ${i + 2}: ${result.message}`);
                errorCount++;
            }
        }

        await new Promise(resolve => setTimeout(resolve, 100));
    }

    showResults(successCount, errorCount, skippedCount, errors);
}

/**
 * Update progress bar
 */
function updateProgress(percent, text) {
    document.getElementById('progressBar').style.width = percent + '%';
    document.getElementById('progressText').textContent = text;
}

/**
 * Show import results
 */
function showResults(successCount, errorCount, skippedCount, errors) {
    document.getElementById('importProgress').style.display = 'none';
    document.getElementById('importResults').style.display = 'block';

    let html = `
        <div style="margin-bottom: 20px;">
            <h4 style="color: #28a745;">✓ Successfully imported: ${successCount}</h4>
            ${skippedCount > 0 ? `<h4 style="color: #ffc107;">⊘ Skipped (duplicates): ${skippedCount}</h4>` : ''}
            ${errorCount > 0 ? `<h4 style="color: #dc3545;">✗ Failed: ${errorCount}</h4>` : ''}
        </div>
    `;

    if (errors.length > 0) {
        html += `
            <div style="margin-top: 20px;">
                <h4>Errors:</h4>
                <ul style="color: #dc3545; max-height: 300px; overflow-y: auto;">
                    ${errors.map(err => `<li>${err}</li>`).join('')}
                </ul>
            </div>
        `;
    }

    if (successCount > 0) {
        html += `
            <div style="margin-top: 20px;">
                <button class="btn btn-primary" onclick="window.location.reload()">
                    <i class="fas fa-plus"></i> Import More Data
                </button>
                <button class="btn btn-secondary" onclick="window.location.href='devices.html'">
                    <i class="fas fa-eye"></i> View Devices
                </button>
            </div>
        `;
    }

    document.getElementById('resultsContent').innerHTML = html;

    if (successCount > 0) {
        Utils.showAlert(`Import completed! ${successCount} records imported successfully.`, 'success');
    } else if (errorCount > 0) {
        Utils.showAlert('Import failed with errors. Please check the error list below.', 'error');
    }
}
