// ignore_for_file: use_colored_box

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PALETTE CENTRALISÉE
// ─────────────────────────────────────────────────────────────────────────────
abstract final class _C {
  /// Fond principal : blanc pur, aligné avec le blanc intégré à l'image.
  static const Color bg           = Color(0xFFFFFFFF);

  // Marque
  static const Color orange       = Color(0xFFF58220);
  static const Color orangeLight  = Color(0xFFFFA94D);
  static const Color green        = Color(0xFF168A49);

  // Typographie
  static const Color textDark     = Color(0xFF2B1A12);
  static const Color textSoft     = Color(0xFF5F5148);

  // UI discrète
  static const Color progressTrack = Color(0xFFEDE5D8);
  static const Color dotBorder     = Color(0xFFD9CEBA);
}

// ─────────────────────────────────────────────────────────────────────────────
//  SPLASH SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class IvoireQuizSplashScreen extends StatefulWidget {
  const IvoireQuizSplashScreen({
    this.autoNavigate = false,
    this.onAnimationComplete,
    super.key,
  });

  /// Mettre à `true` pour que le widget appelle [onAnimationComplete]
  /// à la fin de l'animation et navigate vers l'écran suivant.
  final bool autoNavigate;
  final VoidCallback? onAnimationComplete;

  @override
  State<IvoireQuizSplashScreen> createState() => _IvoireQuizSplashScreenState();
}

