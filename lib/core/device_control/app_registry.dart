/// Maps common app name keywords to Android package names.
///
/// The Agent Driven Environment uses this registry to resolve natural-language
/// commands like "open Facebook" or "launch YouTube" into actual
/// package names that can be launched via Intent.
///
/// Each [AppEntry] contains:
/// - [keywords]: A list of words/phrases that should trigger this app.
/// - [packageName]: The Android package name.
/// - [displayName]: Human-readable name shown in logs/UI.
/// - [searchQuery]: Optional query to search within the app after launch.
class AppRegistry {
  AppRegistry._();
  static final List<AppEntry> entries = [
    // Social Media
    AppEntry(
      keywords: ['facebook', 'fb', 'face book'],
      packageName: 'com.facebook.katana',
      displayName: 'Facebook',
    ),
    AppEntry(
      keywords: ['instagram', 'insta', 'ig'],
      packageName: 'com.instagram.android',
      displayName: 'Instagram',
    ),
    AppEntry(
      keywords: ['twitter', 'x app', 'x'],
      packageName: 'com.twitter.android',
      displayName: 'X (Twitter)',
      altPackages: ['com.x.android'],
    ),
    AppEntry(
      keywords: ['tiktok', 'tik tok'],
      packageName: 'com.zhiliaoapp.musically',
      displayName: 'TikTok',
    ),
    AppEntry(
      keywords: ['snapchat', 'snap'],
      packageName: 'com.snapchat.android',
      displayName: 'Snapchat',
    ),
    AppEntry(
      keywords: ['reddit'],
      packageName: 'com.reddit.frontpage',
      displayName: 'Reddit',
    ),
    AppEntry(
      keywords: ['threads'],
      packageName: 'com.instagram.barcelona',
      displayName: 'Threads',
    ),
    AppEntry(
      keywords: ['telegram'],
      packageName: 'org.telegram.messenger',
      displayName: 'Telegram',
      altPackages: ['org.telegram.messenger.web'],
    ),
    AppEntry(
      keywords: ['whatsapp', 'whats app'],
      packageName: 'com.whatsapp',
      displayName: 'WhatsApp',
      altPackages: ['com.whatsapp.w4b'],
    ),
    AppEntry(
      keywords: ['discord'],
      packageName: 'com.discord',
      displayName: 'Discord',
    ),
    AppEntry(
      keywords: ['linkedin', 'linked in'],
      packageName: 'com.linkedin.android',
      displayName: 'LinkedIn',
    ),
    AppEntry(
      keywords: ['pinterest'],
      packageName: 'com.pinterest',
      displayName: 'Pinterest',
    ),

    // Messaging
    AppEntry(
      keywords: ['messenger', 'fb messenger', 'facebook messenger'],
      packageName: 'com.facebook.orca',
      displayName: 'Messenger',
    ),
    AppEntry(
      keywords: ['signal'],
      packageName: 'org.thoughtcrime.securesms',
      displayName: 'Signal',
    ),
    AppEntry(
      keywords: ['viber'],
      packageName: 'com.viber.voip',
      displayName: 'Viber',
    ),

    // Video & Streaming
    AppEntry(
      keywords: ['youtube', 'yt', 'you tube'],
      packageName: 'com.google.android.youtube',
      displayName: 'YouTube',
    ),
    AppEntry(
      keywords: ['youtube music', 'yt music'],
      packageName: 'com.google.android.apps.youtube.music',
      displayName: 'YouTube Music',
    ),
    AppEntry(
      keywords: ['netflix'],
      packageName: 'com.netflix.mediaclient',
      displayName: 'Netflix',
    ),
    AppEntry(
      keywords: ['spotify'],
      packageName: 'com.spotify.music',
      displayName: 'Spotify',
    ),
    AppEntry(
      keywords: ['twitch'],
      packageName: 'tv.twitch.android.app',
      displayName: 'Twitch',
    ),
    AppEntry(
      keywords: ['disney', 'disney plus', 'disney+'],
      packageName: 'com.disney.disneyplus',
      displayName: 'Disney+',
    ),

    // Shopping
    AppEntry(
      keywords: ['amazon', 'amazon shopping'],
      packageName: 'com.amazon.mShop.android.shopping',
      displayName: 'Amazon',
    ),
    AppEntry(
      keywords: ['shopee'],
      packageName: 'com.shopee.ph',
      displayName: 'Shopee',
      altPackages: ['com.shopee.id', 'com.shopee.my', 'com.shopee.sg'],
    ),
    AppEntry(
      keywords: ['lazada'],
      packageName: 'com.lazada.android',
      displayName: 'Lazada',
    ),
    AppEntry(
      keywords: ['ebay'],
      packageName: 'com.ebay.mobile',
      displayName: 'eBay',
    ),

    // Navigation & Travel
    AppEntry(
      keywords: ['google maps', 'maps', 'map', 'navigate'],
      packageName: 'com.google.android.apps.maps',
      displayName: 'Google Maps',
    ),
    AppEntry(
      keywords: ['waze'],
      packageName: 'com.waze',
      displayName: 'Waze',
    ),
    AppEntry(
      keywords: ['grab'],
      packageName: 'com.grabtaxi.passenger',
      displayName: 'Grab',
    ),
    AppEntry(
      keywords: ['uber'],
      packageName: 'com.ubercab',
      displayName: 'Uber',
      altPackages: ['com.ubercab.eats'],
    ),

    // Productivity & Tools
    AppEntry(
      keywords: ['gmail', 'mail', 'email', 'google mail'],
      packageName: 'com.google.android.gm',
      displayName: 'Gmail',
    ),
    AppEntry(
      keywords: ['google drive', 'drive', 'gdrive'],
      packageName: 'com.google.android.apps.docs',
      displayName: 'Google Drive',
    ),
    AppEntry(
      keywords: ['google docs', 'docs', 'document'],
      packageName: 'com.google.android.apps.docs.editors.docs',
      displayName: 'Google Docs',
    ),
    AppEntry(
      keywords: ['google sheets', 'sheets', 'spreadsheet', 'excel'],
      packageName: 'com.google.android.apps.docs.editors.sheets',
      displayName: 'Google Sheets',
    ),
    AppEntry(
      keywords: ['google slides', 'slides', 'presentation', 'powerpoint'],
      packageName: 'com.google.android.apps.docs.editors.slides',
      displayName: 'Google Slides',
    ),
    AppEntry(
      keywords: ['calendar', 'google calendar'],
      packageName: 'com.google.android.calendar',
      displayName: 'Google Calendar',
    ),
    AppEntry(
      keywords: ['notes', 'google keep', 'keep'],
      packageName: 'com.google.android.keep',
      displayName: 'Google Keep',
    ),
    AppEntry(
      keywords: ['camera', 'photo', 'take photo'],
      packageName: 'com.google.android.GoogleCamera',
      displayName: 'Camera',
      altPackages: [
        'com.sec.android.app.camera',
        'com.motorola.camera3',
        'com.oneplus.camera',
        'com.google.android.GoogleCameraEng',
      ],
    ),
    AppEntry(
      keywords: ['gallery', 'photos', 'google photos', 'pictures'],
      packageName: 'com.google.android.apps.photos',
      displayName: 'Google Photos',
    ),
    AppEntry(
      keywords: ['files', 'file manager', 'file explorer'],
      packageName: 'com.google.android.apps.nbu.files',
      displayName: 'Files by Google',
      altPackages: [
        'com.mi.android.globalFileexplorer',
        'com.sec.android.app.myfiles',
      ],
    ),
    AppEntry(
      keywords: ['calculator', 'calc'],
      packageName: 'com.google.android.calculator',
      displayName: 'Calculator',
      altPackages: [
        'com.miui.calculator',
        'com.sec.android.app.popupcalculator',
      ],
    ),
    AppEntry(
      keywords: ['clock', 'alarm', 'timer', 'stopwatch'],
      packageName: 'com.google.android.deskclock',
      displayName: 'Clock',
      altPackages: [
        'com.sec.android.app.clockpackage',
        'com.oneplus.deskclock',
      ],
    ),
    AppEntry(
      keywords: ['settings', 'phone settings'],
      packageName: 'com.android.settings',
      displayName: 'Settings',
    ),
    AppEntry(
      keywords: ['phone', 'dialer', 'call'],
      packageName: 'com.google.android.dialer',
      displayName: 'Phone',
      altPackages: [
        'com.android.dialer',
        'com.sec.android.app.dialertab',
        'com.oneplus.dialer',
      ],
    ),
    AppEntry(
      keywords: ['messages', 'sms', 'text', 'messaging'],
      packageName: 'com.google.android.apps.messaging',
      displayName: 'Messages',
      altPackages: [
        'com.android.mms',
        'com.sec.android.app.messaging',
      ],
    ),
    AppEntry(
      keywords: ['contacts', 'phonebook'],
      packageName: 'com.google.android.contacts',
      displayName: 'Contacts',
      altPackages: [
        'com.android.contacts',
        'com.sec.android.app.contacts',
      ],
    ),

    // Browsers
    AppEntry(
      keywords: ['chrome', 'google chrome', 'browser', 'web'],
      packageName: 'com.android.chrome',
      displayName: 'Chrome',
    ),
    AppEntry(
      keywords: ['firefox'],
      packageName: 'org.mozilla.firefox',
      displayName: 'Firefox',
    ),
    AppEntry(
      keywords: ['samsung internet', 'samsung browser'],
      packageName: 'com.sec.android.app.sbrowser',
      displayName: 'Samsung Internet',
    ),

    // Education
    AppEntry(
      keywords: ['google classroom', 'classroom'],
      packageName: 'com.google.android.apps.classroom',
      displayName: 'Google Classroom',
    ),
    AppEntry(
      keywords: ['duolingo', 'duo'],
      packageName: 'com.duolingo',
      displayName: 'Duolingo',
    ),
    AppEntry(
      keywords: ['khan academy', 'khan'],
      packageName: 'org.khanacademy.android',
      displayName: 'Khan Academy',
    ),
    AppEntry(
      keywords: ['coursera'],
      packageName: 'org.coursera.android',
      displayName: 'Coursera',
    ),
    AppEntry(
      keywords: ['zoom', 'zoom meeting', 'zoom meeting'],
      packageName: 'us.zoom.videomeetings',
      displayName: 'Zoom',
    ),
    AppEntry(
      keywords: ['google meet', 'meet', 'hangouts'],
      packageName: 'com.google.android.apps.meetings',
      displayName: 'Google Meet',
    ),

    // Finance
    AppEntry(
      keywords: ['gcash', 'g cash'],
      packageName: 'com.globe.gcash.android',
      displayName: 'GCash',
    ),
    AppEntry(
      keywords: ['paymaya', 'maya'],
      packageName: 'com.paymaya',
      displayName: 'Maya',
    ),
    AppEntry(
      keywords: ['paypal'],
      packageName: 'com.paypal.android.p2pmobile',
      displayName: 'PayPal',
    ),
    AppEntry(
      keywords: ['bank', 'banking', 'bdo', 'bpi', 'metrobank'],
      packageName: 'com.android.chrome',
      displayName: 'Browser (for banking)',
    ),

    // Entertainment & Music
    AppEntry(
      keywords: ['shazam'],
      packageName: 'com.shazam.android',
      displayName: 'Shazam',
    ),
    AppEntry(
      keywords: ['soundcloud'],
      packageName: 'com.soundcloud.android',
      displayName: 'SoundCloud',
    ),
    AppEntry(
      keywords: ['deezer'],
      packageName: 'deezer.android.app',
      displayName: 'Deezer',
    ),
    AppEntry(
      keywords: ['kindle'],
      packageName: 'com.amazon.kindle',
      displayName: 'Kindle',
    ),
    AppEntry(
      keywords: ['goodreads'],
      packageName: 'com.goodreads',
      displayName: 'Goodreads',
    ),

    // Health & Fitness
    AppEntry(
      keywords: ['google fit', 'fit', 'fitness'],
      packageName: 'com.google.android.apps.fitness',
      displayName: 'Google Fit',
    ),
    AppEntry(
      keywords: ['samsung health'],
      packageName: 'com.sec.android.app.shealth',
      displayName: 'Samsung Health',
    ),
    AppEntry(
      keywords: ['myfitnesspal'],
      packageName: 'com.myfitnesspal.android',
      displayName: 'MyFitnessPal',
    ),

    // Gaming
    AppEntry(
      keywords: ['roblox'],
      packageName: 'com.roblox.client',
      displayName: 'Roblox',
    ),
    AppEntry(
      keywords: ['minecraft'],
      packageName: 'com.mojang.minecraftpe',
      displayName: 'Minecraft',
    ),
    AppEntry(
      keywords: ['genshin', 'genshin impact'],
      packageName: 'com.miHoYo.GenshinImpact',
      displayName: 'Genshin Impact',
    ),
    AppEntry(
      keywords: ['mobile legends', 'ml', 'mlbb'],
      packageName: 'com.mobile.legends',
      displayName: 'Mobile Legends',
    ),

    // AI & Tools
    AppEntry(
      keywords: ['ambot', 'this app', 'ambot ai'],
      packageName: 'com.ambot.ambot_ai',
      displayName: 'Ambot AI',
    ),
    AppEntry(
      keywords: ['chatgpt', 'openai', 'gpt'],
      packageName: 'com.openai.chatgpt',
      displayName: 'ChatGPT',
    ),
    AppEntry(
      keywords: ['google assistant', 'assistant'],
      packageName: 'com.google.android.googlequicksearchbox',
      displayName: 'Google Assistant',
    ),
  ];

