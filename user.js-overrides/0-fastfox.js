/***************************************************************************************************
  MIXED CONTENT (Fastfox)
***************************************************************************************************/

user_pref("browser.tabs.loadBookmarksInTabs", true); // open bookmarks in a new tab [FF57+]
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true); // [FF68+] allow userChrome/userContent
user_pref("full-screen-api.ignore-widgets", true);
user_pref("signon.rememberSignons", false);
user_pref("browser.privatebrowsing.autostart", false);
user_pref("extensions.formautofill.addresses.usage.hasEntry", false);
user_pref("network.trr.mode", 3);
user_pref("network.trr.custom_uri", "https://dns.quad9.net/dns-query");
user_pref("network.trr.uri", "https://dns.quad9.net/dns-query");
user_pref("network.dns.disableIPv6", false); // localhost:8000 not working
user_pref("browser.vpn_promo.enabled", false);
user_pref("browser.promo.focus.enabled", false);
user_pref("browser.promo.pin.enabled", false);
user_pref("key.url", "https://html.duckduckgo.com/html?q=\\");
user_pref("browser.preferences.moreFromMozilla", false);
user_pref("browser.preferences.experimental", true);
user_pref("xpinstall.signatures.required", false);

/** SANITIZE ON SHUTDOWN : ALL OR NOTHING ***/
user_pref("privacy.clearOnShutdown.cookies", true);
user_pref("privacy.clearOnShutdown.history", true);
user_pref("privacy.clearOnShutdown.openWindows", true);
user_pref("privacy.cpd.openWindows", true);
user_pref("privacy.cpd.history", true);
user_pref("privacy.cpd.cookies", true);
user_pref("privacy.sanitize.sanitizeOnShutdown", true);

// enable "Dark Mode"
user_pref("layout.css.prefers-color-scheme.content-override", 0);
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("devtools.theme", "dark");
user_pref("reader.color_scheme", "dark");
user_pref("browser.theme.content-theme", 0);
user_pref("browser.theme.toolbar-theme", 0);
user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");
