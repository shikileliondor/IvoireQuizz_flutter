import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IvoireQuizSplashScreen extends StatefulWidget {
  const IvoireQuizSplashScreen({
    this.autoNavigate = false,
    this.onAnimationComplete,
    super.key,
  });

  /// Active cette option pour déclencher [onAnimationComplete] à la fin de
  /// l'animation principale, par exemple pour naviguer vers l'écran suivant.
  final bool autoNavigate;
  final VoidCallback? onAnimationComplete;

  @override
  State<IvoireQuizSplashScreen> createState() => _IvoireQuizSplashScreenState();
}

class _IvoireQuizSplashScreenState extends State<IvoireQuizSplashScreen>
    with TickerProviderStateMixin {
  static const Duration _entryDuration = Duration(milliseconds: 2850);
  static const Duration _ambientDuration = Duration(milliseconds: 4200);

  late final AnimationController _entryController;
  late final AnimationController _ambientController;

  late final Animation<double> _backgroundOpacity;
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

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: _entryDuration,
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: _ambientDuration,
    )..repeat(reverse: true);

    _backgroundOpacity = _curved(0.00, 0.18, Curves.easeOutCubic);
    _mascotOpacity = _curved(0.10, 0.36, Curves.easeOut);
    _mascotScale = _curved(0.10, 0.42, Curves.easeOutBack)
        .drive(Tween<double>(begin: 0.92, end: 1));
    _mascotSlide = _curved(0.10, 0.42, Curves.easeOutCubic).drive(
      Tween<Offset>(begin: const Offset(0, 0.14), end: Offset.zero),
    );
    _titleOpacity = _curved(0.34, 0.54, Curves.easeOut);
    _titleSlide = _curved(0.34, 0.58, Curves.easeOutCubic).drive(
      Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero),
    );
    _sloganOpacity = _curved(0.50, 0.70, Curves.easeOut);
    _sloganSlide = _curved(0.50, 0.74, Curves.easeOutCubic).drive(
      Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero),
    );
    _loaderOpacity = _curved(0.66, 0.80, Curves.easeOut);
    _progress = _curved(0.68, 0.98, Curves.easeInOutCubic);
    _dotsOpacity = _curved(0.78, 1.00, Curves.easeOut);

    _entryController.forward().whenComplete(() {
      if (!mounted || !widget.autoNavigate) return;
      widget.onAnimationComplete?.call();
    });
  }

  Animation<double> _curved(double begin, double end, Curve curve) {
    return CurvedAnimation(
      parent: _entryController,
      curve: Interval(begin, end, curve: curve),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final bool compactHeight = screen.height < 720;

    return Scaffold(
      backgroundColor: _SplashColors.ivory,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_entryController, _ambientController]),
          builder: (BuildContext context, Widget? child) {
            return Stack(
              children: <Widget>[
                Opacity(
                  opacity: _backgroundOpacity.value,
                  child: const _DecorativeBackground(),
                ),
                _BottomWaves(ambientValue: _ambientController.value),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _SplashSpacing.horizontal(screen.width),
                  ),
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: compactHeight ? 20 : 36),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: _MainContent(
                              compactHeight: compactHeight,
                              mascotOpacity: _mascotOpacity.value,
                              mascotScale: _mascotScale.value,
                              mascotSlide: _mascotSlide.value,
                              titleOpacity: _titleOpacity.value,
                              titleSlide: _titleSlide.value,
                              sloganOpacity: _sloganOpacity.value,
                              sloganSlide: _sloganSlide.value,
                              ambientValue: _ambientController.value,
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: _loaderOpacity.value,
                        child: _SplashProgress(
                          progress: _progress.value,
                          dotsOpacity: _dotsOpacity.value,
                          ambientValue: _ambientController.value,
                        ),
                      ),
                      SizedBox(height: compactHeight ? 92 : 116),
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

class _MainContent extends StatelessWidget {
  const _MainContent({
    required this.compactHeight,
    required this.mascotOpacity,
    required this.mascotScale,
    required this.mascotSlide,
    required this.titleOpacity,
    required this.titleSlide,
    required this.sloganOpacity,
    required this.sloganSlide,
    required this.ambientValue,
  });

  final bool compactHeight;
  final double mascotOpacity;
  final double mascotScale;
  final Offset mascotSlide;
  final double titleOpacity;
  final Offset titleSlide;
  final double sloganOpacity;
  final Offset sloganSlide;
  final double ambientValue;

  @override
  Widget build(BuildContext context) {
    final double mascotSize = compactHeight ? 178 : 214;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            const Positioned(
              left: 34,
              top: 24,
              child: _MicroOrnament(color: _SplashColors.orange, size: 7),
            ),
            const Positioned(
              right: 24,
              top: 44,
              child: _MicroOrnament.star(color: _SplashColors.green),
            ),
            const Positioned(
              left: 18,
              bottom: 48,
              child: _MicroOrnament.star(color: _SplashColors.green, size: 13),
            ),
            const Positioned(
              right: 44,
              bottom: 24,
              child: _MicroOrnament(color: _SplashColors.orange, size: 9),
            ),
            SlideTransition(
              position: AlwaysStoppedAnimation<Offset>(mascotSlide),
              child: Opacity(
                opacity: mascotOpacity,
                child: Transform.translate(
                  offset: Offset(0, -5 * math.sin(ambientValue * math.pi)),
                  child: Transform.scale(
                    scale: mascotScale,
                    child: _Mascot(size: mascotSize),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: compactHeight ? 20 : 28),
        SlideTransition(
          position: AlwaysStoppedAnimation<Offset>(titleSlide),
          child: Opacity(
            opacity: titleOpacity,
            child: const _BrandTitle(),
          ),
        ),
        SizedBox(height: compactHeight ? 12 : 16),
        SlideTransition(
          position: AlwaysStoppedAnimation<Offset>(sloganSlide),
          child: Opacity(
            opacity: sloganOpacity,
            child: const _Slogan(),
          ),
        ),
      ],
    );
  }
}

class _Mascot extends StatelessWidget {
  const _Mascot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            bottom: 10,
            child: Container(
              width: size * 0.58,
              height: size * 0.10,
              decoration: BoxDecoration(
                color: _SplashColors.shadow.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: _SplashColors.shadow.withOpacity(0.10),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          Image.asset(
            'assets/avecfodn.jpeg',
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
              // Remplacer par assets/images/ivoire_quiz_elephant.png si la mascotte finale est ajoutée plus tard.
              return _MascotPlaceholder(size: size);
            },
          ),
        ],
      ),
    );
  }
}

