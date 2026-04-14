import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/services/application_service.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final applicationService = ApplicationService();
  final messageController = TextEditingController();
  bool isLoading = false;
  bool hasApplied = false;

  @override
  void initState() {
    super.initState();
    checkIfApplied();
  }

  Future<void> checkIfApplied() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final existing = await Supabase.instance.client
        .from('applications')
        .select('id')
        .eq('project_id', widget.project['id'])
        .eq('applicant_id', userId);
    if (mounted) {
      setState(() {
        hasApplied = existing.isNotEmpty;
      });
    }
  }

  Future<void> showApplyDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BrutalistPalette.panel,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: BrutalistPalette.border),
        ),
        title: const Text('Send søknad'),
        content: TextField(
          controller: messageController,
          maxLines: 3,
          decoration: brutalistInputDecoration(
            hintText: 'Skriv en kort melding til prosjekteieren...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: BrutalistPalette.muted,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            style: brutalistPrimaryButtonStyle(),
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                isLoading = true;
              });
              try {
                await applicationService.apply(
                  widget.project['id'],
                  messageController.text,
                );
                setState(() {
                  hasApplied = true;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Søknad sendt!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Feil: $e')));
                }
              } finally {
                setState(() {
                  isLoading = false;
                });
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final isOwner =
        project['owner_id'] == Supabase.instance.client.auth.currentUser!.id;

    return BrutalistScaffold(
      appBar: BrutalistHeader(title: project['title']),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BrutalistPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project['title'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Chip(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: BrutalistPalette.border),
                ),
                backgroundColor: BrutalistPalette.panel,
                label: Text(project['status']),
              ),
              const SizedBox(height: 16),
              Text(project['description'] ?? 'Ingen beskrivelse'),
              const SizedBox(height: 16),
              Text(
                'Maks medlemmer: ${project['max_members']}',
                style: const TextStyle(color: BrutalistPalette.muted),
              ),
              const Spacer(),

              // Vis riktig knapp basert på rolle
              if (!isOwner && project['status'] == 'recruiting')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: brutalistPrimaryButtonStyle(),
                    onPressed: hasApplied || isLoading ? null : showApplyDialog,
                    child: hasApplied
                        ? const Text('Søknad sendt')
                        : const Text('Bli med'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
