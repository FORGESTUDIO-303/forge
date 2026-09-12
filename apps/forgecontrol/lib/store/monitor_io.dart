import 'dart:ffi';
import 'dart:io' show Process;
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'monitor_stub.dart' show SysSample;
export 'monitor_stub.dart' show SysSample;

/// Real Windows telemetry via Win32 FFI + WMI + nvidia-smi.
class _CpuMeter {
  int _prevIdle = 0, _prevKernel = 0, _prevUser = 0;
  bool _first = true;

  double sample() {
    final idle = calloc<FILETIME>();
    final kernel = calloc<FILETIME>();
    final user = calloc<FILETIME>();
    try {
      if (GetSystemTimes(idle, kernel, user) == 0) return 0;
      int comb(Pointer<FILETIME> p) =>
          (p.ref.dwHighDateTime << 32) | p.ref.dwLowDateTime;
      final i = comb(idle), k = comb(kernel), u = comb(user);
      if (_first) {
        _first = false;
      } else {
        final sys = (k - _prevKernel) + (u - _prevUser);
        final pct = sys > 0 ? (1 - (i - _prevIdle) / sys) * 100 : 0;
        _prevIdle = i;
        _prevKernel = k;
        _prevUser = u;
        return pct.clamp(0, 100).toDouble();
      }
      _prevIdle = i;
      _prevKernel = k;
      _prevUser = u;
      return 0;
    } finally {
      calloc.free(idle);
      calloc.free(kernel);
      calloc.free(user);
    }
  }
}

class SystemMonitor {
  static final _cpu = _CpuMeter();
  static final _started = DateTime.now();
  static String? _gpuNameCache;

  static Future<SysSample> read(SysSample? prev) async {
    final cpu = _cpu.sample();
    final mem = calloc<MEMORYSTATUSEX>();
    double total = 0, avail = 0;
    try {
      mem.ref.dwLength = sizeOf<MEMORYSTATUSEX>();
      if (GlobalMemoryStatusEx(mem) != 0) {
        total = mem.ref.ullTotalPhys / 1073741824;
        avail = mem.ref.ullAvailPhys / 1073741824;
      }
    } finally {
      calloc.free(mem);
    }

    // Parallel hardware reads (fire-and-forget, best effort).
    final gpuFuture = _readGpu();
    final cpuTempFuture = _readCpuTemp();
    final fanFuture = _readFanRpm();

    final gpuData = await gpuFuture;
    final cpuTemp = await cpuTempFuture;
    final fanRpm = await fanFuture;

    return SysSample(
      cpu: cpu,
      ramUsedGB: (total - avail).clamp(0, total).toDouble(),
      ramTotalGB: total.toDouble(),
      uptimeMin: DateTime.now().difference(_started).inMinutes,
      cpuTemp: cpuTemp,
      gpuUsage: gpuData.usage,
      gpuTemp: gpuData.temp,
      fanRpm: fanRpm,
      gpuName: _gpuNameCache ?? '',
    );
  }

  /// Read GPU via nvidia-smi (NVIDIA only, best effort).
  static Future<({double usage, double temp})> _readGpu() async {
    try {
      final r = await Process.run('nvidia-smi', [
        '--query-gpu=utilization.gpu,temperature.gpu,name',
        '--format=csv,noheader,nounits',
      ]);
      if (r.exitCode != 0) return (usage: 0.0, temp: 0.0);
      final line = (r.stdout as String).trim();
      if (line.isEmpty) return (usage: 0.0, temp: 0.0);
      final parts = line.split(',').map((s) => s.trim()).toList();
      if (parts.length < 3) return (usage: 0.0, temp: 0.0);
      _gpuNameCache ??= parts[2];
      final usage = double.tryParse(parts[0]) ?? 0.0;
      final temp = double.tryParse(parts[1]) ?? 0.0;
      return (usage: usage, temp: temp);
    } catch (_) {
      return (usage: 0.0, temp: 0.0);
    }
  }

  /// Read CPU temp via WMI MSAcpi_ThermalZoneTemperature (tenths of Kelvin).
  static Future<double> _readCpuTemp() async {
    try {
      final r = await Process.run('powershell', [
        '-NoProfile', '-Command',
        '(Get-CimInstance MSAcpi_ThermalZoneTemperature -Namespace root/wmi '
        '| Select-Object -First 1).CurrentTemperature',
      ]);
      if (r.exitCode != 0) return 0;
      final raw = (r.stdout as String).trim();
      final kelvinTenths = int.tryParse(raw);
      if (kelvinTenths == null || kelvinTenths == 0) return 0;
      return ((kelvinTenths / 10) - 273.15).clamp(0, 150).toDouble();
    } catch (_) {
      return 0;
    }
  }

  /// Read CPU fan RPM via WMI (Win32_Fan or MSAcpi).
  static Future<double> _readFanRpm() async {
    try {
      final r = await Process.run('powershell', [
        '-NoProfile', '-Command',
        '(Get-CimInstance Win32_Fan -ErrorAction SilentlyContinue '
        '| Select-Object -First 1).DesiredSpeed',
      ]);
      if (r.exitCode != 0) return 0;
      final raw = (r.stdout as String).trim();
      return (double.tryParse(raw) ?? 0).clamp(0, 10000);
    } catch (_) {
      return 0;
    }
  }

  static const _schemes = {
    'silent': 'SCHEME_MIN',
    'balanced': 'SCHEME_BALANCED',
    'performance': 'SCHEME_MAX',
  };

  static Future<String> applyPowerMode(String mode) async {
    final alias = _schemes[mode] ?? 'SCHEME_BALANCED';
    try {
      final r = await Process.run('powercfg', ['/setactive', alias]);
      if (r.exitCode == 0) return 'Power plan → $mode';
      return 'powercfg failed: ${(r.stderr as Object).toString().trim()}';
    } catch (e) {
      return 'Could not switch plan: $e';
    }
  }

  static Future<String> currentScheme() async {
    try {
      final r = await Process.run('powercfg', ['/getactivescheme']);
      final line = (r.stdout as String).trim().split('\n').first.trim();
      return line.isEmpty ? 'Unknown scheme' : line;
    } catch (e) {
      return 'Unknown scheme';
    }
  }
}
