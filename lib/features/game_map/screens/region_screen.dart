import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../models/game_map.dart';
import '../providers/game_map_provider.dart';

class RegionScreen extends ConsumerWidget {
  const RegionScreen({super.key, required this.regionId});
  final int regionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regionAsync = ref.watch(regionDetailProvider(regionId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
        title: regionAsync.when(
          data: (r) => Text(
            r.name,
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
      body: regionAsync.when(
        data: (region) => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: region.cities.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _buildCityCard(context, region.cities[i]),
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

  Widget _buildCityCard(BuildContext context, GameCity city) {
    final total = city.levels.length;
    final unlocked = city.levels.where((l) => l.isUnlocked).length;

    return GestureDetector(
      onTap: () => context.push('/home/city/${city.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          border: Border.all(color: AppColors.neutral),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3E8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_city_rounded, color: AppColors.orange, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city.name,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$total niveau${total > 1 ? 'x' : ''} · $unlocked débloqué${unlocked > 1 ? 's' : ''}',
                    style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textGray),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textGray),
          ],
        ),
      ),
    );
  }
}
