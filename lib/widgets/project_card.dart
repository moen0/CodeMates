import 'package:flutter/material.dart';
import 'package:devconnect/models/project.dart';
import 'package:devconnect/models/profile.dart';
import 'package:devconnect/models/skill.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.matchScore,
    required this.skills,
    required this.owner,
    required this.onTap,
    this.onOwnerTap,
  });

  final Project project;
  final int? matchScore;
  final List<Skill> skills;
  final Profile? owner;
  final VoidCallback onTap;
  final VoidCallback? onOwnerTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      color: BrutalistPalette.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: BrutalistPalette.border),
      ),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                project.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (matchScore != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: BrutalistPalette.accent),
                  color: BrutalistPalette.accent.withValues(alpha: 0.12),
                ),
                child: Text(
                  '$matchScore% treff',
                  style: const TextStyle(
                    fontSize: 11,
                    color: BrutalistPalette.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              project.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (skills.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.take(4).map((skill) {
                  final name = skill.name.toUpperCase();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: BrutalistPalette.border,
                      ),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: BrutalistPalette.muted,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onOwnerTap,
              child: Text(
                'Av ${owner?.displayLabel ?? 'Ukjent'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: BrutalistPalette.accent,
                  decoration: TextDecoration.underline,
                  decorationColor: BrutalistPalette.accent,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

