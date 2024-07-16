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
user_pref("privacy.sanitize.sanitizeOnShutdown", false);

/* 1601: control when to send a cross-origin referer
 * 0=always (default), 1=only if base domains match, 2=only if hosts match
 * [SETUP-WEB] Breakage: older modems/routers and some sites e.g banks, vimeo, icloud, instagram
 * If "2" is too strict, then override to "0" and use Smart Referer extension (Strict mode + add exceptions) ***/
user_pref("network.http.referer.XOriginPolicy", 0); // manually set again after running updater.sh or just comment out in user.js

/* 2022: disable all DRM content (EME: Encryption Media Extension)
 * Optionally hide the setting which also disables the DRM prompt
 * [SETUP-WEB] e.g. Netflix, Amazon Prime, Hulu, HBO, Disney+, Showtime, Starz, DirectTV
 * [SETTING] General>DRM Content>Play DRM-controlled content
 * [TEST] https://bitmovin.com/demos/drm
 * [1] https://www.eff.org/deeplinks/2017/10/drms-dead-canary-how-we-just-lost-web-what-we-learned-it-and-what-we-need-do-next ***/
user_pref("media.eme.enabled", true);
