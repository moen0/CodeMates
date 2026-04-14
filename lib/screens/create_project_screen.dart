import 'create_project_step2_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bg = Color(0xFF000000);
  static const Color _panel = Color(0xFF111111);
  static const Color _border = Color(0xFF333333);
  static const Color _muted = Color(0xFF888888);
  static const Color _accent = Color(0xFF6366F1);

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  late final AnimationController _entryController;

  String? selectedType;
  String? selectedGoal;

  final List<String> projectTypes = const [
    'Skoleprosjekt',
    'Sideprosjekt',
    'Startup',
    'Open Source',
  ];

  final List<_GoalOption> projectGoals = const [
    _GoalOption(
      id: 'mvp',
      label: 'Bygge MVP',
      icon: Icons.rocket_launch_outlined,
    ),
    _GoalOption(
      id: 'portfolio',
      label: 'Lage porteføjle',
      icon: Icons.work_outline,
    ),
    _GoalOption(
      id: 'learn',
      label: 'Lære ny teknologi',
      icon: Icons.lightbulb_outline,
    ),
    _GoalOption(
      id: 'solve',
      label: 'Løse et problem',
      icon: Icons.extension_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _goToStepTwo() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tittel kan ikke være tom')),
      );
      return;
    }

    if (selectedType == null || selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Velg både prosjekttype og prosjektmål'),
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateProjectStep2Screen(
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          selectedType: selectedType!,
          selectedGoal: selectedGoal!,
        ),
      ),
    );

    if (mounted && result == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mono = GoogleFonts.spaceMonoTextTheme(Theme.of(context).textTheme);
    final isFormValid =
        titleController.text.trim().isNotEmpty &&
        selectedType != null &&
        selectedGoal != null;

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
                          'STEG 1 AV 2',
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
                                color: _border,
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
                            child: _sectionLabel('Prosjektnavn'),
                          ),
                          _staggered(
                            index: 2,
                            child: _terminalField(
                              child: TextField(
                                controller: titleController,
                                onChanged: (_) => setState(() {}),
                                style: mono.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                                maxLength: 60,
                                decoration: _inputDecoration(
                                  hintText: 'Gi prosjektet ditt et navn',
                                  counterText: '',
                                ),
                              ),
                            ),
                          ),
                          _staggered(
                            index: 3,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${titleController.text.length}/60',
                                style: mono.bodySmall?.copyWith(color: _muted),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _staggered(
                            index: 4,
                            child: _sectionLabel('Kort beskrivelse'),
                          ),
                          _staggered(
                            index: 5,
                            child: _terminalField(
                              child: TextField(
                                controller: descriptionController,
                                onChanged: (_) => setState(() {}),
                                style: mono.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                                minLines: 3,
                                maxLines: 5,
                                maxLength: 200,
                                decoration: _inputDecoration(
                                  hintText:
                                      'Beskriv ideen din i noen setninger',
                                  counterText: '',
                                ),
                              ),
                            ),
                          ),
                          _staggered(
                            index: 6,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${descriptionController.text.length}/200',
                                style: mono.bodySmall?.copyWith(color: _muted),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _staggered(
                            index: 7,
                            child: _sectionLabel('Prosjekttype'),
                          ),
                          const SizedBox(height: 8),
                          _staggered(
                            index: 8,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: projectTypes.map((type) {
                                  final active = selectedType == type;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          setState(() => selectedType = type),
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
                                        type,
                                        style: mono.labelMedium,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _staggered(
                            index: 11,
                            child: _sectionLabel('Prosjektmål'),
                          ),
                          const SizedBox(height: 6),
                          _staggered(
                            index: 12,
                            child: Text(
                              'Hva er hovedmålet?',
                              style: mono.bodySmall?.copyWith(color: _muted),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _staggered(
                            index: 13,
                            child: GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              childAspectRatio: 1,
                              children: projectGoals.map((goal) {
                                final active = selectedGoal == goal.id;
                                return InkWell(
                                  onTap: () =>
                                      setState(() => selectedGoal = goal.id),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: active
                                          ? _accent.withValues(alpha: 0.12)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: active ? _accent : _border,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          goal.icon,
                                          color: active ? _accent : _muted,
                                          size: 26,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          goal.label,
                                          style: mono.bodySmall?.copyWith(
                                            color: active
                                                ? Colors.white
                                                : _muted,
                                            letterSpacing: 0.8,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _staggered(
                            index: 14,
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: !isFormValid ? null : _goToStepTwo,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFormValid
                                      ? _accent
                                      : Colors.transparent,
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
                                child: const Text('NESTE'),
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

  Widget _terminalField({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration({String? hintText, String? counterText}) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: _border),
    );

    return InputDecoration(
      hintText: hintText,
      counterText: counterText,
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
    final start = index * 0.05;
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
}

class _GoalOption {
  const _GoalOption({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
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
