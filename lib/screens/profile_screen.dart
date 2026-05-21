import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';
import 'package:devconnect/widgets/edit_profile_dialog.dart';
import 'package:devconnect/widgets/profile/profile_activity_section.dart';
import 'package:devconnect/widgets/profile/profile_avatar.dart';
import 'package:devconnect/widgets/profile/profile_info_card.dart';
import 'package:devconnect/widgets/profile/profile_skills_section.dart';
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
  }

  Future<void> _showEditProfileDialog() async {
    await showEditProfileDialog(
      context: context,
      currentProfile: _profile,
      onSave: _saveProfileEdits,
    );
    if (mounted) {
      await _loadProfile();
    }
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
              ProfileAvatar(
                avatarUrl: _profile?.avatarUrl,
                isUploading: _isUploadingAvatar,
                accentColor: _accent,
                onTap: _showAvatarSourceSheet,
              ),
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
              ProfileInfoCard(
                university: _profile?.university,
                studyProgramAndYear: _studyProgramAndYear(),
              ),
              const SizedBox(height: 20),

              // Lenke ikoner
              _buildLinks(),
              const SizedBox(height: 28),

              // Ferdigheter
              ProfileSkillsSection(
                skills: _filteredSkills,
                selectedCategory: _selectedCategory,
                categories: _categories,
                accentColor: _accent,
                onCategoryChanged: (category) {
                  setState(() => _selectedCategory = category);
                },
              ),
              const SizedBox(height: 28),

              // Aktivitet
              ProfileActivitySection(
                ownedCount: _ownedProjectsCount,
                memberCount: _memberProjectsCount,
                createdAt: _profile?.createdAt,
                accentColor: _accent,
              ),
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
}
