import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:devconnect/services/matching_service.dart';
import 'project_detail_screen.dart';
import 'create_project_screen.dart';
import 'public_profile_screen.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, this.onOpenProfileTab});

  final VoidCallback? onOpenProfileTab;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final MatchingService _matchingService = MatchingService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> projects = [];
  Map<String, List<Map<String, dynamic>>> _projectSkills = {};
  bool isLoading = true;
  bool showNoSkillsHint = false;
  String _searchQuery = '';
  int? _selectedSkillId;
  String _selectedFilterLabel = 'ALL';
  String _sortMode = 'match';

  List<_FeedFilter> _filters = const [
    _FeedFilter(label: 'ALL'),
  ];

  @override
  void initState() {
    super.initState();
    loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> source,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    return source.where((project) {
      if (!_matchesFilter(project)) return false;
      if (query.isEmpty) return true;

      final title = (project['title'] ?? '').toString().toLowerCase();
      final description =
          (project['description'] ?? '').toString().toLowerCase();
      return title.contains(query) || description.contains(query);
    }).toList();
  }

  bool _matchesFilter(Map<String, dynamic> project) {
    if (_selectedSkillId == null) return true;
    final projectId = project['id']?.toString();
    if (projectId == null) return false;
    final skills = _projectSkills[projectId] ?? const <Map<String, dynamic>>[];
    return skills.any((skill) => skill['id'] == _selectedSkillId);
  }

  void _sortProjects(List<Map<String, dynamic>> source, bool hasUser) {
    source.sort((a, b) {
      if (hasUser && _sortMode == 'match') {
        final scoreA = (a['_matchScore'] as int?) ?? 0;
        final scoreB = (b['_matchScore'] as int?) ?? 0;
        if (scoreA != scoreB) {
          return scoreB.compareTo(scoreA);
        }
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

      final projectSkills = <String, List<Map<String, dynamic>>>{};
      final skillLookup = <int, String>{};

      if (projectIds.isNotEmpty) {
        final skillRows = await Supabase.instance.client
            .from('project_skills')
            .select('project_id, skills(id, name)')
            .inFilter('project_id', projectIds);

        for (final row in skillRows) {
          final map = Map<String, dynamic>.from(row);
          final projectId = map['project_id']?.toString();
          final skill = map['skills'] as Map<String, dynamic>?;
          final skillId = skill?['id'] as int?;
          final skillName = skill?['name']?.toString();
          if (projectId == null || skillId == null || skillName == null) {
            continue;
          }

          projectSkills.putIfAbsent(projectId, () => <Map<String, dynamic>>[]);
          projectSkills[projectId]!.add({
            'id': skillId,
            'name': skillName,
          });
          skillLookup[skillId] = skillName;
        }
      }

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
        project['_matchScore'] = currentUser == null
            ? null
            : (projectId == null ? 0 : (matchesByProject[projectId] ?? 0));
      }

      _sortProjects(loadedProjects, currentUser != null);

      final filterOptions = <_FeedFilter>[const _FeedFilter(label: 'ALL')];
      final sortedSkills = skillLookup.entries.toList()
        ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
      for (final entry in sortedSkills) {
        filterOptions.add(
          _FeedFilter(label: entry.value.toUpperCase(), skillId: entry.key),
        );
      }

      var selectedSkillId = _selectedSkillId;
      var selectedFilterLabel = _selectedFilterLabel;
      if (selectedSkillId != null && !skillLookup.containsKey(selectedSkillId)) {
        selectedSkillId = null;
        selectedFilterLabel = 'ALL';
      } else if (selectedSkillId != null) {
        selectedFilterLabel =
            skillLookup[selectedSkillId]?.toUpperCase() ?? 'ALL';
      }

      if (mounted) {
        setState(() {
          projects = loadedProjects;
          _projectSkills = projectSkills;
          _filters = filterOptions;
          _selectedSkillId = selectedSkillId;
          _selectedFilterLabel = selectedFilterLabel;
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
    final currentUser = Supabase.instance.client.auth.currentUser;
    final filteredProjects = _applyFilters(projects);
    final hasResults = filteredProjects.isNotEmpty;

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
          : RefreshIndicator(
              onRefresh: loadProjects,
              child: ListView.builder(
                itemCount: hasResults
                    ? filteredProjects.length + (showNoSkillsHint ? 2 : 1)
                    : 2 + (showNoSkillsHint ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildFeedHeader(
                      currentUser != null,
                      filteredProjects.length,
                    );
                  }

                  if (!hasResults) {
                    if (showNoSkillsHint && index == 1) {
                      return _buildNoSkillsHint();
                    }
                    return _buildEmptyResults();
                  }

                  final hintIndex = showNoSkillsHint ? 1 : -1;
                  if (showNoSkillsHint && index == hintIndex) {
                    return _buildNoSkillsHint();
                  }

                  final project = filteredProjects[
                      index - (showNoSkillsHint ? 2 : 1)
                  ];
                  final owner = project['profiles'];
                  final matchScore = project['_matchScore'] as int?;
                  final projectId = project['id']?.toString();
                  final skills = projectId == null
                      ? const <Map<String, dynamic>>[]
                      : (_projectSkills[projectId] ??
                          const <Map<String, dynamic>>[]);

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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
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
                          if (skills.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: skills.take(4).map((skill) {
                                final name =
                                    skill['name']?.toString().toUpperCase() ?? '';
                                return Container(
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
                                    name,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: BrutalistPalette.muted,
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              final ownerId = project['owner_id'] as String?;
                              if (ownerId == null) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PublicProfileScreen(userId: ownerId),
                                ),
                              );
                            },
                            child: Text(
                              'Av ${owner?['display_name'] ?? owner?['email'] ?? 'Ukjent'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: BrutalistPalette.accent,
                                decoration: TextDecoration.underline,
                                decorationColor: BrutalistPalette.accent,
                              ),
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

  Widget _buildNoSkillsHint() {
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
      ),
    );
  }

  Widget _buildEmptyResults() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: BrutalistPanel(
        padding: const EdgeInsets.all(16),
        child: const Text(
          'Ingen treff med dette søket',
          style: TextStyle(color: BrutalistPalette.muted),
        ),
      ),
    );
  }

  Widget _buildFeedHeader(bool hasUser, int resultCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: BrutalistPalette.accent,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'CONNECTED',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                _formatHeaderDate(DateTime.now()),
                style: const TextStyle(
                  color: BrutalistPalette.muted,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: brutalistInputDecoration(
              labelText: 'Søk i prosjekter',
              hintText: 'Tittel eller beskrivelse',
            ).copyWith(
              suffixIcon: _searchQuery.isEmpty
                  ? const Icon(Icons.search, size: 18)
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildFilterRow(),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                r'$ QUERY --filter=' + _selectedFilterLabel.toLowerCase(),
                style: const TextStyle(
                  color: BrutalistPalette.muted,
                  letterSpacing: 1.1,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '$resultCount RESULTATER',
                style: const TextStyle(
                  color: BrutalistPalette.accent,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'SORTERING',
                style: TextStyle(
                  color: BrutalistPalette.muted,
                  letterSpacing: 1.1,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              _buildSortChip('match', 'MATCH', enabled: hasUser),
              const SizedBox(width: 8),
              _buildSortChip('newest', 'NYEST', enabled: true),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: BrutalistPalette.border, height: 1),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = filter.skillId == _selectedSkillId;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedSkillId = null;
                    _selectedFilterLabel = 'ALL';
                  } else {
                    _selectedSkillId = filter.skillId;
                    _selectedFilterLabel = filter.label;
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? BrutalistPalette.panel
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? BrutalistPalette.accent
                        : BrutalistPalette.border,
                  ),
                ),
                child: Text(
                  filter.label,
                  style: TextStyle(
                    color: isSelected
                        ? BrutalistPalette.accent
                        : BrutalistPalette.muted,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSortChip(String value, String label, {required bool enabled}) {
    final isSelected = _sortMode == value;
    return GestureDetector(
      onTap: !enabled
          ? null
          : () {
              if (_sortMode == value) return;
              setState(() {
                _sortMode = value;
                final hasUser =
                    Supabase.instance.client.auth.currentUser != null;
                _sortProjects(projects, hasUser);
              });
            },
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? BrutalistPalette.accent.withValues(alpha: 0.12)
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? BrutalistPalette.accent
                  : BrutalistPalette.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? BrutalistPalette.accent
                  : BrutalistPalette.muted,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  String _formatHeaderDate(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year.toString().substring(2);
    return '$day.${months[date.month - 1]}.$year';
  }
}

class _FeedFilter {
  final String label;
  final int? skillId;

  const _FeedFilter({required this.label, this.skillId});
}
