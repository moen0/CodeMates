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
  bool isLoading = false;
  bool hasApplied = false;

  Color _accent(BuildContext context) => Theme.of(context).colorScheme.primary;

  @override
  void initState() {
    super.initState();
    checkIfApplied();
  }

  Future<void> checkIfApplied() async {
    try {
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
    } catch (_) {
      // Keep default state when check fails; user can still open project details.
    }
  }

  Future<void> showApplyDialog() async {
    final messageController = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
          OutlinedButton(
            style: brutalistOutlineButtonStyle(),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            style: brutalistPrimaryButtonStyle(),
            onPressed: () => Navigator.pop(
              dialogContext,
              messageController.text.trim(),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    messageController.dispose();

    if (!mounted || message == null || message.isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await applicationService.apply(widget.project['id'], message);
      if (!mounted) {
        return;
      }
      setState(() {
        hasApplied = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Søknad sendt!')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Feil: $e')));
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
    final project = widget.project;
    final isOwner =
        project['owner_id'] == Supabase.instance.client.auth.currentUser!.id;
    final accent = _accent(context);
    final ownerName =
        project['profiles']?['display_name'] ??
        project['profiles']?['email'] ??
        'Ukjent';

    return BrutalistScaffold(
      appBar: BrutalistHeader(title: project['title'].toString()),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: BrutalistPanel(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      Text(
                        project['title'].toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.18),
                              border: Border.all(color: accent),
                            ),
                            child: Text(
                              _statusLabel(project['status']),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: BrutalistPalette.border,
                              ),
                            ),
                            child: Text(
                              'AV $ownerName',
                              style: const TextStyle(
                                color: BrutalistPalette.muted,
                                fontSize: 12,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'BESKRIVELSE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (project['description']?.toString().trim().isNotEmpty ??
                                false)
                            ? project['description'].toString()
                            : 'Ingen beskrivelse',
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: BrutalistPalette.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.groups_outlined,
                              size: 18,
                              color: BrutalistPalette.muted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Teamstørrelse: ${project['max_members'] ?? '-'}',
                              style: const TextStyle(
                                color: BrutalistPalette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!isOwner && project['status'] == 'recruiting')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: brutalistPrimaryButtonStyle(),
                    onPressed: hasApplied || isLoading ? null : showApplyDialog,
                    child: isLoading
                        ? const SizedBox(
                            width: 96,
                            child: LinearProgressIndicator(minHeight: 2),
                          )
                        : hasApplied
                        ? const Text('SØKNAD SENDT')
                        : const Text('BLI MED'),
                  ),
                ),
              if (isOwner)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: brutalistOutlineButtonStyle(active: true),
                    onPressed: null,
                    child: const Text('DU EIER DETTE PROSJEKTET'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(dynamic status) {
    final text = (status?.toString() ?? '').trim();
    if (text.isEmpty) {
      return 'UKJENT STATUS';
    }
    return text.toUpperCase();
  }
}
