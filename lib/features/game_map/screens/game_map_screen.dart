import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../lives/models/lives.dart';
import '../../lives/providers/lives_provider.dart';
import '../../streak/models/streak.dart';
import '../../streak/providers/streak_provider.dart';
import '../models/game_map.dart';
import '../providers/game_map_provider.dart';
import 'first_journey_intro.dart';

const _pathPositions = [0.50, 0.70, 0.78, 0.64, 0.40, 0.22, 0.30];

class GameMapScreen extends ConsumerWidget {
  const GameMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final map = ref.watch(gameMapProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF4),
      body: Stack(
        children: [
          const Positioned.fill(child: _JourneyBackground()),
          SafeArea(
            child: map.when(
              data: (value) => value.firstTimeIntro
                  ? FirstJourneyIntro(
                      map: value,
                      onDone: () =>
                          ref.read(gameMapProvider.notifier).completeIntro(),
                    )
                  : _Journey(map: value),
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.orange)),
              error: (error, __) {
                final apiError = error is ApiException ? error : null;
                return _ErrorView(
                  message: apiError?.userMessage,
                  onRetry: () => ref.read(gameMapProvider.notifier).refresh(),
                  onLogin: apiError?.isUnauthorized == true
                      ? () => context.go('/auth')
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyBackground extends StatelessWidget {
  const _JourneyBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF3DF),
            Color(0xFFFFFCF7),
            Color(0xFFF7FCF8),
          ],
          stops: [0, .42, 1],
        ),
      ),
      child: const CustomPaint(painter: _BackgroundPainter()),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _paintGlow(
      canvas,
      Offset(size.width * .08, size.height * .20),
      size.width * .43,
      const Color(0xFFF77F00).withValues(alpha: .08),
    );
    _paintGlow(
      canvas,
      Offset(size.width * .96, size.height * .66),
      size.width * .50,
      const Color(0xFF009E60).withValues(alpha: .065),
    );

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFF77F00).withValues(alpha: .075);
    final greenLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF009E60).withValues(alpha: .065);

    for (var i = 0; i < 3; i++) {
      final radius = 30.0 + (i * 16);
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width + 6, size.height * .24),
          radius: radius,
        ),
        1.7,
        3.2,
        false,
        linePaint,
      );
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(-5, size.height * .75),
          radius: radius,
        ),
        -1.4,
        3.0,
        false,
        greenLinePaint,
      );
    }

    final dotPaint = Paint()
      ..color = const Color(0xFF1A1A2E).withValues(alpha: .035);
    _paintDots(canvas, Offset(size.width - 54, size.height * .43), dotPaint);
    _paintDots(canvas, Offset(24, size.height * .91), dotPaint);
  }

  void _paintGlow(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  void _paintDots(Canvas canvas, Offset origin, Paint paint) {
    for (var row = 0; row < 4; row++) {
      for (var column = 0; column < 4; column++) {
        canvas.drawCircle(
          origin + Offset(column * 12, row * 12),
          2.2,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) => false;
}

class _Journey extends ConsumerWidget {
  const _Journey({required this.map});
  final GameMap map;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: () => ref.read(gameMapProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _TopBar(stats: map.stats)),
          SliverToBoxAdapter(child: _WorldCard(map: map)),
          if (map.nodes.isEmpty)
            const SliverFillRemaining(
                hasScrollBody: false, child: _EmptyJourney())
          else
            SliverPadding(
              padding: const EdgeInsets.only(top: 20, bottom: 72),
              sliver: SliverList.builder(
                itemCount: map.nodes.length,
                itemBuilder: (context, index) {
                  final node = map.nodes[index];
                  return _NodeRow(
                    node: node,
                    position: _pathPositions[index % _pathPositions.length],
                    previousPosition: index == 0
                        ? null
                        : _pathPositions[(index - 1) % _pathPositions.length],
                    onTap: () => _openNode(context, node),
                  ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: .12);
                },
              ),
            ),
        ],
      ),
    );
  }

  void _openNode(BuildContext context, GameMapNode node) {
    if (node.state == MapNodeState.locked) return;
    if (node.type == MapNodeType.chest) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(node.state == MapNodeState.claimable
              ? 'Ton coffre est prÃªt !'
              : 'Continue le parcours pour dÃ©bloquer ce coffre.')));
      return;
    }
    if (!node.isPlayable && node.state != MapNodeState.completed) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _LevelSheet(
        node: node,
        onStart: () {
          Navigator.of(sheetContext).pop();
          context.push('/quiz/${node.levelId}');
        },
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.stats});
  final GameMapStats stats;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final lives =
        ref.watch(livesProvider).value ?? const Lives(current: 0, max: 5);
    final streak = ref.watch(streakProvider).value ??
        const Streak(current: 0, longest: 0, freezes: 0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x33F77F00),
                    blurRadius: 10,
                    offset: Offset(0, 4))
              ]),
          alignment: Alignment.center,
          child: Text('IQ',
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 15)),
        ),
        const Spacer(),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(children: [
              _Stat(
                  icon: Icons.favorite_rounded,
                  value: '${stats.lives ?? lives.current}',
                  color: const Color(0xFFEF4444)),
              const SizedBox(width: 8),
              _Stat(
                  icon: Icons.local_fire_department_rounded,
                  value: '${stats.streak ?? streak.current}',
                  color: AppColors.orange),
              const SizedBox(width: 8),
              _Stat(
                  icon: Icons.bolt_rounded,
                  value: '${stats.xpTotal ?? user?.xpTotal ?? 0}',
                  color: const Color(0xFFF5B700)),
              const SizedBox(width: 8),
              _Stat(
                  icon: Icons.monetization_on_rounded,
                  value: '${stats.coins ?? 0}',
                  color: const Color(0xFFE3A500)),
              const SizedBox(width: 8),
              _Stat(
                  icon: Icons.diamond_rounded,
                  value: '${stats.gems ?? 0}',
                  color: const Color(0xFF38A5F8)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.color});
  final IconData icon;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFF1EDE7))),
        child: Row(children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 4),
          Text(value,
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900, color: AppColors.textDark))
        ]),
      );
}

