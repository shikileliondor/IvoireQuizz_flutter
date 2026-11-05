import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/streak_api.dart';
import '../models/streak.dart';

final streakProvider = FutureProvider<Streak>((ref) {
  return ref.watch(streakApiProvider).getStreak();
});
