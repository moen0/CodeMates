import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:devconnect/widgets/brutalist_ui.dart';

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
  final Map<int, String> _selectedSkills = <int, String>{};

  List<Map<String, dynamic>> _skills = <Map<String, dynamic>>[];
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
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
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
      final skillsResponse = await Supabase.instance.client
          .from('skills')
          .select('id, name, category')
          .order('name');

      final userSkillsResponse = await Supabase.instance.client
          .from('user_skills')
          .select('skill_id, proficiency')
          .eq('user_id', currentUser.id);

      final selected = <int, String>{};
      for (final row in userSkillsResponse) {
        final skillId = row['skill_id'] as int?;
        final proficiency = row['proficiency']?.toString();
        if (skillId == null || proficiency == null) {
          continue;
        }
        selected[skillId] = proficiency;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _skills = List<Map<String, dynamic>>.from(skillsResponse);
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

  Future<void> _toggleSkill(Map<String, dynamic> skill) async {
    final skillId = skill['id'] as int;
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
            title: Text(skill['name'].toString()),
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
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Du må være logget inn for å lagre ferdigheter.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await Supabase.instance.client
          .from('user_skills')
          .delete()
          .eq('user_id', currentUser.id);

      if (_selectedSkills.isNotEmpty) {
        await Supabase.instance.client.from('user_skills').insert(
              _selectedSkills.entries
                  .map(
                    (entry) => {
                      'user_id': currentUser.id,
                      'skill_id': entry.key,
                      'proficiency': entry.value,
                    },
                  )
                  .toList(),
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

  List<Map<String, dynamic>> get _filteredSkills {
    final term = _searchTerm.toLowerCase();
    return _skills.where((skill) {
      final category = _normaliseCategory(skill['category']);
      if (category != _activeCategory) {
        return false;
      }
      if (term.isEmpty) {
        return true;
      }
      final name = skill['name']?.toString().toLowerCase() ?? '';
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
                              (item) => item['id'] == entry.key,
                              orElse: () => {'name': 'Ukjent'},
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
                                  Text(skill['name'].toString()),
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
                                  final skillId = skill['id'] as int;
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
                                          Text(skill['name'].toString()),
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

