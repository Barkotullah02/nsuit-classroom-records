/**
 * auth.js — AssetBeacon Thymeleaf Edition
 * Handles login form and already-logged-in redirect.
 * Routes use clean MVC paths (/login, /dashboard).
 */
document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('loginForm');
    if (!loginForm) return;          // Not on login page — skip

    // Already authenticated? Go to dashboard
    if (Utils.isLoggedIn()) {
        window.location.href = '/dashboard';
        return;
    }

    loginForm.addEventListener('submit', async (e) => {
        e.preventDefault();

        const username  = document.getElementById('username').value.trim();
        const password  = document.getElementById('password').value;
        const submitBtn = loginForm.querySelector('button[type="submit"]');

        document.getElementById('alert-container').innerHTML = '';
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Signing in…';

        try {
            const result = await Utils.apiRequest(CONFIG.ENDPOINTS.AUTH, {
                method : 'POST',
                body   : JSON.stringify({ username, password })
            });

            if (result.success) {
                Utils.setToken(result.data.token);
                Utils.setCurrentUser(result.data.user || result.data);
                Utils.showAlert('Login successful! Redirecting…', 'success');
                setTimeout(() => { window.location.href = '/dashboard'; }, 800);
            } else {
                Utils.showAlert(result.message || 'Login failed. Check credentials.');
                submitBtn.disabled = false;
                submitBtn.innerHTML = '<i class="fas fa-sign-in-alt"></i> Sign In';
            }
        } catch {
            Utils.showAlert('An error occurred during login.');
            submitBtn.disabled = false;
            submitBtn.innerHTML = '<i class="fas fa-sign-in-alt"></i> Sign In';
        }
    });
});
