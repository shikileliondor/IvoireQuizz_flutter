enum MapNodeType { level, review, chest, boss, unknown }

enum MapNodeState { completed, current, unlocked, locked, claimable, claimed }

class GameMap {
  final GameWorld world;
  final int progressPercent;
  final int completedLevels;
  final int totalLevels;
  final int? nextPlayableLevelId;
  final List<GameMapNode> nodes;
  final GameMapStats stats;
  final bool firstTimeIntro;

  const GameMap({
    required this.world,
    required this.progressPercent,
    required this.completedLevels,
    required this.totalLevels,
    required this.nodes,
    this.stats = const GameMapStats(),
    this.firstTimeIntro = false,
    this.nextPlayableLevelId,
  });

  GameMapNode? get nextPlayable {
    for (final node in nodes) {
      if (node.levelId == nextPlayableLevelId) return node;
    }
    for (final node in nodes) {
      if (node.state == MapNodeState.current) return node;
    }
    return null;
  }

  factory GameMap.fromJson(Map<String, dynamic> json) {
    final worldJson = _map(
      json['world'] ?? json['current_world'] ?? json['current_region'],
    );
    final rawNodes = json['nodes'] is List
        ? json['nodes'] as List
        : json['path_nodes'] is List
            ? json['path_nodes'] as List
            : const [];
    final progress = _map(json['progress']);
    final nextPlayable = _map(
      json['next_playable'] ?? json['next_playable_level'],
    );
    final nextPlayableLevelId = _nullableInt(
      json['next_playable_level_id'] ??
          nextPlayable['level_id'] ??
          nextPlayable['id'],
    );
    final nodes = rawNodes
        .whereType<Map>()
        .map((node) => GameMapNode.fromJson(
              Map<String, dynamic>.from(node),
              isCurrent: _nullableInt(node['id']) == nextPlayableLevelId,
            ))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return GameMap(
      world: GameWorld.fromJson(worldJson),
      progressPercent: _int(
        progress['percent'] ??
            json['progress_percent'] ??
            worldJson['progress_percent'],
      ),
      completedLevels: _int(progress['completed_levels']),
      totalLevels: _int(progress['total_levels']),
      nextPlayableLevelId: nextPlayableLevelId,
      stats: GameMapStats.fromJson(_map(json['stats'])),
      firstTimeIntro: json['first_time_intro'] == true,
      nodes: nodes,
    );
  }

  /// Temporary adapter for the old regions -> cities -> levels response.
  factory GameMap.fromLegacyRegions(List<dynamic> regions) {
    final maps = regions
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (maps.isEmpty) return const GameMap.empty();
    Map<String, dynamic> selected = maps.first;
    for (final region in maps) {
      if (region['is_completed'] != true) {
        selected = region;
        break;
      }
    }
    final nodes = <GameMapNode>[];
    final cities =
        selected['cities'] is List ? selected['cities'] as List : const [];
    var order = 0;
    var currentAssigned = false;
    for (final city in cities.whereType<Map>()) {
      final levels = city['levels'] is List ? city['levels'] as List : const [];
      for (final raw in levels.whereType<Map>()) {
        final level = Map<String, dynamic>.from(raw);
        final isCurrent = !currentAssigned &&
            level['is_unlocked'] == true &&
            level['is_completed'] != true;
        nodes.add(GameMapNode.fromJson(
          {
            ...level,
            'type': level['is_boss'] == true ? 'boss' : 'level',
            'order': order++
          },
          isCurrent: isCurrent,
        ));
        currentAssigned = currentAssigned || isCurrent;
      }
    }
    final completed =
        nodes.where((n) => n.state == MapNodeState.completed).length;
    final next = nodes.where((n) =>
        n.state == MapNodeState.current || n.state == MapNodeState.unlocked);
    return GameMap(
      world: GameWorld(
          id: _int(selected['id']),
          name: selected['name']?.toString() ?? 'Monde'),
      progressPercent:
          nodes.isEmpty ? 0 : ((completed / nodes.length) * 100).round(),
      completedLevels: completed,
      totalLevels: nodes.length,
      nextPlayableLevelId: next.isEmpty ? null : next.first.levelId,
      nodes: nodes,
      stats: const GameMapStats(),
    );
  }

  const GameMap.empty()
      : world = const GameWorld(id: 0, name: 'Bientôt disponible'),
        progressPercent = 0,
        completedLevels = 0,
        totalLevels = 0,
        nextPlayableLevelId = null,
        nodes = const [],
        stats = const GameMapStats(),
        firstTimeIntro = false;
}

class GameMapStats {
  final int? lives;
  final int? maxLives;
  final int? streak;
  final int? xpTotal;
  final int? coins;
  final int? gems;
  final String? league;

  const GameMapStats({
    this.lives,
    this.maxLives,
    this.streak,
    this.xpTotal,
    this.coins,
    this.gems,
    this.league,
  });

  factory GameMapStats.fromJson(Map<String, dynamic> json) => GameMapStats(
        lives: _nullableInt(json['lives']),
        maxLives: _nullableInt(json['max_lives']),
        streak: _nullableInt(json['streak']),
        xpTotal: _nullableInt(json['xp_total']),
        coins: _nullableInt(json['coins']),
        gems: _nullableInt(json['gems']),
        league: json['league']?.toString(),
      );
}

class GameWorld {
  final int id;
  final String name;
  final int number;
  final String? subtitle;
  final bool isCompleted;

  const GameWorld(
      {required this.id,
      required this.name,
      this.number = 1,
      this.subtitle,
      this.isCompleted = false});

