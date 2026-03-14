        // ── Mirrors /rooms fallback extraction helpers ──────────────────────
        function extractBuildingFromRoomName(roomNumber) {
            const match = roomNumber.match(/^([A-Z]+)/);
            return match ? match[1] : '';
        }

        function extractFloorFromRoomName(roomNumber) {
            const match = roomNumber.match(/\s+(\d)(\d{2})/);
            return match ? match[1] : '';
        }

        // ── Init ────────────────────────────────────────────────────────────────
        document.addEventListener('DOMContentLoaded', function () {
            Utils.checkAuth();

            // Pre-fill from URL params (e.g. from /rooms deeplink)
            const p = new URLSearchParams(window.location.search);
            if (p.get('building')) document.getElementById('buildingFilter').value = p.get('building');
            if (p.get('floor'))    document.getElementById('floorFilter').value    = p.get('floor');

            // Auto-load if building is pre-filled
            if (document.getElementById('buildingFilter').value) {
                applyFilters();
            }
        });

        // ── Main fetch ──────────────────────────────────────────────────────────
        async function loadHistory() {
            const building = document.getElementById('buildingFilter').value.trim();
            const floor    = document.getElementById('floorFilter').value.trim();
            const status   = document.getElementById('statusFilter').value;
            const dateFrom = document.getElementById('dateFrom').value;
            const dateTo   = document.getElementById('dateTo').value;

            if (!building) {
                alert('Please select a building first.');
                return;
            }

            document.getElementById('resultsContainer').innerHTML =
                '<div class="no-data"><div class="spinner"></div><p>Loading…</p></div>';
            document.getElementById('statsStrip').style.display = 'none';

            let url = `${CONFIG.ENDPOINTS.BUILDING_DEVICE_HISTORY}?building=${encodeURIComponent(building)}`;
            if (floor)    url += `&floor=${encodeURIComponent(floor)}`;
            if (status !== 'all') url += `&status=${encodeURIComponent(status)}`;
            if (dateFrom) url += `&date_from=${encodeURIComponent(dateFrom)}`;
            if (dateTo)   url += `&date_to=${encodeURIComponent(dateTo)}`;

            try {
                const result = await Utils.apiRequest(url, { method: 'GET' });

                if (result.success) {
                    renderStats(result.data.statistics);
                    renderTable(result.data.records);
                } else {
                    showError(result.message || 'Failed to load history');
                }
            } catch (e) {
                console.error(e);
                showError('An error occurred while loading history.');
            }
        }

        // ── Filter apply / clear ────────────────────────────────────────────────
        function applyFilters() {
            const building = document.getElementById('buildingFilter').value;
            const floor    = document.getElementById('floorFilter').value;
            const status   = document.getElementById('statusFilter').value;
            const dateFrom = document.getElementById('dateFrom').value;
            const dateTo   = document.getElementById('dateTo').value;
            const today    = new Date().toISOString().split('T')[0];

            if (!building) {
                alert('Please select a building first.');
                return;
            }

            // Build human-readable filter summary
            const buildingNames = {
                NAC: 'NAC - North Academic', SAC: 'SAC - South Academic',
                NTR: 'NTR - North Tower',    LIB: 'LIB - Library', LAB: 'LAB - Laboratory'
            };
            const floorNames = {
                '0':'Ground Floor','2':'2nd','3':'3rd','4':'4th','5':'5th',
                '6':'6th','7':'7th','8':'8th','9':'9th','1':'10th'
            };

            let parts = [`Building: ${buildingNames[building] || building}`];
            if (floor)  parts.push(`Floor: ${floorNames[floor] || floor}`);
            if (status !== 'all') parts.push(`Status: ${status}`);

            let datePart = '';
            if (dateFrom && dateTo)  datePart = `${formatDate(dateFrom)} → ${formatDate(dateTo)}`;
            else if (dateFrom)        datePart = `${formatDate(dateFrom)} → today`;
            else if (dateTo)          datePart = `Beginning → ${formatDate(dateTo)}`;
            if (datePart) parts.push(`Period: ${datePart}`);

            const summary = parts.join('   |   ');

            document.getElementById('filterInfoBar').textContent = summary;
            document.getElementById('filterInfoBar').style.display = 'block';
            document.getElementById('printFilterNote').textContent = summary;  // inside print header
            document.getElementById('clearBtn').style.display = 'inline-flex';

            loadHistory();
        }

        function clearFilters() {
            document.getElementById('buildingFilter').value = '';
            document.getElementById('floorFilter').value    = '';
            document.getElementById('statusFilter').value   = 'all';
            document.getElementById('dateFrom').value       = '';
            document.getElementById('dateTo').value         = '';
            document.getElementById('filterInfoBar').style.display = 'none';
            document.getElementById('filterInfoBar').textContent   = '';
            document.getElementById('printFilterNote').textContent = '';
            document.getElementById('clearBtn').style.display      = 'none';
            document.getElementById('statsStrip').style.display    = 'none';
            document.getElementById('resultsContainer').innerHTML  = `
                <div class="no-data">
                    <i class="fas fa-building"></i>
                    <p>Select a building and click <strong>Apply</strong> to load history.</p>
                </div>`;
        }

        // ── Print ────────────────────────────────────────────────────────────────
        function printHistory() {
            const building = document.getElementById('buildingFilter').value;
            if (!building) {
                alert('Please apply a filter first before printing.');
                return;
            }

            const floor  = document.getElementById('floorFilter').value;
            const status = document.getElementById('statusFilter').value;
            const buildingNames = {
                NAC: 'NAC - North Academic', SAC: 'SAC - South Academic',
                NTR: 'NTR - North Tower',    LIB: 'LIB - Library', LAB: 'LAB - Laboratory'
            };
            const floorNames = {
                '0':'Ground Floor','2':'2nd Floor','3':'3rd Floor','4':'4th Floor',
                '5':'5th Floor','6':'6th Floor','7':'7th Floor','8':'8th Floor',
                '9':'9th Floor','1':'10th Floor'
            };

            let title = buildingNames[building] || building;
            if (floor)  title += ` — ${floorNames[floor] || 'Floor ' + floor}`;
            if (status !== 'all') title += ` (${status} only)`;

            // Stamp the dynamic title into the print-only header
            const h2 = document.querySelector('#printReportHeader h2');
            if (h2) h2.textContent = `Device History Report: ${title}`;

            window.print();
        }

        // ── Renderers ────────────────────────────────────────────────────────────
        function renderStats(stats) {
            const strip = document.getElementById('statsStrip');
            strip.style.display = 'flex';
            strip.innerHTML = `
                <div class="stat-chip">
                    <div>
                        <div class="stat-val">${stats.total_records}</div>
                        <div class="stat-label">Total Records</div>
                    </div>
                </div>
                <div class="stat-chip">
                    <div>
                        <div class="stat-val" style="color:#2e7d32;">${stats.active_count}</div>
                        <div class="stat-label">Active Devices</div>
                    </div>
                </div>
                <div class="stat-chip">
                    <div>
                        <div class="stat-val" style="color:#e65100;">${stats.withdrawn_count}</div>
                        <div class="stat-label">Withdrawn</div>
                    </div>
                </div>
                <div class="stat-chip">
                    <div>
                        <div class="stat-val" style="color:#7b1fa2;">${stats.room_count}</div>
                        <div class="stat-label">Rooms</div>
                    </div>
                </div>
            `;
        }

        function renderTable(records) {
            const container = document.getElementById('resultsContainer');

            if (!records || records.length === 0) {
                container.innerHTML = `
                    <div class="no-data">
                        <i class="fas fa-inbox"></i>
                        <p>No records found for the selected filters.</p>
                    </div>`;
                return;
            }

            container.innerHTML = `
                <div class="history-table table-container">
                    <table>
                        <thead>
                            <tr>
                                <th>Room</th>
                                <th>Floor</th>
                                <th>Device ID</th>
                                <th>Type</th>
                                <th>Brand / Model</th>
                                <th>Installed Date</th>
                                <th>Withdrawn Date</th>
                                <th>Days in Room</th>
                                <th>Status</th>
                                <th>Installed By</th>
                                <th>Withdrawn By</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${records.map(r => {
                                // Derive floor for display (mirrors /rooms fallback)
                                const displayFloor = (r.floor && r.floor.trim() !== '')
                                    ? r.floor
                                    : extractFloorFromRoomName(r.room_number);
                                const floorLabel = displayFloor === '0' ? 'Ground'
                                    : displayFloor ? displayFloor : 'N/A';
                                return `
                                <tr>
                                    <td><strong>${r.room_number}</strong><br><small style="color:#888;">${r.room_name}</small></td>
                                    <td>${floorLabel}</td>
                                    <td><code>${r.device_unique_id}</code></td>
                                    <td>${r.type_name || 'N/A'}</td>
                                    <td>${r.brand_name || 'N/A'}${r.model ? '<br><small style="color:#888;">' + r.model + '</small>' : ''}</td>
                                    <td>${formatDate(r.installed_date)}</td>
                                    <td>${r.withdrawn_date ? formatDate(r.withdrawn_date) : '<span style="color:#2e7d32;">—</span>'}</td>
                                    <td>${r.days_in_room !== null ? r.days_in_room + ' days' : 'N/A'}</td>
                                    <td><span class="status-badge ${r.status}">${r.status}</span></td>
                                    <td>${r.installed_by || 'N/A'}</td>
                                    <td>${r.withdrawn_by || '—'}</td>
                                </tr>`;
                            }).join('')}
                        </tbody>
                    </table>
                </div>`;
        }

        function showError(msg) {
            document.getElementById('resultsContainer').innerHTML = `
                <div style="background:#ffebee;color:#c62828;padding:1rem;border-radius:5px;border-left:4px solid #c62828;margin:1rem 0;">
                    <i class="fas fa-exclamation-triangle"></i> ${msg}
                </div>`;
        }

        function formatDate(dateString) {
            if (!dateString || dateString === '0000-00-00') return 'N/A';
            const d = new Date(dateString);
            return d.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
        }

        // Logout
        document.addEventListener('DOMContentLoaded', function () {
            const logoutBtn = document.getElementById('logoutBtn');
            if (logoutBtn) logoutBtn.addEventListener('click', () => Utils.logout());
        });
