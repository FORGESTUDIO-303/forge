import 'dart:math';

/// One system sample. `demo=true` on web / unsupported platforms.
class SysSample {
  final double cpu; // 0..100
  final double ramUsedGB;
  final double ramTotalGB;
  final int uptimeMin;
  final double cpuTemp; // °C, 0 = unavailable
  final double gpuUsage; // 0..100, 0 = unavailable
  final double gpuTemp; // °C, 0 = unavailable
  final double fanRpm; // RPM, 0 = unavailable
  final String gpuName; // e.g. "RTX 4070"
  final bool demo;
  const SysSample({
    required this.cpu,
    required this.ramUsedGB,
    required this.ramTotalGB,
    required this.uptimeMin,
    this.cpuTemp = 0,
    this.gpuUsage = 0,
    this.gpuTemp = 0,
    this.fanRpm = 0,
    this.gpuName = '',
    this.demo = false,
  });

  double get ramPct =>
      ramTotalGB <= 0 ? 0 : (ramUsedGB / ramTotalGB * 100).clamp(0, 100);

  SysSample copyWith({
    double? cpu,
    double? ramUsedGB,
    double? ramTotalGB,
    int? uptimeMin,
    double? cpuTemp,
    double? gpuUsage,
    double? gpuTemp,
    double? fanRpm,
    String? gpuName,
    bool? demo,
  }) =>
      SysSample(
        cpu: cpu ?? this.cpu,
        ramUsedGB: ramUsedGB ?? this.ramUsedGB,
        ramTotalGB: ramTotalGB ?? this.ramTotalGB,
        uptimeMin: uptimeMin ?? this.uptimeMin,
        cpuTemp: cpuTemp ?? this.cpuTemp,
        gpuUsage: gpuUsage ?? this.gpuUsage,
        gpuTemp: gpuTemp ?? this.gpuTemp,
        fanRpm: fanRpm ?? this.fanRpm,
        gpuName: gpuName ?? this.gpuName,
        demo: demo ?? this.demo,
      );
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
    final gpu = (45 + 30 * sin(t / 5) + rnd.nextDouble() * 8).clamp(5, 99).toDouble();
    final cpuT = (52 + 15 * sin(t / 9) + rnd.nextDouble() * 3).clamp(35, 95).toDouble();
    final gpuT = (58 + 18 * sin(t / 6) + rnd.nextDouble() * 4).clamp(38, 92).toDouble();
    final fan = (800 + 400 * sin(t / 8) + rnd.nextDouble() * 100).clamp(400, 2200).toDouble();
    return SysSample(
      cpu: cpu,
      ramUsedGB: used,
      ramTotalGB: total,
      uptimeMin: DateTime.now().difference(_t0).inMinutes,
      cpuTemp: cpuT,
      gpuUsage: gpu,
      gpuTemp: gpuT,
      fanRpm: fan,
      gpuName: 'Demo GPU',
      demo: true,
    );
  }

  static Future<String> applyPowerMode(String mode) async =>
      'Demo data on web — power plans switch for real in the Windows build.';

  static Future<String> currentScheme() async => 'Demo scheme';
}
