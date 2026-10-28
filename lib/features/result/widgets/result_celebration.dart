import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/audio/app_audio_controller.dart';

const _orange = Color(0xFFF77F00);
const _green = Color(0xFF009E60);
const _gold = Color(0xFFFFC21A);
const _textDark = Color(0xFF1A1A2E);
const _textGray = Color(0xFF6B7280);
const _slate = Color(0xFF64748B);
const _neutral = Color(0xFFE5E7EB);
const _correct = Color(0xFF22C55E);
const _incorrect = Color(0xFFEF4444);

enum ResultOutcome {
  perfect,
  victory,
  average,
  defeat;

  static ResultOutcome fromScore(int correct, int total) {
    if (total <= 0) return ResultOutcome.defeat;
    if (correct >= total) return ResultOutcome.perfect;
    final ratio = correct / total;
    if (ratio >= 0.7) return ResultOutcome.victory;
    if (ratio >= 0.4) return ResultOutcome.average;
    return ResultOutcome.defeat;
  }

  bool get celebrates =>
      this == ResultOutcome.perfect || this == ResultOutcome.victory;

  String get title => switch (this) {
        ResultOutcome.perfect => 'PARFAIT !',
        ResultOutcome.victory => 'VICTOIRE !',
        ResultOutcome.average => 'PAS MAL !',
        ResultOutcome.defeat => 'DOMMAGE…',
      };

  String get message => switch (this) {
        ResultOutcome.perfect => 'Parfait ! Tu es un vrai Ivoirien !',
        ResultOutcome.victory => 'Très bien ! Tu connais bien ton pays !',
        ResultOutcome.average => 'Pas mal ! Continue à apprendre !',
        ResultOutcome.defeat => 'Courage ! Tu feras mieux la prochaine fois !',
      };

  String get mascotAsset => switch (this) {
        ResultOutcome.perfect ||
        ResultOutcome.victory =>
          'assets/mascot/effobi_victoire.png',
        ResultOutcome.average => 'assets/mascot/effobi_reflechit.png',
        ResultOutcome.defeat => 'assets/mascot/effobi_defaite.png',
      };
}

int resultStars(int correct, int total) {
  if (total <= 0) return 0;
  final ratio = correct / total;
  if (ratio >= 0.9) return 3;
  if (ratio >= 0.7) return 2;
  if (ratio >= 0.4) return 1;
  return 0;
}

extension _Motion on Widget {
  /// Applique les effets seulement si l'utilisateur n'a pas réduit les animations.
  Widget motion(bool still, Animate Function(Widget widget) effects) =>
      still ? this : effects(this);
}

/// En-tête de l'écran de résultat : mascotte, titre, étoiles et score animés
/// selon que la partie est une victoire ou une défaite.
class ResultCelebrationHeader extends StatefulWidget {
  const ResultCelebrationHeader({
    super.key,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.categoryName,
  });

  final int correctAnswers;
  final int totalQuestions;
  final String categoryName;

  @override
  State<ResultCelebrationHeader> createState() =>
      _ResultCelebrationHeaderState();
}

class _ResultCelebrationHeaderState extends State<ResultCelebrationHeader> {
  static const int _firstStarMs = 950;
  static const int _starStepMs = 260;

  late final ResultOutcome _outcome =
      ResultOutcome.fromScore(widget.correctAnswers, widget.totalQuestions);
  late final int _stars =
      resultStars(widget.correctAnswers, widget.totalQuestions);
  final List<Timer> _haptics = <Timer>[];

  @override
  void initState() {
    super.initState();
    unawaited(
      AppAudioController.instance.playEffect(
        GameSound.forResult(celebrates: _outcome.celebrates),
      ),
    );
    if (_outcome == ResultOutcome.defeat) {
      _haptic(620, HapticFeedback.heavyImpact);
    } else {
      _haptic(350, HapticFeedback.mediumImpact);
    }
    for (var i = 0; i < _stars; i++) {
      _haptic(_firstStarMs + _starStepMs * i + 150, HapticFeedback.lightImpact);
    }
  }

  void _haptic(int delayMs, Future<void> Function() feedback) {
    _haptics.add(Timer(Duration(milliseconds: delayMs), () {
      if (mounted) feedback();
    }));
  }

