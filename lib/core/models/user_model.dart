import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required int id,
    required String name,
    required String email,
    @JsonKey(name: 'friend_code') required String friendCode,
    @JsonKey(name: 'avatar_id') required int avatarId,
    @JsonKey(name: 'total_score') required int totalScore,
    @JsonKey(name: 'games_played') required int gamesPlayed,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}
