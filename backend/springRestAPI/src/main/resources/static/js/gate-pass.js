        /**
         * Get URL parameter
         */
        function getUrlParameter(name) {
            const urlParams = new URLSearchParams(window.location.search);
            return urlParams.get(name);
        }

        /**
         * Format date
         */
        function formatDate(dateString) {
            if (!dateString) return 'N/A';
            const date = new Date(dateString);
            return date.toLocaleDateString('en-US', { 
                year: 'numeric', 
                month: 'long', 
                day: 'numeric' 
            });
        }

        function formatTime(timeString) {
            if (!timeString) return '';
            const parts = String(timeString).split(':');
            if (parts.length < 2) return timeString;
            const hh = parts[0].padStart(2, '0');
            const mm = parts[1].padStart(2, '0');
            return `${hh}:${mm}`;
        }

        /**
         * Load gate pass data
         */
        async function loadGatePass() {
            const installationId = getUrlParameter('id');
            
            if (!installationId) {
                showError('No installation ID provided');
                return;
            }

            try {
                const token = localStorage.getItem(CONFIG.STORAGE_KEYS.TOKEN);
                if (!token) {
                    showError('Authentication required. Please login.');
                    return;
                }

                const response = await fetch(`${CONFIG.API_BASE_URL}${CONFIG.ENDPOINTS.INSTALLATIONS}?installation_id=${installationId}`, {
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Content-Type': 'application/json'
                    }
                });

                const result = await response.json();
                
                if (result.success && result.data.length > 0) {
                    renderGatePass(result.data[0]);
                } else {
                    showError('Installation record not found');
                }
            } catch (error) {
                console.error('Error loading gate pass:', error);
                showError('Failed to load gate pass data');
            }
        }

        /**
         * Render gate pass
         */
        function renderGatePass(data) {
            const container = document.getElementById('gatePassContent');
            
            const html = `
                <div class="header">
                    <img src="${CONFIG.LOGO_PATH}" alt="NSU Logo" class="logo">
                    <div class="title">North South University</div>
                    <div class="university-address" style="font-size: 11px; margin: 2px 0; color: #333;">Plot# 15, Block# B, Basundhara, Dhaka-1229</div>
                    <div style="text-align: center; margin-top: 15px;">
                        <div style="font-size: 14px; font-weight: bold; margin: 10px auto; padding: 5px 15px; border: 2px solid #000; display: inline-block;">MATERIAL GATE PASS</div>
                    </div>
                </div>

                <div class="gate-pass-info">
                    <div class="info-item">
                        <span class="info-label">Incoming</span> <span class="checkbox">${data.pass_direction === 'incoming' ? '☑' : '☐'}</span>
                        &nbsp;&nbsp;
                        <span class="info-label">Outgoing</span> <span class="checkbox">${data.pass_direction === 'outgoing' || !data.pass_direction ? '☑' : '☐'}</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Serial:</span> ${data.gate_pass_number || 'N/A'}
                    </div>
                </div>

                <div class="header-fields">
                    <div>
                        <span class="info-label">Date:</span> ${formatDate(data.gate_pass_date || data.installed_date)}
                        &nbsp;&nbsp;
                        <span class="info-label">Time:</span> ${formatTime(data.gate_pass_time) || new Date().toLocaleTimeString('en-US', {hour: '2-digit', minute: '2-digit'})}
                    </div>
                    <div>
                        <span class="info-label">Department:</span> ${data.department || ''}
                        &nbsp;&nbsp;
                        <span class="info-label">Departure/Incoming Gate:</span> ${data.gate_name || ''}
                    </div>
                </div>

                <div class="table-container">
                    <table>
                        <thead>
                            <tr>
                                <th class="sl-col">Sl</th>
                                <th class="desc-col">Description of Material</th>
                                <th class="qty-col">Quantity</th>
                                <th class="remarks-col">Remarks</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td class="sl-col">01</td>
                                <td class="desc-col">
                                    ${data.type_name} - ${data.brand_name}${data.model ? ', ' + data.model : ''}<br>
                                    Serial: ${data.serial_number || 'N/A'}<br>
                                    Device ID: ${data.device_unique_id}
                                    ${data.room_number ? '<br>Currently Installed in: ' + data.room_number + (data.room_name ? ' (' + data.room_name + ')' : '') : ''}
                                </td>
                                <td class="qty-col">01</td>
                                <td class="remarks-col">${data.vendor_destination || data.destination || ''}</td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <div class="vendor-destination">
                    <span class="info-label">Vendor/Destination:</span> ${data.vendor_destination || data.destination || ''}
                </div>

                <div class="signature-container">
                    <div class="signature-grid">
                        <div class="sig-box">
                            <div class="sig-title">Bearer Details</div>
                            <div><strong>Name:</strong> ${data.bearer_name || data.carrier_name || data.installed_by_name || ''}</div>
                            <div><strong>Company:</strong> ${data.bearer_company || data.carrier_department || ''}</div>
                            <div><strong>Contact No:</strong> ${data.bearer_contact_no || data.carrier_telephone || ''}</div>
                            <div class="sig-line"><strong>Signature & Date:</strong> ____________________ ${data.bearer_signature_date ? '(' + formatDate(data.bearer_signature_date) + ')' : ''}</div>
                        </div>
                        <div class="sig-box">
                            <div class="sig-title">Security Office</div>
                            <div><strong>Duty Officer Name:</strong> ${data.security_officer_name || data.security_name || ''}</div>
                            <div><strong>Designation:</strong> ${data.security_officer_designation || data.security_appointment || ''}</div>
                            <div><strong>Ext:</strong> ${data.security_officer_ext || ''}</div>
                            <div class="sig-line"><strong>Signature & Date:</strong> ____________________ ${data.security_officer_signature_date ? '(' + formatDate(data.security_officer_signature_date) + ')' : ''}</div>
                        </div>
                        <div class="sig-box">
                            <div class="sig-title">Processing Person</div>
                            <div><strong>Name:</strong> ${data.processing_name || data.receiver_name || ''}</div>
                            <div><strong>Designation:</strong> ${data.processing_designation || data.receiver_appointment || ''}</div>
                            <div><strong>Ext:</strong> ${data.processing_ext || ''}</div>
                            <div class="sig-line"><strong>Signature & Date:</strong> ____________________ ${data.processing_signature_date ? '(' + formatDate(data.processing_signature_date) + ')' : ''}</div>
                        </div>
                        <div class="sig-box">
                            <div class="sig-title">Authorized By</div>
                            <div><strong>Name:</strong> ${data.authorized_name || ''}</div>
                            <div><strong>Designation:</strong> ${data.authorized_designation || ''}</div>
                            <div><strong>Ext:</strong> ${data.authorized_ext || ''}</div>
                            <div class="sig-line"><strong>Signature & Date:</strong> ____________________ ${data.authorized_signature_date ? '(' + formatDate(data.authorized_signature_date) + ')' : ''}</div>
                        </div>
                    </div>
                </div>

                <div class="footer">
                    <p>This is a computer-generated gate pass for device movement tracking.</p>
                    <p>Generated on: ${new Date().toLocaleString()}</p>
                    ${data.data_entry_by_name ? `<p>Prepared by: ${data.data_entry_by_name}</p>` : ''}
                </div>
            `;

            container.innerHTML = html;
        }

        /**
         * Show error message
         */
        function showError(message) {
            const container = document.getElementById('gatePassContent');
            container.innerHTML = `
                <div class="error">
                    <i class="fas fa-exclamation-circle"></i> ${message}
                </div>
            `;
        }

        // Load gate pass on page load
        document.addEventListener('DOMContentLoaded', loadGatePass);
    </script>
</body>