class _IvoireQuizSplashScreenState extends State<IvoireQuizSplashScreen>
    with TickerProviderStateMixin {
  // ── Durées ─────────────────────────────────────────────────────────────────
  static const Duration _entryDur   = Duration(milliseconds: 2850);
  static const Duration _ambientDur = Duration(milliseconds: 4400);

  // ── Controllers ────────────────────────────────────────────────────────────
  late final AnimationController _entry;
  late final AnimationController _ambient; // boucle infinie (effets vivants)

  // ── Animations d'entrée ────────────────────────────────────────────────────
  late final Animation<double> _bgOpacity;
  late final Animation<double> _mascotOpacity;
  late final Animation<double> _mascotScale;
  late final Animation<Offset> _mascotSlide;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _sloganOpacity;
  late final Animation<Offset> _sloganSlide;
  late final Animation<double> _loaderOpacity;
  late final Animation<double> _progress;
  late final Animation<double> _dotsOpacity;

  // ── init ───────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _entry   = AnimationController(vsync: this, duration: _entryDur);
    _ambient = AnimationController(vsync: this, duration: _ambientDur)
      ..repeat(reverse: true);

    // Helper local
    Animation<double> c(double t0, double t1, Curve curve) => CurvedAnimation(
          parent: _entry,
          curve: Interval(t0, t1, curve: curve),
        );

    _bgOpacity     = c(0.00, 0.22, Curves.easeOutCubic);
    _mascotOpacity = c(0.08, 0.38, Curves.easeOut);
    _mascotScale   = c(0.08, 0.44, Curves.easeOutBack)
        .drive(Tween(begin: 0.90, end: 1.0));
    _mascotSlide   = c(0.08, 0.44, Curves.easeOutCubic)
        .drive(Tween(begin: const Offset(0, 0.12), end: Offset.zero));
    _titleOpacity  = c(0.32, 0.54, Curves.easeOut);
    _titleSlide    = c(0.32, 0.58, Curves.easeOutCubic)
        .drive(Tween(begin: const Offset(0, 0.18), end: Offset.zero));
    _sloganOpacity = c(0.48, 0.70, Curves.easeOut);
    _sloganSlide   = c(0.48, 0.74, Curves.easeOutCubic)
        .drive(Tween(begin: const Offset(0, 0.12), end: Offset.zero));
    _loaderOpacity = c(0.64, 0.80, Curves.easeOut);
    _progress      = c(0.66, 0.98, Curves.easeInOutCubic);
    _dotsOpacity   = c(0.78, 1.00, Curves.easeOut);

    _entry.forward().whenComplete(() {
      if (!mounted || !widget.autoNavigate) return;
      widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    _ambient.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size    = MediaQuery.sizeOf(context);
    final compact = size.height < 720;
    final hPad    = size.width < 360 ? 20.0 : 28.0;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_entry, _ambient]),
          builder: (context, _) {
            return Stack(
              children: [
                // Fond décoratif (motifs, silhouettes)
                Opacity(
                  opacity: _bgOpacity.value,
                  child: const _DecorBackground(),
                ),

                // Vagues du bas inspirées du drapeau ivoirien
                _BottomWaves(ambient: _ambient.value),

                // Contenu principal
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Column(
                    children: [
                      SizedBox(height: compact ? 20 : 36),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: _MainContent(
                              compact:        compact,
                              mascotOpacity:  _mascotOpacity.value,
                              mascotScale:    _mascotScale.value,
                              mascotSlide:    _mascotSlide.value,
                              titleOpacity:   _titleOpacity.value,
                              titleSlide:     _titleSlide.value,
                              sloganOpacity:  _sloganOpacity.value,
                              sloganSlide:    _sloganSlide.value,
                              ambient:        _ambient.value,
                            ),
                          ),
                        ),
                      ),

                      // Barre de chargement + points
                      Opacity(
                        opacity: _loaderOpacity.value,
                        child: _ProgressSection(
                          progress:    _progress.value,
                          dotsOpacity: _dotsOpacity.value,
                          ambient:     _ambient.value,
                        ),
                      ),
                      SizedBox(height: compact ? 90 : 114),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONTENU CENTRAL
// ─────────────────────────────────────────────────────────────────────────────
class _MainContent extends StatelessWidget {
  const _MainContent({
    required this.compact,
    required this.mascotOpacity,
    required this.mascotScale,
    required this.mascotSlide,
    required this.titleOpacity,
    required this.titleSlide,
    required this.sloganOpacity,
    required this.sloganSlide,
    required this.ambient,
  });

  final bool    compact;
  final double  mascotOpacity;
  final double  mascotScale;
  final Offset  mascotSlide;
  final double  titleOpacity;
  final Offset  titleSlide;
  final double  sloganOpacity;
  final Offset  sloganSlide;
  final double  ambient;

  @override
  Widget build(BuildContext context) {
    final mascotSz = compact ? 180.0 : 218.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Zone mascotte avec micro ornements ─────────────────────────────
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(left:  28, top:    18, child: _Ornament.dot(color: _C.orange, size: 7)),
            Positioned(right: 18, top:    36, child: _Ornament.star(color: _C.green)),
            Positioned(left:  14, bottom: 44, child: _Ornament.star(color: _C.green, size: 13)),
            Positioned(right: 38, bottom: 18, child: _Ornament.dot(color: _C.orange, size: 9)),

            SlideTransition(
              position: AlwaysStoppedAnimation(mascotSlide),
              child: Opacity(
                opacity: mascotOpacity,
                child: Transform.translate(
                  // Légère lévitation sinusoïdale calée sur le cycle ambiant
                  offset: Offset(0, -5 * math.sin(ambient * math.pi)),
                  child: Transform.scale(
                    scale: mascotScale,
                    child: _Mascot(size: mascotSz),
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: compact ? 20 : 30),

        // ── Titre ──────────────────────────────────────────────────────────
        SlideTransition(
          position: AlwaysStoppedAnimation(titleSlide),
          child: Opacity(opacity: titleOpacity, child: const _BrandTitle()),
        ),

        SizedBox(height: compact ? 12 : 16),

        // ── Slogan ─────────────────────────────────────────────────────────
        SlideTransition(
          position: AlwaysStoppedAnimation(sloganSlide),
          child: Opacity(opacity: sloganOpacity, child: const _Slogan()),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MASCOTTE
//  ─ Le ColoredBox parent a EXACTEMENT le même blanc pur que le Scaffold
//    → l'image (fond blanc intégré) se fond naturellement dans la page.
//  ─ Aucune carte, aucune ombre forte, aucun cadre visible.
// ─────────────────────────────────────────────────────────────────────────────
class _Mascot extends StatelessWidget {
  const _Mascot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _C.bg, // blanc pur identique au fond du Scaffold → fondu parfait
      child: SizedBox(
        width:  size,
        height: size,
        child: Image.asset(
          'assets/avecfodn.jpeg',  // ← asset existant dans le projet
          width:  size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, _, __) => _MascotFallback(size: size),
        ),
      ),
    );
  }
}

/// Placeholder affiché si l'asset est manquant (ex : tests unitaires).
class _MascotFallback extends StatelessWidget {
  const _MascotFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  size * 0.88,
      height: size * 0.88,
      decoration: BoxDecoration(
        color:  _C.bg,
        shape:  BoxShape.circle,
        border: Border.all(color: _C.orange.withOpacity(0.18)),
      ),
      child: Icon(Icons.cruelty_free_rounded, color: _C.orange, size: size * 0.44),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TITRE  "IvoireQuiz"
// ─────────────────────────────────────────────────────────────────────────────
class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.nunito(
      fontSize:      44,
      height:        1,
      fontWeight:    FontWeight.w900,
      letterSpacing: -1.6,
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment:    Alignment.bottomRight,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(children: [
            TextSpan(text: 'Ivoire', style: base.copyWith(color: _C.orange)),
            TextSpan(text: 'Quiz',   style: base.copyWith(color: _C.green)),
          ]),
        ),
        // Petit trait soulignement sous "Quiz" — discret et élégant
        Positioned(
          right:  2,
          bottom: -8,
          child: Container(
            width:  50,
            height: 4,
            decoration: BoxDecoration(
              color:        _C.orange.withOpacity(0.28),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SLOGAN
// ─────────────────────────────────────────────────────────────────────────────
class _Slogan extends StatelessWidget {
  const _Slogan();

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.nunito(
      color:         _C.textSoft,
      fontSize:      19,
      height:        1.38,
      fontWeight:    FontWeight.w600,
      letterSpacing: -0.1,
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: [
        TextSpan(text: 'Connais-tu vraiment\n', style: base),
        TextSpan(text: 'la ',                   style: base),
        TextSpan(
          text:  'Côte\u202fd\u2019Ivoire',     // espace fine + apostrophe typographique
          style: base.copyWith(
            color:      _C.orange,
            fontWeight: FontWeight.w900,
          ),
        ),
        TextSpan(text: '\u202f?', style: base), // espace fine avant ?
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SECTION CHARGEMENT  (barre arrondie + 3 points)
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.progress,
    required this.dotsOpacity,
    required this.ambient,
  });

  final double progress;
  final double dotsOpacity;
  final double ambient;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Barre
        Container(
          width:   164,
          height:  8,
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color:        _C.progressTrack,
            borderRadius: BorderRadius.circular(999),
            border:       Border.all(color: Colors.white.withOpacity(0.70)),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_C.orangeLight, _C.orange],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color:      _C.orange.withOpacity(0.28),
                      blurRadius: 6,
                      offset:     const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        // 3 points paginés avec pulsation douce
        Opacity(
          opacity: dotsOpacity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Dot(
                color: _C.orange,
                scale: 1 + 0.08 * math.sin(ambient * math.pi),
              ),
              const SizedBox(width: 9),
              const _Dot(color: Colors.white, borderColor: _C.dotBorder, scale: 1.0),
              const SizedBox(width: 9),
              _Dot(
                color: _C.green,
                scale: 1 + 0.08 * math.cos(ambient * math.pi),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.scale, this.borderColor});

  final Color  color;
  final Color? borderColor;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width:  9,
        height: 9,
        decoration: BoxDecoration(
          color:  color,
          shape:  BoxShape.circle,
          border: borderColor != null ? Border.all(color: borderColor!) : null,
          boxShadow: [
            BoxShadow(
              color:      color.withOpacity(color == Colors.white ? 0.08 : 0.22),
              blurRadius: 10,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FOND DÉCORATIF  (motifs géométriques + silhouettes icônes, très atténués)
// ─────────────────────────────────────────────────────────────────────────────
class _DecorBackground extends StatelessWidget {
  const _DecorBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -28, right: -26,
          child: Opacity(opacity: 0.11,
            child: _CornerPattern(color: _C.green,  rotate: -0.15)),
        ),
        Positioned(
          left: -38, bottom: 110,
          child: Opacity(opacity: 0.10,
            child: _CornerPattern(color: _C.orange, rotate:  0.22)),
        ),
        const Positioned(top:  80, left:  28, child: _Ghost(icon: Icons.terrain_rounded,     size: 62)),
        const Positioned(top: 136, right: 22, child: _Ghost(icon: Icons.park_rounded,         size: 56)),
        const Positioned(left: 32, bottom: 250, child: _Ghost(icon: Icons.water_rounded,       size: 70)),
        const Positioned(right: 30, bottom: 220, child: _Ghost(icon: Icons.location_on_rounded, size: 58)),
      ],
    );
  }
}

class _Ghost extends StatelessWidget {
  const _Ghost({required this.icon, required this.size});

  final IconData icon;
  final double   size;

  @override
  Widget build(BuildContext context) =>
      Icon(icon, size: size, color: _C.textDark.withOpacity(0.028));
}

class _CornerPattern extends StatelessWidget {
  const _CornerPattern({required this.color, required this.rotate});

  final Color  color;
  final double rotate;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotate,
      child: CustomPaint(
        size: const Size(150, 150),
        painter: _CornerPainter(color: color),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap   = StrokeCap.round
      ..color       = color.withOpacity(0.26);

    for (var i = 0; i < 6; i++) {
      final inset = 12.0 + i * 17;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(inset, inset, size.width - inset, size.height - inset),
          const Radius.circular(26),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  VAGUES DU BAS  (orange gauche / vert droite, animées)
// ─────────────────────────────────────────────────────────────────────────────
class _BottomWaves extends StatelessWidget {
  const _BottomWaves({required this.ambient});

  final double ambient;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Transform.translate(
          offset: Offset(0, 2.8 * math.sin(ambient * math.pi)),
          child: const CustomPaint(painter: _WavesPainter()),
        ),
      ),
    );
  }
}

class _WavesPainter extends CustomPainter {
  const _WavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height - math.min(124.0, size.height * 0.165);

    final orangePaint = Paint()..color = _C.orange.withOpacity(0.93)..style = PaintingStyle.fill;
    final greenPaint  = Paint()..color = _C.green.withOpacity(0.94)  ..style = PaintingStyle.fill;
    final veilPaint   = Paint()..color = Colors.white.withOpacity(0.11)..style = PaintingStyle.fill;

    // Vague orange (gauche)
    final orange = Path()
      ..moveTo(0, baseY + 16)
      ..cubicTo(size.width * 0.14, baseY - 20,
                size.width * 0.30, baseY + 16,
                size.width * 0.46, baseY - 8)
      ..cubicTo(size.width * 0.34, baseY + 62,
                size.width * 0.18, size.height + 10,
                0,                size.height)
      ..close();

    // Vague verte (droite)
    final green = Path()
      ..moveTo(size.width, baseY - 6)
      ..cubicTo(size.width * 0.82, baseY - 30,
                size.width * 0.66, baseY + 28,
                size.width * 0.52, baseY + 2)
      ..cubicTo(size.width * 0.64, baseY + 68,
                size.width * 0.82, size.height + 14,
                size.width,        size.height)
      ..close();

    // Voile blanc adoucissant la superposition orange/vert
    final veil = Path()
      ..moveTo(0, baseY + 44)
      ..cubicTo(size.width * 0.12, baseY + 16,
                size.width * 0.24, baseY + 44,
                size.width * 0.38, baseY + 22)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(orange, orangePaint);
    canvas.drawPath(green,  greenPaint);
    canvas.drawPath(veil,   veilPaint);
  }

  @override
  bool shouldRepaint(covariant _WavesPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  MICRO ORNEMENTS  (points • et étoiles ✦ autour de la mascotte)
// ─────────────────────────────────────────────────────────────────────────────
class _Ornament extends StatelessWidget {
  const _Ornament._({required this.color, required this.size, required this.isStar});

  factory _Ornament.dot({required Color color, required double size}) =>
      _Ornament._(color: color, size: size, isStar: false);

  factory _Ornament.star({required Color color, double size = 15}) =>
      _Ornament._(color: color, size: size, isStar: true);

  final Color  color;
  final double size;
  final bool   isStar;

  @override
  Widget build(BuildContext context) {
    if (isStar) {
      return Icon(Icons.auto_awesome_rounded, color: color.withOpacity(0.68), size: size);
    }
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(color: color.withOpacity(0.68), shape: BoxShape.circle),
    );
  }
}