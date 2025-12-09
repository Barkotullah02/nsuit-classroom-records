/**
 * Authentication Module
 * Handles login functionality
 */

document.addEventListener('DOMContentLoaded', () => {
    // Only run login page logic if we're on the login page
    const loginForm = document.getElementById('loginForm');
    if (!loginForm) {
        // Not on login page, skip
        return;
    }

    // Redirect if already logged in
    if (Utils.isLoggedIn()) {
        window.location.href = 'dashboard.html';
        return;
    }
    
    loginForm.addEventListener('submit', async (e) => {
        e.preventDefault();

        const username = document.getElementById('username').value.trim();
        const password = document.getElementById('password').value;

        // Clear previous alerts
        document.getElementById('alert-container').innerHTML = '';

        // Disable submit button
        const submitBtn = loginForm.querySelector('button[type="submit"]');
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Signing in...';

        try {
            const result = await Utils.apiRequest(CONFIG.ENDPOINTS.AUTH, {
                method: 'POST',
                body: JSON.stringify({ username, password })
            });

            if (result.success) {
                // Store JWT token and user data
                Utils.setToken(result.data.token);
                Utils.setCurrentUser(result.data.user);
                
                // Show success message
                Utils.showAlert('Login successful! Redirecting...', 'success');
                
                // Redirect to dashboard
                setTimeout(() => {
                    window.location.href = 'dashboard.html';
                }, 1000);
            } else {
                Utils.showAlert(result.message || 'Login failed');
                submitBtn.disabled = false;
                submitBtn.innerHTML = '<i class="fas fa-sign-in-alt"></i> Sign In';
            }
        } catch (error) {
            Utils.showAlert('An error occurred during login');
            submitBtn.disabled = false;
            submitBtn.innerHTML = '<i class="fas fa-sign-in-alt"></i> Sign In';
        }
    });
});
