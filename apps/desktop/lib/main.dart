import 'dart:async';

import 'package:flutter/material.dart';
import 'package:galeiria_client/galeiria_client.dart';

void main() => runApp(const GaleiriaDesktopApp());

class GaleiriaDesktopApp extends StatelessWidget {
  const GaleiriaDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Galeiria Desktop',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: Colors.indigo),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _serverController = TextEditingController(text: 'http://127.0.0.1:8765');
  final _libraryController = TextEditingController(text: r'D:\Fotos');
  GaleiriaClient? _client;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _photos = const [];
  Map<String, dynamic>? _job;
  String? _error;
  bool _busy = false;
  Timer? _jobTimer;

  @override
  void dispose() {
    _jobTimer?.cancel();
    _client?.close();
    _serverController.dispose();
    _libraryController.dispose();
    super.dispose();
  }

  GaleiriaClient _getClient() {
    final url = _serverController.text.trim();
    if (_client == null || _client!.baseUrl != url) {
      _client?.close();
      _client = GaleiriaClient(baseUrl: url);
    }
    return _client!;
  }

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = _getClient();
      await client.health();
      final values = await Future.wait([client.stats(), client.photos(limit: 60)]);
      if (!mounted) return;
      setState(() {
        _stats = values[0] as Map<String, dynamic>;
        _photos = values[1] as List<Map<String, dynamic>>;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startScan() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = _getClient();
      final created = await client.startScan(_libraryController.text.trim());
      final id = created['id'] as int;
      _jobTimer?.cancel();
      await _loadJob(id);
      _jobTimer = Timer.periodic(const Duration(seconds: 1), (_) => _loadJob(id));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadJob(int id) async {
    try {
      final job = await _getClient().scanJob(id);
      if (!mounted) return;
      setState(() => _job = job);
      if (job['status'] == 'completed' || job['status'] == 'failed') {
        _jobTimer?.cancel();
        await _refresh();
      }
    } catch (error) {
      _jobTimer?.cancel();
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galeiria'),
        actions: [
          IconButton(onPressed: _busy ? null : _refresh, icon: const Icon(Icons.refresh), tooltip: 'Atualizar'),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 320,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('PC / Servidor', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextField(controller: _serverController, decoration: const InputDecoration(labelText: 'Endereço da API')),
                const SizedBox(height: 20),
                Text('Biblioteca', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextField(controller: _libraryController, decoration: const InputDecoration(labelText: 'Pasta da biblioteca')),
                const SizedBox(height: 12),
                FilledButton.icon(onPressed: _busy ? null : _startScan, icon: const Icon(Icons.manage_search), label: const Text('Indexar biblioteca')),
                if (_job != null) ...[
                  const SizedBox(height: 16),
                  _JobCard(job: _job!),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _StatsBar(stats: _stats),
                Expanded(
                  child: _photos.isEmpty
                      ? const Center(child: Text('Conecte ao servidor e indexe uma biblioteca.'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemCount: _photos.length,
                          itemBuilder: (context, index) {
                            final photo = _photos[index];
                            final id = photo['id'] as int;
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(_getClient().thumbnailUrl(id), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      color: Colors.black54,
                                      child: Text(photo['filename']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar({this.stats});
  final Map<String, dynamic>? stats;

  @override
  Widget build(BuildContext context) {
    Widget item(String label, Object? value, IconData icon) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon), const SizedBox(width: 8), Text('$label: ${value ?? '-'}')]),
        );
    return Wrap(
      children: [
        item('Fotos', stats?['photos'], Icons.photo_library_outlined),
        item('Bibliotecas', stats?['libraries'], Icons.folder_outlined),
        item('Duplicadas', stats?['exact_duplicate_groups'], Icons.content_copy_outlined),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});
  final Map<String, dynamic> job;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Indexação: ${job['status']}'),
            const SizedBox(height: 8),
            Text('Encontradas: ${job['found']}'),
            Text('Indexadas: ${job['indexed']}'),
            Text('Ignoradas: ${job['skipped']}'),
            Text('Erros: ${job['errors']}'),
          ],
        ),
      ),
    );
  }
}
