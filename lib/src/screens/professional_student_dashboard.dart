import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/dashboard_layout.dart';
import '../services/api.dart';

class ProfessionalStudentDashboard extends StatefulWidget {
  const ProfessionalStudentDashboard({super.key});
  @override
  State<ProfessionalStudentDashboard> createState() =>
      _ProfessionalStudentDashboardState();
}

class _ProfessionalStudentDashboardState
    extends State<ProfessionalStudentDashboard> {
  List<dynamic> modules = [];
  IO.Socket? socket;
  String? translatingForId;

  @override
  void initState() {
    super.initState();
    _fetchModules();
    _setupSocket();
  }

  Future<void> _fetchModules() async {
    try {
      modules = await Api.getList('/modules');
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load modules: $e')));
    }
  }

  void _setupSocket() {
    try {
      socket = IO.io(
        Api.base,
        IO.OptionBuilder().setTransports(['websocket']).build(),
      );
      socket!.onConnect((_) {
        debugPrint('Socket connected');
      });
      socket!.on('module:new', (data) {
        setState(() {
          modules.insert(0, data);
        });
      });
      socket!.on('file:new', (data) {
        setState(() {
          modules.insert(0, data);
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
    }
  }

  Future<void> _translateModule(dynamic mod) async {
    final id = mod['id'] ?? mod['_id'];
    setState(() {
      translatingForId = id;
    });
    try {
      // Basic demo: translate description; for PDFs, send base64 in body (server extracts)
      final res = await Api.post('/translate', {
        'text': (mod['description'] ?? '').toString(),
      });
      final translated = res['translatedText'] ?? '';

      // Show dialog with download option
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('IsiZulu Translation'),
            content: SingleChildScrollView(
              child: Text(translated.isEmpty ? 'No content' : translated),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () => _downloadTranslation(mod['title'], translated),
                child: const Text('Download'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Translate failed: $e')));
    } finally {
      setState(() {
        translatingForId = null;
      });
    }
  }

  Future<void> _translateModuleFiles(dynamic mod) async {
    final id = mod['id'] ?? mod['_id'];
    setState(() {
      translatingForId = id;
    });
    try {
      // Translate PDF files
      final res = await Api.postEmpty('/translate-pdf/$id');
      final translated = res['translatedText'] ?? '';

      // Show dialog with download option
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('IsiZulu Translation'),
            content: SingleChildScrollView(
              child: Text(translated.isEmpty ? 'No content' : translated),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () =>
                    _downloadTranslation('${mod['title']}_files', translated),
                child: const Text('Download'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Translate files failed: $e')));
    } finally {
      setState(() {
        translatingForId = null;
      });
    }
  }

  Future<void> _downloadTranslation(String? title, String content) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${title ?? 'translation'}_isizulu.txt';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content);

      // Share the file
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Translated content: $title');
      Navigator.pop(context); // Close the dialog
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  @override
  void dispose() {
    socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Student Dashboard',
      userType: 'student',
      currentPage: 'dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _fetchModules,
          tooltip: 'Refresh modules',
        ),
      ],
      child: Column(
        children: [
          // Stats cards
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildStatCard(
                  'Modules',
                  modules.length.toString(),
                  Icons.library_books,
                ),
                const SizedBox(width: 16),
                _buildStatCard('Completed', '3', Icons.check_circle),
                const SizedBox(width: 16),
                _buildStatCard('Points', '1250', Icons.stars),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Modules view (only view now)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learning Modules',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  if (modules.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.library_books,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No modules available yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your teacher will add modules soon',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                        itemCount: modules.length,
                        itemBuilder: (_, i) {
                          final m = modules[i];
                          final id = m['id'] ?? m['_id'];
                          final busy = translatingForId == id;
                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.library_books,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    m['title'] ?? 'Untitled Module',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Text(
                                      m['description'] ?? 'No description',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateTime.parse(
                                          m['createdAt'],
                                        ).toLocal().toString().split(' ')[0],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const Spacer(),
                                      Chip(
                                        label: Text(
                                          '${(m['fileIds'] ?? []).length}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: busy
                                        ? null
                                        : () => _translateModule(m),
                                    icon: const Icon(Icons.translate),
                                    label: Text(
                                      busy
                                          ? 'Translating...'
                                          : 'Translate to IsiZulu',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if ((m['fileIds'] ?? []).isNotEmpty)
                                    OutlinedButton.icon(
                                      onPressed: busy
                                          ? null
                                          : () => _translateModuleFiles(m),
                                      icon: const Icon(Icons.description),
                                      label: Text(
                                        busy
                                            ? 'Translating files...'
                                            : 'Translate Files',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
