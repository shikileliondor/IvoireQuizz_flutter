import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_map_api.dart';
import '../models/game_map.dart';

class GameMapNotifier extends AsyncNotifier<GameMap> {
  @override
  Future<GameMap> build() => ref.read(gameMapApiProvider).getMap();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(gameMapApiProvider).getMap(),
    );
  }

  Future<void> completeIntro() async {
    await ref.read(gameMapApiProvider).markIntroSeen();
    await refresh();
  }
}

final gameMapProvider =
    AsyncNotifierProvider<GameMapNotifier, GameMap>(GameMapNotifier.new);

final regionDetailProvider = FutureProvider.family<GameRegion, int>((ref, id) {
  return ref.read(gameMapApiProvider).getRegion(id);
});

final cityDetailProvider = FutureProvider.family<GameCity, int>((ref, id) {
  return ref.read(gameMapApiProvider).getCity(id);
});

final levelDetailProvider = FutureProvider.family<GameLevel, int>((ref, id) {
  return ref.read(gameMapApiProvider).getLevel(id);
});
