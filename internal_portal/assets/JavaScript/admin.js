(() => {
    const ADMIN_TOKEN_KEY = "internalPortalAdminToken";
    const ADMIN_USER_KEY = "internalPortalAdminUser";

    const loginForm = document.getElementById("admin-login-form");
    const emailInput = document.getElementById("admin-email");
    const passwordInput = document.getElementById("admin-password");
    const loginError = document.getElementById("admin-login-error");
    const logoutButton = document.getElementById("admin-logout");
    const inviteForm = document.getElementById("invite-form");
    const inviteEmail = document.getElementById("invite-email");
    const inviteMessage = document.getElementById("invite-message");
    const inviteLink = document.getElementById("invite-link");
    const usersMessage = document.getElementById("users-message");
    const usersTableBody = document.getElementById("users-table-body");

    function getToken() {
        try {
            return sessionStorage.getItem(ADMIN_TOKEN_KEY);
        } catch (_error) {
            return null;
        }
    }

    function setSession(token, user) {
        sessionStorage.setItem(ADMIN_TOKEN_KEY, token);
        sessionStorage.setItem(ADMIN_USER_KEY, JSON.stringify(user));
        document.body.classList.add("admin-authenticated");
    }

    function clearSession() {
        sessionStorage.removeItem(ADMIN_TOKEN_KEY);
        sessionStorage.removeItem(ADMIN_USER_KEY);
        document.body.classList.remove("admin-authenticated");
    }

    function formatDate(value) {
        if (!value) {
            return "Never";
        }
        return new Intl.DateTimeFormat(undefined, {
            dateStyle: "medium",
            timeStyle: "short",
        }).format(new Date(value));
    }

    function renderUsers(users) {
        usersTableBody.innerHTML = "";
        users.forEach((user) => {
            const row = document.createElement("tr");
            const actionDisabled = user.role === "admin";
            row.innerHTML = `
                <td>${user.email}</td>
                <td>${user.role}</td>
                <td><span class="status-pill ${user.is_active ? "active" : "inactive"}">${user.is_active ? "Active" : "Inactive"}</span></td>
                <td>${formatDate(user.latest_login_at)}</td>
                <td>${formatDate(user.invite_sent_at)}</td>
                <td>
                    <button class="admin-button ${user.is_active ? "danger" : "secondary"}" type="button" data-user-id="${user.id}" data-next-status="${!user.is_active}" ${actionDisabled ? "disabled" : ""}>
                        ${user.is_active ? "Deactivate" : "Activate"}
                    </button>
                </td>
            `;
            usersTableBody.appendChild(row);
        });
    }

    async function loadUsers() {
        const token = getToken();
        if (!token) {
            return;
        }
        usersMessage.textContent = "Loading users...";
        try {
            const result = await window.PortalApi.listUsers(token);
            renderUsers(result.items);
            usersMessage.textContent = "";
        } catch (error) {
            usersMessage.textContent = error.message || "Unable to load users.";
            clearSession();
        }
    }

    loginForm.addEventListener("submit", async (event) => {
        event.preventDefault();
        loginError.textContent = "";
        try {
            const result = await window.PortalApi.login(emailInput.value.trim(), passwordInput.value);
            if (result.user.role !== "admin") {
                throw new Error("Admin role required.");
            }
            setSession(result.token, result.user);
            passwordInput.value = "";
            await loadUsers();
        } catch (error) {
            loginError.textContent = error.message || "Invalid admin credentials.";
            passwordInput.value = "";
            passwordInput.focus();
        }
    });

    logoutButton.addEventListener("click", () => {
        clearSession();
    });

    inviteForm.addEventListener("submit", async (event) => {
        event.preventDefault();
        const token = getToken();
        inviteMessage.classList.remove("success");
        inviteMessage.textContent = "";
        inviteLink.hidden = true;
        inviteLink.textContent = "";
        try {
            const result = await window.PortalApi.inviteUser(token, inviteEmail.value.trim());
            inviteEmail.value = "";
            inviteMessage.classList.add("success");
            inviteMessage.textContent = result.email_sent
                ? "Invitation email sent."
                : "Invitation created, but email delivery is not configured.";
            inviteLink.hidden = true;
            inviteLink.textContent = "";
            await loadUsers();
        } catch (error) {
            inviteMessage.textContent = error.message || "Unable to invite user.";
        }
    });

    usersTableBody.addEventListener("click", async (event) => {
        const button = event.target.closest("button[data-user-id]");
        if (!button) {
            return;
        }
        const token = getToken();
        button.disabled = true;
        try {
            await window.PortalApi.setUserStatus(token, button.dataset.userId, button.dataset.nextStatus === "true");
            await loadUsers();
        } catch (error) {
            usersMessage.textContent = error.message || "Unable to update user.";
            button.disabled = false;
        }
    });

    async function bootstrap() {
        const token = getToken();
        if (!token) {
            return;
        }
        try {
            const user = await window.PortalApi.me(token);
            if (user.role !== "admin") {
                clearSession();
                return;
            }
            document.body.classList.add("admin-authenticated");
            await loadUsers();
        } catch (_error) {
            clearSession();
        }
    }

    bootstrap();
})();
