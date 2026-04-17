import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:devconnect/services/matching_service.dart';
import 'project_detail_screen.dart';
import 'create_project_screen.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, this.onOpenProfileTab});

  final VoidCallback? onOpenProfileTab;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final MatchingService _matchingService = MatchingService();

  List<Map<String, dynamic>> projects = [];
  bool isLoading = true;
  bool showNoSkillsHint = false;

  @override
  void initState() {
    super.initState();
    loadProjects();
  }

  Future<void> loadProjects() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;

      var projectsQuery = Supabase.instance.client
          .from('projects')
          .select('*, profiles:owner_id(display_name, email)')
          .eq('status', 'recruiting');

      if (currentUser != null) {
        projectsQuery = projectsQuery.neq('owner_id', currentUser.id);
      }

      final response = await projectsQuery.order('created_at', ascending: false);

      final loadedProjects = List<Map<String, dynamic>>.from(response);
      final projectIds = loadedProjects
          .map((project) => project['id']?.toString())
          .whereType<String>()
          .toList();

      Map<String, int> matchesByProject = const <String, int>{};
      var shouldShowNoSkillsHint = false;

      if (currentUser != null && projectIds.isNotEmpty) {
        final matchResult = await _matchingService.calculateMatchesForUser(
          currentUser.id,
          projectIds,
        );
        matchesByProject = matchResult.scores;
        shouldShowNoSkillsHint = !matchResult.userHasSkills;
      } else if (currentUser != null) {
        final matchResult = await _matchingService.calculateMatchesForUser(
          currentUser.id,
          const <String>[],
        );
        shouldShowNoSkillsHint = !matchResult.userHasSkills;
      }

      for (final project in loadedProjects) {
        final projectId = project['id']?.toString();
        project['_matchScore'] =
            currentUser == null
                ? null
                : (projectId == null ? 0 : (matchesByProject[projectId] ?? 0));
      }

      if (currentUser != null) {
        loadedProjects.sort((a, b) {
          final scoreA = (a['_matchScore'] as int?) ?? 0;
          final scoreB = (b['_matchScore'] as int?) ?? 0;
          if (scoreA != scoreB) {
            return scoreB.compareTo(scoreA);
          }

          final createdA =
              DateTime.tryParse(a['created_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final createdB =
              DateTime.tryParse(b['created_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return createdB.compareTo(createdA);
        });
      }

      if (mounted) {
        setState(() {
          projects = loadedProjects;
          showNoSkillsHint = shouldShowNoSkillsHint;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kunne ikke laste prosjekter: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrutalistScaffold(
      appBar: const BrutalistHeader(title: 'Utforsk prosjekter'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: BrutalistPalette.accent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
          );
          if (result == true) {
            loadProjects();
          }
        },
        child: const Icon(Icons.add),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : projects.isEmpty
              ? const Center(child: Text('Ingen prosjekter ennå'))
              : RefreshIndicator(
                  onRefresh: loadProjects,
                  child: ListView.builder(
                    itemCount: projects.length + (showNoSkillsHint ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (showNoSkillsHint && index == 0) {
                        return InkWell(
                          onTap: widget.onOpenProfileTab,
                          child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: BrutalistPalette.panel,
                            border: Border.fromBorderSide(
                              BorderSide(color: BrutalistPalette.accent),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Legg til ferdigheter for bedre matching.',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: BrutalistPalette.accent,
                              ),
                            ],
                          ),
                        ));
                      }

                      final project =
                          projects[index - (showNoSkillsHint ? 1 : 0)];
                      final owner = project['profiles'];
                      final matchScore = project['_matchScore'] as int?;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: BrutalistPalette.panel,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(color: BrutalistPalette.border),
                        ),
                        child: ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  project['title'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (matchScore != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: BrutalistPalette.accent),
                                    color: BrutalistPalette.accent.withValues(alpha: 0.12),
                                  ),
                                  child: Text(
                                    '$matchScore% treff',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: BrutalistPalette.accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                project['description'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Av ${owner?['display_name'] ?? owner?['email'] ?? 'Ukjent'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: BrutalistPalette.muted,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProjectDetailScreen(project: project),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
