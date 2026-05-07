import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';
import 'package:devconnect/services/auth_service.dart';
import 'package:devconnect/services/profile_service.dart';
import 'package:devconnect/models/profile.dart';
import 'package:devconnect/models/user_skill.dart';

import 'edit_skills_screen.dart';
import 'welcome.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.refreshToken = 0});

  final int refreshToken;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _panel = BrutalistPalette.panel;
  static const Color _border = BrutalistPalette.border;

  Color get _accent => Theme.of(context).colorScheme.primary;

  final _authService = AuthService();
  final _profileService = ProfileService();

  Profile? _profile;
  List<UserSkill> _skills = [];
  int _ownedProjectsCount = 0;
  int _memberProjectsCount = 0;
  String _selectedCategory = 'language';
  bool _isLoading = true;
  bool _isUploadingAvatar = false;

  final _categories = {
    'language': 'SPRÅK',
    'frontend': 'FRONTEND',
    'backend': 'BACKEND',
    'data_ai': 'DATA & AI',
    'devops': 'DEVOPS',
    'database': 'DATABASE',
    'design': 'DESIGN',
    'mobile': 'MOBIL',
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    final userId = _authService.currentUserId;

    if (userId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await Future.wait<dynamic>([
        _profileService.getProfile(userId),
        _profileService.getUserSkills(userId),
        _profileService.getOwnedProjectsCount(userId),
        _profileService.getMemberProjectsCount(userId),
      ]);

      final profileRes = results[0] as Profile?;
      final skillsRes = results[1] as List<UserSkill>;
      final ownedProjectsRes = results[2] as int;
      final memberProjectsRes = results[3] as int;

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profileRes;
        _skills = skillsRes;
        _ownedProjectsCount = ownedProjectsRes;
        _memberProjectsCount = memberProjectsRes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kunne ikke laste profil: $e')));
    }
  }

  Future<void> _showAvatarSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: BrutalistPalette.border),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined,
                    color: Colors.white),
                title: const Text('Ta bilde',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: Colors.white),
                title: const Text('Velg fra galleri',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              if ((_profile?.avatarUrl ?? '').isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: Colors.redAccent),
                  title: const Text('Fjern profilbilde',
                      style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _removeAvatar();
                  },
                ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      await _pickAndUploadAvatar(source);
    }
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (picked == null) return;

    final userId = _authService.currentUserId;
    if (userId == null) {
      return;
    }

    setState(() => _isUploadingAvatar = true);

    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.path.split('.').last.toLowerCase();

      final bustedUrl = await _profileService.uploadAvatar(
        userId: userId,
        bytes: bytes,
        extension: ext,
      );

      if (!mounted) return;
      setState(() {
        _profile = _profile?.copyWith(avatarUrl: bustedUrl);
        _isUploadingAvatar = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilbilde oppdatert')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke laste opp bilde: $e')),
      );
    }
  }

  Future<void> _removeAvatar() async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      return;
    }

    setState(() => _isUploadingAvatar = true);
    try {
      await _profileService.removeAvatar(userId: userId);

      if (!mounted) return;
      setState(() {
        _profile = _profile?.copyWith(avatarUrl: null);
        _isUploadingAvatar = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilbilde fjernet')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke fjerne bilde: $e')),
      );
    }
  }

  Future<void> _saveProfileEdits({
    required String displayName,
    required String bio,
    required String university,
    required String githubUrl,
    required String studyProgram,
    required int? year,
    required String linkedinUrl,
    required String websiteUrl,
    required bool availabilityOpen,
  }) async {
    final current = _profile;
    if (current == null) {
      throw const FormatException('Fant ikke profilen din');
    }

    final normalizedName = _normalizeOptionalText(displayName);
    if (normalizedName == null) {
      throw const FormatException('Navn kan ikke være tomt');
    }

    final updated = current.copyWith(
      displayName: normalizedName,
      bio: _normalizeOptionalText(bio),
      university: _normalizeOptionalText(university),
      githubUrl: _normalizeOptionalText(githubUrl),
      studyProgram: _normalizeOptionalText(studyProgram),
      year: year,
      linkedinUrl: _normalizeOptionalText(linkedinUrl),
      websiteUrl: _normalizeOptionalText(websiteUrl),
      availability: availabilityOpen,
    );

    await _profileService.updateProfile(updated);

    if (!mounted) {
      return;
    }

    setState(() {
      _profile = updated;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profil oppdatert')));
  }

  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(
      text: _profile?.displayName ?? '',
    );
    final bioController = TextEditingController(
      text: _profile?.bio ?? '',
    );
    final universityController = TextEditingController(
      text: _profile?.university ?? '',
    );
    final githubController = TextEditingController(
      text: _profile?.githubUrl ?? '',
    );
    final studyProgramController = TextEditingController(
      text: _profile?.studyProgram ?? '',
    );
    final linkedinController = TextEditingController(
      text: _profile?.linkedinUrl ?? '',
    );
    final websiteController = TextEditingController(
      text: _profile?.websiteUrl ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var isSaving = false;
        var selectedYear = _profile?.year;
        if (selectedYear != null && (selectedYear < 1 || selectedYear > 5)) {
          selectedYear = null;
        }
        var availabilityOpen = _availabilityFromProfile(_profile?.availability);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _panel,
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
                      decoration: brutalistInputDecoration(labelText: 'Navn *'),
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
                      dropdownColor: _panel,
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
                      activeTrackColor: _accent,
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
                            await _saveProfileEdits(
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
                            if (mounted) setDialogState(() => isSaving = false);
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

  /// Logger ut brukeren og sender dem tilbake til velkomstskjermen.
  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Welcome()),
      (_) => false,
    );
  }

  Future<void> _openSkillsEditor() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditSkillsScreen()),
    );

    if (changed == true && mounted) {
      setState(() {
        _isLoading = true;
      });
      await _loadProfile();
    }
  }

  List<UserSkill> get _filteredSkills {
    return _skills
        .where((s) => _normalizeSkillCategory(s.skill?.category) == _selectedCategory)
        .toList();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const BrutalistScaffold(
        appBar: BrutalistHeader(title: 'Profil'),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return BrutalistScaffold(
      appBar: const BrutalistHeader(title: 'Profil'),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              _buildAvatar(),
              const SizedBox(height: 16),

              Text(
                _availabilityLabel(_profile?.availability),
                style: TextStyle(
                  color: _accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),

              // Navn
              Text(
                _profile?.displayName ?? 'Ukjent bruker',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),

              // Bio
              if ((_profile?.bio ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _profile!.bio!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 12),

              // Tilgjengelighet badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: _accent, width: 1),
                ),
                child: Text(
                  _availabilityFromProfile(_profile?.availability)
                      ? 'ÅPEN FOR SAMARBEID'
                      : 'OPPTATT NÅ',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _showEditProfileDialog,
                style: brutalistOutlineButtonStyle(active: true),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('REDIGER PROFIL'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _openSkillsEditor,
                style: brutalistOutlineButtonStyle(),
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('REDIGER FERDIGHETER'),
              ),
              const SizedBox(height: 24),

              // Info kort
              _buildInfoCard(),
              const SizedBox(height: 20),

              // Lenke ikoner
              _buildLinks(),
              const SizedBox(height: 28),

              // Ferdigheter
              _buildSkillsSection(),
              const SizedBox(height: 28),

              // Aktivitet
              _buildActivitySection(),
              const SizedBox(height: 32),

              OutlinedButton.icon(
                onPressed: _signOut,
                style: brutalistOutlineButtonStyle().copyWith(
                  side: WidgetStateProperty.all(
                    const BorderSide(color: Colors.redAccent),
                  ),
                  foregroundColor: WidgetStateProperty.all(Colors.redAccent),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('LOGG UT'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final url = _profile?.avatarUrl;
    final hasImage = url != null && url.isNotEmpty;

    return GestureDetector(
      onTap: _isUploadingAvatar ? null : _showAvatarSourceSheet,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              border: Border.all(color: _accent, width: 2),
              color: _panel,
            ),
            child: hasImage
                ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.person,
                size: 40,
                color: Colors.grey,
              ),
            )
                : const Icon(Icons.person, size: 40, color: Colors.grey),
          ),
          // Camera badge in lower right corner
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _accent,
                border: Border.all(color: _panel, width: 2),
              ),
              child: const Icon(
                Icons.photo_camera,
                size: 14,
                color: Colors.black,
              ),
            ),
          ),
          // Upload overlay
          if (_isUploadingAvatar)
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

  Widget _buildInfoCard() {
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
                _profile?.university ?? 'Ikke angitt',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.menu_book, size: 18, color: Colors.grey[400]),
              const SizedBox(width: 10),
              Text(
                _studyProgramAndYear(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildLinks() {
    return BrutalistPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _linkIcon(Icons.code, _profile?.githubUrl),
          const SizedBox(width: 16),
          _linkIcon(Icons.business, _profile?.linkedinUrl),
          const SizedBox(width: 16),
          _linkIcon(Icons.language, _profile?.websiteUrl),
        ],
      ),
    );
  }

  Widget _linkIcon(IconData icon, String? url) {
    final isActive = url != null && url.isNotEmpty;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(
          color: isActive ? _accent : _border,
        ),
        borderRadius: BorderRadius.zero,
      ),
      child: IconButton(
        icon: Icon(icon, size: 22),
        color: isActive ? Colors.white : Colors.grey[700],
        onPressed: isActive ? () {
          // TODO: åpne url med url_launcher
        } : null,
      ),
    );
  }

  Widget _buildSkillsSection() {
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

          // Kategori tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.entries.map((entry) {
                final isSelected = _selectedCategory == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = entry.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _accent.withValues(alpha: 0.2)
                            : const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.zero,
                        border: isSelected
                            ? Border.all(color: _accent, width: 1)
                            : Border.all(color: _border),
                      ),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? _accent
                              : Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Skill chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _filteredSkills.map((s) {
              final color = _proficiencyColor(s.proficiency);
              final skillName = s.skill?.name ?? 'Ukjent';
              return Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: _border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skillName,
                      style:
                      const TextStyle(color: Colors.white, fontSize: 14),
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

          if (_filteredSkills.isEmpty)
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

  Widget _buildActivitySection() {
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
              _statCard('$_ownedProjectsCount', 'PROSJEKTER\nOPPRETTET', _accent),
              const SizedBox(width: 10),
              _statCard('$_memberProjectsCount', 'PROSJEKTER\nDELTATT', _accent),
              const SizedBox(width: 10),
              _statCard(
                _formatDate(_profile?.createdAt),
                'MEDLEM\nSIDEN',
                _accent,
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
      'Jan', 'Feb', 'Mar', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String? _normalizeOptionalText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _studyProgramAndYear() {
    final program = _displayValue(_profile?.studyProgram);
    final year = _profile?.year;

    if (program == 'Ikke angitt' && year == null) {
      return 'Ikke angitt';
    }
    if (year == null) {
      return program;
    }
    if (program == 'Ikke angitt') {
      return 'År $year';
    }
    return '$program - År $year';
  }

  String _displayValue(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return 'Ikke angitt';
    }
    return text;
  }

  bool _availabilityFromProfile(bool? value) {
    return value ?? true;
  }

  String _availabilityLabel(bool? value) {
    return _availabilityFromProfile(value) ? 'STATUS: ÅPEN' : 'STATUS: OPPTATT';
  }

  String _normalizeSkillCategory(String? rawValue) {
    final raw = rawValue?.toLowerCase().trim() ?? '';
    switch (raw) {
      case 'language':
      case 'languages':
        return 'language';
      case 'frontend':
      case 'front_end':
      case 'front-end':
        return 'frontend';
      case 'backend':
      case 'back_end':
      case 'back-end':
        return 'backend';
      case 'data_ai':
      case 'dataai':
      case 'data':
      case 'ai':
        return 'data_ai';
      case 'devops':
        return 'devops';
      case 'database':
      case 'databases':
      case 'db':
        return 'database';
      case 'design':
      case 'ui':
      case 'ux':
        return 'design';
      case 'mobile':
        return 'mobile';
      default:
        return raw;
    }
  }
}



