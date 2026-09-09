import 'package:flutter_test/flutter_test.dart';
import 'package:forge_control/models/profile.dart';

void main() {
  test('ForgeProfile JSON round-trips', () {
    final p = ForgeProfile(
      name: 'Full Forge',
      mode: 'performance',
      fanCurve: [40, 55, 75, 90, 100],
      rgbEffect: 'wave',
      brightness: 1.0,
    );
    final back = ForgeProfile.fromJson(p.toJson());
    expect(back.name, 'Full Forge');
    expect(back.mode, 'performance');
    expect(back.fanCurve, [40, 55, 75, 90, 100]);
    expect(back.brightness, 1.0);
  });

  test('ForgeProfile defaults are sane', () {
    final p = ForgeProfile(name: 'x');
    expect(p.fanCurve.length, 5);
    expect(p.mode, 'balanced');
  });
}
