import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';
import 'monitor.dart';

/// Live telemetry + profiles. Polls every second, keeps 60-sample history.
class SystemStore extends ChangeNotifier {
  static const _profilesKey = 'forgecontrol.profiles.v1';
  static const _activeKey = 'forgecontrol.active.v1';

  SysSample? sample;
  final List<double> cpuHistory = [];
  final List<ForgeProfile> profiles = [];
  String activeProfile = 'Default';
  String mode = 'balanced';
  List<int> fanCurve = [25, 40, 60, 80, 100];
  int rgbColor = 0xFF22D3EE;
  String rgbEffect = 'breathing';
  double brightness = 0.8;
  String schemeNote = '';
  bool loaded = false;

  // Expose sensor data from sample.
  double get cpuTemp => sample?.cpuTemp ?? 0;
  double get gpuUsage => sample?.gpuUsage ?? 0;
  double get gpuTemp => sample?.gpuTemp ?? 0;
  double get fanRpm => sample?.fanRpm ?? 0;
  String get gpuName => sample?.gpuName ?? '';
  Timer? _timer;

  ForgeProfile get current => ForgeProfile(
        name: activeProfile,
        mode: mode,
        fanCurve: List.of(fanCurve),
        rgbColor: rgbColor,
        rgbEffect: rgbEffect,
        brightness: brightness,
      );

  Future<void> init() async {
    await _loadProfiles();
    sample = await SystemMonitor.read(null);
    schemeNote = await SystemMonitor.currentScheme();
    loaded = true;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      sample = await SystemMonitor.read(sample);
      cpuHistory.add(sample!.cpu);
      if (cpuHistory.length > 60) cpuHistory.removeAt(0);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> setMode(String m) async {
    mode = m;
    schemeNote = await SystemMonitor.applyPowerMode(m);
    notifyListeners();
    await _saveProfiles();
  }

  void setFan(int i, int v) {
    fanCurve[i] = v.clamp(0, 100);
    notifyListeners();
  }

  void setRgb({int? color, String? effect, double? bright}) {
    if (color != null) rgbColor = color;
    if (effect != null) rgbEffect = effect;
    if (bright != null) bright.clamp(0.0, 1.0);
    if (bright != null) brightness = bright;
    notifyListeners();
  }

  Future<void> saveProfile(String name) async {
    profiles.removeWhere((p) => p.name == name);
    profiles.add(current..name = name);
    activeProfile = name;
    notifyListeners();
    await _saveProfiles();
  }

  Future<void> applyProfile(ForgeProfile p) async {
    activeProfile = p.name;
    mode = p.mode;
    fanCurve = List.of(p.fanCurve);
    rgbColor = p.rgbColor;
    rgbEffect = p.rgbEffect;
    brightness = p.brightness;
    schemeNote = await SystemMonitor.applyPowerMode(mode);
    notifyListeners();
    await _saveProfiles();
  }

  Future<void> deleteProfile(String name) async {
    profiles.removeWhere((p) => p.name == name);
    if (activeProfile == name) activeProfile = 'Default';
    notifyListeners();
    await _saveProfiles();
  }

  Future<void> _loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profilesKey);
    profiles.clear();
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        profiles.addAll(
            list.map((e) => ForgeProfile.fromJson(e as Map<String, dynamic>)));
      } catch (_) {}
    }
    if (profiles.isEmpty) {
      profiles.addAll([
        ForgeProfile(name: 'Silent Night', mode: 'silent',
            fanCurve: [20, 30, 45, 65, 85], rgbColor: 0xFF334155,
            rgbEffect: 'static', brightness: 0.4),
        ForgeProfile(name: 'Balanced', mode: 'balanced'),
        ForgeProfile(name: 'Full Forge', mode: 'performance',
            fanCurve: [40, 55, 75, 90, 100], rgbColor: 0xFFF472B6,
            rgbEffect: 'wave', brightness: 1.0),
      ]);
    }
    activeProfile = prefs.getString(_activeKey) ?? profiles.first.name;
    final active = profiles.where((p) => p.name == activeProfile);
    if (active.isNotEmpty) {
      final p = active.first;
      mode = p.mode;
      fanCurve = List.of(p.fanCurve);
      rgbColor = p.rgbColor;
      rgbEffect = p.rgbEffect;
      brightness = p.brightness;
    }
  }

  Future<void> _saveProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profilesKey,
        jsonEncode(profiles.map((p) => p.toJson()).toList()));
    await prefs.setString(_activeKey, activeProfile);
  }
}
