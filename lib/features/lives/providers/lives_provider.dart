import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/lives_api.dart';
import '../models/lives.dart';

final livesProvider = FutureProvider<Lives>((ref) {
  return ref.watch(livesApiProvider).getLives();
});