class _MascotPlaceholder extends StatelessWidget {
  const _MascotPlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 0.86,
      height: size * 0.86,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        shape: BoxShape.circle,
        border: Border.all(color: _SplashColors.orange.withOpacity(0.16)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _SplashColors.orange.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Icon(
        Icons.cruelty_free_rounded,
        color: _SplashColors.orange,
        size: size * 0.42,
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = GoogleFonts.nunito(
      fontSize: 42,
      height: 1,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.4,
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: <Widget>[
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: 'Ivoire',
                style: baseStyle.copyWith(color: _SplashColors.orange),
              ),
              TextSpan(
                text: 'Quiz',
                style: baseStyle.copyWith(color: _SplashColors.green),
              ),
            ],
          ),
        ),
        Positioned(
          right: 1,
          bottom: -9,
          child: Container(
            width: 52,
            height: 5,
            decoration: BoxDecoration(
              color: _SplashColors.orange.withOpacity(0.28),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    );
  }
}

class _Slogan extends StatelessWidget {
  const _Slogan();

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = GoogleFonts.nunito(
      color: _SplashColors.textSoft,
      fontSize: 20,
      height: 1.34,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.1,
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: <InlineSpan>[
          TextSpan(text: 'Connais-tu vraiment\n', style: baseStyle),
          TextSpan(text: 'la ', style: baseStyle),
          TextSpan(
            text: 'Côte d’Ivoire',
            style: baseStyle.copyWith(
              color: _SplashColors.orange,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(text: ' ?', style: baseStyle),
        ],
      ),
    );
  }
}

class _SplashProgress extends StatelessWidget {
  const _SplashProgress({
    required this.progress,
    required this.dotsOpacity,
    required this.ambientValue,
  });

  final double progress;
  final double dotsOpacity;
  final double ambientValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 168,
          height: 8,
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: _SplashColors.progressTrack,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.68)),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[
                      _SplashColors.orangeLight,
                      _SplashColors.orange,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Opacity(
          opacity: dotsOpacity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _PageDot(
                color: _SplashColors.orange,
                scale: 1 + (0.08 * math.sin(ambientValue * math.pi)),
              ),
              const SizedBox(width: 9),
              const _PageDot(
                color: Colors.white,
                borderColor: _SplashColors.dotBorder,
                scale: 1,
              ),
              const SizedBox(width: 9),
              _PageDot(
                color: _SplashColors.green,
                scale: 1 + (0.06 * math.cos(ambientValue * math.pi)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({
    required this.color,
    required this.scale,
    this.borderColor,
  });

  final Color color;
  final Color? borderColor;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: borderColor == null ? null : Border.all(color: borderColor!),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withOpacity(color == Colors.white ? 0.10 : 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorativeBackground extends StatelessWidget {
  const _DecorativeBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned(
          top: -28,
          right: -26,
          child: Opacity(
            opacity: 0.12,
            child: Image.asset(
              'assets/images/pattern_top_right.png',
              width: 150,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const _CornerPattern(
                color: _SplashColors.green,
                rotate: -0.15,
              ),
            ),
          ),
        ),
        Positioned(
          left: -38,
          bottom: 114,
          child: Opacity(
            opacity: 0.12,
            child: Image.asset(
              'assets/images/pattern_bottom_left.png',
              width: 150,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const _CornerPattern(
                color: _SplashColors.orange,
                rotate: 0.22,
              ),
            ),
          ),
        ),
        const Positioned(
          top: 84,
          left: 30,
          child: _IvorySilhouette(icon: Icons.terrain_rounded, size: 64),
        ),
        const Positioned(
          top: 138,
          right: 24,
          child: _IvorySilhouette(icon: Icons.park_rounded, size: 58),
        ),
        const Positioned(
          left: 36,
          bottom: 252,
          child: _IvorySilhouette(icon: Icons.water_rounded, size: 72),
        ),
        const Positioned(
          right: 34,
          bottom: 224,
          child: _IvorySilhouette(icon: Icons.location_on_rounded, size: 60),
        ),
      ],
    );
  }
}

class _CornerPattern extends StatelessWidget {
  const _CornerPattern({required this.color, required this.rotate});

  final Color color;
  final double rotate;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotate,
      child: CustomPaint(
        size: const Size(150, 150),
        painter: _CornerPatternPainter(color: color),
      ),
    );
  }
}

