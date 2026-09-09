import 'dart:convert';

/// A saved Forge Control profile: power mode + fan curve + RGB look.
class ForgeProfile {
  String name;
  String mode; // silent | balanced | performance
  List<int> fanCurve; // 5 fan-% steps for 40/55/70/85/100 C targets
  int rgbColor; // ARGB
  String rgbEffect; // static | breathing | cycle | wave
  double brightness;

  ForgeProfile({
    required this.name,
    this.mode = 'balanced',
    List<int>? fanCurve,
    this.rgbColor = 0xFF22D3EE,
    this.rgbEffect = 'breathing',
    this.brightness = 0.8,
  }) : fanCurve = fanCurve ?? [25, 40, 60, 80, 100];

  Map<String, dynamic> toJson() => {
        'name': name,
        'mode': mode,
        'fanCurve': fanCurve,
        'rgbColor': rgbColor,
        'rgbEffect': rgbEffect,
        'brightness': brightness,
      };

  factory ForgeProfile.fromJson(Map<String, dynamic> j) => ForgeProfile(
        name: j['name'] as String? ?? 'Profile',
        mode: j['mode'] as String? ?? 'balanced',
        fanCurve: (j['fanCurve'] as List?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            [25, 40, 60, 80, 100],
        rgbColor: (j['rgbColor'] as num?)?.toInt() ?? 0xFF22D3EE,
        rgbEffect: j['rgbEffect'] as String? ?? 'breathing',
        brightness: (j['brightness'] as num?)?.toDouble() ?? 0.8,
      );

  String encode() => jsonEncode(toJson());
}
