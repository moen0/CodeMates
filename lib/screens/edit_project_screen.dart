import 'package:flutter/material.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';
import '../services/project_service.dart';
import 'package:devconnect/models/project.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProjectScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  const EditProjectScreen({super.key, required this.project});

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _meetingLinkController;
  final _service = ProjectService();
  bool _isSaving = false;
  late final Project _project;

  @override
  void initState() {
    super.initState();
    _project = Project.fromMap(widget.project);
    _titleController = TextEditingController(text: _project.title);
    _descriptionController = TextEditingController(text: _project.description);
    _meetingLinkController = TextEditingController(text: _project.meetingLink ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _meetingLinkController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _service.updateProject(
        projectId: _project.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        meetingLink: _meetingLinkController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feil: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrutalistPalette.panel,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: BrutalistPalette.border),
        ),
        title: const Text('Slett prosjekt'),
        content: const Text('Er du sikker? Dette kan ikke angres.'),
        actions: [
          OutlinedButton(
            style: brutalistOutlineButtonStyle(),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Slett'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    print('Project ID: ${_project.id}');
    print('Project owner: ${_project.ownerId}');
    print('Current user: ${Supabase.instance.client.auth.currentUser?.id}');
    print('Auth token exists: ${Supabase.instance.client.auth.currentSession != null}');
    final session = Supabase.instance.client.auth.currentSession;
    print('User ID: ${session?.user.id}');
    print('User role: ${session?.user.role}');
    print('Token expired: ${session?.isExpired}');
    print('Access token (first 30): ${session?.accessToken.substring(0, 30)}');
    setState(() => _isSaving = true);
    try {
      await _service.deleteProject(_project.id);
      if (!mounted) return;
      // Pop both edit screen and detail screen
      Navigator.pop(context, 'deleted');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feil: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrutalistScaffold(
      appBar: BrutalistHeader(title: 'Rediger prosjekt'),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TITTEL',
                  style: TextStyle(
                    color: BrutalistPalette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: brutalistInputDecoration(hintText: 'Prosjektnavn'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Tittel er påkrevd' : null,
                ),
                const SizedBox(height: 20),
                const Text(
                  'BESKRIVELSE',
                  style: TextStyle(
                    color: BrutalistPalette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: brutalistInputDecoration(hintText: 'Beskriv prosjektet...'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'MØTELENKE',
                  style: TextStyle(
                    color: BrutalistPalette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Discord, Teams, Google Meet, osv.',
                  style: TextStyle(color: BrutalistPalette.muted, fontSize: 11),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _meetingLinkController,
                  keyboardType: TextInputType.url,
                  decoration: brutalistInputDecoration(hintText: 'https://discord.gg/...'),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: brutalistPrimaryButtonStyle(),
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 2,
                            child: LinearProgressIndicator(),
                          )
                        : const Text('LAGRE ENDRINGER'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isSaving ? null : _confirmDelete,
                    child: const Text('SLETT PROSJEKT'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
