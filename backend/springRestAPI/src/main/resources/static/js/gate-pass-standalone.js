        function getUrlParameter(name) {
            const urlParams = new URLSearchParams(window.location.search);
            return urlParams.get(name);
        }

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
            // Expecting HH:MM or HH:MM:SS
            const parts = String(timeString).split(':');
            if (parts.length < 2) return timeString;
            const hh = parts[0].padStart(2, '0');
            const mm = parts[1].padStart(2, '0');
            return `${hh}:${mm}`;
        }

        async function loadGatePass() {
            const gatePassId = getUrlParameter('id');
            
            if (!gatePassId) {
                showError('No gate pass ID provided');
                return;
            }

            try {
                const token = localStorage.getItem('jwt_token');
                if (!token) {
                    showError('Authentication required. Please login.');
                    return;
                }

                const response = await fetch(`${CONFIG.API_BASE_URL}${CONFIG.ENDPOINTS.GATE_PASSES}?gate_pass_id=${gatePassId}`, {
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Content-Type': 'application/json'
                    }
                });

                const result = await response.json();
                
                if (result.success && result.data.length > 0) {
                    renderGatePass(result.data[0]);
                } else {
                    showError('Gate pass not found');
                }
            } catch (error) {
                console.error('Error loading gate pass:', error);
                showError('Failed to load gate pass data');
            }
        }

        function renderGatePass(data) {
            let devicesHtml = '';
            
            if (data.devices && data.devices.length > 0) {
                data.devices.forEach((device, index) => {
                    const roomInfo = device.current_room_number ? 
                        `Currently Installed in: ${device.current_room_number}${device.current_room_name ? ' (' + device.current_room_name + ')' : ''}` : '';
                    
                    devicesHtml += `
                        <tr>
                            <td class="sl-col">${String(index + 1).padStart(2, '0')}</td>
                            <td class="desc-col">
                                ${device.type_name} - ${device.brand_name}${device.model ? ', ' + device.model : ''}<br>
                                Serial: ${device.serial_number || 'N/A'}<br>
                                Device ID: ${device.device_unique_id}
                                ${roomInfo ? '<br>' + roomInfo : ''}
                            </td>
                            <td class="qty-col">01</td>
                            <td class="remarks-col">${data.destination || ''}</td>
                        </tr>
                    `;
                });
            }

            // Generate tech circuit pattern with flashy effects
            let circuitPattern = '<div class="watermark-pattern">';
            // Horizontal glowing lines
            for (let i = 0; i < 8; i++) {
                const top = 15 + (i * 10);
                const left = 5 + Math.random() * 20;
                const width = 40 + Math.random() * 40;
                const delay = Math.random() * 2;
                circuitPattern += `<div class="circuit-line" style="top:${top}%;left:${left}%;width:${width}%;height:2px;animation-delay:${delay}s;"></div>`;
            }
            // Vertical glowing lines
            for (let i = 0; i < 8; i++) {
                const top = 10 + Math.random() * 30;
                const left = 10 + (i * 11);
                const height = 30 + Math.random() * 40;
                const delay = Math.random() * 2;
                circuitPattern += `<div class="circuit-line" style="top:${top}%;left:${left}%;height:${height}%;width:2px;animation-delay:${delay}s;"></div>`;
            }
            // Glowing circuit nodes
            for (let i = 0; i < 20; i++) {
                const top = 15 + Math.random() * 70;
                const left = 10 + Math.random() * 80;
                circuitPattern += `<div class="circuit-node" style="top:${top}%;left:${left}%;"></div>`;
            }
            circuitPattern += '</div>';
            
            const html = circuitPattern + `
                <div class="header">
                    <img src="${CONFIG.LOGO_PATH}" alt="NSU Logo" class="logo">
                    <div class="title">North South University</div>
                    <div class="university-address">Plot# 15, Block# B, Basundhara, Dhaka-1229</div>
                    <div style="text-align: center; margin-top: 15px;">
                        <div class="gate-pass-title">MATERIAL GATE PASS</div>
                    </div>
                </div>

                <div class="gate-pass-info">
                    <div class="info-item">
                        <span class="info-label">Incoming</span> <span class="checkbox">${data.pass_direction === 'incoming' ? '☑' : '☐'}</span>
                        &nbsp;&nbsp;
                        <span class="info-label">Outgoing</span> <span class="checkbox">${data.pass_direction === 'outgoing' || !data.pass_direction ? '☑' : '☐'}</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Serial:</span> ${data.gate_pass_number}
                    </div>
                </div>

                <div class="header-fields">
                    <div>
                        <span class="info-label">Date:</span> ${data.gate_pass_date ? formatDate(data.gate_pass_date) : 'N/A'}
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
                            ${devicesHtml}
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
                            <div><strong>Name:</strong> ${data.bearer_name || data.carrier_name || ''}</div>
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
            `;

            // Render in both containers for printing twice
            document.getElementById('gatePassContent').innerHTML = html;
            document.getElementById('gatePassContentCopy').innerHTML = html;
            document.getElementById('gatePassContentCopy').style.display = 'block';
        }

        function showError(message) {
            const container = document.getElementById('gatePassContent');
            container.innerHTML = `
                <div class="error">
                    <i class="fas fa-exclamation-circle"></i> ${message}
                </div>
            `;
        }

        document.addEventListener('DOMContentLoaded', loadGatePass);
    </script>
</body>
