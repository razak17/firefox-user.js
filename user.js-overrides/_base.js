// HOMEPAGE
user_pref("browser.newtabpage.activity-stream.feeds.section.highlights", false);
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);

// FONT
user_pref("font.name.serif.x-western", "FreeSans");
user_pref("font.size.variable.x-western", 14);
user_pref("font.internaluseonly.changed", false);

// SEARCH AND URL BAR
user_pref("browser.urlbar.suggest.history", false);
user_pref("browser.urlbar.suggest.bookmark", true);
user_pref("browser.urlbar.suggest.openpage", true);
// user_pref("browser.urlbar.suggest.engines", false);
user_pref("browser.urlbar.suggest.topsites", false);
user_pref("browser.search.countryCode", "US");
user_pref("browser.search.widget.inNavBar", true);
user_pref("browser.search.geoSpecificDefaults", false);
user_pref("browser.search.geoSpecificDefaults.url", "");
user_pref("browser.urlbar.placeholderName", "DuckDuckGo");
user_pref("browser.urlbar.placeholderName.private", "DuckDuckGo");

// BOOKMARKS
user_pref("browser.tabs.loadBookmarksInTabs", true); // open bookmarks in a new tab [FF57+]
user_pref("browser.bookmarks.max_backups", 2);
user_pref("browser.toolbars.bookmarks.showOtherBookmarks", false);
user_pref("browser.toolbars.bookmarks.visibility", "never");

// DEVTOOLS
user_pref("devtools.editor.keymap", "vim");

// WELCOME & WHAT's NEW NOTICES
user_pref("startup.homepage_welcome_url", "");
user_pref("startup.homepage_welcome_url.additional", "");
user_pref("startup.homepage_override_url", ""); // What's New page after updates

/*** [SECTION 0100]: STARTUP ***/
user_pref("browser.startup.page", 3);

// disable Firefox from asking to set as the default browser
user_pref("browser.shell.checkDefaultBrowser", false);

// disable fullscreen delay and notices
user_pref("full-screen-api.transition-duration.enter", "0 0");
user_pref("full-screen-api.transition-duration.leave", "0 0");
user_pref("full-screen-api.warning.delay", -1);
user_pref("full-screen-api.warning.timeout", 0);

// enable "Dark Mode"
user_pref("layout.css.prefers-color-scheme.content-override", 0);
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("devtools.theme", "dark");
user_pref("reader.color_scheme", "dark");

// fix icons for extensions on Dark Mode
user_pref("svg.context-properties.content.enabled", true);

// WARNINGS
user_pref("browser.tabs.warnOnClose", false);
user_pref("browser.tabs.warnOnCloseOtherTabs", false);
user_pref("browser.tabs.closeWindowWithLastTab", false);
user_pref("browser.tabs.warnOnOpen", false);

// APPEARANCE
user_pref("sidebar.position_start", false);
user_pref("browser.download.autohideButton", false); // [FF57+]
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true); // [FF68+] allow userChrome/userContent

// CONTENT BEHAVIOR
user_pref("accessibility.browsewithcaret", false);
user_pref("accessibility.typeaheadfind", false);
user_pref("clipboard.autocopy", false); // disable autocopy default [LINUX]
user_pref("layout.spellcheckDefault", 2); // 0=none, 1-multi-line, 2=multi-line & single-line

// UX BEHAVIOR
user_pref("browser.backspace_action", 2); // 0=previous page, 1=scroll up, 2=do nothing
user_pref("browser.quitShortcut.disabled", true); // disable Ctrl-Q quit shortcut [LINUX] [MAC] [FF87+]
user_pref("browser.urlbar.decodeURLsOnCopy", true); // see bugzilla 1320061 [FF53+]
user_pref("general.autoScroll", false); // middle-click enabling auto-scrolling [DEFAULT: false on Linux]
user_pref("ui.key.menuAccessKey", 0); // disable alt key toggling the menu bar [RESTART]
user_pref("view_source.tab", false); // view "page/selection source" in a new window [FF68+, FF59 and under]
user_pref("full-screen-api.ignore-widgets", true);