  @override
  void dispose() {
    for (final timer in _haptics) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.of(context).disableAnimations;
    final bool defeat = _outcome == ResultOutcome.defeat;

    final Widget content = Column(
      children: [
        SizedBox(height: 200, child: _stage(still)),
        const SizedBox(height: 6),
        _title(still),
        const SizedBox(height: 10),
        _starsRow(still),
        const SizedBox(height: 10),
        _scoreLine(still),
        const SizedBox(height: 8),
        Text(
          _outcome.message,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ).motion(
            still,
            (w) => w
                .animate()
                .fadeIn(duration: 400.ms, delay: 1400.ms)
                .moveY(begin: 8, end: 0, duration: 400.ms, delay: 1400.ms)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: const BoxDecoration(
            color: _neutral,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Text(
            widget.categoryName,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _textGray,
            ),
          ),
        ).motion(
            still, (w) => w.animate().fadeIn(duration: 400.ms, delay: 1550.ms)),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: switch (_outcome) {
            ResultOutcome.perfect || ResultOutcome.victory => const [
                Color(0xFFFFE2B8),
                Color(0xFFFFF8F0)
              ],
            ResultOutcome.average => const [
                Color(0xFFFFF1E0),
                Color(0xFFFFF8F0)
              ],
            ResultOutcome.defeat => const [
                Color(0xFFE6EBF3),
                Color(0xFFF7F8FB)
              ],
          },
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      // Petite secousse d'« impact » quand la mascotte tombe après une défaite.
      child: content.motion(
          still || !defeat,
          (w) => w
              .animate()
              .shakeX(delay: 620.ms, duration: 420.ms, hz: 5, amount: 5)),
    );
  }

  Widget _stage(bool still) {
    final Widget image = Image.asset(
      _outcome.mascotAsset,
      height: 175,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) =>
          const Icon(Icons.pets, color: _orange, size: 64),
    );

    final Widget mascot = switch (_outcome) {
      ResultOutcome.perfect || ResultOutcome.victory => image
          // Saute de joie en boucle…
          .motion(
              still,
              (w) => w
                  .animate(
                      delay: 900.ms,
                      onPlay: (controller) => controller.repeat(reverse: true))
                  .moveY(
                      begin: 0,
                      end: -14,
                      duration: 420.ms,
                      curve: Curves.easeOut)
                  .scaleXY(
                      begin: 1,
                      end: 1.03,
                      duration: 420.ms,
                      alignment: Alignment.bottomCenter))
          // …après une entrée élastique.
          .motion(
              still,
              (w) => w
                  .animate()
                  .scale(
                      begin: Offset.zero,
                      end: const Offset(1, 1),
                      duration: 750.ms,
                      curve: Curves.elasticOut)
                  .rotate(
                      begin: -0.08,
                      end: 0,
                      duration: 750.ms,
                      curve: Curves.elasticOut)),
      ResultOutcome.average => image
          .motion(
              still,
              (w) => w
                  .animate(
                      delay: 700.ms,
                      onPlay: (controller) => controller.repeat(reverse: true))
                  .rotate(
                      begin: -0.015,
                      end: 0.015,
                      duration: 1400.ms,
                      curve: Curves.easeInOut,
                      alignment: Alignment.bottomCenter))
          .motion(
              still,
              (w) => w.animate().fadeIn(duration: 300.ms).scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.easeOutBack)),
      ResultOutcome.defeat => image
          // Respire doucement, tête basse…
          .motion(
              still,
              (w) => w
                  .animate(
                      delay: 1500.ms,
                      onPlay: (controller) => controller.repeat(reverse: true))
                  .moveY(
                      begin: 0,
                      end: 5,
                      duration: 1600.ms,
                      curve: Curves.easeInOut))
          // …après être tombée du haut de l'écran et avoir secoué la tête.
          .motion(
              still,
              (w) => w
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .moveY(
                      begin: -240,
                      end: 0,
                      duration: 650.ms,
                      curve: Curves.bounceOut)
                  .then(delay: 120.ms)
                  .shake(hz: 3, rotation: 0.08, duration: 650.ms)),
    };

