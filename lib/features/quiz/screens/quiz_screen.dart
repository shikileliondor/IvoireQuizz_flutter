import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _orange = Color(0xFFF77F00);
const _textDark = Color(0xFF1A1A2E);
const _textGray = Color(0xFF6B7280);
const _cardBg = Color(0xFFF8F9FA);
const _neutral = Color(0xFFE5E7EB);
const _correct = Color(0xFF22C55E);
const _incorrect = Color(0xFFEF4444);

class QuizScreen extends StatefulWidget {
  final String? categoryId;
  final String mode;

  const QuizScreen({
    super.key,
    this.categoryId,
    required this.mode,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  int? _selectedOptionId;
  bool _answered = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _timeLeft = 20;
  int _sessionStartTime = 0;
  Timer? _timer;
  List<Map<String, dynamic>> _answers = [];
  static const _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now().millisecondsSinceEpoch;
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final token = await _storage.read(key: 'auth_token');

      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://10.0.2.2:8000/api',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      String url = '/quiz/questions?mode=${widget.mode}';
      if (widget.categoryId != null) {
        url += '&category_id=${widget.categoryId}';
      }

      final response = await dio.get(url);

      if (response.data['success'] == true) {
        final list = response.data['data'] as List;
        setState(() {
          _questions = list.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
        _startTimer();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('ERREUR QUIZ: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 20;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeLeft <= 0) {
        timer.cancel();
        _onOptionSelected(null);
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _onOptionSelected(int? optionId) {
    if (_answered) return;
    _stopTimer();

    final responseTime = 20 - _timeLeft;
    final question = _questions[_currentIndex];

    setState(() {
      _selectedOptionId = optionId;
      _answered = true;
    });

    _answers.add({
      'question_id': question['id'],
      'selected_option_id': optionId,
      'response_time_seconds': responseTime,
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionId = null;
        _answered = false;
        _timeLeft = 20;
      });
      _startTimer();
    } else {
      _submitSession();
    }
  }

  Future<void> _submitSession() async {
    setState(() => _isSubmitting = true);

    try {
      final token = await _storage.read(key: 'auth_token');

      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://10.0.2.2:8000/api',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final durationSeconds =
          ((DateTime.now().millisecondsSinceEpoch - _sessionStartTime) / 1000)
              .round();

      final response = await dio.post(
        '/sessions',
        data: {
          'category_id':
              widget.categoryId != null ? int.parse(widget.categoryId!) : null,
          'mode': widget.mode,
          'duration_seconds': durationSeconds,
          'answers': _answers,
        },
      );

      if (response.data['success'] == true) {
        if (mounted) {
          context.go('/result', extra: response.data['data']);
        }
      } else {
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      debugPrint('ERREUR SUBMIT: $e');
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: _orange),
              const SizedBox(height: 16),
              Text(
                'Chargement des questions...',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: _textGray,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isSubmitting) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: _orange),
              const SizedBox(height: 16),
              Text(
                'Calcul de votre score...',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textGray,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.quiz_outlined, size: 64, color: _neutral),
              const SizedBox(height: 16),
              Text(
                'Aucune question disponible',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: _textGray,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Retour',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildQuestion()),
            _buildOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final progress = (_currentIndex + 1) / _questions.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: _textDark,
              ),
              Expanded(
                child: Text(
                  'Question ${_currentIndex + 1}/${_questions.length}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ),
              _buildTimer(),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: _neutral,
              valueColor: const AlwaysStoppedAnimation<Color>(_orange),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _buildTimer() {
    final danger = _timeLeft <= 5;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: danger ? _incorrect.withValues(alpha: 0.12) : _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: danger ? _incorrect.withValues(alpha: 0.25) : _neutral,
        ),
      ),
      child: Text(
        '${_timeLeft}s',
        style: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: danger ? _incorrect : _textDark,
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    final question = _questions[_currentIndex];
    final questionText = (question['question_text'] ?? question['question'] ?? '')
        .toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _neutral),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_alt_outlined, color: _orange, size: 30),
            const SizedBox(height: 16),
            Text(
              questionText,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _textDark,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildOptions() {
    final question = _questions[_currentIndex];
    final rawOptions = (question['options'] as List? ?? const <dynamic>[])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    int? correctId;
    for (final option in rawOptions) {
      if (option['is_correct'] == true || option['is_correct'] == 1) {
        correctId = option['id'] as int?;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: List.generate(rawOptions.length, (index) {
          final option = rawOptions[index];
          final id = option['id'] as int?;
          final isSelected = id == _selectedOptionId;
          final isCorrect = id != null && id == correctId;

          Color borderColor = _neutral;
          Color fillColor = Colors.white;
          Color textColor = _textDark;

          if (_answered) {
            if (isCorrect) {
              borderColor = _correct;
              fillColor = _correct.withValues(alpha: 0.08);
            } else if (isSelected) {
              borderColor = _incorrect;
              fillColor = _incorrect.withValues(alpha: 0.08);
            }
          } else if (isSelected) {
            borderColor = _orange;
            fillColor = _orange.withValues(alpha: 0.08);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: _answered ? null : () => _onOptionSelected(id),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        (option['option_text'] ?? option['text'] ?? '').toString(),
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (_answered && isCorrect)
                      const Icon(Icons.check_circle, color: _correct)
                    else if (_answered && isSelected && !isCorrect)
                      const Icon(Icons.cancel, color: _incorrect),
                  ],
                ),
              ),
            ),
          )
              .animate(delay: (70 * index).ms)
              .fadeIn(duration: 250.ms)
              .slideX(begin: 0.08, end: 0);
        }),
      ),
    );
  }
}
