import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({required this.sessions, super.key});

  final List<Map<String, dynamic>> sessions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Historique des parties',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
      ),
      body: sessions.isEmpty
          ? const Center(
              child: Text('Aucune partie enregistrée pour le moment.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final session = sessions[index];
                final category = session['category'];
                final name =
                    category is Map ? category['name']?.toString() : null;
                final mode = session['mode']?.toString();
                final title = name ??
                    (mode == 'daily_challenge'
                        ? 'Questions du jour'
                        : 'Quiz mixte');
                final correct = session['correct_answers'] ?? 0;
                final total = session['total_questions'] ?? 10;
                final points = session['total_score'] ??
                    session['points_earned'] ??
                    session['score'] ??
                    0;
                final date = (session['completed_at'] ?? session['created_at'])
                    ?.toString();
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFF3E8),
                      child:
                          Icon(Icons.quiz_outlined, color: Color(0xFFF77F00)),
                    ),
                    title: Text(title,
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                        '$correct/$total bonnes réponses${date == null ? '' : ' · ${date.substring(0, date.length >= 10 ? 10 : date.length)}'}'),
                    trailing: Text('$points pts',
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF77F00))),
                  ),
                );
              },
            ),
    );
  }
}