class _CornerPatternPainter extends CustomPainter {
  const _CornerPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.30);

    for (int i = 0; i < 6; i++) {
      final double inset = 14.0 + (i * 18);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(inset, inset, size.width - inset, size.height - inset),
          const Radius.circular(28),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CornerPatternPainter oldDelegate) => false;
}

class _IvorySilhouette extends StatelessWidget {
  const _IvorySilhouette({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: _SplashColors.textDark.withOpacity(0.035),
    );
  }
}

class _MicroOrnament extends StatelessWidget {
  const _MicroOrnament({
    required this.color,
    required this.size,
  }) : isStar = false;

  const _MicroOrnament.star({
    required this.color,
    this.size = 15,
  }) : isStar = true;

  final Color color;
  final double size;
  final bool isStar;

  @override
  Widget build(BuildContext context) {
    if (isStar) {
      return Icon(
        Icons.auto_awesome_rounded,
        color: color.withOpacity(0.72),
        size: size,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.72),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _BottomWaves extends StatelessWidget {
  const _BottomWaves({required this.ambientValue});

  final double ambientValue;

  @override
  Widget build(BuildContext context) {
    final double lift = 2.5 * math.sin(ambientValue * math.pi);

    return Positioned.fill(
      child: IgnorePointer(
        child: Transform.translate(
          offset: Offset(0, lift),
          child: CustomPaint(
            painter: const _BottomWavesPainter(),
          ),
        ),
      ),
    );
  }
}

class _BottomWavesPainter extends CustomPainter {
  const _BottomWavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double baseY = size.height - math.min(126, size.height * 0.17);

    final Paint orangePaint = Paint()
      ..color = _SplashColors.orange.withOpacity(0.92)
      ..style = PaintingStyle.fill;
    final Paint greenPaint = Paint()
      ..color = _SplashColors.green.withOpacity(0.94)
      ..style = PaintingStyle.fill;
    final Paint whiteVeilPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final Path orangePath = Path()
      ..moveTo(0, baseY + 18)
      ..cubicTo(size.width * 0.14, baseY - 18, size.width * 0.30, baseY + 14,
          size.width * 0.45, baseY - 6)
      ..cubicTo(size.width * 0.34, baseY + 64, size.width * 0.20,
          size.height + 12, 0, size.height)
      ..close();

    final Path greenPath = Path()
      ..moveTo(size.width, baseY - 4)
      ..cubicTo(size.width * 0.82, baseY - 28, size.width * 0.67, baseY + 30,
          size.width * 0.52, baseY + 2)
      ..cubicTo(size.width * 0.64, baseY + 70, size.width * 0.82,
          size.height + 14, size.width, size.height)
      ..close();

    final Path orangeVeil = Path()
      ..moveTo(0, baseY + 46)
      ..cubicTo(size.width * 0.13, baseY + 18, size.width * 0.25, baseY + 45,
          size.width * 0.38, baseY + 24)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(orangePath, orangePaint);
    canvas.drawPath(greenPath, greenPaint);
    canvas.drawPath(orangeVeil, whiteVeilPaint);
  }

  @override
  bool shouldRepaint(covariant _BottomWavesPainter oldDelegate) => false;
}

class _SplashSpacing {
  const _SplashSpacing._();

  static double horizontal(double width) => width < 360 ? 22 : 28;
}

class _SplashColors {
  const _SplashColors._();

  static const Color ivory = Color(0xFFFFFCF4);
  static const Color orange = Color(0xFFF58220);
  static const Color orangeLight = Color(0xFFFFA94D);
  static const Color green = Color(0xFF168A49);
  static const Color textDark = Color(0xFF1F241F);
  static const Color textSoft = Color(0xFF5F645B);
  static const Color shadow = Color(0xFF3B2B18);
  static const Color progressTrack = Color(0xFFF1E7D6);
  static const Color dotBorder = Color(0xFFEADFCB);
}
