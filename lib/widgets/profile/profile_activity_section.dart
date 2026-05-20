import 'package:flutter/material.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';

class ProfileActivitySection extends StatelessWidget {
  const ProfileActivitySection({
    super.key,
    required this.ownedCount,
    required this.memberCount,
    required this.createdAt,
    required this.accentColor,
  });

  final int ownedCount;
  final int memberCount;
  final DateTime? createdAt;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AKTIVITET',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard('$ownedCount', 'PROSJEKTER\nOPPRETTET', accentColor),
              const SizedBox(width: 10),
              _statCard('$memberCount', 'PROSJEKTER\nDELTATT', accentColor),
              const SizedBox(width: 10),
              _statCard(
                _formatDate(createdAt),
                'MEDLEM\nSIDEN',
                accentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color valueColor) {
    return Expanded(
      child: BrutalistPanel(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '?';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mai',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

