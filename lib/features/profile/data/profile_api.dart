import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import '../models/user_stats.dart';

class ProfileApi {
  const ProfileApi(this._client);
  final ApiClient _client;

  Future<UserStats> getStats() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/profile/stats',
      parser: (raw) => raw as Map<String, dynamic>,
    );
    final api = ApiResponse.fromJson(res, (d) => d as Map<String, dynamic>);
    return UserStats.fromJson(api.data!);
  }
}

final profileApiProvider = Provider<ProfileApi>(
  (ref) => ProfileApi(ref.watch(apiClientProvider)),
);
