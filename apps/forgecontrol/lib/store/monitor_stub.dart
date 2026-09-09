import 'dart:math';

/// One system sample. `demo=true` on web / unsupported platforms.
class SysSample {
  final double cpu; // 0..100
  final double ramUsedGB;
  final double ramTotalGB;
  final int uptimeMin;
  final bool demo;
  const SysSample({
    required this.cpu,
    required this.ramUsedGB,
    required this.ramTotalGB,
    required this.uptimeMin,
    this.demo = false,
  });

  double get ramPct =>
      ramTotalGB <= 0 ? 0 : (ramUsedGB / ramTotalGB * 100).clamp(0, 100);
}

/// Demo monitor for web: plausible sine-wave telemetry.
class SystemMonitor {
  static final _t0 = DateTime.now();
  static Future<SysSample> read(SysSample? prev) async {
    final t = DateTime.now().difference(_t0).inSeconds.toDouble();
    final rnd = Random();
    final cpu = (32 + 22 * sin(t / 7) + 10 * sin(t / 2.3) + rnd.nextDouble() * 4)
        .clamp(4, 98)
        .toDouble();
    const total = 16.0;
    final used = (9.2 + 1.4 * sin(t / 23) + rnd.nextDouble() * 0.3)
        .clamp(4, total - 0.5)
        .toDouble();
    return SysSample(
      cpu: cpu,
      ramUsedGB: used,
      ramTotalGB: total,
      uptimeMin: DateTime.now().difference(_t0).inMinutes,
      demo: true,
    );
  }

  static Future<String> applyPowerMode(String mode) async =>
      'Demo data on web — power plans switch for real in the Windows build.';

  static Future<String> currentScheme() async => 'Demo scheme';
}