  /// Find the best matching app entry for a given query text.
  /// Returns null if no match is found.
  static AppEntry? findMatch(String query) {
    final lowerQuery = query.toLowerCase().trim();

    // Exact keyword match (highest priority)
    for (final entry in entries) {
      for (final keyword in entry.keywords) {
        if (lowerQuery == keyword.toLowerCase()) {
          return entry;
        }
      }
    }

    // Contains keyword match
    for (final entry in entries) {
      for (final keyword in entry.keywords) {
        if (lowerQuery.contains(keyword.toLowerCase())) {
          return entry;
        }
      }
    }

    // Fuzzy: check if any keyword is contained in the query
    final queryWords = lowerQuery.split(RegExp(r'\s+'));
    for (final entry in entries) {
      for (final keyword in entry.keywords) {
        final keywordWords = keyword.toLowerCase().split(RegExp(r'\s+'));
        var matchCount = 0;
        for (final kw in keywordWords) {
          if (queryWords.any((qw) => qw.contains(kw) || kw.contains(qw))) {
            matchCount++;
          }
        }
        if (matchCount >= keywordWords.length * 0.7) {
          return entry;
        }
      }
    }

    return null;
  }

  /// Extract app launch intent from a command string.
  /// Returns the package name if found, null otherwise.
  static String? extractPackageName(String command) {
    final entry = findMatch(command);
    return entry?.packageName;
  }

  /// Get all available app names for suggestions.
  static List<String> getAllAppNames() {
    return entries.map((e) => e.displayName).toList();
  }

  /// Get all keywords for indexing.
  static List<String> getAllKeywords() {
    return entries.expand((e) => e.keywords).toList();
  }
}

class AppEntry {
  final List<String> keywords;
  final String packageName;
  final String displayName;
  final List<String> altPackages;
  final String? searchQuery;

  const AppEntry({
    required this.keywords,
    required this.packageName,
    required this.displayName,
    this.altPackages = const [],
    this.searchQuery,
  });

  /// Get all package names to try (primary + alternates).
  List<String> get allPackages => [packageName, ...altPackages];
}
