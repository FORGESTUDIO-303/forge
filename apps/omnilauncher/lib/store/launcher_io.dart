import 'dart:io' show Process, ProcessStartMode;

/// Desktop launcher: starts the real executable, detached.
class Launcher {
  /// true = launched, false = failed, null = not supported here.
  static Future<bool?> launch(String execPath) async {
    if (execPath.isEmpty) return null;
    try {
      await Process.start(execPath, const [],
          runInShell: true, mode: ProcessStartMode.detached);
      return true;
    } catch (_) {
      return false;
    }
  }
}
