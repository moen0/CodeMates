import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'project_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, dynamic>> projects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProjects();
  }

  Future<void> loadProjects() async {
    try {
      final response = await Supabase.instance.client
          .from('projects')
          .select()
          .eq('status', 'recruiting')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          projects = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Feil: $e');
      if (mounted) setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Utforsk prosjekter')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : projects.isEmpty
          ? const Center(child: Text('Ingen prosjekter ennå'))
          : RefreshIndicator(
        onRefresh: loadProjects,
        child: ListView.builder(
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            final owner = project['profiles'];

            return Card(
              margin: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(project['title'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
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
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectDetailScreen(
                          project: project),
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