class _WorldCard extends StatelessWidget {
  const _WorldCard({required this.map});
  final GameMap map;
  @override
  Widget build(BuildContext context) {
    final next = map.nextPlayable;
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFF77F00), Color(0xFFFFA423)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: Color(0x3DF77F00), blurRadius: 18, offset: Offset(0, 8))
        ],
      ),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('MONDE ${map.world.number}',
                    style: GoogleFonts.nunito(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(map.world.name,
                    style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 26)),
                const SizedBox(height: 4),
                Text(
                    next == null
                        ? 'Parcours terminÃ© !'
                        : 'Prochain dÃ©fi : ${next.title}',
                    style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ])),
          SizedBox(
              width: 78,
              height: 78,
              child: Image.asset('assets/Effobi salutation.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.explore_rounded,
                      color: Colors.white,
                      size: 52))),
        ]),
        const SizedBox(height: 15),
        Row(children: [
          Expanded(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                      value: (map.progressPercent.clamp(0, 100)) / 100,
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Colors.white)))),
          const SizedBox(width: 10),
          Text('${map.progressPercent}%',
              style: GoogleFonts.nunito(
                  color: Colors.white, fontWeight: FontWeight.w900)),
        ]),
      ]),
    );
  }
}

class _NodeRow extends StatelessWidget {
  const _NodeRow(
      {required this.node,
      required this.position,
      required this.previousPosition,
      required this.onTap});
  final GameMapNode node;
  final double position;
  final double? previousPosition;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: node.type == MapNodeType.boss ? 126 : 108,
        child: Stack(children: [
          if (previousPosition != null)
            Positioned.fill(
                child: CustomPaint(
                    painter: _PathPainter(previousPosition!, position))),
          Align(
              alignment: Alignment(position * 2 - 1, 0),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (node.state == MapNodeState.current)
                  _NextLabel(
                      title: node.type == MapNodeType.boss
                          ? 'AFFRONTER'
                          : 'CONTINUER'),
                Semantics(
                    button: true,
                    label: node.title,
                    child: GestureDetector(
                        onTap: onTap, child: _NodeButton(node: node))),
                if (node.type == MapNodeType.boss)
                  Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Text(node.title,
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark))),
              ])),
        ]),
      );
}

