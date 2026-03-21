import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_model.freezed.dart';
part 'session_model.g.dart';

@freezed
class SessionModel with _$SessionModel {
  const factory SessionModel({
    required int id,
    @JsonKey(name: 'user_id') required int userId,
    @JsonKey(name: 'category_id') int? categoryId,
    required String mode,
    required int score,
    @JsonKey(name: 'bonus_score') required int bonusScore,
    @JsonKey(name: 'total_score') required int totalScore,
    @JsonKey(name: 'correct_answers') required int correctAnswers,
    @JsonKey(name: 'duration_seconds') required int durationSeconds,
    @JsonKey(name: 'completed_at') String? completedAt,
  }) = _SessionModel;

  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      _$SessionModelFromJson(json);
}
