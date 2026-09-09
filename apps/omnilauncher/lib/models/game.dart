import 'dart:convert';

/// A game entry in the OmniLauncher library. Fully offline model.
class Game {
  final String id;
  String title;
  String platform;
  String category;
  bool favorite;
  int playtimeMinutes;
  DateTime? lastPlayed;
  String execPath;
  int colorSeed;

  Game({
    required this.id,
    required this.title,
    this.platform = 'PC',
    this.category = 'Other',
    this.favorite = false,
    this.playtimeMinutes = 0,
    this.lastPlayed,
    this.execPath = '',
    this.colorSeed = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'platform': platform,
        'category': category,
        'favorite': favorite,
        'playtimeMinutes': playtimeMinutes,
        'lastPlayed': lastPlayed?.toIso8601String(),
        'execPath': execPath,
        'colorSeed': colorSeed,
      };

  factory Game.fromJson(Map<String, dynamic> j) => Game(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Untitled',
        platform: j['platform'] as String? ?? 'PC',
        category: j['category'] as String? ?? 'Other',
        favorite: j['favorite'] as bool? ?? false,
        playtimeMinutes: (j['playtimeMinutes'] as num?)?.toInt() ?? 0,
        lastPlayed: j['lastPlayed'] == null
            ? null
            : DateTime.tryParse(j['lastPlayed'] as String),
        execPath: j['execPath'] as String? ?? '',
        colorSeed: (j['colorSeed'] as num?)?.toInt() ?? 0,
      );

  static List<Game> sample() {
    final now = DateTime.now();
    var i = 0;
    Game mk(String t, String p, String c, int mins, int daysAgo, bool fav) =>
        Game(
          id: 'sample-${i++}',
          title: t,
          platform: p,
          category: c,
          playtimeMinutes: mins,
          lastPlayed: now.subtract(Duration(days: daysAgo)),
          favorite: fav,
          colorSeed: i * 47,
        );
    return [
      mk('Neon Rogue', 'PC', 'Roguelike', 128 * 60, 0, true),
      mk('Card Battler Legends', 'PC', 'Card Game', 42 * 60, 2, true),
      mk('Idle Empire Tycoon', 'Mobile', 'Idle', 300 * 60, 5, false),
      mk('Rhythm Combat', 'PC', 'Action', 18 * 60, 1, false),
    ];
  }

  String get playtimeLabel {
    final h = playtimeMinutes ~/ 60;
    final m = playtimeMinutes % 60;
    if (h == 0) return '${m}m';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  String encode() => jsonEncode(toJson());
}