class _NextLabel extends StatelessWidget {
  const _NextLabel({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
            color: AppColors.textDark, borderRadius: BorderRadius.circular(12)),
        child: Text(title,
            style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 10,
                letterSpacing: .8,
                fontWeight: FontWeight.w900)),
      );
}

class _NodeButton extends StatelessWidget {
  const _NodeButton({required this.node});
  final GameMapNode node;
  @override
  Widget build(BuildContext context) {
    final locked = node.state == MapNodeState.locked;
    final completed = node.state == MapNodeState.completed ||
        node.state == MapNodeState.claimed;
    final chest = node.type == MapNodeType.chest;
    final boss = node.type == MapNodeType.boss;
    final main = locked
        ? const Color(0xFFD9D9D9)
        : completed
            ? const Color(0xFF24B86A)
            : boss
                ? const Color(0xFF7C3AED)
                : chest
                    ? const Color(0xFFF5B700)
                    : AppColors.orange;
    final shadow = locked
        ? const Color(0xFFB9B9B9)
        : completed
            ? const Color(0xFF15834A)
            : boss
                ? const Color(0xFF5420AA)
                : chest
                    ? const Color(0xFFC58D00)
                    : const Color(0xFFC85F00);
    final size = boss
        ? 82.0
        : chest
            ? 70.0
            : 72.0;
    final icon = locked
        ? Icons.lock_rounded
        : completed
            ? Icons.check_rounded
            : boss
                ? Icons.workspace_premium_rounded
                : chest
                    ? Icons.inventory_2_rounded
                    : Icons.star_rounded;
    return Container(
      width: size,
      height: size + 7,
      padding: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
          color: shadow, borderRadius: BorderRadius.circular(size / 2)),
      child: Container(
          decoration: BoxDecoration(
              color: main,
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: .22), width: 3)),
          child: Icon(icon,
              color: locked ? const Color(0xFF858585) : Colors.white,
              size: boss ? 38 : 32)),
    );
  }
}

class _PathPainter extends CustomPainter {
  const _PathPainter(this.from, this.to);
  final double from;
  final double to;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE6DED4)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final start = Offset(from * size.width, 0),
        end = Offset(to * size.width, size.height);
    const step = 15.0;
    final count = ((end - start).distance / step).floor();
    for (var i = 1; i < count; i += 2) {
      final a = Offset.lerp(start, end, i / count)!;
      final b = Offset.lerp(start, end, (i + 1) / count)!;
      canvas.drawLine(a, b, paint);
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.from != from || old.to != to;
}

class _LevelSheet extends StatelessWidget {
  const _LevelSheet({required this.node, required this.onStart});
  final GameMapNode node;
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: SafeArea(
            top: false,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                      color: AppColors.neutral,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 20),
              Icon(
                  node.type == MapNodeType.boss
                      ? Icons.workspace_premium_rounded
                      : Icons.star_rounded,
                  color: node.type == MapNodeType.boss
                      ? const Color(0xFF7C3AED)
                      : AppColors.orange,
                  size: 42),
              const SizedBox(height: 8),
              Text(node.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 23,
                      color: AppColors.textDark)),
              const SizedBox(height: 5),
              Text(
                  node.subtitle ??
                      '${node.totalQuestions} questions pour avancer dans le parcours',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(color: AppColors.textGray)),
              const SizedBox(height: 20),
              SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: node.levelId == null ? null : onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(node.state == MapNodeState.completed
                        ? 'REJOUER'
                        : 'COMMENCER'),
                  )),
            ])),
      );
}

class _EmptyJourney extends StatelessWidget {
  const _EmptyJourney();
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Le prochain parcours arrive bientÃ´t.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  color: AppColors.textGray, fontWeight: FontWeight.w700))));
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.onRetry,
    this.onLogin,
    this.message,
  });

  final VoidCallback onRetry;
  final VoidCallback? onLogin;
  final String? message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: AppColors.textGray,
              ),
              const SizedBox(height: 12),
              Text(
                message ?? 'Impossible de charger le parcours',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onLogin ?? onRetry,
                child: Text(
                  onLogin == null ? 'Réessayer' : 'Se reconnecter',
                ),
              ),
            ],
          ),
        ),
      );
}
