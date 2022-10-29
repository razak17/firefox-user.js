/***************************************************************************************************
  MIXED CONTENT
***************************************************************************************************/

/*** [SECTION 4500]: RFP (RESIST FINGERPRINTING) **/
user_pref("privacy.resistFingerprinting", false); // Cause of light theme bug
user_pref("privacy.resistFingerprinting.letterboxing", false); // reduced screen size

/* 4520: disable WebGL (Web Graphics Library)
 * [SETUP-WEB] If you need it then override it. RFP still randomizes canvas for naive scripts ***/
user_pref("webgl.disabled", false);
