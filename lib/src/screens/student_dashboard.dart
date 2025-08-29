import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  List<dynamic> modules = [];
  IO.Socket? socket;
  String? translatingForId;

  @override
  void initState() {
    super.initState();
    _load();
    _setupSocket();
  }

  Future<void> _load() async {
    modules = await Api.getList('/modules');
    setState(() {});
  }

  void _setupSocket() {
    socket = IO.io(
      Api.base,
      IO.OptionBuilder().setTransports(['websocket']).build(),
    );
    socket!.onConnect((_) => debugPrint('Socket connected'));
    socket!.on('module:new', (data) {
      setState(() {
        modules.insert(0, data);
      });
    });
  }

  Future<void> _translateModule(dynamic mod) async {
    setState(() {
      translatingForId = mod['id'] ?? mod['_id'];
    });
    try {
      // Basic demo: translate description; for PDFs, send base64 in body (server extracts)
      final res = await Api.post('/translate', {
        'text': (mod['description'] ?? '').toString(),
      });
      final translated = res['translatedText'] ?? '';
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

      // Show dialog
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Student Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisExtent: 200,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: modules.length,
          itemBuilder: (_, i) {
            final m = modules[i];
            final id = m['id'] ?? m['_id'];
            final busy = translatingForId == id;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m['title'] ?? 'Module',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        m['description'] ?? '',
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OutlinedButton.icon(
                              onPressed: busy
                                  ? null
                                  : () => _translateModule(m),
                              icon: const Icon(Icons.translate),
                              label: Text(busy ? 'Translating...' : 'IsiZulu'),
                            ),
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
                        const Spacer(),
                        Chip(
                          label: Text('${(m['fileIds'] ?? []).length} file(s)'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    socket?.dispose();
    super.dispose();
  }
}
