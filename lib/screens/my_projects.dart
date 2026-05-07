import 'package:flutter/material.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';
import 'package:devconnect/models/project.dart';
import 'package:devconnect/services/auth_service.dart';
import 'package:devconnect/services/project_service.dart';
import 'project_detail_screen.dart';
import 'create_project_screen.dart';

class MyProjectsScreen extends StatefulWidget {
  const MyProjectsScreen({super.key});

  @override
  State<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends State<MyProjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();
  final _projectService = ProjectService();

  List<Project> ownedProjects = [];
  List<Project> memberProjects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadProjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadProjects() async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final owned = await _projectService.getOwnedProjects(userId);
      final member = await _projectService.getMemberProjects(userId);

      if (mounted) {
        setState(() {
          ownedProjects = owned;
          memberProjects = member;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feil: $e')),
        );
      }
    }
  }

  Widget _buildProjectCard(Project project, {bool isOwner = false}) {
    final statusColor = isOwner ? BrutalistPalette.accent : Colors.green;
    final statusLabel = isOwner ? 'Eier' : 'Medlem';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: statusColor),
                color: statusColor.withValues(alpha: 0.12),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: statusColor,
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
            const SizedBox(height: 4),
            if (project.owner != null)
              Text(
                'Av ${project.owner!.displayLabel}',
                style: const TextStyle(
                  fontSize: 12,
                  color: BrutalistPalette.muted,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailScreen(project: project.toMap()),
            ),
          );
          if (!mounted) return;
          if (result != null) {
            await loadProjects();
          }
        },
      ),
    );
  }

  Widget _buildTab(List<Project> projects, {required bool isOwner}) {
    if (projects.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadProjects,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    isOwner
                        ? 'Du har ikke opprettet noen prosjekter ennå'
                        : 'Du er ikke med i noen prosjekter ennå',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: BrutalistPalette.muted),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: loadProjects,
      child: ListView.builder(
        itemCount: projects.length,
        itemBuilder: (context, index) =>
            _buildProjectCard(projects[index], isOwner: isOwner),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabBar = TabBar(
      controller: _tabController,
      indicatorColor: BrutalistPalette.accent,
      labelColor: BrutalistPalette.accent,
      unselectedLabelColor: BrutalistPalette.muted,
      tabs: [
        Tab(text: 'Egne (${ownedProjects.length})'),
        Tab(text: 'Medlem (${memberProjects.length})'),
      ],
    );

    return BrutalistScaffold(
      appBar: BrutalistHeader(
        title: 'Mine prosjekter',
        bottom: tabBar,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: BrutalistPalette.accent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
          );
          if (!mounted) return;
          if (result != null) {
            await loadProjects();
          }
        },
        child: const Icon(Icons.add),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildTab(ownedProjects, isOwner: true),
          _buildTab(memberProjects, isOwner: false),
        ],
      ),
    );
  }
}