  factory GameWorld.fromJson(Map<String, dynamic> json) => GameWorld(
        id: _int(json['id']),
        name: json['name']?.toString() ?? 'Monde',
        number: _int(json['number'] ?? json['order'], 1),
        subtitle: (json['subtitle'] ?? json['description'])?.toString(),
        isCompleted: json['is_completed'] == true,
      );
}

class GameMapNode {
  final String id;
  final MapNodeType type;
  final MapNodeState state;
  final int order;
  final int? levelId;
  final String title;
  final String? subtitle;
  final int stars;
  final int totalQuestions;
  final Map<String, dynamic> rewards;

  const GameMapNode(
      {required this.id,
      required this.type,
      required this.state,
      required this.order,
      required this.title,
      this.levelId,
      this.subtitle,
      this.stars = 0,
      this.totalQuestions = 10,
      this.rewards = const {}});

  bool get isPlayable =>
      levelId != null &&
      (state == MapNodeState.current || state == MapNodeState.unlocked);

  factory GameMapNode.fromJson(
    Map<String, dynamic> json, {
    bool isCurrent = false,
  }) {
    final rawType = (json['type'] ?? json['node_type'])?.toString();
    final type = switch (rawType) {
      'chest' => MapNodeType.chest,
      'boss' => MapNodeType.boss,
      'level' => json['is_boss'] == true ? MapNodeType.boss : MapNodeType.level,
      'review' => MapNodeType.review,
      _ => json['is_boss'] == true ? MapNodeType.boss : MapNodeType.unknown,
    };
    final explicitState = json['state']?.toString();
    final state = isCurrent
        ? MapNodeState.current
        : switch (explicitState) {
            'completed' => MapNodeState.completed,
            'current' => MapNodeState.current,
            'unlocked' => MapNodeState.unlocked,
            'claimable' => MapNodeState.claimable,
            'claimed' => MapNodeState.claimed,
            _ => json['is_opened'] == true
                ? MapNodeState.claimed
                : json['is_completed'] == true
                    ? MapNodeState.completed
                    : json['is_unlocked'] == true
                        ? MapNodeState.unlocked
                        : MapNodeState.locked,
          };
    final levelId = _nullableInt(json['level_id'] ??
        (type == MapNodeType.chest || type == MapNodeType.unknown
            ? null
            : json['id']));
    return GameMapNode(
      id: json['node_id']?.toString() ??
          '${type.name}-${json['id'] ?? json['order'] ?? 0}',
      type: type,
      state: state,
      order: _int(json['order']),
      levelId: levelId,
      title: json['title']?.toString() ??
          (type == MapNodeType.chest
              ? 'Coffre'
              : type == MapNodeType.boss
                  ? 'Boss'
                  : 'Niveau'),
      subtitle: (json['subtitle'] ?? json['chapter_name'])?.toString(),
      stars: _int(json['stars']),
      totalQuestions: _int(json['total_questions'], 10),
      rewards: {
        ..._map(json['rewards']),
        if (json['xp_reward'] != null) 'xp': _int(json['xp_reward']),
      },
    );
  }
}

// Legacy detail models kept until the old detail endpoints are retired.
class GameLevel {
  final int id;
  final String title;
  final bool isBoss;
  final bool isUnlocked;
  final bool isCompleted;
  final int stars;
  final int difficulty;
  final int totalQuestions;
  final int minScore;
  final Map<String, dynamic> rewards;
  const GameLevel(
      {required this.id,
      required this.title,
      this.isBoss = false,
      this.isUnlocked = false,
      this.isCompleted = false,
      this.stars = 0,
      this.difficulty = 1,
      this.totalQuestions = 10,
      this.minScore = 0,
      this.rewards = const {}});
  factory GameLevel.fromJson(Map<String, dynamic> j) => GameLevel(
      id: _int(j['id']),
      title: j['title']?.toString() ?? 'Niveau',
      isBoss: j['is_boss'] == true,
      isUnlocked: j['is_unlocked'] == true,
      isCompleted: j['is_completed'] == true,
      stars: _int(j['stars']),
      difficulty: _int(j['difficulty'], 1),
      totalQuestions: _int(j['total_questions'], 10),
      minScore: _int(j['min_score']),
      rewards: _map(j['rewards']));
}

class GameCity {
  final int id;
  final String name;
  final List<GameLevel> levels;
  const GameCity(
      {required this.id, required this.name, this.levels = const []});
  factory GameCity.fromJson(Map<String, dynamic> j) => GameCity(
      id: _int(j['id']),
      name: j['name']?.toString() ?? 'Ville',
      levels: (j['levels'] is List ? j['levels'] as List : const [])
          .whereType<Map>()
          .map((e) => GameLevel.fromJson(Map<String, dynamic>.from(e)))
          .toList());
}

class GameRegion {
  final int id;
  final String name;
  final List<GameCity> cities;
  final bool isCompleted;
  const GameRegion(
      {required this.id,
      required this.name,
      this.cities = const [],
      this.isCompleted = false});
  factory GameRegion.fromJson(Map<String, dynamic> j) => GameRegion(
      id: _int(j['id']),
      name: j['name']?.toString() ?? 'Région',
      isCompleted: j['is_completed'] == true,
      cities: (j['cities'] is List ? j['cities'] as List : const [])
          .whereType<Map>()
          .map((e) => GameCity.fromJson(Map<String, dynamic>.from(e)))
          .toList());
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
int _int(dynamic value, [int fallback = 0]) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? fallback;
int? _nullableInt(dynamic value) => value == null ? null : _int(value);
