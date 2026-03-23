import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({
    required this.categories,
    required this.selectedMode,
    super.key,
  });

  final List<Map<String, dynamic>> categories;
  final String selectedMode;

  ({Color bgColor, Color iconColor, IconData icon}) _getCategoryStyle(int index) {
    switch (index % 3) {
      case 0:
        return (
          bgColor: const Color(0xFFFFF3E8),
          iconColor: const Color(0xFFF77F00),
          icon: Icons.menu_book_rounded,
        );
      case 1:
        return (
          bgColor: const Color(0xFFE8F5E9),
          iconColor: const Color(0xFF22C55E),
          icon: Icons.location_on_rounded,
        );
      case 2:
      default:
        return (
          bgColor: const Color(0xFFFFFDE8),
          iconColor: const Color(0xFFFFB300),
          icon: Icons.restaurant_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.textDark,
        ),
        title: Text(
          'Toutes les catégories',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: categories.isEmpty
          ? Center(
              child: Text(
                'Aucune catégorie disponible.',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGray,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final Map<String, dynamic> category = categories[index];
                final ({Color bgColor, Color iconColor, IconData icon}) style = _getCategoryStyle(index);
                final String categoryName = (category['name'] as String?)?.trim().isNotEmpty == true
                    ? (category['name'] as String).trim()
                    : 'Catégorie';
                final int questionsCount = (category['questions_count'] as num?)?.toInt() ?? 0;

                return GestureDetector(
                  onTap: () {
                    if (selectedMode == 'mixed') {
                      context.push('/quiz/null/mixed');
                      return;
                    }
                    context.push('/quiz/${category['id']}/$selectedMode');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: style.bgColor,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Icon(
                            style.icon,
                            size: 24,
                            color: style.iconColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                categoryName,
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$questionsCount questions disponibles',
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textGray,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
