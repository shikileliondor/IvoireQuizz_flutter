import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_api.dart';
import '../models/user_stats.dart';

final profileStatsProvider = FutureProvider<UserStats>((ref) {
  return ref.watch(profileApiProvider).getStats();
});
