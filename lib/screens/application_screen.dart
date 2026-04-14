import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/application_service.dart';
import 'package:devconnect/widgets/brutalist_ui.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen>
    with SingleTickerProviderStateMixin {
  final applicationService = ApplicationService();
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return BrutalistScaffold(
      appBar: BrutalistHeader(
        title: 'Søknader',
        bottom: TabBar(
          controller: tabController,
          indicatorColor: BrutalistPalette.accent,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Mottatte'),
            Tab(text: 'Sendte'),
          ],
        ),
      ),
      child: TabBarView(
        controller: tabController,
        children: [
          ReceivedApplicationsTab(service: applicationService),
          SentApplicationsTab(service: applicationService),
        ],
      ),
    );
  }
}

// Mottatte søknader (du er prosjekteier)
class ReceivedApplicationsTab extends StatefulWidget {
  final ApplicationService service;
  const ReceivedApplicationsTab({super.key, required this.service});

  @override
  State<ReceivedApplicationsTab> createState() =>
      _ReceivedApplicationsTabState();
}

class _ReceivedApplicationsTabState extends State<ReceivedApplicationsTab> {
  List<Map<String, dynamic>> applications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadApplications();
  }

  Future<void> loadApplications() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    // Hent prosjekter jeg eier
    final myProjects = await Supabase.instance.client
        .from('projects')
        .select('id')
        .eq('owner_id', userId);

    List<Map<String, dynamic>> allApps = [];
    for (var project in myProjects) {
      final apps = await widget.service.getProjectApplications(project['id']);
      allApps.addAll(apps);
    }

    if (mounted) {
      setState(() {
        applications = allApps;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (applications.isEmpty) {
      return const Center(child: Text('Ingen søknader å behandle'));
    }

    return ListView.builder(
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final app = applications[index];
        final profile = app['profiles'];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: BrutalistPalette.panel,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: BrutalistPalette.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?['display_name'] ?? profile?['email'] ?? 'Ukjent',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                if (app['message'] != null) Text(app['message']),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      style: brutalistPrimaryButtonStyle(),
                      onPressed: () async {
                        await widget.service.accept(
                          app['id'],
                          app['project_id'],
                          app['applicant_id'],
                        );
                        loadApplications();
                      },
                      child: const Text('Godkjenn'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: brutalistOutlineButtonStyle(),
                      onPressed: () async {
                        await widget.service.reject(app['id']);
                        loadApplications();
                      },
                      child: const Text('Avslå'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Sendte søknader (mine søknader)
class SentApplicationsTab extends StatefulWidget {
  final ApplicationService service;
  const SentApplicationsTab({super.key, required this.service});

  @override
  State<SentApplicationsTab> createState() => _SentApplicationsTabState();
}

class _SentApplicationsTabState extends State<SentApplicationsTab> {
  List<Map<String, dynamic>> applications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadApplications();
  }

  Future<void> loadApplications() async {
    final apps = await widget.service.getMyApplications();
    if (mounted) {
      setState(() {
        applications = apps;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (applications.isEmpty) {
      return const Center(child: Text('Du har ikke sendt noen søknader'));
    }

    return ListView.builder(
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final app = applications[index];
        final project = app['projects'];

        Color statusColor;
        switch (app['status']) {
          case 'accepted':
            statusColor = Colors.green;
            break;
          case 'rejected':
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.orange;
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: BrutalistPalette.panel,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: BrutalistPalette.border),
          ),
          child: ListTile(
            title: Text(project?['title'] ?? 'Ukjent prosjekt'),
            subtitle: Text(app['message'] ?? ''),
            trailing: Chip(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: BrutalistPalette.border),
              ),
              label: Text(
                app['status'],
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: statusColor,
            ),
          ),
        );
      },
    );
  }
}
