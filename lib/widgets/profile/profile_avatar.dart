import 'package:flutter/material.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.avatarUrl,
    required this.isUploading,
    required this.accentColor,
    this.onTap,
  });

  final String? avatarUrl;
  final bool isUploading;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              border: Border.all(color: accentColor, width: 2),
              color: BrutalistPalette.panel,
            ),
            child: hasImage
                ? Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey,
                    ),
                  )
                : const Icon(Icons.person, size: 40, color: Colors.grey),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: accentColor,
                border: Border.all(color: BrutalistPalette.panel, width: 2),
              ),
              child: const Icon(
                Icons.photo_camera,
                size: 14,
                color: Colors.black,
              ),
            ),
          ),
          if (isUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

