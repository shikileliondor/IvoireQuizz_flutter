import 'package:freezed_annotation/freezed_annotation.dart';

part 'question_model.freezed.dart';
part 'question_model.g.dart';

@freezed
class OptionModel with _$OptionModel {
  const factory OptionModel({
    required int id,
    @JsonKey(name: 'option_text') required String optionText,
  }) = _OptionModel;

  factory OptionModel.fromJson(Map<String, dynamic> json) =>
      _$OptionModelFromJson(json);
}

@freezed
class QuestionModel with _$QuestionModel {
  const factory QuestionModel({
    required int id,
    @JsonKey(name: 'category_id') required int categoryId,
    required String type,
    @JsonKey(name: 'question_text') required String questionText,
    required String explanation,
    required int difficulty,
    required List<OptionModel> options,
  }) = _QuestionModel;

  factory QuestionModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionModelFromJson(json);
}
