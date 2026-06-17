






WebFont.load({
    google: {
        families: ["Roboto Mono:regular", "Roboto Mono:500"]
    }
});


! function (o, c) {
    var n = c.documentElement,
        t = " w-mod-";
    n.className += t + "js", ("ontouchstart" in o || o.DocumentTouch && c instanceof DocumentTouch) && (n.className += t + "touch")
}(window, document);


(() => {
    const AUTH_KEY = "internalPortalAuthenticated";
    const TOKEN_KEY = "internalPortalToken";
    const USER_KEY = "internalPortalUser";
    const ADMIN_KEY = "internalPortalAdmin";
    const form = document.getElementById("portal-auth-form");

    function markPageLoaded() {
        if (!document.body) {
            return;
        }
        document.body.classList.add("loaded");
    }

    function hideLoader() {
        const loader = document.querySelector(".page-loader");
        if (!loader) {
            return;
        }
        loader.style.opacity = "0";
        loader.style.display = "none";
    }

    function showLoaderBriefly() {
        const loader = document.querySelector(".page-loader");
        if (!loader) {
            return;
        }
        markPageLoaded();
        loader.style.display = "flex";
        loader.style.opacity = "1";
        window.setTimeout(() => {
            loader.style.opacity = "0";
            window.setTimeout(() => {
                loader.style.display = "none";
            }, 450);
        }, 1200);
    }

    function applyAdminState(user) {
        const isAdmin = Boolean(user && user.role === "admin");
        try {
            if (isAdmin) {
                sessionStorage.setItem(ADMIN_KEY, "true");
            } else {
                sessionStorage.removeItem(ADMIN_KEY);
            }
        } catch (_error) {
        }
        document.documentElement.classList.toggle("portal-admin", isAdmin);
    }

    async function validateExistingSession() {
        let token = null;
        try {
            token = sessionStorage.getItem(TOKEN_KEY);
        } catch (_error) {
        }
        if (!token || !window.PortalApi) {
            return;
        }
        try {
            const user = await window.PortalApi.me(token);
            applyAdminState(user);
            sessionStorage.setItem(AUTH_KEY, "true");
            sessionStorage.setItem(USER_KEY, JSON.stringify(user));
            document.documentElement.classList.add("portal-authenticated");
        } catch (_error) {
            sessionStorage.removeItem(AUTH_KEY);
            sessionStorage.removeItem(TOKEN_KEY);
            sessionStorage.removeItem(USER_KEY);
            sessionStorage.removeItem(ADMIN_KEY);
            document.documentElement.classList.remove("portal-authenticated");
            document.documentElement.classList.remove("portal-admin");
        } finally {
            markPageLoaded();
            hideLoader();
        }
    }

    validateExistingSession();

    markPageLoaded();
    hideLoader();

    if (!form) {
        return;
    }

    const emailInput = document.getElementById("portal-auth-email");
    const passwordInput = document.getElementById("portal-auth-password");
    const errorMessage = document.getElementById("portal-auth-error");

    form.addEventListener("submit", async (event) => {
        event.preventDefault();
        const email = (emailInput ? emailInput.value : "").trim().toLowerCase();
        const password = passwordInput ? passwordInput.value : "";

        if (!window.PortalApi) {
            if (errorMessage) {
                errorMessage.textContent = "Authentication service is unavailable.";
            }
            return;
        }

        try {
            const result = await window.PortalApi.login(email, password);
            try {
                sessionStorage.setItem(AUTH_KEY, "true");
                sessionStorage.setItem(TOKEN_KEY, result.token);
                sessionStorage.setItem(USER_KEY, JSON.stringify(result.user));
            } catch (_error) {
            }
            if (errorMessage) {
                errorMessage.textContent = "";
            }
            applyAdminState(result.user);
            document.documentElement.classList.add("portal-authenticated");
            showLoaderBriefly();
            return;
        } catch (error) {
            if (errorMessage) {
                errorMessage.textContent = error.message || "Invalid email or password.";
            }
        }
        if (passwordInput) {
            passwordInput.value = "";
            passwordInput.focus();
        }
    });
})();






