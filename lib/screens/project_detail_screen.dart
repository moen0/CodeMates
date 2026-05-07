import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/services/application_service.dart';
import '/services/project_service.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';
import 'edit_project_screen.dart';
import 'projects_chat_screen.dart';
import 'public_profile_screen.dart';
import '../models/project_member.dart';
import 'package:devconnect/services/auth_service.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _applicationService = ApplicationService();
  final _projectService = ProjectService();
  final _authService = AuthService();
  bool isLoading = false;
  bool hasApplied = false;
  List<ProjectMember> members = [];
  late Map<String, dynamic> project;

  @override
  void initState() {
    super.initState();
    project = Map<String, dynamic>.from(widget.project);
    checkIfApplied();
    _loadMembers();
  }

  Future<void> checkIfApplied() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        return;
      }
      final existing = await _applicationService.hasUserApplied(
        projectId: project['id'],
        userId: userId,
      );
      if (mounted) setState(() => hasApplied = existing);
    } catch (_) {}
  }

  Future<void> _loadMembers() async {
    try {
      final result = await _projectService.getProjectMembers(project['id']);
      if (mounted) setState(() => members = result);
    } catch (_) {}
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
            onPressed: () => Navigator.pop(dialogContext, messageController.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    messageController.dispose();
    if (!mounted || message == null || message.isEmpty) return;

    setState(() => isLoading = true);
    try {
      await _applicationService.apply(project['id'], message);
      if (!mounted) return;
      setState(() => hasApplied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Søknad sendt!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feil: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _openEditScreen() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(builder: (_) => EditProjectScreen(project: project)),
    );
    if (!mounted) return;
    if (result == 'deleted') {
      Navigator.pop(context, 'deleted');
    } else if (result == true) {
      try {
        final refreshed = await _projectService.getProjectByIdWithDetails(project['id']);
        if (refreshed != null && mounted) setState(() => project = refreshed);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUserId;
    final isOwner = userId != null && project['owner_id'] == userId;
    final ownerName =
        project['profiles']?['display_name'] ??
        project['profiles']?['email'] ??
        'Ukjent';
    final meetingLink = project['meeting_link'] as String?;

    return BrutalistScaffold(
      appBar: BrutalistHeader(
        title: project['title'].toString(),
        actions: isOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Rediger prosjekt',
                  onPressed: _openEditScreen,
                ),
              ]
            : null,
      ),
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
                      // Title + status row
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: BrutalistPalette.accent.withValues(alpha: 0.18),
                              border: Border.all(color: BrutalistPalette.accent),
                            ),
                            child: Text(
                              _statusLabel(project['status']),
                              style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: BrutalistPalette.border),
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

                      // Description
                      const SizedBox(height: 20),
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
                        (project['description']?.toString().trim().isNotEmpty ?? false)
                            ? project['description'].toString()
                            : 'Ingen beskrivelse',
                      ),

                      // Team size
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: BrutalistPalette.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.groups_outlined, size: 18, color: BrutalistPalette.muted),
                            const SizedBox(width: 8),
                            Text(
                              'Teamstørrelse: ${project['max_members'] ?? '-'}',
                              style: const TextStyle(color: BrutalistPalette.muted),
                            ),
                          ],
                        ),
                      ),

                      // Meeting link
                      if (meetingLink != null && meetingLink.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'MØTEROM',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _MeetingLinkTile(link: meetingLink),
                      ],

                      // Members
                      const SizedBox(height: 20),
                      const Text(
                        'MEDLEMMER',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (members.isEmpty)
                        const Text(
                          'Ingen medlemmer ennå',
                          style: TextStyle(color: BrutalistPalette.muted),
                        )
                      else
                        ...members.map((m) {
                          final profile = m.user;
                          final name = profile?.displayLabel ?? 'Ukjent';
                          final memberId = m.userId;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PublicProfileScreen(userId: memberId),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: BrutalistPalette.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_outline, size: 16, color: BrutalistPalette.muted),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(name)),
                                    const Icon(Icons.chevron_right, size: 16, color: BrutalistPalette.muted),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),

              // Action buttons
              const SizedBox(height: 12),
              if (isOwner || (userId != null && members.any((m) => m.userId == userId)))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: brutalistOutlineButtonStyle(),
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text('PROSJEKTCHAT'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectChatScreen(
                            projectId: project['id'],
                            projectTitle: project['title'],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (!isOwner && project['status'] == 'recruiting')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: brutalistPrimaryButtonStyle(),
                    onPressed: hasApplied || isLoading ? null : showApplyDialog,
                    child: isLoading
                        ? const SizedBox(width: 96, child: LinearProgressIndicator(minHeight: 2))
                        : hasApplied
                        ? const Text('SØKNAD SENDT')
                        : const Text('BLI MED'),
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
    return text.isEmpty ? 'UKJENT STATUS' : text.toUpperCase();
  }
}

class _MeetingLinkTile extends StatelessWidget {
  final String link;
  const _MeetingLinkTile({required this.link});

  IconData get _icon {
    final l = link.toLowerCase();
    if (l.contains('discord')) return Icons.discord;
    if (l.contains('meet.google') || l.contains('zoom')) return Icons.videocam_outlined;
    if (l.contains('teams')) return Icons.groups_outlined;
    return Icons.link;
  }

  String get _label {
    final l = link.toLowerCase();
    if (l.contains('discord')) return 'Discord';
    if (l.contains('meet.google')) return 'Google Meet';
    if (l.contains('zoom')) return 'Zoom';
    if (l.contains('teams')) return 'Microsoft Teams';
    return 'Møtelenke';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: link));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lenke kopiert')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: BrutalistPalette.accent),
          color: BrutalistPalette.accent.withValues(alpha: 0.08),
        ),
        child: Row(
          children: [
            Icon(_icon, size: 18, color: BrutalistPalette.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label,
                    style: const TextStyle(
                      color: BrutalistPalette.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    link,
                    style: const TextStyle(
                      color: BrutalistPalette.muted,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.copy_outlined, size: 16, color: BrutalistPalette.muted),
          ],
        ),
      ),
    );
  }
}
