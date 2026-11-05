import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../game_map/providers/game_map_provider.dart';
import '../data/quiz_api.dart';
import '../models/quiz_models.dart';

enum QuizStatus {
  idle,
  loading,
  active,
  submittingAnswer,
  finishing,
  finished,
  error
}

class QuizState {
  final QuizStatus status;
  final QuizSession? session;
  final List<QuizQuestion> questions;
  final int currentIndex;
  final AnswerResult? lastResult;
  final bool answered;
  final int timeLeft;
  final Map<String, dynamic> finalResult;
  final String? errorMessage;

  const QuizState({
    this.status = QuizStatus.idle,
    this.session,
    this.questions = const [],
    this.currentIndex = 0,
    this.lastResult,
    this.answered = false,
    this.timeLeft = 20,
    this.finalResult = const {},
    this.errorMessage,
  });

  QuizQuestion? get currentQuestion =>
      questions.isNotEmpty && currentIndex < questions.length
          ? questions[currentIndex]
          : null;

  bool get isLastQuestion => currentIndex >= questions.length - 1;

  QuizState copyWith({
    QuizStatus? status,
    QuizSession? session,
    List<QuizQuestion>? questions,
    int? currentIndex,
    AnswerResult? lastResult,
    bool? answered,
    int? timeLeft,
    Map<String, dynamic>? finalResult,
    String? errorMessage,
  }) {
    return QuizState(
      status: status ?? this.status,
      session: session ?? this.session,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      lastResult: lastResult ?? this.lastResult,
      answered: answered ?? this.answered,
      timeLeft: timeLeft ?? this.timeLeft,
      finalResult: finalResult ?? this.finalResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class QuizNotifier extends Notifier<QuizState> {
  Timer? _timer;

  @override
  QuizState build() {
    ref.onDispose(() => _timer?.cancel());
    return const QuizState();
  }

  Future<void> startSession(int levelId) async {
    state = state.copyWith(status: QuizStatus.loading);
    try {
      final result = await ref.read(quizApiProvider).startSession(levelId);
      state = state.copyWith(
        status: QuizStatus.active,
        session: result.session,
        questions: result.questions,
        currentIndex: 0,
        answered: false,
        timeLeft:
            result.questions.isNotEmpty ? result.questions.first.timeLimit : 20,
      );
      _startTimer();
    } catch (e) {
      state = state.copyWith(
        status: QuizStatus.error,
        errorMessage: e is ApiException
            ? e.userMessage
            : 'Impossible de charger les questions.',
      );
    }
  }

  Future<void> submitAnswer(int? answerId) async {
    if (state.answered ||
        state.session == null ||
        state.currentQuestion == null) {
      return;
    }
    _stopTimer();

    final responseTime = (state.currentQuestion!.timeLimit) - state.timeLeft;
    state = state.copyWith(
      status: QuizStatus.submittingAnswer,
      answered: true,
    );

    try {
      final result = await ref.read(quizApiProvider).submitAnswer(
            sessionId: state.session!.id,
            questionId: state.currentQuestion!.id,
            answerId: answerId,
            responseTime: responseTime,
          );
      state = state.copyWith(
        status: QuizStatus.active,
        lastResult: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: QuizStatus.error,
        errorMessage: e is ApiException
            ? e.userMessage
            : 'Impossible d’enregistrer la réponse.',
      );
    }
  }

  Future<void> nextQuestion() async {
    if (state.isLastQuestion) {
      await _finishSession();
      return;
    }
    final next = state.currentIndex + 1;
    state = state.copyWith(
      currentIndex: next,
      answered: false,
      lastResult: null,
      timeLeft: state.questions[next].timeLimit,
      status: QuizStatus.active,
    );
    _startTimer();
  }

  Future<void> _finishSession() async {
    if (state.session == null) return;
    state = state.copyWith(status: QuizStatus.finishing);
    try {
      final result =
          await ref.read(quizApiProvider).finishSession(state.session!.id);
      ref.invalidate(gameMapProvider);
      state = state.copyWith(
        status: QuizStatus.finished,
        finalResult: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: QuizStatus.error,
        errorMessage: e is ApiException
            ? e.userMessage
            : 'Impossible de terminer la partie.',
      );
    }
  }

  Future<void> abandon() async {
    _stopTimer();
    if (state.session != null) {
      try {
        await ref.read(quizApiProvider).abandonSession(state.session!.id);
      } catch (_) {}
    }
    state = const QuizState();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.timeLeft <= 0) {
        _timer?.cancel();
        submitAnswer(null);
        return;
      }
      state = state.copyWith(timeLeft: state.timeLeft - 1);
    });
  }

  void _stopTimer() => _timer?.cancel();
}

final quizProvider =
    NotifierProvider<QuizNotifier, QuizState>(QuizNotifier.new);
