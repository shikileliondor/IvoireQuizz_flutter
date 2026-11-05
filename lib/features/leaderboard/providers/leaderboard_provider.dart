import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/leaderboard_api.dart';
import '../models/league.dart';

final leaderboardProvider = FutureProvider<League>((ref) {
  return ref.watch(leaderboardApiProvider).getRanking();
});
