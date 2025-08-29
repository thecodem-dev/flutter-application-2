import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../widgets/dashboard_layout.dart';
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

class ProfessionalTeacherDashboard extends StatefulWidget {
  const ProfessionalTeacherDashboard({super.key});
  @override
  State<ProfessionalTeacherDashboard> createState() =>
      _ProfessionalTeacherDashboardState();
}

class _ProfessionalTeacherDashboardState
    extends State<ProfessionalTeacherDashboard> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  List<String> uploadedFileIds = [];
  bool uploading = false;
  bool creating = false;
  List<dynamic> modules = [];
  int _currentIndex = 0;
  IO.Socket? socket;

  @override
  void initState() {
    super.initState();
    _fetchModules();
    _setupSocket();
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
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() {
        uploading = false;
      });
    }
  }

  Future<void> _createModule() async {
    if (titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a module title')),
      );
      return;
    }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Module created successfully')),
      );
      // Switch to modules view
      setState(() {
        _currentIndex = 1;
      });
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

  Widget _buildCreateModuleView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New Module',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Module Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload Files',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                              label: Text(
                                '${uploadedFileIds.length} file(s) uploaded',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Supported formats: PDF, DOC, PPT, Images',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: creating ? null : _createModule,
                  icon: const Icon(Icons.add),
                  label: creating
                      ? const Text('Creating...')
                      : const Text('Publish Module'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModulesView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Modules',
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
                      'No modules created yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create your first module to get started',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentIndex = 0;
                        });
                      },
                      child: const Text('Create Module'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: modules.length,
                itemBuilder: (_, i) {
                  final m = modules[i];
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
                              color: Theme.of(context).colorScheme.primary,
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
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Teacher Dashboard',
      userType: 'teacher',
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
                  'Total Modules',
                  modules.length.toString(),
                  Icons.library_books,
                ),
                const SizedBox(width: 16),
                _buildStatCard('Students', '128', Icons.people),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Files Uploaded',
                  uploadedFileIds.length.toString(),
                  Icons.file_upload,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tab bar
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _buildTabItem('Create', 0),
                  _buildTabItem('My Modules', 1),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Content based on selected tab
          Expanded(
            child: _currentIndex == 0
                ? _buildCreateModuleView()
                : _buildModulesView(),
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

  Widget _buildTabItem(String title, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
