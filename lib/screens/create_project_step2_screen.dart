import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:devconnect/services/project_service.dart';

class CreateProjectStep2Screen extends StatefulWidget {
  const CreateProjectStep2Screen({
    super.key,
    required this.title,
    required this.description,
    required this.selectedType,
    required this.selectedGoal,
  });

  final String title;
  final String description;
  final String selectedType;
  final String selectedGoal;

  @override
  State<CreateProjectStep2Screen> createState() =>
      _CreateProjectStep2ScreenState();
}

class _CreateProjectStep2ScreenState extends State<CreateProjectStep2Screen>
    with SingleTickerProviderStateMixin {
  static const Color _bg = Color(0xFF000000);
  static const Color _panel = Color(0xFF111111);
  static const Color _border = Color(0xFF333333);
  static const Color _muted = Color(0xFF888888);
  static const Color _accent = Color(0xFF6366F1);

  late final AnimationController _entryController;
  final projectService = ProjectService();

  bool isLoading = false;
  String selectedSkillCategory = 'language';
  String searchQuery = '';
  String? selectedTeamSize;
  String? selectedTimeframe;
  final customMonthsController = TextEditingController();

  List<Map<String, dynamic>> allSkills = [];
  List<int> selectedSkillIds = [];

  final List<_SkillCategoryOption> skillCategories = const [
    _SkillCategoryOption(id: 'language', label: 'Language'),
    _SkillCategoryOption(id: 'frontend', label: 'Frontend'),
    _SkillCategoryOption(id: 'backend', label: 'Backend'),
    _SkillCategoryOption(id: 'dataAi', label: 'Data/AI'),
    _SkillCategoryOption(id: 'devops', label: 'DevOps'),
    _SkillCategoryOption(id: 'database', label: 'Database'),
    _SkillCategoryOption(id: 'design', label: 'Design'),
    _SkillCategoryOption(id: 'mobile', label: 'Mobile'),
    _SkillCategoryOption(id: 'other', label: 'Other'),
  ];

  final List<String> teamSizes = const ['2', '3', '4', '5+'];
  final List<_TimeframeOption> timeframeOptions = const [
    _TimeframeOption(id: '1m', label: '1 måned'),
    _TimeframeOption(id: '6m', label: '6 måneder'),
    _TimeframeOption(id: 'custom', label: 'Velg selv'),
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    loadSkills();
  }

  @override
  void dispose() {
    _entryController.dispose();
    customMonthsController.dispose();
    super.dispose();
  }

  Future<void> loadSkills() async {
    final response = await projectService.getSkills();

    if (mounted) {
      setState(() {
        allSkills = response;
      });
    }
  }

  Future<void> _onCreatePressed() async {
    if (isLoading) {
      return;
    }

    if (selectedTeamSize == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Velg teamstørrelse')));
      return;
    }

    if (selectedTimeframe == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Velg tidsramme')));
      return;
    }

    if (selectedTimeframe == 'custom') {
      final months = int.tryParse(customMonthsController.text.trim());
      if (months == null || months <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skriv inn antall måneder')),
        );
        return;
      }
    }

    if (selectedSkillIds.isEmpty) {
      final continueWithoutSkills = await _showNoSkillsWarningDialog() ?? false;
      if (!continueWithoutSkills) {
        return;
      }
    }

    await createProject();
  }

  Future<bool?> _showNoSkillsWarningDialog() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _panel,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: _border),
          ),
          title: const Text('Ingen ferdigheter valgt'),
          content: const Text(
            'Du har ikke valgt noen ferdigheter. Prosjektet blir vanskeligere å finne for andre.',
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: _muted,
                side: const BorderSide(color: _border),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text('Legg til ferdigheter'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text('Fortsett likevel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> createProject() async {
    setState(() {
      isLoading = true;
    });

    try {
      await projectService.createProject(
        title: widget.title,
        description: widget.description,
        maxMembers: _teamSizeToMaxMembers(selectedTeamSize!),
        selectedType: widget.selectedType,
        selectedGoal: widget.selectedGoal,
        selectedSkillIds: selectedSkillIds,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Prosjekt opprettet!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Feil: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mono = GoogleFonts.spaceMonoTextTheme(Theme.of(context).textTheme);
    final normalizedQuery = searchQuery.trim().toLowerCase();

    final filteredSkills = normalizedQuery.isNotEmpty
        ? allSkills.where((skill) {
            final name = (skill['name']?.toString() ?? '').toLowerCase();
            return name.contains(normalizedQuery);
          }).toList()
        : allSkills
              .where(
                (skill) =>
                    projectService.resolveSkillCategory(skill) ==
                    selectedSkillCategory,
              )
              .toList();

    final selectedSkills = allSkills
        .where((skill) => selectedSkillIds.contains(skill['id']))
        .toList();

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _ScanlinePainter()),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _staggered(
                  index: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: _border)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              color: Colors.white,
                              style: IconButton.styleFrom(
                                backgroundColor: _panel,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                  side: BorderSide(color: _border),
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'Nytt prosjekt',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'STEG 2 AV 2',
                          style: mono.bodySmall?.copyWith(
                            color: _muted,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: const [
                            Expanded(
                              child: Divider(
                                color: _accent,
                                thickness: 2,
                                height: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Divider(
                                color: _accent,
                                thickness: 2,
                                height: 2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: DefaultTextStyle(
                      style:
                          mono.bodyMedium?.copyWith(color: Colors.white) ??
                          const TextStyle(color: Colors.white),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _staggered(
                            index: 1,
                            child: _sectionLabel('Ønskede ferdigheter'),
                          ),
                          const SizedBox(height: 8),
                          _staggered(
                            index: 2,
                            child: TextField(
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value;
                                });
                              },
                              style: mono.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                              decoration: _inputDecoration(
                                hintText: 'Søk etter ferdigheter...',
                              ).copyWith(prefixIcon: const Icon(Icons.search)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (selectedSkills.isNotEmpty)
                            _staggered(
                              index: 3,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: selectedSkills.map((skill) {
                                  return OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        selectedSkillIds.remove(skill['id']);
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: _accent,
                                      side: const BorderSide(color: _accent),
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.zero,
                                      ),
                                    ),
                                    icon: const Icon(Icons.close, size: 14),
                                    label: Text(
                                      skill['name'].toString(),
                                      style: mono.labelSmall,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          if (selectedSkills.isNotEmpty)
                            const SizedBox(height: 12),
                          if (normalizedQuery.isEmpty)
                            _staggered(
                              index: 4,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: skillCategories.map((category) {
                                    final active =
                                        selectedSkillCategory == category.id;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8,
                                        bottom: 12,
                                      ),
                                      child: OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            selectedSkillCategory = category.id;
                                          });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: active
                                              ? Colors.white
                                              : _muted,
                                          backgroundColor: active
                                              ? _accent
                                              : Colors.transparent,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.zero,
                                          ),
                                          side: BorderSide(
                                            color: active ? _accent : _border,
                                          ),
                                        ),
                                        child: Text(
                                          category.label,
                                          style: mono.labelSmall,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          _staggered(
                            index: 5,
                            child: filteredSkills.isEmpty
                                ? Text(
                                    normalizedQuery.isNotEmpty
                                        ? 'Ingen treff for soket ditt'
                                        : 'Ingen ferdigheter i ${_categoryLabel(selectedSkillCategory)} enda',
                                    style: mono.bodySmall?.copyWith(
                                      color: _muted,
                                    ),
                                  )
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: filteredSkills.map((skill) {
                                      final isSelected = selectedSkillIds
                                          .contains(skill['id']);
                                      return FilterChip(
                                        selected: isSelected,
                                        label: Text(
                                          skill['name'].toString(),
                                          style: mono.bodySmall,
                                        ),
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              selectedSkillIds.add(skill['id']);
                                            } else {
                                              selectedSkillIds.remove(
                                                skill['id'],
                                              );
                                            }
                                          });
                                        },
                                        showCheckmark: false,
                                        color: WidgetStateProperty.resolveWith((
                                          states,
                                        ) {
                                          if (states.contains(
                                            WidgetState.selected,
                                          )) {
                                            return _accent.withValues(
                                              alpha: 0.18,
                                            );
                                          }
                                          return _panel;
                                        }),
                                        side: BorderSide(
                                          color: isSelected ? _accent : _border,
                                        ),
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : _muted,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                          const SizedBox(height: 24),
                          _staggered(
                            index: 6,
                            child: _sectionLabel('Teamstorrelse'),
                          ),
                          const SizedBox(height: 10),
                          _staggered(
                            index: 7,
                            child: Row(
                              children: teamSizes.map((size) {
                                final active = selectedTeamSize == size;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          selectedTeamSize = size;
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: active
                                            ? Colors.white
                                            : _muted,
                                        backgroundColor: active
                                            ? _accent
                                            : Colors.transparent,
                                        side: BorderSide(
                                          color: active ? _accent : _border,
                                        ),
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero,
                                        ),
                                      ),
                                      child: Text(
                                        size,
                                        style: mono.labelMedium,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _staggered(
                            index: 8,
                            child: _sectionLabel('Tidsramme'),
                          ),
                          const SizedBox(height: 10),
                          _staggered(
                            index: 9,
                            child: Row(
                              children: timeframeOptions.map((timeframe) {
                                final active =
                                    selectedTimeframe == timeframe.id;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          selectedTimeframe = timeframe.id;
                                          if (timeframe.id != 'custom') {
                                            customMonthsController.clear();
                                          }
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: active
                                            ? Colors.white
                                            : _muted,
                                        backgroundColor: active
                                            ? _accent
                                            : Colors.transparent,
                                        side: BorderSide(
                                          color: active ? _accent : _border,
                                        ),
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero,
                                        ),
                                      ),
                                      child: Text(
                                        timeframe.label,
                                        textAlign: TextAlign.center,
                                        style: mono.labelSmall,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          if (selectedTimeframe == 'custom') ...[
                            const SizedBox(height: 10),
                            _staggered(
                              index: 10,
                              child: TextField(
                                controller: customMonthsController,
                                keyboardType: TextInputType.number,
                                style: mono.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                                decoration: _inputDecoration(
                                  hintText: 'Antall maaneder',
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          _staggered(
                            index: 11,
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _onCreatePressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accent,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.transparent,
                                  disabledForegroundColor: const Color(
                                    0xFF555555,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                    side: BorderSide(color: _border),
                                  ),
                                  textStyle: mono.labelLarge?.copyWith(
                                    letterSpacing: 2,
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('OPPRETT PROSJEKT'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.spaceMono(
        color: Colors.white,
        fontSize: 13,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: _border),
    );

    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.spaceMono(color: _muted),
      filled: true,
      fillColor: _panel,
      border: border,
      enabledBorder: border,
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: _accent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _staggered({required int index, required Widget child}) {
    final start = index * 0.06;
    final end = (start + 0.22).clamp(0.0, 1.0);
    final curve = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }

  String _categoryLabel(String categoryId) {
    for (final category in skillCategories) {
      if (category.id == categoryId) {
        return category.label;
      }
    }
    return categoryId;
  }

  int _teamSizeToMaxMembers(String teamSize) {
    switch (teamSize) {
      case '2':
        return 2;
      case '3':
        return 3;
      case '4':
        return 4;
      case '5+':
        return 5;
      default:
        return 4;
    }
  }
}

class _SkillCategoryOption {
  const _SkillCategoryOption({required this.id, required this.label});

  final String id;
  final String label;
}

class _TimeframeOption {
  const _TimeframeOption({required this.id, required this.label});

  final String id;
  final String label;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 24.0;
    final paint = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.11)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
