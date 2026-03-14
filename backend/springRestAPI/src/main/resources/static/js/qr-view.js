        // Get data from URL parameter
        const urlParams = new URLSearchParams(window.location.search);
        const encodedData = urlParams.get('data');

        if (!encodedData) {
            document.querySelector('.qr-container').innerHTML = `
                <div class="qr-header">
                    <h1 style="color: #dc3545;"><i class="fas fa-exclamation-triangle"></i> Invalid QR Code</h1>
                    <p>No device data found in QR code.</p>
                </div>
            `;
        } else {
            try {
                // Decode the data
                const jsonData = atob(decodeURIComponent(encodedData));
                const deviceData = JSON.parse(jsonData);

                // Populate device information
                document.getElementById('deviceUID').textContent = deviceData.uid;
                document.getElementById('deviceType').textContent = deviceData.type;
                document.getElementById('deviceBrand').textContent = deviceData.brand;
                document.getElementById('deviceModel').textContent = deviceData.model;
                document.getElementById('deviceSerial').textContent = deviceData.serial;
                document.getElementById('purchaseDate').textContent = deviceData.purchase_date;
                document.getElementById('currentRoom').textContent = deviceData.current_room;
                document.getElementById('installedDate').textContent = deviceData.installed_date;

                // Show notes if available
                if (deviceData.notes && deviceData.notes.trim() !== '') {
                    document.getElementById('notesSection').style.display = 'block';
                    document.getElementById('deviceNotes').textContent = deviceData.notes;
                }

                // Populate installation history
                const historyList = document.getElementById('historyList');
                if (deviceData.history && deviceData.history.length > 0) {
                    historyList.innerHTML = deviceData.history.map(h => `
                        <div class="history-item ${h.status === 'active' ? 'active' : ''}">
                            <div><strong>${h.room}</strong></div>
                            <div style="font-size: 0.9rem; color: #666;">
                                <i class="fas fa-calendar"></i> ${h.from} 
                                ${h.to !== 'Current' ? `→ ${h.to}` : '<span style="color: #28a745;">(Current)</span>'}
                            </div>
                        </div>
                    `).join('');
                } else {
                    historyList.innerHTML = '<div style="padding: 15px; background: #f8f9fa; border-radius: 8px; color: #666; text-align: center;"><i class="fas fa-info-circle"></i> No previous history available</div>';
                }

                // Update view full button - extract device ID from history or use uid
                document.getElementById('viewFullBtn').href = 
                    `/device-history?uid=${encodeURIComponent(deviceData.uid)}`;

            } catch (error) {
                console.error('Error parsing device data:', error);
                document.querySelector('.qr-container').innerHTML = `
                    <div class="qr-header">
                        <h1 style="color: #dc3545;"><i class="fas fa-exclamation-triangle"></i> Error</h1>
                        <p>Failed to load device information.</p>
                        <p style="font-size: 0.9rem; color: #999;">${error.message}</p>
                    </div>
                `;
            }
        }
    </script>
</body>
