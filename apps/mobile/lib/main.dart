import 'package:flutter/material.dart';
import 'package:galeiria_client/galeiria_client.dart';

void main() => runApp(const GaleiriaMobileApp());

class GaleiriaMobileApp extends StatelessWidget {
  const GaleiriaMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Galeiria',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: Colors.indigo),
      home: const MobileHomePage(),
    );
  }
}

class MobileHomePage extends StatefulWidget {
  const MobileHomePage({super.key});

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> {
  final _serverController = TextEditingController(text: 'http://192.168.1.100:8765');
  final _tokenController = TextEditingController();
  final _searchController = TextEditingController();
  GaleiriaClient? _client;
  List<Map<String, dynamic>> _photos = const [];
  List<Map<String, dynamic>> _searchResults = const [];
  List<Map<String, dynamic>> _projects = const [];
  Map<String, dynamic>? _stats;
  String _status = 'Informe o IP e o token mostrados no PC.';
  bool _loading = false;
  int _tab = 0;

  GaleiriaClient _getClient() {
    final url = _serverController.text.trim();
    final token = _tokenController.text.trim();
    if (_client == null || _client!.baseUrl != url) {
      _client?.close();
      _client = GaleiriaClient(baseUrl: url, token: token);
    } else {
      _client!.token = token;
    }
    return _client!;
  }

  @override
  void dispose() {
    _client?.close();
    _serverController.dispose();
    _tokenController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _loading = true;
      _status = 'Conectando ao PC...';
    });
    try {
      final client = _getClient();
      final health = await client.health();
      final results = await Future.wait([
        client.stats(),
        client.photos(limit: 120),
        client.projects(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _photos = results[1] as List<Map<String, dynamic>>;
        _projects = results[2] as List<Map<String, dynamic>>;
        _status = 'PC conectado • API ${health['version'] ?? ''}';
      });
    } catch (error) {
      if (mounted) setState(() => _status = 'Não foi possível conectar: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _searchResults = const []);
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await _getClient().search(query, limit: 120);
      if (mounted) setState(() => _searchResults = result);
    } catch (error) {
      if (mounted) setState(() => _status = 'Erro na busca: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshProjects() async {
    try {
      final result = await _getClient().projects();
      if (mounted) setState(() => _projects = result);
    } catch (error) {
      if (mounted) setState(() => _status = 'Erro ao carregar projetos: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Galeiria')),
      body: IndexedStack(
        index: _tab,
        children: [
          _galleryTab(),
          _searchTab(),
          _projectsTab(),
          _syncTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) {
          setState(() => _tab = value);
          if (value == 2) _refreshProjects();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.photo_library_outlined), selectedIcon: Icon(Icons.photo_library), label: 'Galeria'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Pesquisar'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Projetos'),
          NavigationDestination(icon: Icon(Icons.sync), label: 'Sync'),
        ],
      ),
    );
  }

  Widget _galleryTab() {
    return Column(
      children: [
        _connectionCard(),
        const Divider(height: 1),
        Expanded(child: _photoGrid(_photos, empty: 'A galeria do PC aparecerá aqui.')),
      ],
    );
  }

  Widget _connectionCard() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _serverController,
            decoration: const InputDecoration(
              labelText: 'PC Galeiria',
              hintText: 'http://192.168.1.10:8765',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.computer),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                    labelText: 'Token de pareamento',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key),
                  ),
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _loading ? null : _connect,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Conectar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: Text(_status)),
          if (_stats != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('${_stats!['photos']} fotos • ${_stats!['exact_duplicate_groups']} grupos duplicados'),
            ),
        ],
      ),
    );
  }

  Widget _searchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SearchBar(
            controller: _searchController,
            hintText: 'goblin, dragão, nome do projeto...',
            leading: const Icon(Icons.search),
            trailing: [IconButton(onPressed: _loading ? null : _search, icon: const Icon(Icons.arrow_forward))],
            onSubmitted: (_) => _search(),
          ),
        ),
        Expanded(child: _photoGrid(_searchResults, empty: 'Pesquise por nome, tag ou projeto.')),
      ],
    );
  }

  Widget _projectsTab() {
    if (_projects.isEmpty) {
      return const Center(child: Text('Nenhum projeto carregado. Criação de projetos pelo celular entra na próxima etapa.'));
    }
    return RefreshIndicator(
      onRefresh: _refreshProjects,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
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
      ),
    );
  }

  Widget _syncTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        ListTile(
          leading: Icon(Icons.wifi),
          title: Text('Sincronização na rede local'),
          subtitle: Text('O protocolo de upload retomável, descoberta automática e sync em background será a próxima grande etapa.'),
        ),
        ListTile(
          leading: Icon(Icons.security),
          title: Text('Pareamento protegido'),
          subtitle: Text('A API já exige token para dispositivos remotos. Futuramente o pareamento será feito por QR code.'),
        ),
      ],
    );
  }

  Widget _photoGrid(List<Map<String, dynamic>> photos, {required String empty}) {
    if (photos.isEmpty) return Center(child: Text(empty));
    final client = _getClient();
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        final id = photo['id'] as int;
        return Hero(
          tag: 'photo-$id',
          child: Material(
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PhotoPage(client: client, photo: photo)),
              ),
              child: Image.network(
                client.thumbnailUrl(id),
                headers: client.authHeaders,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black12, child: Icon(Icons.broken_image)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class PhotoPage extends StatelessWidget {
  const PhotoPage({super.key, required this.client, required this.photo});

  final GaleiriaClient client;
  final Map<String, dynamic> photo;

  @override
  Widget build(BuildContext context) {
    final id = photo['id'] as int;
    return Scaffold(
      appBar: AppBar(title: Text(photo['filename']?.toString() ?? 'Foto')),
      body: Center(
        child: Hero(
          tag: 'photo-$id',
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 6,
            child: Image.network(client.fileUrl(id), headers: client.authHeaders, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
