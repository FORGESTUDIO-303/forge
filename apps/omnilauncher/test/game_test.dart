import 'package:flutter_test/flutter_test.dart';
import 'package:omnilauncher/models/game.dart';

void main() {
  test('Game JSON round-trips', () {
    final g = Game(
      id: '1',
      title: 'Neon Rogue',
      platform: 'PC',
      favorite: true,
      playtimeMinutes: 90,
    );
    final back = Game.fromJson(g.toJson());
    expect(back.title, 'Neon Rogue');
    expect(back.favorite, isTrue);
    expect(back.playtimeLabel, '1h 30m');
  });

  test('playtimeLabel formats minutes and hours', () {
    expect(Game(id: 'a', title: 'x', playtimeMinutes: 45).playtimeLabel, '45m');
    expect(Game(id: 'b', title: 'y', playtimeMinutes: 120).playtimeLabel, '2h');
  });
}
