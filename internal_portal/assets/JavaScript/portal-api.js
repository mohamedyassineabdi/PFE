window.PortalApi = (() => {
    const API_BASE = (window.PORTAL_API_BASE || "http://127.0.0.1:8000/api/v1").replace(/\/$/, "");

    async function request(path, options = {}) {
        const headers = {
            "Content-Type": "application/json",
            ...(options.headers || {}),
        };
        const response = await fetch(`${API_BASE}${path}`, {
            ...options,
            headers,
        });
        const payload = await response.json().catch(() => ({}));
        if (!response.ok) {
            throw new Error(payload.detail || payload.message || "Request failed");
        }
        return payload;
    }

    function authHeaders(token) {
        return token ? { Authorization: `Bearer ${token}` } : {};
    }

    return {
        login(email, password) {
            return request("/auth/login", {
                method: "POST",
                body: JSON.stringify({ email, password }),
            });
        },
        me(token) {
            return request("/auth/me", {
                headers: authHeaders(token),
            });
        },
        setPassword(token, password, confirmPassword) {
            return request("/auth/set-password", {
                method: "POST",
                body: JSON.stringify({ token, password, confirm_password: confirmPassword }),
            });
        },
        listUsers(token) {
            return request("/auth/admin/users", {
                headers: authHeaders(token),
            });
        },
        inviteUser(token, email) {
            return request("/auth/admin/users/invite", {
                method: "POST",
                headers: authHeaders(token),
                body: JSON.stringify({ email }),
            });
        },
        setUserStatus(token, userId, isActive) {
            return request(`/auth/admin/users/${userId}/status`, {
                method: "PATCH",
                headers: authHeaders(token),
                body: JSON.stringify({ is_active: isActive }),
            });
        },
    };
})();
