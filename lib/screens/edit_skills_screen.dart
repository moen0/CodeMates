import 'package:flutter/material.dart';

import 'package:devconnect/widgets/brutalist_ui.dart';
import 'package:devconnect/services/auth_service.dart';
import 'package:devconnect/services/profile_service.dart';
import 'package:devconnect/models/skill.dart';

class EditSkillsScreen extends StatefulWidget {
  const EditSkillsScreen({super.key});

  @override
  State<EditSkillsScreen> createState() => _EditSkillsScreenState();
}

class _EditSkillsScreenState extends State<EditSkillsScreen> {
  static const Map<String, String> _categoryLabels = {
    'language': 'SPRÅK',
    'frontend': 'FRONTEND',
    'backend': 'BACKEND',
    'data_ai': 'DATA & AI',
    'devops': 'DEVOPS',
    'database': 'DATABASE',
    'design': 'DESIGN',
    'mobile': 'MOBIL',
    'other': 'ANNET',
  };

  final TextEditingController _searchController = TextEditingController();

  final _authService = AuthService();
  final _profileService = ProfileService();

  final Map<String, String> _selectedSkills = <String, String>{};

  List<Skill> _skills = <Skill>[];
  bool _isLoading = true;
  bool _isSaving = false;
  String _activeCategory = 'language';
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Du må være logget inn for å redigere ferdigheter.')),
      );
      return;
    }

    try {
      final skillsResponse = await _profileService.getAllSkills();
      final userSkillsResponse = await _profileService.getUserSkills(currentUserId);

      final selected = <String, String>{};
      for (final row in userSkillsResponse) {
        final skillId = row.skillId;
        final proficiency = row.proficiency;
        if (skillId.isEmpty || proficiency.isEmpty) {
          continue;
        }
        selected[skillId] = proficiency;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _skills = skillsResponse;
        _selectedSkills
          ..clear()
          ..addAll(selected);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke laste ferdigheter: $e')),
      );
    }
  }

  String _normaliseCategory(dynamic rawValue) {
    final raw = rawValue?.toString().toLowerCase().trim() ?? '';
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
      case 'other':
      default:
        return 'other';
    }
  }

  Future<String?> _pickProficiency({String? current}) async {
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
              style: brutalistOutlineButtonStyle(active: current == 'beginner'),
              onPressed: () => Navigator.pop(dialogContext, 'beginner'),
              child: const Text('Nybegynner'),
            ),
            OutlinedButton(
              style: brutalistOutlineButtonStyle(active: current == 'intermediate'),
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

  Future<void> _toggleSkill(Skill skill) async {
    final skillId = skill.id;
    final existing = _selectedSkills[skillId];

    if (existing != null) {
      final action = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: BrutalistPalette.panel,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: BrutalistPalette.border),
            ),
            title: Text(skill.name),
            content: const Text('Vil du endre nivå eller fjerne ferdigheten?'),
            actions: [
              OutlinedButton(
                style: brutalistOutlineButtonStyle(),
                onPressed: () => Navigator.pop(dialogContext, 'remove'),
                child: const Text('Fjern'),
              ),
              ElevatedButton(
                style: brutalistPrimaryButtonStyle(),
                onPressed: () => Navigator.pop(dialogContext, 'change'),
                child: const Text('Endre nivå'),
              ),
            ],
          );
        },
      );

      if (action == 'remove') {
        setState(() {
          _selectedSkills.remove(skillId);
        });
      } else if (action == 'change') {
        final picked = await _pickProficiency(current: existing);
        if (picked == null || !mounted) {
          return;
        }
        setState(() {
          _selectedSkills[skillId] = picked;
        });
      }
      return;
    }

    final picked = await _pickProficiency();
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedSkills[skillId] = picked;
    });
  }

  Future<void> _saveSkills() async {
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Du må være logget inn for å lagre ferdigheter.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _profileService.clearUserSkills(currentUserId);

      if (_selectedSkills.isNotEmpty) {
        await Future.wait(
          _selectedSkills.entries.map(
            (entry) => _profileService.addUserSkill(
              userId: currentUserId,
              skillId: entry.key,
              proficiency: entry.value,
            ),
          ),
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ferdigheter oppdatert.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke lagre ferdigheter: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  List<Skill> get _filteredSkills {
    final term = _searchTerm.toLowerCase();
    return _skills.where((skill) {
      final category = _normaliseCategory(skill.category);
      if (category != _activeCategory) {
        return false;
      }
      if (term.isEmpty) {
        return true;
      }
      final name = skill.name.toLowerCase();
      return name.contains(term);
    }).toList();
  }

  Color _proficiencyColor(String proficiency) {
    switch (proficiency) {
      case 'advanced':
        return Colors.greenAccent;
      case 'intermediate':
        return Colors.amberAccent;
      default:
        return BrutalistPalette.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrutalistScaffold(
      appBar: const BrutalistHeader(title: 'Rediger ferdigheter'),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BrutalistPanel(
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchTerm = value.trim();
                          });
                        },
                        decoration: brutalistInputDecoration(
                          labelText: 'Søk ferdigheter',
                          hintText: 'F.eks. Flutter, Python, Docker',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categoryLabels.entries.map((entry) {
                          final isActive = entry.key == _activeCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: OutlinedButton(
                              style: brutalistOutlineButtonStyle(active: isActive),
                              onPressed: () {
                                setState(() {
                                  _activeCategory = entry.key;
                                });
                              },
                              child: Text(entry.value),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedSkills.isNotEmpty)
                      BrutalistPanel(
                        padding: const EdgeInsets.all(10),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedSkills.entries.map((entry) {
                            final skill = _skills.firstWhere(
                              (item) => item.id == entry.key,
                              orElse: () => const Skill(id: '', name: 'Ukjent'),
                            );
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: BrutalistPalette.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    color: _proficiencyColor(entry.value),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(skill.name),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedSkills.remove(entry.key);
                                      });
                                    },
                                    child: const Icon(Icons.close, size: 16),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    if (_selectedSkills.isNotEmpty) const SizedBox(height: 12),
                    Expanded(
                      child: _filteredSkills.isEmpty
                          ? const Center(
                              child: Text(
                                'Ingen ferdigheter i denne kategorien.',
                                style: TextStyle(color: BrutalistPalette.muted),
                              ),
                            )
                          : SingleChildScrollView(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _filteredSkills.map((skill) {
                                  final skillId = skill.id;
                                  final selectedProficiency = _selectedSkills[skillId];
                                  final isSelected = selectedProficiency != null;
                                  return InkWell(
                                    onTap: () => _toggleSkill(skill),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? BrutalistPalette.accent.withValues(alpha: 0.15)
                                            : BrutalistPalette.panel,
                                        border: Border.all(
                                          color: isSelected
                                              ? BrutalistPalette.accent
                                              : BrutalistPalette.border,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(skill.name),
                                          if (isSelected) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 8,
                                              height: 8,
                                              color: _proficiencyColor(selectedProficiency),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: brutalistPrimaryButtonStyle(),
                        onPressed: _isSaving ? null : _saveSkills,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Lagre ferdigheter'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

