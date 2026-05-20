import 'package:flutter/material.dart';
import 'package:devconnect/models/user_skill.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';

class ProfileSkillsSection extends StatelessWidget {
  const ProfileSkillsSection({
    super.key,
    required this.skills,
    required this.selectedCategory,
    required this.categories,
    required this.accentColor,
    required this.onCategoryChanged,
  });

  final List<UserSkill> skills;
  final String selectedCategory;
  final Map<String, String> categories;
  final Color accentColor;
  final ValueChanged<String> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FERDIGHETER',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.entries.map((entry) {
                final isSelected = selectedCategory == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onCategoryChanged(entry.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor.withValues(alpha: 0.2)
                            : const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.zero,
                        border: isSelected
                            ? Border.all(color: accentColor, width: 1)
                            : Border.all(color: BrutalistPalette.border),
                      ),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? accentColor : Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((skill) {
              final color = _proficiencyColor(skill.proficiency);
              final skillName = skill.skill?.name ?? 'Ukjent';
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: BrutalistPalette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skillName,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      color: color,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (skills.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Ingen ferdigheter i denne kategorien',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Color _proficiencyColor(String? level) {
    switch (level) {
      case 'advanced':
        return Colors.green;
      case 'intermediate':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}