    final Color glow = switch (_outcome) {
      ResultOutcome.perfect || ResultOutcome.victory => const Color(0x99FFD54F),
      ResultOutcome.average => const Color(0x66FFD9A8),
      ResultOutcome.defeat => const Color(0x5594A3B8),
    };

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (_outcome.celebrates)
          _SunburstRays(spin: !still).motion(
              still,
              (w) => w
                  .animate()
                  .fadeIn(delay: 250.ms, duration: 500.ms)
                  .scaleXY(
                      begin: 0.4, end: 1, delay: 250.ms, duration: 700.ms)),
        Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [glow, glow.withAlpha(0)]),
          ),
        ).motion(
            still,
            (w) => w
                .animate(
                    onPlay: (controller) => controller.repeat(reverse: true))
                .scaleXY(
                    begin: 0.9,
                    end: 1.08,
                    duration: 1200.ms,
                    curve: Curves.easeInOut)),
        mascot,
      ],
    );
  }

  Widget _title(bool still) {
    final Text title = Text(
      _outcome.title,
      style: GoogleFonts.nunito(
        fontSize: 30,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.4,
        color: _outcome == ResultOutcome.defeat ? _slate : _orange,
      ),
    );

    return switch (_outcome) {
      ResultOutcome.perfect || ResultOutcome.victory => title
          .motion(
              still,
              (w) => w
                  .animate(
                      delay: 1600.ms,
                      onPlay: (controller) => controller.repeat())
                  .shimmer(
                      duration: 3000.ms,
                      curve: const Interval(0, 0.45, curve: Curves.easeInOut),
                      color: const Color(0xFFFFF3B0)))
          .motion(
              still,
              (w) => w.animate().fadeIn(delay: 450.ms, duration: 200.ms).scale(
                  begin: const Offset(0.2, 0.2),
                  end: const Offset(1, 1),
                  delay: 450.ms,
                  duration: 650.ms,
                  curve: Curves.elasticOut)),
      ResultOutcome.average => title.motion(
          still,
          (w) => w
              .animate()
              .fadeIn(delay: 450.ms, duration: 300.ms)
              .moveY(begin: 12, end: 0, delay: 450.ms, duration: 400.ms)),
      ResultOutcome.defeat => title.motion(
          still,
          (w) => w
              .animate()
              .fadeIn(delay: 700.ms, duration: 300.ms)
              .moveY(begin: -12, end: 0, delay: 700.ms, duration: 400.ms)
              .then()
              .shake(hz: 2, rotation: 0.04, duration: 500.ms)),
    };
  }

  Widget _starsRow(bool still) {
    final bool defeat = _outcome == ResultOutcome.defeat;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final bool earned = i < _stars;
        final bool middle = i == 1;
        final Widget star = Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 4, middle ? 10 : 0),
          child: Icon(
            Icons.star_rounded,
            size: middle ? 54 : 42,
            color: earned ? _gold : const Color(0xFFD9DEE7),
            shadows: earned
                ? const [Shadow(color: Color(0x88F77F00), blurRadius: 14)]
                : null,
          ),
        );
        final int startMs = _firstStarMs + _starStepMs * i;

        if (earned) {
          return star.motion(
              still,
              (w) => w
                  .animate()
                  .scale(
                      begin: Offset.zero,
                      end: const Offset(1, 1),
                      delay: startMs.ms,
                      duration: 650.ms,
                      curve: Curves.elasticOut)
                  .rotate(
                      begin: -0.25,
                      end: 0,
                      delay: startMs.ms,
                      duration: 650.ms,
                      curve: Curves.easeOutBack));
        }
        return star.motion(still, (w) {
          final Animate faded =
              w.animate().fadeIn(delay: 800.ms, duration: 300.ms);
          return defeat
              ? faded
                  .then(delay: 150.ms)
                  .shake(hz: 4, rotation: 0.12, duration: 450.ms)
              : faded;
        });
      }),
    );
  }

  Widget _scoreLine(bool still) {
    final TextStyle scoreStyle = GoogleFonts.nunito(
      fontSize: 64,
      fontWeight: FontWeight.w800,
      color: switch (_outcome) {
        ResultOutcome.perfect || ResultOutcome.victory => _correct,
        ResultOutcome.average => _orange,
        ResultOutcome.defeat => _incorrect,
      },
      height: 1,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('${widget.correctAnswers}', style: scoreStyle).motion(
            still,
            (w) => w.animate().custom(
                  delay: 400.ms,
                  duration: 900.ms,
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Text(
                    '${(widget.correctAnswers * value).round()}',
                    style: scoreStyle,
                  ),
                )),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '/${widget.totalQuestions}',
            style: GoogleFonts.nunito(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _textGray,
              height: 1,
            ),
          ),
        ),
      ],
    ).motion(
        still,
        (w) => w
            .animate()
            .fadeIn(duration: 400.ms, delay: 300.ms)
            .slideY(begin: 0.3, end: 0, duration: 400.ms, delay: 300.ms));
  }
}