window.dataLayer = window.dataLayer || [];

function gtag() {
    dataLayer.push(arguments);
}
if (localStorage.getItem('consentMode') === null) {
    gtag('consent', 'default', {
        'ad_storage': 'denied',
        'ad_user_data': 'denied',
        'ad_personalization': 'denied',
        'analytics_storage': 'denied',
        'personalization_storage': 'denied',
        'functionality_storage': 'denied',
        'security_storage': 'denied',
    });
} else {
    gtag('consent', 'default', JSON.parse(localStorage.getItem('consentMode')));
}


// Google Tag Manager 

(function (w, d, s, l, i) {
    w[l] = w[l] || [];
    w[l].push({
        'gtm.start': new Date().getTime(),
        event: 'gtm.js'
    });

    var f = d.getElementsByTagName(s)[0],
        j = d.createElement(s),
        dl = l !== 'dataLayer' ? '&l=' + l : '';

    j.async = true;
    j.src = 'https://www.googletagmanager.com/gtm.js?id=' + i + dl;

    f.parentNode.insertBefore(j, f);
})(window, document, 'script', 'dataLayer', 'GTM-K43K2ZQ');



window.__WEBFLOW_CURRENCY_SETTINGS = {
    "currencyCode": "USD",
    "symbol": "$",
    "decimal": ".",
    "fractionDigits": 2,
    "group": ",",
    "template": "{{wf {\"path\":\"symbol\",\"type\":\"PlainText\"} }} {{wf {\"path\":\"amount\",\"type\":\"CommercePrice\"} }} {{wf {\"path\":\"currencyCode\",\"type\":\"PlainText\"} }}",
    "hideDecimalForWholeNumbers": false
};


// avoid quick flash of default text


(function hideEmblem() {


    var el = document.createElement('style');


    document.head.appendChild(el);


    var styleSheet = el.sheet;


    styleSheet.insertRule('.certik-emblem { display: none; }', 0);


})();



/* selectContract */
function selectContract() {
    let selectBtns = document.querySelectorAll(".js-select-contract");
    let toggleContractDropdown = document.querySelector(".js-toggle-contract-dropdown");
    let contractDropdown = document.querySelector(".js-contract-dropdown");

    if (selectBtns.length && toggleContractDropdown && contractDropdown) {
        toggleContractDropdown.addEventListener("click", function (e) {
            e.preventDefault();
            if (contractDropdown.classList.contains("is-open")) {
                contractDropdown.classList.remove("is-open");
                toggleContractDropdown.classList.remove("is-active");
            } else {
                contractDropdown.classList.add("is-open");
                toggleContractDropdown.classList.add("is-active");
            }
        });

        selectBtns.forEach((selectBtn) => {
            selectBtn.addEventListener("click", function (e) {
                e.preventDefault();
                let copyId = selectBtn.getAttribute("data-code-option");
                let copyText = document.querySelector("[data-copied='" + copyId + "']");
                let copyTextValue = copyText.value;
                let copyTextFeat = document.querySelector("[data-copied='00']");
                let selectedOptionThumb = selectBtn.querySelector(".copy-company-thumb").innerHTML;
                let selectedOptionName = selectBtn.querySelector(".copy-code-label.hide-in-mobile").innerHTML;
                let selectedOptionNameMob = selectBtn.querySelector(".copy-code-label.show-in-mobile").innerHTML;
                document.querySelector(".contractor-feat .copy-company-thumb").innerHTML = selectedOptionThumb;
                document.querySelector(".contractor-feat .copy-code-label.hide-in-mobile").innerHTML = selectedOptionName;
                document.querySelector(".contractor-feat .copy-code-label.show-in-mobile").innerHTML = selectedOptionNameMob;
                copyTextFeat.setAttribute("value", copyTextValue);
                if (contractDropdown.classList.contains("is-open")) {
                    contractDropdown.classList.remove("is-open");
                    toggleContractDropdown.classList.remove("is-active");
                }
            });
        })
    }
}
selectContract();



