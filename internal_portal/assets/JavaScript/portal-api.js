window.PortalApi = (() => {
    const runtimeConfig = window.__PORTAL_RUNTIME_CONFIG__ || {};
    const API_BASE = String(runtimeConfig.portalApiBase || window.PORTAL_API_BASE || "").trim().replace(/\/$/, "");

    async function request(path, options = {}) {
        const requestUrl = API_BASE ? `${API_BASE}${path}` : path;
        const headers = {
            "Content-Type": "application/json",
            ...(options.headers || {}),
        };
        const response = await fetch(requestUrl, {
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
