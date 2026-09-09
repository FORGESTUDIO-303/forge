/// Web / fallback launcher: real launching needs dart:io (desktop only).
class Launcher {
  /// true = launched, false = failed, null = not supported here.
  static Future<bool?> launch(String execPath) async => null;
}
