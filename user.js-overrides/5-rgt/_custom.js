/***************************************************************************************************
  MIXED CONTENT
***************************************************************************************************/

/*** [SECTION 2800]: SHUTDOWN & SANITIZING ***/
user_pref("network.cookie.lifetimePolicy", 0);

/*** [SECTION 4500]: RFP (RESIST FINGERPRINTING) **/
user_pref("privacy.resistFingerprinting.letterboxing", false); // reduced screen size

/*** [SECTION 1600]: HEADERS / REFERERS ***/
user_pref("privacy.userContext.newTabContainerOnLeftClick.enabled", true);

/** SANITIZE ON SHUTDOWN : ALL OR NOTHING ***/
user_pref("privacy.clearOnShutdown.cookies", false);
user_pref("privacy.clearOnShutdown.history", false);
user_pref("privacy.clearOnShutdown.openWindows", false);
user_pref("privacy.cpd.openWindows", false);
user_pref("privacy.cpd.history", false);
user_pref("privacy.cpd.cookies", false);

// disable web extension restrictions (Bitwarden, 1Password, etc)
user_pref("privacy.resistFingerprinting.block_mozAddonManager", false);
user_pref("extensions.webextensions.restrictedDomains", "");

/* 4520: disable WebGL (Web Graphics Library)
 * [SETUP-WEB] If you need it then override it. RFP still randomizes canvas for naive scripts ***/
user_pref("webgl.disabled", false);