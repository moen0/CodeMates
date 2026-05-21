import 'package:flutter/material.dart';
import 'package:devconnect/models/profile.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';

typedef SaveProfileEdits = Future<void> Function({
  required String displayName,
  required String bio,
  required String university,
  required String githubUrl,
  required String studyProgram,
  required int? year,
  required String linkedinUrl,
  required String websiteUrl,
  required bool availabilityOpen,
});

Future<void> showEditProfileDialog({
  required BuildContext context,
  required Profile? currentProfile,
  required SaveProfileEdits onSave,
}) async {
  final nameController = TextEditingController(
    text: currentProfile?.displayName ?? '',
  );
  final bioController = TextEditingController(
    text: currentProfile?.bio ?? '',
  );
  final universityController = TextEditingController(
    text: currentProfile?.university ?? '',
  );
  final githubController = TextEditingController(
    text: currentProfile?.githubUrl ?? '',
  );
  final studyProgramController = TextEditingController(
    text: currentProfile?.studyProgram ?? '',
  );
  final linkedinController = TextEditingController(
    text: currentProfile?.linkedinUrl ?? '',
  );
  final websiteController = TextEditingController(
    text: currentProfile?.websiteUrl ?? '',
  );

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
        var isSaving = false;
        var selectedYear = currentProfile?.year;
        if (selectedYear != null && (selectedYear < 1 || selectedYear > 5)) {
          selectedYear = null;
        }
        var availabilityOpen = currentProfile?.availability ?? true;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: BrutalistPalette.panel,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: BrutalistPalette.border),
              ),
              title: const Text('Rediger profil'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration:
                          brutalistInputDecoration(labelText: 'Navn *'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: bioController,
                      maxLines: 3,
                      decoration: brutalistInputDecoration(labelText: 'Bio'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: universityController,
                      decoration: brutalistInputDecoration(
                        labelText: 'Universitet',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: githubController,
                      decoration: brutalistInputDecoration(
                        labelText: 'GitHub URL',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: studyProgramController,
                      decoration: brutalistInputDecoration(
                        labelText: 'Studieprogram',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: selectedYear,
                      dropdownColor: BrutalistPalette.panel,
                      decoration: brutalistInputDecoration(
                        labelText: 'Årstrinn',
                      ),
                      items: const [1, 2, 3, 4, 5]
                          .map(
                            (year) => DropdownMenuItem<int>(
                              value: year,
                              child: Text('År $year'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setDialogState(
                        () => selectedYear = value,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: linkedinController,
                      decoration: brutalistInputDecoration(
                        labelText: 'LinkedIn URL',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: websiteController,
                      decoration: brutalistInputDecoration(
                        labelText: 'Nettside',
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
                      value: availabilityOpen,
                      activeTrackColor: BrutalistPalette.accent,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Åpen for samarbeid'),
                      onChanged: (value) => setDialogState(
                        () => availabilityOpen = value,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  style: brutalistOutlineButtonStyle(),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Avbryt'),
                ),
                ElevatedButton(
                  style: brutalistPrimaryButtonStyle(),
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() => isSaving = true);
                          try {
                            await onSave(
                              displayName: nameController.text,
                              bio: bioController.text,
                              university: universityController.text,
                              githubUrl: githubController.text,
                              studyProgram: studyProgramController.text,
                              year: selectedYear,
                              linkedinUrl: linkedinController.text,
                              websiteUrl: websiteController.text,
                              availabilityOpen: availabilityOpen,
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() => isSaving = false);
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Lagre'),
                ),
              ],
            );
          },
        );
      },
  );
}

