import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../models/game_map.dart';
import '../providers/game_map_provider.dart';

class CityScreen extends ConsumerWidget {
  const CityScreen({super.key, required this.cityId});
  final int cityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cityAsync = ref.watch(cityDetailProvider(cityId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
        title: cityAsync.when(
          data: (c) => Text(
            c.name,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ),
      body: cityAsync.when(
        data: (city) => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: city.levels.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _buildLevelCard(context, city.levels[i], i),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
        error: (e, _) => Center(
          child: Text(e.toString(), style: GoogleFonts.nunito(color: AppColors.textGray)),
        ),
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, GameLevel level, int index) {
    final locked = !level.isUnlocked;

    return GestureDetector(
      onTap: locked ? null : () => context.push('/home/level/${level.id}'),
      child: Opacity(
        opacity: locked ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: level.isBoss ? const Color(0xFFFFF3E8) : Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            border: Border.all(
              color: level.isBoss ? AppColors.orange : AppColors.neutral,
              width: level.isBoss ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: locked
                      ? AppColors.neutral
                      : level.isBoss
                          ? AppColors.orange
                          : const Color(0xFFFFF3E8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  locked
                      ? Icons.lock_rounded
                      : level.isBoss
                          ? Icons.military_tech_rounded
                          : Icons.play_arrow_rounded,
                  color: locked
                      ? AppColors.textGray
                      : level.isBoss
                          ? Colors.white
                          : AppColors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            level.title,
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (level.isBoss)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: const BoxDecoration(
                              color: AppColors.orange,
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            child: Text(
                              'BOSS',
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${level.totalQuestions} questions · Difficulté ${level.difficulty}',
                      style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textGray),
                    ),
                  ],
                ),
              ),
              if (!locked)
                const Icon(Icons.chevron_right_rounded, color: AppColors.textGray),
            ],
          ),
        ),
      ),
    );
  }
}
