import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:devconnect/widgets/brutalist_ui.dart';
import 'home_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _bioController = TextEditingController();
  final _universityController = TextEditingController();
  final _studyProgramController = TextEditingController();
  final _githubController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _websiteController = TextEditingController();

  final Map<int, _SelectedSkill> _selectedSkills = <int, _SelectedSkill>{};

  int _step = 0;
  bool _isLoadingSkills = true;
  bool _isSaving = false;
  bool _isOpenForCollaboration = true;
  int? _selectedYear;
  String _activeCategory = 'language';

  List<Map<String, dynamic>> _allSkills = <Map<String, dynamic>>[];

  static const _skillCategories = <_SkillCategory>[
    _SkillCategory(key: 'language', label: 'SPRÅK'),
    _SkillCategory(key: 'frontend', label: 'FRONTEND'),
    _SkillCategory(key: 'backend', label: 'BACKEND'),
    _SkillCategory(key: 'data_ai', label: 'DATA & AI'),
    _SkillCategory(key: 'devops', label: 'DEVOPS'),
    _SkillCategory(key: 'database', label: 'DATABASE'),
    _SkillCategory(key: 'design', label: 'DESIGN'),
    _SkillCategory(key: 'mobile', label: 'MOBIL'),
  ];

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _isLoadingSkills = false;
      return;
    }
    _loadSkills();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _universityController.dispose();
    _studyProgramController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  String? _normalise(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  Future<void> _loadSkills() async {
    try {
      final response = await Supabase.instance.client
          .from('skills')
          .select('id, name, category')
          .order('name');

      if (!mounted) {
        return;
      }

      setState(() {
        _allSkills = List<Map<String, dynamic>>.from(response);
        _isLoadingSkills = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingSkills = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke laste ferdigheter: $e')),
      );
    }
  }

  String _normaliseCategory(String raw) {
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
      case 'ai':
      case 'data':
        return 'data_ai';
      case 'devops':
        return 'devops';
      case 'database':
      case 'databases':
      case 'db':
        return 'database';
      case 'design':
      case 'ux':
      case 'ui':
        return 'design';
      case 'mobile':
        return 'mobile';
      default:
        return raw;
    }
  }

  List<Map<String, dynamic>> _skillsForActiveCategory() {
    return _allSkills.where((skill) {
      final raw = (skill['category']?.toString() ?? '').toLowerCase().trim();
      return _normaliseCategory(raw) == _activeCategory;
    }).toList();
  }

  Future<String?> _pickProficiency() async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: BrutalistPalette.panel,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: BrutalistPalette.border),
          ),
          title: const Text('Velg nivå'),
          actionsAlignment: MainAxisAlignment.start,
          actions: [
            OutlinedButton(
              style: brutalistOutlineButtonStyle(),
              onPressed: () => Navigator.pop(dialogContext, 'beginner'),
              child: const Text('Nybegynner'),
            ),
            OutlinedButton(
              style: brutalistOutlineButtonStyle(),
              onPressed: () => Navigator.pop(dialogContext, 'intermediate'),
              child: const Text('Middels'),
            ),
            ElevatedButton(
              style: brutalistPrimaryButtonStyle(),
              onPressed: () => Navigator.pop(dialogContext, 'advanced'),
              child: const Text('Erfaren'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleSkill(Map<String, dynamic> skill) async {
    final skillId = skill['id'] as int;

    if (_selectedSkills.containsKey(skillId)) {
      setState(() {
        _selectedSkills.remove(skillId);
      });
      return;
    }

    final proficiency = await _pickProficiency();
    if (proficiency == null || !mounted) {
      return;
    }

    setState(() {
      _selectedSkills[skillId] = _SelectedSkill(skill: skill, proficiency: proficiency);
    });
  }

  Future<void> _saveProfile() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Du må være logget inn for å fullføre profil')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updates = {
      'bio': _normalise(_bioController.text),
      'email': currentUser.email,
      'university': _normalise(_universityController.text),
      'study_program': _normalise(_studyProgramController.text),
      'year': _selectedYear,
      'github_url': _normalise(_githubController.text),
      'linkedin_url': _normalise(_linkedinController.text),
      'website_url': _normalise(_websiteController.text),
      'availability': _isOpenForCollaboration,
    };

    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': currentUser.id,
        ...updates,
      });

      await Supabase.instance.client
          .from('user_skills')
          .delete()
          .eq('user_id', currentUser.id);

      if (_selectedSkills.isNotEmpty) {
        await Supabase.instance.client.from('user_skills').insert(
              _selectedSkills.values
                  .map(
                    (selected) => {
                      'user_id': currentUser.id,
                      'skill_id': selected.skill['id'],
                      'proficiency': selected.proficiency,
                    },
                  )
                  .toList(),
            );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil lagret!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke lagre profil: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrutalistScaffold(
      appBar: const BrutalistHeader(title: 'Profiloppsett'),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _StepIndicator(currentStep: _step),
              const SizedBox(height: 12),
              Expanded(
                child: IndexedStack(
                  index: _step,
                  children: [
                    _buildStepOne(),
                    _buildStepTwo(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_step == 0)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: brutalistPrimaryButtonStyle(),
                    onPressed: () {
                      setState(() {
                        _step = 1;
                      });
                    },
                    child: const Text('Neste'),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: brutalistOutlineButtonStyle(),
                        onPressed: _isSaving
                            ? null
                            : () {
                                setState(() {
                                  _step = 0;
                                });
                              },
                        child: const Text('Tilbake'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: brutalistPrimaryButtonStyle(),
                        onPressed: _isSaving ? null : _saveProfile,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Fullfør profil'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepOne() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Steg 1 av 2'.toUpperCase(),
            style: const TextStyle(
              color: BrutalistPalette.muted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: BrutalistPalette.panel,
                  child: const Icon(Icons.person, size: 40, color: BrutalistPalette.muted),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('TODO: bildevelger kommer senere')),
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: BrutalistPalette.accent,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide(color: BrutalistPalette.border),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          BrutalistPanel(
            child: TextField(
              controller: _bioController,
              maxLength: 150,
              minLines: 2,
              maxLines: 2,
              decoration: brutalistInputDecoration(
                labelText: 'Bio',
                hintText: 'Kort om deg',
              ).copyWith(counterText: ''),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_bioController.text.length}/150',
              style: const TextStyle(color: BrutalistPalette.muted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),
          BrutalistPanel(
            child: TextField(
              controller: _universityController,
              decoration: brutalistInputDecoration(
                labelText: 'Universitet / studiested',
              ),
            ),
          ),
          const SizedBox(height: 10),
          BrutalistPanel(
            child: TextField(
              controller: _studyProgramController,
              decoration: brutalistInputDecoration(
                labelText: 'Studieretning',
                hintText: 'f.eks. Dataingeniør',
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'ÅRSTRINN',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1, 2, 3, 4, 5].map((year) {
              final active = _selectedYear == year;
              return OutlinedButton(
                style: brutalistOutlineButtonStyle(active: active),
                onPressed: () {
                  setState(() {
                    _selectedYear = year;
                  });
                },
                child: Text('År $year'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTwo() {
    final skillsInCategory = _skillsForActiveCategory();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Steg 2 av 2'.toUpperCase(),
            style: const TextStyle(
              color: BrutalistPalette.muted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'FERDIGHETER',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedSkills.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedSkills.values.map((selected) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: BrutalistPalette.panel,
                    border: Border.all(color: BrutalistPalette.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        color: BrutalistPalette.accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${selected.skill['name']} (${_proficiencyLabel(selected.proficiency)})',
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSkills.remove(selected.skill['id'] as int);
                          });
                        },
                        child: const Icon(Icons.close, size: 16),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          if (_selectedSkills.isNotEmpty) const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _skillCategories.map((category) {
                final active = _activeCategory == category.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    style: brutalistOutlineButtonStyle(active: active),
                    onPressed: () {
                      setState(() {
                        _activeCategory = category.key;
                      });
                    },
                    child: Text(category.label),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoadingSkills)
            const Center(child: CircularProgressIndicator())
          else if (skillsInCategory.isEmpty)
            const Text(
              'Ingen ferdigheter i denne kategorien.',
              style: TextStyle(color: BrutalistPalette.muted),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skillsInCategory.map((skill) {
                final skillId = skill['id'] as int;
                final selected = _selectedSkills.containsKey(skillId);
                return GestureDetector(
                  onTap: () => _toggleSkill(skill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? BrutalistPalette.accent.withValues(alpha: 0.18)
                          : BrutalistPalette.panel,
                      border: Border.all(
                        color: selected
                            ? BrutalistPalette.accent
                            : BrutalistPalette.border,
                      ),
                    ),
                    child: Text(skill['name'].toString()),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
          const Text(
            'LENKER',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          BrutalistPanel(
            child: TextField(
              controller: _githubController,
              decoration: brutalistInputDecoration(
                labelText: 'GitHub URL',
              ).copyWith(prefixIcon: const Icon(Icons.code)),
            ),
          ),
          const SizedBox(height: 10),
          BrutalistPanel(
            child: TextField(
              controller: _linkedinController,
              decoration: brutalistInputDecoration(
                labelText: 'LinkedIn URL',
              ).copyWith(prefixIcon: const Icon(Icons.business_center)),
            ),
          ),
          const SizedBox(height: 10),
          BrutalistPanel(
            child: TextField(
              controller: _websiteController,
              decoration: brutalistInputDecoration(
                labelText: 'Nettside',
              ).copyWith(prefixIcon: const Icon(Icons.language)),
            ),
          ),
          const SizedBox(height: 12),
          BrutalistPanel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Åpen for samarbeid',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Switch(
                  value: _isOpenForCollaboration,
                  activeThumbColor: BrutalistPalette.accent,
                  onChanged: (value) {
                    setState(() {
                      _isOpenForCollaboration = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _proficiencyLabel(String proficiency) {
    switch (proficiency) {
      case 'advanced':
        return 'Erfaren';
      case 'intermediate':
        return 'Middels';
      default:
        return 'Nybegynner';
    }
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          currentStep == 0 ? 'Steg 1 av 2' : 'Steg 2 av 2',
          style: const TextStyle(
            color: BrutalistPalette.muted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Divider(
                color: BrutalistPalette.accent,
                thickness: 2,
                height: 2,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Divider(
                color: currentStep == 0
                    ? BrutalistPalette.border
                    : BrutalistPalette.accent,
                thickness: 2,
                height: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SkillCategory {
  const _SkillCategory({required this.key, required this.label});

  final String key;
  final String label;
}

class _SelectedSkill {
  const _SelectedSkill({required this.skill, required this.proficiency});

  final Map<String, dynamic> skill;
  final String proficiency;
}

