import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Slug de la catégorie Logos renvoyé par l'API.
const String logoCategorySlug = 'logos';

const String logoLegalNotice =
    'Les logos et marques présentés appartiennent à leurs propriétaires '
    'respectifs. Ils sont affichés uniquement pour permettre leur '
    'identification, dans un but éducatif et culturel. IvoireQuiz n’est '
    'affilié à aucune de ces entreprises, ni soutenu ou sponsorisé par elles.';

const ({Color bgColor, Color iconColor, IconData icon}) logoCategoryStyle = (
  bgColor: Color(0xFFE8F0FE),
  iconColor: Color(0xFF2563EB),
  icon: Icons.storefront_rounded,
);

const String _noticeAcceptedKey = 'logos_notice_accepted';

bool isLogoCategory(Map<String, dynamic> category) =>
    category['slug']?.toString() == logoCategorySlug;

/// Place les Logos en tête, l'accueil n'affichant que les premières
/// catégories. La carte reste cachée tant qu'aucun logo n'est publié.
List<Map<String, dynamic>> withLogosFirst(
    List<Map<String, dynamic>> categories) {
  final logos = categories.where((category) =>
      isLogoCategory(category) &&
      ((category['questions_count'] as num?)?.toInt() ?? 0) > 0);
  return <Map<String, dynamic>>[
    ...logos,
    ...categories.where((category) => !isLogoCategory(category)),
  ];
}

/// Ouvre une catégorie du lancement rapide. La première entrée dans les
/// Logos passe par la mention légale.
Future<void> openQuickLaunchCategory(
  BuildContext context,
  Map<String, dynamic> category,
  String mode,
) async {
  if (mode == 'mixed') {
    context.push('/quiz/null/mixed');
    return;
  }
  if (!isLogoCategory(category)) {
    context.push('/quiz/${category['id']}/$mode');
    return;
  }
  if (!await _acceptLogoNotice(context) || !context.mounted) return;
  context.push('/quiz/${category['id']}/$mode?slug=$logoCategorySlug');
}

Future<bool> _acceptLogoNotice(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_noticeAcceptedKey) ?? false) return true;
  if (!context.mounted) return false;

  final bool? accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(logoCategoryStyle.icon, color: logoCategoryStyle.iconColor),
      title: const Text('Mode Logos'),
      content: const Text(
        '$logoLegalNotice\n\n'
        'Pour demander le retrait d’un logo, écrivez-nous à l’adresse '
        'indiquée sur la fiche de l’app dans le store.',
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler')),
        FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('J’ai compris')),
      ],
    ),
  );
  if (accepted != true) return false;
  await prefs.setBool(_noticeAcceptedKey, true);
  return true;
}
