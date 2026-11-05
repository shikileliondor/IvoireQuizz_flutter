import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import '../models/lives.dart';

class LivesApi {
  const LivesApi(this._client);
  final ApiClient _client;

  Future<Lives> getLives() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/lives',
      parser: (raw) => raw as Map<String, dynamic>,
    );
    final api = ApiResponse.fromJson(res, (d) => d as Map<String, dynamic>);
    return Lives.fromJson(api.data!);
  }
}

final livesApiProvider = Provider<LivesApi>(
  (ref) => LivesApi(ref.watch(apiClientProvider)),
);
