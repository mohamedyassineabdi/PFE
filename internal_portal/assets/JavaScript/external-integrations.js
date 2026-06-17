(() => {
    const runtimeConfig = window.__PORTAL_RUNTIME_CONFIG__ || {};

    function appendScript(src, attributes = {}) {
        const script = document.createElement("script");
        script.src = src;
        Object.entries(attributes).forEach(([key, value]) => {
            if (value === true) {
                script.setAttribute(key, "");
            } else if (value !== false && value != null) {
                script.setAttribute(key, String(value));
            }
        });
        document.body.appendChild(script);
    }

    function activateLegacyMedia() {
        document.querySelectorAll("source[data-src]").forEach((source) => {
            const sourceUrl = source.getAttribute("data-src");
            if (sourceUrl) {
                source.setAttribute("src", sourceUrl);
            }
        });
        document.querySelectorAll("video").forEach((video) => {
            if (video.querySelector("source[src]")) {
                video.load();
            }
        });
    }

    if (runtimeConfig.enableLegacyExternalScripts) {
        activateLegacyMedia();
        appendScript(
            "https://chaingpt-web.s3.us-east-2.amazonaws.com/assets/js/Update+02.08.24/ScrambleTextPlugin.min.js"
        );
        appendScript(
            "https://chaingpt-web.s3.us-east-2.amazonaws.com/assets/js/Update+02.08.24/main-global.min.js"
        );
        appendScript(
            "https://chaingpt-web.s3.us-east-2.amazonaws.com/assets/js/main-script-no-reviews.js",
            { type: "module", async: true }
        );
    }

    if (runtimeConfig.enableAnalytics) {
        appendScript(
            "https://static.cloudflareinsights.com/beacon.min.js/vcd15cbe7772f49c399c6a5babf22c1241717689176015",
            {
                defer: true,
                integrity: "sha512-ZpsOmlRQV6y907TI0dKBHq9Md29nnaEIPlkf84rnaERnq6zvWvPUqr2ft8M1aS28oN72PdrCzSjY4U6VaAw1EQ==",
                "data-cf-beacon": "{\"rayId\":\"91d5ce491cf0ea40\",\"serverTiming\":{\"name\":{\"cfExtPri\":true,\"cfL4\":true,\"cfSpeedBrain\":true,\"cfCacheStatus\":true}},\"version\":\"2025.1.0\",\"token\":\"0411ff5694344c8eabb413d9bc9e540c\"}",
                crossorigin: "anonymous",
            }
        );
    }
})();
