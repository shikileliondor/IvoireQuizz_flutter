class LeaguePlayer {
  final int rank;
  final String name;
  final int xp;
  final bool isCurrentUser;

  const LeaguePlayer({
    required this.rank,
    required this.name,
    required this.xp,
    this.isCurrentUser = false,
  });

  factory LeaguePlayer.fromJson(Map<String, dynamic> json) {
    return LeaguePlayer(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? json['user']?['name']?.toString() ?? 'Joueur',
      xp: (json['xp'] as num?)?.toInt() ??
          (json['season_xp'] as num?)?.toInt() ?? 0,
      isCurrentUser: json['is_current_user'] == true,
    );
  }
}

class League {
  final String name;
  final List<LeaguePlayer> ranking;

  const League({required this.name, required this.ranking});

  factory League.fromJson(Map<String, dynamic> json) {
    final rawRanking = json['ranking'] ?? json['players'];
    return League(
      name: json['league']?['name']?.toString() ??
          json['name']?.toString() ?? 'Classement',
      ranking: rawRanking is List
          ? rawRanking
              .whereType<Map<String, dynamic>>()
              .map(LeaguePlayer.fromJson)
              .toList()
          : const [],
    );
  }
}
