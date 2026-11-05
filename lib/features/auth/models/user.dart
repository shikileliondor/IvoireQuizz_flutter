class User {
  final int id;
  final String name;
  final String email;
  final int xpTotal;
  final int coins;
  final int gems;
  final int totalScore;
  final int gamesPlayed;
  final String? friendCode;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.xpTotal = 0,
    this.coins = 0,
    this.gems = 0,
    this.totalScore = 0,
    this.gamesPlayed = 0,
    this.friendCode,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      xpTotal: (json['xp_total'] as num?)?.toInt() ?? 0,
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      gems: (json['gems'] as num?)?.toInt() ?? 0,
      totalScore: (json['total_score'] as num?)?.toInt() ?? 0,
      gamesPlayed: (json['games_played'] as num?)?.toInt() ?? 0,
      friendCode: json['friend_code']?.toString(),
    );
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final n = parts[0];
    return n.substring(0, n.length >= 2 ? 2 : 1).toUpperCase();
  }

  String get firstName => name.trim().split(RegExp(r'\s+')).first;
}