class _SunburstRays extends StatefulWidget {
  const _SunburstRays({required this.spin});

  final bool spin;

  @override
  State<_SunburstRays> createState() => _SunburstRaysState();
}

class _SunburstRaysState extends State<_SunburstRays>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void initState() {
    super.initState();
    if (widget.spin) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: RotationTransition(
        turns: _controller,
        child: const CustomPaint(painter: _RaysPainter()),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  const _RaysPainter();

  static const int _rays = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final Rect circle =
        Rect.fromCircle(center: center, radius: size.shortestSide / 2);
    final Paint paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xAAFFC21A), Color(0x00FFC21A)],
      ).createShader(circle);
    const double sweep = 2 * math.pi / _rays;
    for (var i = 0; i < _rays; i++) {
      final Path ray = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(circle, i * sweep, sweep / 2, false)
        ..close();
      canvas.drawPath(ray, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter oldDelegate) => false;
}

/// Pluie de confettis aux couleurs de la Côte d'Ivoire, tirée depuis les deux
/// côtés de l'écran. À placer dans un `Positioned.fill` au-dessus du contenu.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.pieces = 90});

  final int pieces;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..forward();
  late final List<_Confetto> _confetti =
      _Confetto.burst(widget.pieces, math.Random());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_confetti, _controller),
        ),
      ),
    );
  }
}

class _Confetto {
  const _Confetto({
    required this.fromLeft,
    required this.vx,
    required this.vy,
    required this.color,
    required this.width,
    required this.height,
    required this.round,
    required this.rotation,
    required this.spin,
    required this.flip,
    required this.phase,
    required this.sway,
  });

  static const List<Color> _palette = [
    _orange,
    _green,
    _gold,
    Color(0xFFFFB347),
    Color(0xFF3DD68C),
  ];

  final bool fromLeft;
  final double vx;
  final double vy;
  final Color color;
  final double width;
  final double height;
  final bool round;
  final double rotation;
  final double spin;
  final double flip;
  final double phase;
  final double sway;

  static List<_Confetto> burst(int count, math.Random random) {
    return List.generate(count, (i) {
      final bool fromLeft = i.isEven;
      // Vers le haut et vers l'intérieur de l'écran.
      final double tilt = 0.2 + random.nextDouble() * 0.6;
      final double angle = -math.pi / 2 + (fromLeft ? tilt : -tilt);
      final double speed = 850 + random.nextDouble() * 900;
      final bool round = random.nextDouble() < 0.25;
      final double size = 6 + random.nextDouble() * 5;
      return _Confetto(
        fromLeft: fromLeft,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        color: _palette[random.nextInt(_palette.length)],
        width: size,
        height: round ? size : size * 1.7,
        round: round,
        rotation: random.nextDouble() * math.pi * 2,
        spin: (random.nextDouble() - 0.5) * 12,
        flip: 4 + random.nextDouble() * 8,
        phase: random.nextDouble() * math.pi * 2,
        sway: 10 + random.nextDouble() * 18,
      );
    });
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.confetti, this.progress) : super(repaint: progress);

  final List<_Confetto> confetti;
  final Animation<double> progress;

  // Freinage de l'air et gravité : éclat rapide puis chute lente (~190 px/s).
  static const double _drag = 2.8;
  static const double _gravity = 520;
  static const double _seconds = 4.2;

  @override
  void paint(Canvas canvas, Size size) {
    final double t = progress.value * _seconds;
    final double fade = progress.value < 0.75 ? 1 : (1 - progress.value) / 0.25;
    if (fade <= 0) return;

    final double decay = (1 - math.exp(-_drag * t)) / _drag;
    final double fall = _gravity / _drag * (t - decay);
    final Paint paint = Paint();

    for (final c in confetti) {
      final double x0 = c.fromLeft ? 0 : size.width;
      final double y0 = size.height * 0.42;
      final double x = x0 +
          c.vx * decay +
          math.sin(c.phase + t * 5) * c.sway * math.min(1.0, t);
      final double y = y0 + c.vy * decay + fall;
      if (y > size.height + 20) continue;

      paint.color = c.color.withAlpha((255 * fade).round());
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(c.rotation + c.spin * t)
        ..scale(1, math.cos(c.phase + c.flip * t));
      if (c.round) {
        canvas.drawCircle(Offset.zero, c.width / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: c.width, height: c.height),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.confetti != confetti;
}
