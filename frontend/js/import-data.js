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
    document.getElementById('logoutBtn').addEventListener('click', () => Utils.logout());
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
    const csv = `device_unique_id,room_number,installed_date,installer_name,installer_id,team_members,installation_type,installation_notes,withdrawn_date,withdrawer_name,withdrawer_id,withdrawal_notes,issue_at_withdrawal,storage_location,gate_pass_number,gate_pass_date,status
50-ITD-00508-00542,101,2024-01-15,John Doe,EMP001,,NEW_INSTALLATION,Initial installation,,,,,,,,,active
50-ITD-00508-00543,102,2024-02-20,Jane Smith,EMP002,Tech Team A,NEW_INSTALLATION,New projector installed,2024-06-15,Mike Johnson,EMP003,Moved to room 201,,,,GP-2024-001,2024-06-15,withdrawn
50-ITD-00508-00544,201,2024-03-10,Robert Lee,EMP004,,REPAIRED,Repaired and reinstalled,,,,,,,,,active
50-ITD-00508-00545,B101,2024-04-05,Sarah Chen,EMP005,Installation Team,OLD_REINSTALL,Reinstalled old device,,,,,,,,,active`;

    downloadCSV(csv, 'installations_template.csv');
}

/**
 * Download gate pass template CSV
 */
function downloadGatePassTemplate() {
    const csv = `gate_pass_number,device_unique_ids,pass_direction,gate_pass_date,gate_pass_time,department,gate_name,vendor_destination,bearer_name,bearer_company,bearer_contact_no,security_officer_name,security_officer_designation,security_officer_ext,processing_name,processing_designation,processing_ext,authorized_name,authorized_designation,authorized_ext
GP001,DEV001,outgoing,2026-01-04,10:30,IT Department,Main Gate,ABC Vendor Ltd,John Smith,NSU,01712345678,Officer Ahmed,Security Officer,101,Manager Khan,IT Manager,201,Director Rahman,Director,301
GP002,"DEV002,DEV003",incoming,2026-01-05,14:00,Engineering,Back Gate,XYZ Supplier,Sarah Lee,Tech Corp,01798765432,Officer Hassan,Security Officer,102,Supervisor Ali,Engineering Lead,202,VP Tech,Vice President,302
GP003,DEV004,outgoing,2026-01-06,09:15,Admin,Front Gate,LMN Company,Mike Johnson,NSU,01623456789,Officer Karim,Senior Officer,103,Coordinator Alam,Admin Coordinator,203,Manager Hoque,Department Head,303`;

    downloadCSV(csv, 'gate_passes_template.csv');
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
        } else if (importType === 'gate-passes') {
            await importGatePasses(rows, skipDuplicates);
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

        // Build installation data matching database structure
        // Template columns: device_unique_id,room_number,installed_date,installer_name,installer_id,
        //                  team_members,installation_type,installation_notes,withdrawn_date,
        //                  withdrawer_name,withdrawer_id,withdrawal_notes,issue_at_withdrawal,
        //                  storage_location,gate_pass_number,gate_pass_date,status
        const installationData = {
            device_id: device.device_id,
            room_id: room.room_id,
            installed_date: row[2] || null,
            installer_name: row[3] || null,
            installer_id: row[4] || null,
            team_members: row[5] || null,
            installation_type: row[6] || 'NEW_INSTALLATION',
            installation_notes: row[7] || null,
            withdrawn_date: row[8] || null,
            withdrawer_name: row[9] || null,
            withdrawer_id: row[10] || null,
            withdrawal_notes: row[11] || null,
            issue_at_withdrawal: row[12] || null,
            storage_location: row[13] || null,
            gate_pass_number: row[14] || null,
            gate_pass_date: row[15] || null,
            status: row[16] || 'active'
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
 * Import gate passes from CSV
 */
async function importGatePasses(rows, skipDuplicates) {
    const headers = rows[0];
    const dataRows = rows.slice(1);

    let successCount = 0;
    let errorCount = 0;
    let skippedCount = 0;
    const errors = [];

    for (let i = 0; i < dataRows.length; i++) {
        const row = dataRows[i];
        updateProgress((i + 1) / dataRows.length * 100, `Processing row ${i + 1} of ${dataRows.length}...`);

        // Parse device_unique_ids (can be comma-separated)
        const deviceUniqueIds = row[1] ? row[1].split(',').map(id => id.trim()) : [];
        
        if (deviceUniqueIds.length === 0) {
            errors.push(`Row ${i + 2}: No devices specified`);
            errorCount++;
            continue;
        }

        // Get device IDs from device unique IDs
        const deviceIds = [];
        for (const uniqueId of deviceUniqueIds) {
            const deviceResult = await Utils.apiRequest(`${CONFIG.ENDPOINTS.DEVICES}?device_unique_id=${encodeURIComponent(uniqueId)}`);
            
            if (!deviceResult.success || deviceResult.data.length === 0) {
                errors.push(`Row ${i + 2}: Device "${uniqueId}" not found`);
                errorCount++;
                continue;
            }
            
            deviceIds.push(deviceResult.data[0].device_id);
        }

        if (deviceIds.length === 0) {
            continue; // Already logged error above
        }

        // Build gate pass data
        const gatePassData = {
            devices: deviceIds,
            gate_pass_number: row[0] || null,
            pass_direction: row[2] || 'outgoing',
            gate_pass_date: row[3] || null,
            gate_pass_time: row[4] || null,
            department: row[5] || null,
            gate_name: row[6] || null,
            vendor_destination: row[7] || null,
            bearer_name: row[8] || null,
            bearer_company: row[9] || null,
            bearer_contact_no: row[10] || null,
            bearer_signature: null,
            bearer_signature_date: null,
            security_officer_name: row[11] || null,
            security_officer_designation: row[12] || null,
            security_officer_ext: row[13] || null,
            security_officer_signature: null,
            security_officer_signature_date: null,
            processing_name: row[14] || null,
            processing_designation: row[15] || null,
            processing_ext: row[16] || null,
            processing_signature: null,
            processing_signature_date: null,
            authorized_name: row[17] || null,
            authorized_designation: row[18] || null,
            authorized_ext: row[19] || null,
            authorized_signature: null,
            authorized_signature_date: null,
            // Backward compatibility fields
            consignee_name: row[5] || null,
            destination: row[7] || null,
            carrier_name: row[8] || null,
            carrier_department: row[9] || null,
            carrier_telephone: row[10] || null,
            carrier_appointment: null,
            security_name: row[11] || null,
            security_appointment: row[12] || null,
            security_department: 'Duty Security Officer',
            security_telephone: null,
            receiver_name: row[14] || null,
            receiver_appointment: row[15] || null,
            receiver_department: null,
            receiver_telephone: null,
            purpose: 'Bulk Import',
            remarks: null
        };

        // Validate required fields
        if (!gatePassData.gate_pass_number) {
            errors.push(`Row ${i + 2}: Gate pass number is required`);
            errorCount++;
            continue;
        }

        if (!gatePassData.gate_pass_date) {
            errors.push(`Row ${i + 2}: Gate pass date is required`);
            errorCount++;
            continue;
        }

        if (!gatePassData.department || !gatePassData.vendor_destination || !gatePassData.bearer_name || !gatePassData.bearer_company || !gatePassData.bearer_contact_no) {
            errors.push(`Row ${i + 2}: Missing required fields (department, vendor_destination, bearer details)`);
            errorCount++;
            continue;
        }

        // Create gate pass
        const result = await Utils.apiRequest(CONFIG.ENDPOINTS.GATE_PASSES, {
            method: 'POST',
            body: JSON.stringify(gatePassData)
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
