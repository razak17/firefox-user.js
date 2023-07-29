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

// increase the absolute number of HTTP connections
user_pref("network.http.max-connections", 1800);
user_pref("network.http.max-persistent-connections-per-server", 10);

// increase TLS token caching
user_pref("network.ssl_tokens_cache_capacity", 32768);

// display tab dropdown when there are too many tabs
user_pref("browser.tabs.tabmanager.enabled", false);

// hide "More from Mozilla" from settings
user_pref("browser.preferences.moreFromMozilla", false);

// show "Firefox Experiments" on settings
user_pref("browser.preferences.experimental", true);

// for correct styles `chrome/ui/floating-findbar-on-top.css`
// user_pref("browser.toolbars.bookmarks.visibility", "always");