document.addEventListener("DOMContentLoaded", () => {
    setTimeout(function () {
        $("#learn-more-blog").detach().appendTo($("#blog-slider .media-slider-item").last());
    }, 4000);
});




document.addEventListener("DOMContentLoaded", () => {
    setTimeout(function () {
        $("#learn-more-videos").detach().appendTo($("#videos-slider .media-slider-item").last());
    }, 4000);
});




const runtimeConfig = window.__PORTAL_RUNTIME_CONFIG__ || {};
if (runtimeConfig.enableAnalytics) {
    var cookie3Options = {
        "siteId": 214,
        "additionalTracking": true,
        "cookielessEnabled": true
    }
    window._paq = window._paq || [];
    (function () {
        var d = document,
            g = d.createElement('script'),
            s = d.getElementsByTagName('script')[0];
        g.async = true;
        g.src = 'https://cdn.cookie3.co/scripts/analytics/latest/cookie3.analytics.min.js';
        s.parentNode.insertBefore(g, s);
    })();
}


function hideBanner() {
    document.getElementById('cookie-consent-banner').style.display = 'none';
}
document.getElementById('btn-hide-banner').addEventListener('click', function () {
    hideBanner();
});
document.getElementById('btn-hide-banner-mob').addEventListener('click', function () {
    hideBanner();
});
if (localStorage.getItem('consentMode') === null) {
    document.getElementById('btn-accept-all').addEventListener('click', function () {
        setConsent({
            necessary: true,
            analytics: true,
            preferences: true,
            marketing: true,
            userdata: true,
            personalization: true
        });
        hideBanner();
    });
    document.getElementById('btn-reject-all').addEventListener('click', function () {
        setConsent({
            necessary: false,
            analytics: false,
            preferences: false,
            marketing: false,
            userdata: false,
            personalization: false
        });
        hideBanner();
    });
    document.getElementById('cookie-consent-banner').style.display = 'flex';
}

function setConsent(consent) {
    const consentMode = {
        'ad_storage': consent.marketing ? 'granted' : 'denied',
        'ad_user_data': consent.userdata ? 'granted' : 'denied',
        'ad_personalization': consent.personalization ? 'granted' : 'denied',
        'analytics_storage': consent.analytics ? 'granted' : 'denied',
        'personalization_storage': consent.preferences ? 'granted' : 'denied',
        'functionality_storage': consent.necessary ? 'granted' : 'denied',
        'security_storage': consent.necessary ? 'granted' : 'denied',
    };
    gtag('consent', 'update', consentMode);
    localStorage.setItem('consentMode', JSON.stringify(consentMode));
}

function CheckSiteVersion() {
    const productionDomain = "www.chaingpt.org";
    const stageDomain = "chain-gpt.webflow.io";
    const currentDomain = window.location.hostname;
    if (currentDomain === stageDomain) {
        document.body.classList.add("stage-site");
    }
    if (currentDomain === productionDomain) {
        document.body.classList.add("prod-site");
    }

    const path = window.location.pathname;
    if (path.startsWith('/ko') || path.startsWith('/ko/')) {
        document.body.classList.add("korean-language");
    }

    document.body.classList.add("page-ready");
}
CheckSiteVersion();


document.querySelectorAll('a[target="_blank"]').forEach(link => {
    if (!link.rel.includes("noreferrer")) {
        link.rel += " noreferrer";
    }
    if (!link.rel.includes("noopener")) {
        link.rel += " noopener";
    }
});



