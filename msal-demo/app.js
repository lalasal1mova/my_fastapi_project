// app.js
import { PublicClientApplication, InteractionRequiredAuthError } from "https://cdn.jsdelivr.net/npm/@azure/msal-browser/dist/msal-browser.esm.js";

// MSAL konfiqurasiya
const msalConfig = {
    auth: {
        clientId: "YOUR_CLIENT_ID_HERE",
        redirectUri: window.location.origin + "/redirect.html"
    },
    cache: { cacheLocation: "localStorage" }
};

const msalInstance = new PublicClientApplication(msalConfig);

const loginBtn = document.getElementById("loginBtn");
const logoutBtn = document.getElementById("logoutBtn");
const getTokenBtn = document.getElementById("getTokenBtn");
const output = document.getElementById("output");

// login/logout/token
loginBtn.addEventListener("click", async () => {
    try {
        await msalInstance.loginPopup({ scopes: ["User.Read"] });
        output.textContent = "User logged in!";
    } catch (err) {
        output.textContent = "Login error: " + err.message;
    }
});

logoutBtn.addEventListener("click", () => {
    const account = msalInstance.getActiveAccount();
    if (account) msalInstance.logoutPopup({ account });
    else output.textContent = "No active account";
});

getTokenBtn.addEventListener("click", async () => {
    const account = msalInstance.getActiveAccount();
    if (!account) return output.textContent = "Login first";
    try {
        const tokenResponse = await msalInstance.acquireTokenSilent({ scopes: ["User.Read"], account });
        output.textContent = tokenResponse.accessToken;
    } catch (err) {
        if (err instanceof InteractionRequiredAuthError) {
            const tokenResponse = await msalInstance.acquireTokenPopup({ scopes: ["User.Read"], account });
            output.textContent = tokenResponse.accessToken;
        } else output.textContent = "Token error: " + err.message;
    }
});