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
  List<Map<String, dynamic>> _exactDuplicates = const [];
  List<Map<String, dynamic>> _nearDuplicates = const [];
  List<Map<String, dynamic>> _projects = const [];
  Map<String, dynamic>? _job;
  String? _pairingToken;
  String? _error;
  bool _busy = false;
  int _section = 0;
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

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() => _run(() async {
        final client = _getClient();
        await client.health();
        final values = await Future.wait([client.stats(), client.photos(limit: 120)]);
        if (!mounted) return;
        setState(() {
          _stats = values[0] as Map<String, dynamic>;
          _photos = values[1] as List<Map<String, dynamic>>;
        });
      });

  Future<void> _loadDuplicates() => _run(() async {
        final client = _getClient();
        final values = await Future.wait([
          client.exactDuplicates(limit: 100),
          client.nearDuplicates(maxDistance: 5, limit: 200),
        ]);
        if (!mounted) return;
        setState(() {
          _exactDuplicates = values[0];
          _nearDuplicates = values[1];
        });
      });

  Future<void> _loadProjects() => _run(() async {
        final result = await _getClient().projects();
        if (mounted) setState(() => _projects = result);
      });

  Future<void> _loadPairingToken() => _run(() async {
        final token = await _getClient().localPairingToken();
        if (mounted) setState(() => _pairingToken = token);
      });

  Future<void> _startScan() => _run(() async {
        final created = await _getClient().startScan(_libraryController.text.trim());
        final id = created['id'] as int;
        _jobTimer?.cancel();
        await _loadJob(id);
        _jobTimer = Timer.periodic(const Duration(seconds: 1), (_) => _loadJob(id));
      });

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

  Future<void> _selectSection(int value) async {
    setState(() => _section = value);
    if (value == 1) await _loadDuplicates();
    if (value == 2) await _loadProjects();
    if (value == 3 && _pairingToken == null) await _loadPairingToken();
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
            width: 330,
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
                FilledButton.icon(
                  onPressed: _busy ? null : _startScan,
                  icon: const Icon(Icons.manage_search),
                  label: const Text('Indexar biblioteca'),
                ),
                if (_job != null) ...[
                  const SizedBox(height: 16),
                  _JobCard(job: _job!),
                ],
                const SizedBox(height: 24),
                const Divider(),
                _NavButton(icon: Icons.photo_library, label: 'Galeria', selected: _section == 0, onTap: () => _selectSection(0)),
                _NavButton(icon: Icons.content_copy, label: 'Duplicadas', selected: _section == 1, onTap: () => _selectSection(1)),
                _NavButton(icon: Icons.view_in_ar, label: 'Projetos 3D', selected: _section == 2, onTap: () => _selectSection(2)),
                _NavButton(icon: Icons.devices, label: 'Parear celular', selected: _section == 3, onTap: () => _selectSection(3)),
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
                const Divider(height: 1),
                Expanded(child: _sectionBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionBody() {
    switch (_section) {
      case 1:
        return _duplicatesView();
      case 2:
        return _projectsView();
      case 3:
        return _pairingView();
      default:
        return _galleryView();
    }
  }

  Widget _galleryView() {
    if (_photos.isEmpty) return const Center(child: Text('Conecte ao servidor e indexe uma biblioteca.'));
    final client = _getClient();
    return GridView.builder(
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
              Image.network(
                client.thumbnailUrl(id),
                headers: client.authHeaders,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
              ),
              if (photo['ai_generated_hint'] == 1)
                const Positioned(top: 6, right: 6, child: Chip(label: Text('IA'))),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.black54,
                  child: Text(
                    photo['filename']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _duplicatesView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Duplicatas exatas', style: Theme.of(context).textTheme.headlineSmall),
        const Text('Mesmo conteúdo SHA-256. Nada é apagado automaticamente.'),
        const SizedBox(height: 12),
        if (_exactDuplicates.isEmpty) const Text('Nenhum grupo exato encontrado.'),
        for (final group in _exactDuplicates)
          Card(
            child: ListTile(
              leading: const Icon(Icons.copy_all),
              title: Text('${group['count']} arquivos iguais'),
              subtitle: Text((group['photos'] as List).map((p) => p['filename']).join(' • ')),
            ),
          ),
        const SizedBox(height: 28),
        Text('Quase duplicatas', style: Theme.of(context).textTheme.headlineSmall),
        const Text('Candidatas por dHash. Revise antes de qualquer ação.'),
        const SizedBox(height: 12),
        if (_nearDuplicates.isEmpty) const Text('Nenhum candidato próximo encontrado.'),
        for (final pair in _nearDuplicates.take(100))
          Card(
            child: ListTile(
              leading: const Icon(Icons.compare),
              title: Text('${pair['left']['filename']} ↔ ${pair['right']['filename']}'),
              subtitle: Text('Similaridade dHash: ${((pair['similarity'] as num) * 100).toStringAsFixed(1)}%'),
            ),
          ),
      ],
    );
  }

  Widget _projectsView() {
    if (_projects.isEmpty) return const Center(child: Text('Nenhum projeto criado ainda.'));
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _projects.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final project = _projects[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.view_in_ar)),
          title: Text(project['name']?.toString() ?? 'Projeto'),
          subtitle: Text('${project['photo_count'] ?? 0} imagens • ${project['description'] ?? ''}'),
        );
      },
    );
  }

  Widget _pairingView() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phonelink_lock, size: 56),
                const SizedBox(height: 16),
                Text('Parear celular', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                const Text('No Android, informe o endereço deste PC e o token abaixo. O token só pode ser consultado localmente no PC.'),
                const SizedBox(height: 20),
                SelectableText(_pairingToken ?? 'Carregando token...', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                OutlinedButton.icon(onPressed: _busy ? null : _loadPairingToken, icon: const Icon(Icons.refresh), label: const Text('Mostrar/atualizar token')),
                const SizedBox(height: 12),
                const Text('QR code e descoberta automática por Wi-Fi entram na próxima etapa.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
      leading: Icon(icon),
      title: Text(label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: onTap,
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
