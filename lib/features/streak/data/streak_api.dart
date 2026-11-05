import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import '../models/streak.dart';

class StreakApi {
  const StreakApi(this._client);
  final ApiClient _client;

  Future<Streak> getStreak() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/streak',
      parser: (raw) => raw as Map<String, dynamic>,
    );
    final api = ApiResponse.fromJson(res, (d) => d as Map<String, dynamic>);
    return Streak.fromJson(api.data!);
  }
}

final streakApiProvider = Provider<StreakApi>(
  (ref) => StreakApi(ref.watch(apiClientProvider)),
);
