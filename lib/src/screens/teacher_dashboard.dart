import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api.dart';

// helpers for multipart with auth header
import 'package:http/http.dart' as http;
import '../services/session.dart';

class MultipartRequestWithHeaders extends http.MultipartRequest {
  MultipartRequestWithHeaders(super.method, super.url) {
    Session.token().then((t) {
      if (t != null) headers['Authorization'] = 'Bearer $t';
    });
  }
}

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});
  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  List<String> uploadedFileIds = [];
  bool uploading = false;
  bool creating = false;
  List<dynamic> modules = [];

  @override
  void initState() {
    super.initState();
    _fetchModules();
  }

  Future<void> _fetchModules() async {
    modules = await Api.getList('/modules');
    setState(() {});
  }

  Future<void> _pickAndUploadFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;
    setState(() {
      uploading = true;
    });
    try {
      // Build multipart manually
      final uri = Uri.parse('${Api.base}/files/upload');
      final req = MultipartRequestWithHeaders('POST', uri);
      for (final f in result.files) {
        if (f.bytes == null) continue;
        req.files.add(
          http.MultipartFile.fromBytes(
            'files',
            f.bytes as Uint8List,
            filename: f.name,
          ),
        );
      }
      final res = await req.send();
      final body = jsonDecode(await res.stream.bytesToString());
      uploadedFileIds = List<String>.from(body['fileIds'] ?? []);
      setState(() {});
    } finally {
      setState(() {
        uploading = false;
      });
    }
  }

  Future<void> _createModule() async {
    setState(() {
      creating = true;
    });
    try {
      final data = await Api.post('/modules', {
        'title': titleCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'fileIds': uploadedFileIds,
      });
      titleCtrl.clear();
      descCtrl.clear();
      uploadedFileIds = [];
      await _fetchModules();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Module created')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        creating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Module',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Module Title',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: uploading ? null : _pickAndUploadFiles,
                            icon: const Icon(Icons.upload_file),
                            label: Text(
                              uploading ? 'Uploading...' : 'Upload Files',
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (uploadedFileIds.isNotEmpty)
                            Chip(
                              label: Text('${uploadedFileIds.length} file(s)'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: creating ? null : _createModule,
                          child: creating
                              ? const CircularProgressIndicator()
                              : const Text('Publish Module'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Modules',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: modules.length,
                          itemBuilder: (_, i) {
                            final m = modules[i];
                            return ListTile(
                              title: Text(m['title']),
                              subtitle: Text(m['description'] ?? ''),
                              trailing: Text(
                                DateTime.parse(
                                  m['createdAt'],
                                ).toLocal().toString().split('.').first,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