$(document).ready(function () {
    $('.case-item-image-wrapper').each(function () {
        let color = $(this).find('.case-bg-color').text();
        $(this).find('.case-item-bg-gradient').css('background', 'linear-gradient(134.28deg, ' + color + ' 10.03%, rgba(9, 9, 14, 0) 42.81%)');
    });

    let switcherHandler = function () {
        let switcher = $('#pricing-switcher-wrapper');
        if (switcher.hasClass('active')) {
            $('#pricing-api').fadeOut('fast', () => $('#pricing-sdk').fadeIn())
        } else {
            $('#pricing-sdk').fadeOut('fast', () => $('#pricing-api').fadeIn())
        }
        switcher.toggleClass('active');
        $('#pricing-switcher-wrapper-point').toggleClass('active');
    }
    $(document).on('click', '#pricing-switcher-wrapper', switcherHandler);
    $(document).on('click', '.price-slide-icon', function (e) {
        let parent = $(e.target).closest('.pricing-clip-col');
        if (parent.hasClass('active')) {
            parent.removeClass('active');
            parent.find('.features-list').slideUp();
            parent.find('.pricing-clip-action').slideUp();
        } else {
            parent.addClass('active');
            parent.find('.features-list').slideDown();
            parent.find('.pricing-clip-action').slideDown();
        }
    });
});

(() => {
    function initSolutionsVisuals() {
        const rows = Array.from(document.querySelectorAll("[data-solution-agent]"));
        const visuals = Array.from(document.querySelectorAll("[data-solution-visual]"));

        if (!rows.length || !visuals.length) {
            return;
        }

        function setVisual(agent) {
            visuals.forEach((visual) => {
                visual.classList.toggle("is-active", visual.dataset.solutionVisual === agent);
            });
        }

        function syncVisualToViewport() {
            const viewportFocus = window.innerHeight * 0.52;
            let activeRow = rows[0];
            let closestDistance = Number.POSITIVE_INFINITY;

            rows.forEach((row) => {
                const rect = row.getBoundingClientRect();

                if (rect.bottom < 0 || rect.top > window.innerHeight) {
                    return;
                }

                const rowCenter = rect.top + rect.height / 2;
                const distance = Math.abs(rowCenter - viewportFocus);

                if (distance < closestDistance) {
                    closestDistance = distance;
                    activeRow = row;
                }
            });

            setVisual(activeRow.dataset.solutionAgent);
        }

        let ticking = false;
        function requestSync() {
            if (ticking) {
                return;
            }
            ticking = true;
            window.requestAnimationFrame(() => {
                syncVisualToViewport();
                ticking = false;
            });
        }

        rows.forEach((row) => {
            const agent = row.dataset.solutionAgent;
            row.addEventListener("pointerenter", () => setVisual(agent));
            row.addEventListener("focusin", () => setVisual(agent));
        });

        window.addEventListener("scroll", requestSync, { passive: true });
        window.addEventListener("resize", requestSync);
        syncVisualToViewport();
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", initSolutionsVisuals);
    } else {
        initSolutionsVisuals();
    }
})();


(() => {
    const webglLayer = document.querySelector(".webgl");
    if (!webglLayer || window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
        return;
    }

    let targetX = 0;
    let targetY = 0;
    let currentX = 0;
    let currentY = 0;
    const maxX = 34;
    const maxY = 24;
    const ease = 0.08;

    function updateTarget(event) {
        const x = event.clientX / window.innerWidth - 0.5;
        const y = event.clientY / window.innerHeight - 0.5;
        targetX = x * maxX;
        targetY = y * maxY;
    }

    function animate() {
        currentX += (targetX - currentX) * ease;
        currentY += (targetY - currentY) * ease;
        webglLayer.style.setProperty("--webgl-cursor-x", `${currentX.toFixed(2)}px`);
        webglLayer.style.setProperty("--webgl-cursor-y", `${currentY.toFixed(2)}px`);
        requestAnimationFrame(animate);
    }

    window.addEventListener("pointermove", updateTarget, { passive: true });
    animate();
})();
