import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import '../models/game_map.dart';

class GameMapApi {
  const GameMapApi(this._client);
  final ApiClient _client;

  Future<GameMap> getMap() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/game/map',
      parser: (raw) => raw as Map<String, dynamic>,
    );
    final api = ApiResponse.fromJson(res, (d) => d as Map<String, dynamic>);
    final data = api.data ?? {};
    if (data['world'] != null ||
        data['current_world'] != null ||
        data['current_region'] != null) {
      return GameMap.fromJson(data);
    }
    final rawRegions = data['regions'];
    return rawRegions is List
        ? GameMap.fromLegacyRegions(rawRegions)
        : const GameMap.empty();
  }

  Future<void> markIntroSeen() async {
    await _client.post<Map<String, dynamic>>(
      '/me/intro-seen',
      parser: (raw) => raw as Map<String, dynamic>,
    );
  }

  Future<GameRegion> getRegion(int id) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/regions/$id',
      parser: (raw) => raw as Map<String, dynamic>,
    );
    final api = ApiResponse.fromJson(res, (d) => d as Map<String, dynamic>);
    return GameRegion.fromJson(api.data!);
  }

  Future<GameCity> getCity(int id) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/cities/$id',
      parser: (raw) => raw as Map<String, dynamic>,
    );
    final api = ApiResponse.fromJson(res, (d) => d as Map<String, dynamic>);
    return GameCity.fromJson(api.data!);
  }

  Future<GameLevel> getLevel(int id) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/levels/$id',
      parser: (raw) => raw as Map<String, dynamic>,
    );
    final api = ApiResponse.fromJson(res, (d) => d as Map<String, dynamic>);
    return GameLevel.fromJson(api.data!);
  }
}

final gameMapApiProvider = Provider<GameMapApi>(
  (ref) => GameMapApi(ref.watch(apiClientProvider)),
);
