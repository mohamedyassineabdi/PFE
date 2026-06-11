(() => {
    const form = document.getElementById("set-password-form");
    const passwordInput = document.getElementById("new-password");
    const confirmInput = document.getElementById("confirm-password");
    const message = document.getElementById("set-password-message");
    const queryToken = new URLSearchParams(window.location.search).get("token");
    const hashToken = new URLSearchParams(window.location.hash.replace(/^#/, "")).get("token");
    const token = queryToken || hashToken;

    if (token && window.history && window.history.replaceState) {
        window.history.replaceState(null, "", "setup-password.html");
    }

    if (!token) {
        message.textContent = "Invitation token is missing.";
        form.querySelector("button").disabled = true;
        return;
    }

    form.addEventListener("submit", async (event) => {
        event.preventDefault();
        message.classList.remove("success");
        message.textContent = "";

        if (passwordInput.value !== confirmInput.value) {
            message.textContent = "Passwords do not match.";
            confirmInput.focus();
            return;
        }

        try {
            await window.PortalApi.setPassword(token, passwordInput.value, confirmInput.value);
            message.classList.add("success");
            message.textContent = "Password saved. Redirecting to sign in...";
            passwordInput.value = "";
            confirmInput.value = "";
            window.setTimeout(() => {
                window.location.href = "index.html";
            }, 1200);
        } catch (error) {
            message.textContent = error.message || "Unable to set password.";
        }
    });
})();
