import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import '../models/league.dart';

class LeaderboardApi {
  const LeaderboardApi(this._client);
  final ApiClient _client;

  Future<League> getRanking() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/league/ranking',
      parser: (raw) => raw as Map<String, dynamic>,
    );
    final api = ApiResponse.fromJson(res, (d) => d as Map<String, dynamic>);
    return League.fromJson(api.data ?? {});
  }
}

final leaderboardApiProvider = Provider<LeaderboardApi>(
  (ref) => LeaderboardApi(ref.watch(apiClientProvider)),
);
