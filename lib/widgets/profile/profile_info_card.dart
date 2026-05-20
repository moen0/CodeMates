import 'package:flutter/material.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({
    super.key,
    required this.university,
    required this.studyProgramAndYear,
  });

  final String? university;
  final String studyProgramAndYear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: BrutalistPanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              Icon(Icons.school, size: 18, color: Colors.grey[400]),
              const SizedBox(width: 10),
              Text(
                university ?? 'Ikke angitt',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.menu_book, size: 18, color: Colors.grey[400]),
              const SizedBox(width: 10),
              Text(
                studyProgramAndYear,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