// UX FEATURES: disable and hide the icons and menus
user_pref("extensions.pocket.enabled", false); // Pocket Account [FF46+]
user_pref("extensions.screenshots.disabled", false); // [FF55+]
user_pref("identity.fxaccounts.enabled", false); // Firefox Accounts & Sync [FF60+] [RESTART]
user_pref("reader.parse-on-load.enabled", false); // Reader View

/*** [SECTION 0400]: SAFE BROWSING (SB) ***/
user_pref("browser.safebrowsing.malware.enabled", true);
user_pref("browser.safebrowsing.phishing.enabled", true);
user_pref("browser.safebrowsing.downloads.enabled", true);

// Hardware acceleration
user_pref("browser.preferences.defaultPerformanceSettings.enabled", false);
user_pref("layers.acceleration.disabled", true);

/*** [SECTION 5000]: OPTIONAL OPSEC ***/
user_pref("signon.rememberSignons", false);
user_pref("browser.privatebrowsing.autostart", false);
user_pref("extensions.formautofill.addresses.usage.hasEntry", false);

/** EXTENSIONS ***/
user_pref("extensions.webextensions.restrictedDomains", "");

/*** [SECTION 0700]: DNS / DoH / PROXY / SOCKS / IPv6 ***/
user_pref("network.trr.mode", 3);
// https://dns.quad9.net/dns-query
// https://doh-ch.blahdns.com/dns-query
user_pref("network.trr.custom_uri", "https://dns.quad9.net/dns-query");
user_pref("network.trr.uri", "https://dns.quad9.net/dns-query");
user_pref("network.dns.disableIPv6", false); // localhost:8000 not working

// Disable firefox suggest (Manually)
user_pref("browser.urlbar.groupLabels.enabled", false);

// disable promos
user_pref("browser.vpn_promo.enabled", false);
user_pref("browser.promo.focus.enabled", false);
user_pref("browser.promo.pin.enabled", false);

// search engine
user_pref("key.url", "https://html.duckduckgo.com/html?q=\\");

// 1244: enable HTTPS-Only mode in all windows [FF76+]
user_pref("dom.security.https_only_mode", false); // [FF76+]

// css selector
user_pref("layout.css.has-selector.enabled", true);

/* 1212: set OCSP fetch failures (non-stapled, see 1211) to hard-fail [SETUP-WEB]  ***/
user_pref("security.OCSP.require", false);

// disable VPN promotions
user_pref("browser.privatebrowsing.vpnpromourl", "");

// Cookie Banner handling
user_pref("cookiebanners.service.mode", 2);
user_pref("cookiebanners.service.mode.privateBrowsing", 2);

// reduce the 5ms waits to render the page
user_pref("nglayout.initialpaint.delay", 0);
user_pref("nglayout.initialpaint.delay_in_oopif", 0);

// notification interval (in ms) to avoid layout thrashing
user_pref("content.notify.interval", 100000);

// disable preSkeletonUI on startup
user_pref("browser.startup.preXulSkeletonUI", false);

// webrender tweaks
user_pref("gfx.webrender.all", true);
user_pref("gfx.webrender.precache-shaders", true);
user_pref("gfx.webrender.compositor", true);
user_pref("layers.gpu-process.enabled", true);
user_pref("gfx.canvas.accelerated", true);
user_pref("gfx.canvas.accelerated.cache-items", 32768);
user_pref("gfx.canvas.accelerated.cache-size", 4096);
user_pref("gfx.content.skia-font-cache-size", 80);

// image tweaks
user_pref("image.cache.size", 10485760);
user_pref("image.mem.decode_bytes_at_a_time", 131072);
user_pref("image.mem.shared.unmap.min_expiration_ms", 120000);

// increase media cache
user_pref("media.memory_cache_max_size", 1048576);
user_pref("media.memory_caches_combined_limit_kb", 2560000);

// decrease video buffering
user_pref("media.cache_readahead_limit", 9000);
user_pref("media.cache_resume_threshold", 6000);

// increase memory cache size
user_pref("browser.cache.memory.max_entry_size", 153600);

// use bigger packets
user_pref("network.buffer.cache.size", 262144);
user_pref("network.buffer.cache.count", 128);

// enable css has selector
user_pref("layout.css.has-selector.enabled", true);

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

// disable firefox view
user_pref("browser.tabs.firefox-view", false);
