import 'package:flutter/material.dart';
import 'package:devconnect/services/matching_service.dart';
import 'package:devconnect/services/auth_service.dart';
import 'package:devconnect/services/project_service.dart';
import 'package:devconnect/models/project.dart';
import 'package:devconnect/models/skill.dart';
import 'project_detail_screen.dart';
import 'create_project_screen.dart';
import 'public_profile_screen.dart';
import 'register.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, this.onOpenProfileTab, this.isGuest = false});

  final VoidCallback? onOpenProfileTab;
  final bool isGuest;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final MatchingService _matchingService = MatchingService();
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  final ProjectService _projectService = ProjectService();

  List<Project> projects = [];
  Map<String, List<Skill>> _projectSkills = {};
  Map<String, int> _matchScores = {};
  bool isLoading = true;
  bool showNoSkillsHint = false;
  String _searchQuery = '';
  String? _selectedSkillId;
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

  List<Project> _applyFilters(
    List<Project> source,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    return source.where((project) {
      if (!_matchesFilter(project)) return false;
      if (query.isEmpty) return true;

      final title = project.title.toLowerCase();
      final description = project.description.toLowerCase();
      return title.contains(query) || description.contains(query);
    }).toList();
  }

  bool _matchesFilter(Project project) {
    if (_selectedSkillId == null) return true;
    final projectId = project.id;
    final skills = _projectSkills[projectId] ?? const <Skill>[];
    return skills.any((skill) => skill.id == _selectedSkillId);
  }

  void _sortProjects(List<Project> source, bool hasUser) {
    source.sort((a, b) {
      if (hasUser && _sortMode == 'match') {
        final scoreA = _matchScores[a.id] ?? 0;
        final scoreB = _matchScores[b.id] ?? 0;
        if (scoreA != scoreB) {
          return scoreB.compareTo(scoreA);
        }
      }

      return b.createdAt.compareTo(a.createdAt);
    });
  }

  Future<void> loadProjects() async {
    try {
      final currentUserId = _authService.currentUserId;

      final loadedProjects = await _projectService.getRecruitingProjects(
        excludeOwnerId: currentUserId,
      );

      final projectIds = loadedProjects.map((project) => project.id).toList();
      final projectSkills =
          await _projectService.getProjectSkillsForProjects(projectIds);

      final skillLookup = <String, String>{};
      for (final skills in projectSkills.values) {
        for (final skill in skills) {
          skillLookup[skill.id] = skill.name;
        }
      }

      var shouldShowNoSkillsHint = false;
      final matchScores = <String, int>{};

      if (currentUserId != null) {
        final matchResult = await _matchingService.calculateMatchesForUser(
          currentUserId,
          projectIds,
        );
        matchScores.addAll(matchResult.scores);
        shouldShowNoSkillsHint = !matchResult.userHasSkills;
      }

      _sortProjects(loadedProjects, currentUserId != null);

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
          _matchScores = matchScores;
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
    final hasUser = _authService.isLoggedIn;
    final filteredProjects = _applyFilters(projects);
    final hasResults = filteredProjects.isNotEmpty;

    return BrutalistScaffold(
      appBar: const BrutalistHeader(title: 'Utforsk prosjekter'),
      // Gjest-modus: sticky terminal-banner i bunn istedenfor navigasjonsmeny
      bottomNavigationBar: widget.isGuest ? _buildGuestBanner(context) : null,
      floatingActionButton: widget.isGuest
          ? null
          : FloatingActionButton(
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
                      hasUser,
                      filteredProjects.length,
                    );
                  }

                  if (!hasResults) {
                    if (showNoSkillsHint && index == 1) {
                      return _buildNoSkillsHint();
                    }
                    // Skil mellom "ingen prosjekter finnes" og "ingen søketreff"
                    final hasActiveFilter = _searchQuery.isNotEmpty || _selectedSkillId != null;
                    return _buildEmptyResults(isFilterEmpty: !hasActiveFilter);
                  }

                  final hintIndex = showNoSkillsHint ? 1 : -1;
                  if (showNoSkillsHint && index == hintIndex) {
                    return _buildNoSkillsHint();
                  }

                  final project =
                      filteredProjects[index - (showNoSkillsHint ? 2 : 1)];
                  final owner = project.owner;
                  final matchScore =
                      hasUser ? _matchScores[project.id] : null;
                  final skills = _projectSkills[project.id] ?? const <Skill>[];

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
                              project.title,
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
                            project.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (skills.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: skills.take(4).map((skill) {
                                final name = skill.name.toUpperCase();
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
                              final ownerId = project.ownerId;
                              if (ownerId.isEmpty) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PublicProfileScreen(userId: ownerId),
                                ),
                              );
                            },
                            child: Text(
                              'Av ${owner?.displayLabel ?? 'Ukjent'}',
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
                            builder: (_) => ProjectDetailScreen(
                              project: _projectToMap(project),
                              isGuest: widget.isGuest,
                            ),
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

  Map<String, dynamic> _projectToMap(Project project) {
    return {
      'id': project.id,
      'owner_id': project.ownerId,
      'title': project.title,
      'description': project.description,
      'status': project.status,
      'created_at': project.createdAt.toIso8601String(),
      'updated_at': project.updatedAt?.toIso8601String(),
      'max_members': project.maxMembers,
      'meeting_link': project.meetingLink,
      'project_type': project.projectType,
      'goal': project.goal,
      'profiles': project.owner == null
          ? null
          : {
              'display_name': project.owner!.displayName,
              'email': project.owner!.email,
            },
    };
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

  Widget _buildEmptyResults({required bool isFilterEmpty}) {
    final message = isFilterEmpty
        ? 'Ingen prosjekter publisert ennå'
        : 'Ingen treff med dette søket';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: BrutalistPanel(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: const TextStyle(color: BrutalistPalette.muted),
        ),
      ),
    );
  }

  // Terminal-stil gjest-banner nederst på skjermen
  Widget _buildGuestBanner(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: BrutalistPalette.panel,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '> GJEST_MODE: read_only',
                  style: TextStyle(
                    color: BrutalistPalette.muted,
                    fontSize: 11,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '  registrer for full tilgang',
                  style: TextStyle(
                    color: BrutalistPalette.border,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Register()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: BrutalistPalette.accent),
                ),
                child: const Text(
                  '[REGISTRER]',
                  style: TextStyle(
                    color: BrutalistPalette.accent,
                    fontSize: 11,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
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
              // Gjest-indikator ved siden av CONNECTED
              if (widget.isGuest) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: BrutalistPalette.muted),
                  ),
                  child: const Text(
                    'GJEST',
                    style: TextStyle(
                      color: BrutalistPalette.muted,
                      fontSize: 9,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
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
                final hasUser = _authService.isLoggedIn;
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
  final String? skillId;

  const _FeedFilter({required this.label, this.skillId});
}
