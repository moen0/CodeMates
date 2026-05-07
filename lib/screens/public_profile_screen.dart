import 'package:flutter/material.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';
import 'package:devconnect/services/profile_service.dart';
import 'package:devconnect/models/profile.dart';
import 'package:devconnect/models/user_skill.dart';

/// Viser en annen brukers profil i lesemodus (ingen redigering).
class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final _profileService = ProfileService();

  Profile? _profile;
  List<UserSkill> _skills = [];
  String _selectedCategory = 'language';
  bool _isLoading = true;

  final _categories = const {
    'language': 'SPRÅK',
    'frontend': 'FRONTEND',
    'backend': 'BACKEND',
    'data_ai': 'DATA & AI',
    'devops': 'DEVOPS',
    'database': 'DATABASE',
    'design': 'DESIGN',
    'mobile': 'MOBIL',
  };

  Color get _accent => Theme.of(context).colorScheme.primary;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Henter profil og ferdigheter for [widget.userId] fra Supabase.
  Future<void> _loadProfile() async {
    try {
      final profileRes = await _profileService.getProfile(widget.userId);
      final skillsRes = await _profileService.getUserSkills(widget.userId);

      if (!mounted) return;
      setState(() {
        _profile = profileRes;
        _skills = skillsRes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke laste profil: $e')),
      );
    }
  }

  /// Returnerer ferdigheter filtrert på valgt kategori-tab.
  List<UserSkill> get _filteredSkills =>
      _skills.where((s) => s.skill?.category == _selectedCategory).toList();

  /// Returnerer farge basert på ferdighetsnivå: grønn, gul eller grå.
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

  /// Tolker tilgjengelighetsfeltet uavhengig av om det er bool eller streng.
  bool _availabilityOpen(bool? value) {
    return value ?? true;
  }

  /// Bygger en lesbar tekst av studieprogram og årstrinn.
  String _studyLine() {
    final program = _profile?.studyProgram?.trim() ?? '';
    final year = _profile?.year?.toString().trim() ?? '';
    if (program.isEmpty && year.isEmpty) return 'Ikke angitt';
    if (year.isEmpty) return program;
    if (program.isEmpty) return 'År $year';
    return '$program - År $year';
  }

  /// Formaterer en ISO-datostreng til norsk kortformat, f.eks. "Jan 2025".
  String _formatDate(DateTime? date) {
    if (date == null) return '?';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const BrutalistScaffold(
        appBar: BrutalistHeader(title: 'Profil'),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final name = _profile?.displayLabel ?? 'Ukjent bruker';
    final avatarUrl = _profile?.avatarUrl;
    final hasImage = avatarUrl != null && avatarUrl.isNotEmpty;
    final isOpen = _availabilityOpen(_profile?.availability);

    return BrutalistScaffold(
      appBar: BrutalistHeader(title: name),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  border: Border.all(color: _accent, width: 2),
                  color: BrutalistPalette.panel,
                ),
                child: hasImage
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.person, size: 40, color: Colors.grey),
                      )
                    : const Icon(Icons.person, size: 40, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              // Status
              Text(
                isOpen ? 'STATUS: ÅPEN' : 'STATUS: OPPTATT',
                style: TextStyle(
                  color: _accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),

              // Navn
              Text(
                name,
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
                  ),
                ),
              const SizedBox(height: 12),

              // Tilgjengelighetsbadge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: _accent, width: 1),
                ),
                child: Text(
                  isOpen ? 'ÅPEN FOR SAMARBEID' : 'OPPTATT NÅ',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Info-kort
              BrutalistPanel(
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
                        _studyLine(),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Icon(Icons.calendar_today, size: 18, color: Colors.grey[400]),
                      const SizedBox(width: 10),
                      Text(
                        'Medlem siden ${_formatDate(_profile?.createdAt)}',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Lenke-ikoner
              BrutalistPanel(
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
              ),
              const SizedBox(height: 28),

              // Ferdigheter
              _buildSkillsSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// Bygger et lenke-ikon. Aktivt (accent) dersom [url] er satt, ellers grået ut.
  Widget _linkIcon(IconData icon, String? url) {
    final isActive = url != null && url.isNotEmpty;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: BrutalistPalette.panel,
        border: Border.all(color: isActive ? _accent : BrutalistPalette.border),
      ),
      child: IconButton(
        icon: Icon(icon, size: 22),
        color: isActive ? Colors.white : Colors.grey[700],
        onPressed: null, // TODO: url_launcher
      ),
    );
  }

  /// Bygger ferdighetsseksjonen med kategori-tabs og skill-chips.
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
                    onTap: () => setState(() => _selectedCategory = entry.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _accent.withValues(alpha: 0.2)
                            : const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.zero,
                        border: isSelected
                            ? Border.all(color: _accent, width: 1)
                            : Border.all(color: BrutalistPalette.border),
                      ),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? _accent : Colors.grey[400],
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
              final name = s.skill?.name ?? 'Ukjent';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: BrutalistPalette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
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
}
